"
Records an MCP server's calls as its local backend does, and through OpenTelemetry when the OTEL_* environment asks for traces.

This class lives in the optional MCP-OpenTelemetry package so MCP core can remain free of OpenTelemetry dependencies.
"
Class {
	#name : 'MCPOpenTelemetryObservabilityBackend',
	#superclass : 'MCPLocalObservabilityBackend',
	#instVars : [
		'tracer',
		'meter',
		'logger',
		'inputSizeHistogram',
		'outputSizeHistogram',
		'outputBudgetExceededCounter',
		'recordsById',
		'operationDurationHistogram',
		'configured',
		'serverInfo'
	],
	#classVars : [
		'Backends',
		'OwnPackageNames'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend class >> configureProvidersWith: aSettings [
	"Rebuilds the image's OpenTelemetry from the settings as they are now, and answers whether they ask for traces."

	self resetProviders.
	^ self wantsTraces: aSettings
]

{ #category : 'class initialization' }
MCPOpenTelemetryObservabilityBackend class >> initialize [

	SessionManager default registerToolClassNamed: self name
]

{ #category : 'reporting' }
MCPOpenTelemetryObservabilityBackend class >> ownPackageNames [
	"The packages MCP's baseline lists, read once per image session. None when MCP was loaded without its baseline, so that nothing is taken for MCP's own by mistake."

	^ OwnPackageNames ifNil: [
			  OwnPackageNames := self environment
				                     at: #BaselineOfMCP
				                     ifPresent: [ :baseline |
						                     [ (baseline allPackageNames collect: [ :each | each asString ]) asSet ]
							                     on: Error
							                     do: [ Set new ] ]
				                     ifAbsent: [ Set new ] ]
]

{ #category : 'resource' }
MCPOpenTelemetryObservabilityBackend class >> pharoVersion [
	"Pharo's version with its build, as semantic versioning writes build metadata: 14.0.0+build.791. A development image changes from one build to the next."

	| version |
	version := SystemVersion current.
	^ '{1}.{2}.{3}+build.{4}' format: {
			  version major.
			  version minor.
			  version patch.
			  version build }
]

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend class >> reconfigure: someBackends with: aSettings [
	"Configures each of someBackends afresh from aSettings, the providers once for all of them. The providers are global and may be the user's: they are rebuilt only when the settings ask for traces or one of these backends was configured to record through them."

	| wanted |
	wanted := self wantsTraces: aSettings.
	(wanted or: [ someBackends anySatisfy: [ :each | each isConfiguredForTraces ] ]) ifTrue: [ self resetProviders ].
	someBackends do: [ :each |
			[ each configureFor: each serverInfo configured: wanted ]
				on: Error
				do: [ :error | error return: nil ] ]
]

{ #category : 'registry' }
MCPOpenTelemetryObservabilityBackend class >> register: aBackend [

	(Backends ifNil: [ Backends := WeakSet new ]) add: aBackend
]

{ #category : 'registry' }
MCPOpenTelemetryObservabilityBackend class >> registeredBackends [
	"The backends of this kind the image still holds. A weak registry, so that finding them neither walks the heap nor keeps one alive; one dropped since the last garbage collection may still be answered, which costs it a reconfiguration it does not use."

	^ (Backends ifNil: [ ^ #(  ) ]) asArray select: [ :each | each isNotNil ]
]

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend class >> resetProviders [
	"Drops the image's OpenTelemetry providers, processors and exporters, which are global. Those an image was saved with would otherwise keep sending where an earlier session's settings said, after those settings changed or were removed; and a processor a reset shut down would be handed to the next provider."

	{
		OTTracerProvider.
		OTSpanProcessor.
		OTSpanExporter.
		OTMeterProvider.
		OTLoggerProvider } do: [ :each |
			[ each reset ]
				on: Error
				do: [ :error | error return: nil ] ]
]

{ #category : 'resource' }
MCPOpenTelemetryObservabilityBackend class >> resourceAttributesFor: aServerInfo [
	"What the image's telemetry says about what ran: this server and its version, the OpenTelemetry SDK, the OS family, and the Pharo and VM versions. Never the host name, the process, its command line or the image's path, which the SDK's default detectors would send and which name the user and the project. An attribute Pharo cannot tell, or the SDK would refuse, is left out, and the others still describe the server."

	| attributes |
	attributes := OrderedDictionary new.
	attributes at: 'service.name' put: 'pharo-mcp'.
	[
		OTTracerProvider defaultResource attributes keysAndValuesDo: [ :key :value |
			(key beginsWith: 'telemetry.sdk.') ifTrue: [ attributes at: key put: value ] ] ]
		on: Error
		do: [ nil ].
	{
		('service.version' -> [ aServerInfo version ]).
		('process.runtime.name' -> [ OTTracerProvider runtimeName ]).
		('process.runtime.version' -> [ self pharoVersion ]).
		('process.runtime.description' -> [ Smalltalk vm version trimBoth ]).
		('os.type' -> [ OTTracerProvider defaultOsType ]) } do: [ :each |
			[ each value value ifNotNil: [ :value | attributes at: each key put: (OTAttributeNormalizer normalizeAttributeValue: value) ] ]
				on: Error
				do: [ nil ] ].
	^ attributes
]

{ #category : 'resource' }
MCPOpenTelemetryObservabilityBackend class >> resourceDetectorsFor: aServerInfo [
	"OTEL_RESOURCE_ATTRIBUTES first, so whoever runs the image can add attributes, such as deployment.environment.name, but not rename the server or change what it says about itself; OTEL_SERVICE_NAME is not read, for the same reason. The server's own attributes are read each time a provider is made, so an image started again elsewhere describes where it runs."

	^ OrderedCollection new
		  add: OTEnvironmentResourceDetector new;
		  add: (OTBlockResourceDetector
				   named: 'mcp'
				   detecting: [
					   OTResource attributes: (self resourceAttributesFor: aServerInfo) schemaUrl: OTTracerProvider semanticConventionsSchemaUrl ]);
		  yourself
]

{ #category : 'resource' }
MCPOpenTelemetryObservabilityBackend class >> resourceIsConfigured [
	"Whether the configuration file the image was started with, named by OTEL_CONFIG_FILE, says what its telemetry describes. Whoever wrote it chose, so it wins."

	^ [ OTConfigurationSource configuredResource isNotNil ]
		  on: Error
		  do: [ false ]
]

{ #category : 'system startup' }
MCPOpenTelemetryObservabilityBackend class >> startUp: resuming [
	"An image starting again may run elsewhere, with other settings or none: every backend of this kind is configured afresh from them, before its server answers a call. An image without one leaves OpenTelemetry alone."

	| backends |
	resuming ifFalse: [ ^ self ].
	OwnPackageNames := nil.
	backends := self registeredBackends.
	backends ifEmpty: [ ^ self ].
	[ self reconfigure: backends with: MCPOpenTelemetrySettings current ]
		on: Error
		do: [ :error | error return: nil ]
]

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend class >> wantsTraces: aSettings [

	^ [ aSettings isConfigured ]
		  on: Error
		  do: [ false ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> argumentNamesIn: inputObject [
	"The names of the arguments a call was given, sorted, without their values; at most maxArgumentNames of them."

	| names |
	inputObject isDictionary ifFalse: [ ^ #(  ) ].
	names := ((inputObject keys collect: [ :each | each asString ] as: Array) select: [ :each | self isReportableName: each ]) sort.
	^ names first: (names size min: self maxArgumentNames)
]

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend >> configureFor: aServerInfo configured: aBoolean [
	"Records through OpenTelemetry from now on, through the providers as they now are, only when aBoolean, so the settings ask for traces, and the providers could be made to describe the server. Instruments made from earlier providers are dropped."

	serverInfo := aServerInfo.
	tracer := nil.
	meter := nil.
	logger := nil.
	inputSizeHistogram := nil.
	outputSizeHistogram := nil.
	outputBudgetExceededCounter := nil.
	operationDurationHistogram := nil.
	configured := aBoolean and: [ self describeServer: aServerInfo ]
]

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend >> configureFor: aServerInfo settings: aSettings [
	"Configures this backend from aSettings. The providers, which are global and may be the user's, are rebuilt only when the settings ask for traces or another backend was configured to record through them."

	| wanted |
	wanted := self class wantsTraces: aSettings.
	(wanted or: [ self class registeredBackends anySatisfy: [ :each | each ~~ self and: [ each isConfiguredForTraces ] ] ]) ifTrue: [
		self class resetProviders ].
	self configureFor: aServerInfo configured: wanted
]

{ #category : 'resource' }
MCPOpenTelemetryObservabilityBackend >> describeServer: aServerInfo [
	"Makes the image's OpenTelemetry providers describe this server and nothing that identifies the machine, its user or the image, now and whenever they are made again, unless a configuration file says what they describe. Answers whether they do. A provider the SDK would not let describe the server would describe the machine through its default detectors instead, so then nothing is recorded."

	| detectors resource |
	self class resourceIsConfigured ifTrue: [ ^ true ].
	^ [
		  detectors := self class resourceDetectorsFor: aServerInfo.
		  resource := OTTracerProvider resourceFromDetectors: detectors.
		  OTTracerProvider resourceDetectors: detectors.
		  {
			  OTTracerProvider.
			  OTMeterProvider.
			  OTLoggerProvider } do: [ :each | each current resource: resource ].
		  true ]
		  on: Error
		  do: [ false ]
]

{ #category : 'private - logging' }
MCPOpenTelemetryObservabilityBackend >> emitEventNamed: eventName body: bodyString [

	self logger logRecordBuilder
		eventName: eventName;
		body: bodyString;
		emit
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> endSpan: span withAttributes: attributes record: aRecord at: finishedAt [
	"Instrumentation leaves a successful span's status unset. A failed one is marked without a description, because the conventions would put the error message there and a message is a value."

	span ifNil: [ ^ nil ].
	attributes do: [ :each | span attributeAt: each key put: each value ].
	aRecord outputBudgetExceeded ifTrue: [ span addEventNamed: 'pharo.mcp.output_budget_exceeded' attributes: #(  ) ].
	aRecord status = 'error' ifTrue: [ span setStatus: OTSpan error description: '' ].
	span end: finishedAt
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> errorTypeFor: anError [
	"error.type as the conventions for MCP spell it: the JSON-RPC code of a protocol error, and tool_error for a call answered with a result that reports one."

	(anError isNotNil and: [ anError mcpIsProtocolError ]) ifFalse: [ ^ 'tool_error' ].
	^ [ (anError asJRPCResponseWithId: nil) error code printString ]
		  on: Error
		  do: [ :error | '_OTHER' ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> finishAttributesFor: aRecord error: anError errorType: errorType [
	"What is known once a call is answered: sizes, and for a failure its kind. An exception is named by its nearest class in Pharo or MCP, and never by its message or stack."

	| attributes |
	attributes := OrderedCollection new.
	attributes
		add: 'pharo.mcp.input.bytes' -> aRecord inputByteCount;
		add: 'pharo.mcp.output.bytes' -> aRecord outputByteCount;
		add: 'pharo.mcp.output_budget.exceeded' -> aRecord outputBudgetExceeded.
	errorType ifNil: [ ^ attributes asArray ].
	attributes add: 'error.type' -> errorType.
	aRecord errorKind ifNotEmpty: [ :kind | attributes add: 'pharo.mcp.error.kind' -> kind ].
	(aRecord errorCode isNotEmpty and: [ self isReportableName: aRecord errorCode ]) ifTrue: [
		attributes add: 'pharo.mcp.error.code' -> aRecord errorCode ].
	aRecord schemaViolationCount > 0 ifTrue: [
		attributes add: 'pharo.mcp.error.schema.violation_count' -> aRecord schemaViolationCount ].
	anError ifNotNil: [ attributes add: 'pharo.mcp.exception.type' -> (self reportableClassNameOf: anError class) ].
	^ attributes asArray
]

{ #category : 'private - flushing' }
MCPOpenTelemetryObservabilityBackend >> flushProvidersWithin: milliseconds [
	"The flush goes on in the background past the wait. An error there is dropped: in a headless image an unhandled one would quit it."

	| done |
	done := Semaphore new.
	[
		[
			{
				OTTracerProvider.
				OTMeterProvider.
				OTLoggerProvider } do: [ :each |
					[ each current forceFlush ]
						on: Error
						do: [ :error | error return: nil ] ] ] ensure: [ done signal ] ]
		forkAt: Processor userBackgroundPriority
		named: 'MCP OpenTelemetry flush'.
	done waitTimeoutMilliseconds: milliseconds
]

{ #category : 'private - flushing' }
MCPOpenTelemetryObservabilityBackend >> flushTimeoutMilliseconds [

	^ 1000
]

{ #category : 'actions' }
MCPOpenTelemetryObservabilityBackend >> forceFlush [
	"Writes the local metrics, and gives OpenTelemetry's providers at most flushTimeoutMilliseconds to send what they hold, so that stopping a server never waits on an unreachable collector."

	super forceFlush.
	self isRecordingTraces ifTrue: [ self flushProvidersWithin: self flushTimeoutMilliseconds ]
]

{ #category : 'initialization' }
MCPOpenTelemetryObservabilityBackend >> initialize [

	super initialize.
	recordsById := Dictionary new.
	self class register: self
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> inputSizeHistogram [

	inputSizeHistogram ifNotNil: [ ^ inputSizeHistogram ].
	inputSizeHistogram := self meter histogramNamed: 'pharo.mcp.tool.input.size' unit: 'By' description: 'MCP tool-call input size'.
	^ inputSizeHistogram
]

{ #category : 'testing' }
MCPOpenTelemetryObservabilityBackend >> isConfiguredForTraces [
	"Whether settings that ask for traces configured it, so that the providers are its doing."

	^ configured == true
]

{ #category : 'testing' }
MCPOpenTelemetryObservabilityBackend >> isRecordingTraces [
	"Whether it records traces through the providers as they are: unless it was configured from settings that ask for none, or providers that would not describe its server. It records locally either way."

	^ configured ~~ false
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isReportableName: aString [
	"A name the caller chose leaves the image only when it reads as an identifier, so a value put where a name belongs is never exported: at most 64 ASCII letters, digits, underscores and hyphens, starting with a letter or an underscore."

	| isWordCharacter |
	(aString isString and: [ aString size between: 1 and: 64 ]) ifFalse: [ ^ false ].
	isWordCharacter := [ :each | each asInteger < 128 and: [ each isAlphaNumeric or: [ each = $_ ] ] ].
	^ (aString first isDigit not and: [ isWordCharacter value: aString first ]) and: [
		  aString allSatisfy: [ :each | (isWordCharacter value: each) or: [ each = $- ] ] ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isReportablePackageName: aName [
	"Pharo's kernel and collections, and MCP's own packages, which a user's package cannot be taken for by sharing a prefix."

	^ (#( 'Kernel' 'Collections' ) anySatisfy: [ :prefix | aName = prefix or: [ aName beginsWith: prefix , '-' ] ]) or: [
		  self class ownPackageNames includes: aName asString ]
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> logger [

	logger ifNotNil: [ ^ logger ].
	logger := OTLoggerProvider current loggerNamed: 'mcp-pharo'.
	^ logger
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> maxArgumentNames [

	^ 32
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> meter [

	meter ifNotNil: [ ^ meter ].
	meter := OTMeterProvider current meterNamed: 'mcp-pharo'.
	^ meter
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> operationDurationHistogram [

	operationDurationHistogram ifNotNil: [ ^ operationDurationHistogram ].
	operationDurationHistogram := self meter
		                              histogramNamed: 'mcp.server.operation.duration'
		                              unit: 's'
		                              description: 'MCP request duration as observed on the receiver'.
	^ operationDurationHistogram
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> originOfTool: aTool [
	"mcp for a tool one of MCP's own packages defines, other for a tool another package registered, unknown when the server has no tool by the name it was called with."

	aTool ifNil: [ ^ 'unknown' ].
	^ (self class ownPackageNames includes: aTool class package name asString)
		  ifTrue: [ 'mcp' ]
		  ifFalse: [ 'other' ]
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> outputBudgetExceededCounter [

	outputBudgetExceededCounter ifNotNil: [ ^ outputBudgetExceededCounter ].
	outputBudgetExceededCounter := self meter
		                               counterNamed: 'pharo.mcp.tool.output_budget.exceeded'
		                               unit: '1'
		                               description: 'MCP tool calls exceeding output budget'.
	^ outputBudgetExceededCounter
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> outputSizeHistogram [

	outputSizeHistogram ifNotNil: [ ^ outputSizeHistogram ].
	outputSizeHistogram := self meter
		                       histogramNamed: 'pharo.mcp.tool.output.size'
		                       unit: 'By'
		                       description: 'MCP tool-call output size'.
	^ outputSizeHistogram
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> parentContextIn: contextDictionary [
	"The caller's trace context, which travels in the request's _meta under the unprefixed W3C keys (SEP-414), or the current context when the request carries none. A malformed one is ignored rather than allowed to fail the call."

	| meta |
	meta := contextDictionary at: #meta ifAbsent: [ nil ].
	(meta isDictionary and: [ meta isNotEmpty ]) ifFalse: [ ^ OpenTelemetry currentContext ].
	^ [ OpenTelemetry textMapPropagator extract: OpenTelemetry currentContext from: meta ]
		  on: Error
		  do: [ :error | OpenTelemetry currentContext ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> protocolVersionIn: contextDictionary [
	"The protocol version a modern request declares in its _meta; a legacy one declares it only at initialize, which this call does not see."

	| meta |
	meta := contextDictionary at: #meta ifAbsent: [ ^ nil ].
	meta isDictionary ifFalse: [ ^ nil ].
	^ meta at: MCP modernProtocolVersionKey ifAbsent: [ nil ]
]

{ #category : 'private - metrics' }
MCPOpenTelemetryObservabilityBackend >> recordMetricsFor: aRecord named: aToolName origin: anOrigin errorType: errorType [

	| attributes |
	attributes := OrderedCollection new.
	attributes
		add: 'mcp.method.name' -> 'tools/call';
		add: 'gen_ai.tool.name' -> aToolName;
		add: 'gen_ai.operation.name' -> 'execute_tool';
		add: 'pharo.mcp.tool.origin' -> anOrigin.
	errorType ifNotNil: [ attributes add: 'error.type' -> errorType ].
	attributes := attributes asArray.
	self operationDurationHistogram record: aRecord durationMilliseconds / 1000.0 attributes: attributes.
	self inputSizeHistogram record: aRecord inputByteCount attributes: attributes.
	self outputSizeHistogram record: aRecord outputByteCount attributes: attributes.
	aRecord outputBudgetExceeded ifTrue: [ self outputBudgetExceededCounter add: 1 attributes: attributes ]
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordSessionEnd [

	self isRecordingTraces ifTrue: [
		self withoutFailingTheCall: [ self emitEventNamed: 'mcp.session.end' body: 'MCP session ended' ] ].
	super recordSessionEnd
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordSessionStart [

	super recordSessionStart.
	self isRecordingTraces ifTrue: [
		self withoutFailingTheCall: [ self emitEventNamed: 'mcp.session.start' body: 'MCP session started' ] ]
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [
	"Records the end of the call locally, and ends its span when one was started."

	| entry errorType |
	super recordToolCallFinish: aRecord result: aToolResult error: anError.
	aRecord ifNil: [ ^ nil ].
	entry := recordsById removeKey: aRecord id ifAbsent: [ ^ aRecord ].
	self withoutFailingTheCall: [
			errorType := aRecord status = 'error'
				             ifTrue: [ self errorTypeFor: anError ]
				             ifFalse: [ nil ].
			self
				recordMetricsFor: aRecord
				named: (entry at: 2)
				origin: (entry at: 3)
				errorType: errorType.
			self
				endSpan: (entry at: 1)
				withAttributes: (self finishAttributesFor: aRecord error: anError errorType: errorType)
				record: aRecord
				at: aRecord finishedAt ].
	^ aRecord
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [
	"Records the call locally, and starts its span when the settings ask for traces."

	| record |
	record := super
		          recordToolCallStart: aToolName
		          input: inputObject
		          dispatchPath: dispatchPath
		          context: contextDictionary.
	(record isNil or: [ self isRecordingTraces not ]) ifTrue: [ ^ record ].
	self withoutFailingTheCall: [
			self
				startSpanFor: record
				named: aToolName
				input: inputObject
				context: contextDictionary ].
	^ record
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> reportableClassNameOf: aClass [
	"The nearest class, from aClass up, that Pharo's kernel or collections or MCP defines, so that no class of the user's leaves the image under its own name."

	| class |
	class := aClass.
	[ class isNotNil ] whileTrue: [
			(self isReportablePackageName: class package name) ifTrue: [ ^ class name asString ].
			class := class superclass ].
	^ '_OTHER'
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> reportableToolName: aToolName in: contextDictionary [
	"A tool the server has is named as it names itself. A name it does not have is the caller's, and leaves the image only when it reads as an identifier."

	^ ((contextDictionary at: #tool ifAbsent: [ nil ]) isNotNil or: [ self isReportableName: aToolName ])
		  ifTrue: [ aToolName ]
		  ifFalse: [ '_OTHER' ]
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> serverInfo [
	"What this backend's server says it is, as it was last configured with."

	^ serverInfo
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> sessionIdIn: aContext [
	"The session.id entry of the caller's W3C baggage, when it reads as an identifier: the session the call belongs to, as the caller counts sessions."

	| id |
	id := [ (OTBaggage fromContext: aContext) valueAt: 'session.id' ]
		      on: Error
		      do: [ :error | error return: nil ].
	^ (id isString and: [ self isReportableName: id ])
		  ifTrue: [ id ]
		  ifFalse: [ nil ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> startAttributesFor: aRecord named: aToolName origin: anOrigin input: inputObject context: contextDictionary parent: aContext [
	"The attributes known when a call starts, set before the span starts so a sampler sees them. They follow the OpenTelemetry conventions for MCP where those name the fact, and say nothing the caller passed but argument names and the session its trace context names."

	| attributes tool |
	tool := contextDictionary at: #tool ifAbsent: [ nil ].
	attributes := OrderedCollection new.
	attributes
		add: 'mcp.method.name' -> 'tools/call';
		add: 'gen_ai.tool.name' -> aToolName;
		add: 'gen_ai.operation.name' -> 'execute_tool';
		add: 'network.transport' -> 'tcp';
		add: 'network.protocol.name' -> 'http';
		add: 'pharo.mcp.dispatch_path' -> aRecord dispatchPath;
		add: 'pharo.mcp.tool.origin' -> anOrigin.
	(self sessionIdIn: aContext) ifNotNil: [ :id | attributes add: 'session.id' -> id ].
	(self protocolVersionIn: contextDictionary) ifNotNil: [ :version | attributes add: 'mcp.protocol.version' -> version ].
	(self argumentNamesIn: inputObject) ifNotEmpty: [ :names | attributes add: 'pharo.mcp.argument.names' -> names ].
	(self unknownArgumentNamesIn: inputObject for: tool) ifNotEmpty: [ :names |
		attributes add: 'pharo.mcp.argument.unknown_names' -> names ].
	^ attributes asArray
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> startSpanFor: aRecord named: aToolName input: inputObject context: contextDictionary [

	| name origin parent span |
	name := self reportableToolName: aToolName in: contextDictionary.
	origin := self originOfTool: (contextDictionary at: #tool ifAbsent: [ nil ]).
	parent := self parentContextIn: contextDictionary.
	span := (self tracer spanBuilderNamed: 'tools/call ' , name)
		        kind: OTSpan server;
		        inContext: parent;
		        attributes: (self
				         startAttributesFor: aRecord
				         named: name
				         origin: origin
				         input: inputObject
				         context: contextDictionary
				         parent: parent);
		        startSpan.
	recordsById at: aRecord id put: {
			span.
			name.
			origin }
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> tracer [

	tracer ifNotNil: [ ^ tracer ].
	tracer := OTTracerProvider current tracerNamed: 'mcp-pharo'.
	^ tracer
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> unknownArgumentNamesIn: inputObject for: aTool [
	"The argument names a call was given that its tool's schema does not declare: what agents expect a tool to take."

	| known |
	aTool ifNil: [ ^ #(  ) ].
	known := [ aTool inputSchema properties collect: [ :each | each name asString ] as: Set ]
		         on: Error
		         do: [ :error | ^ #(  ) ].
	^ (self argumentNamesIn: inputObject) reject: [ :each | known includes: each ]
]

{ #category : 'private - recording' }
MCPOpenTelemetryObservabilityBackend >> withoutFailingTheCall: aBlock [
	"Recording is never a reason for a tool call to fail. A warning while recording, such as a deprecation the SDK runs into, is resumed as a tool call resumes it, and the recording goes on; anything that goes wrong is dropped, and the call goes on unrecorded."

	^ [
		  aBlock
			  on: Warning
			  do: [ :warning | warning mcpResume ] ]
		  on: Error
		  do: [ :error | error return: nil ]
]
