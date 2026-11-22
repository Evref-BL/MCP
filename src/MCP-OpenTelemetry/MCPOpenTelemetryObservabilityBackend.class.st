"
Records an MCP server's calls as its local backend does, and through OpenTelemetry when its settings ask for traces: MCP's settings file, or else the OTEL_* environment.

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
		'serverInfo',
		'clock',
		'ownSessionId',
		'ownSessionLastCallAt',
		'sessionMutex'
	],
	#classVars : [
		'Backends',
		'OwnPackageNames',
		'PharoPackageNames'
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

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend class >> ownSessionClockTolerance [
	"How far the clock may go back without ending the server's own session, as a clock synchronization moves it."

	^ 1 minute
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend class >> ownSessionIdleTime [
	"How long the server's own session lasts without a call: the next call after it starts another."

	^ 30 minutes
]

{ #category : 'reporting' }
MCPOpenTelemetryObservabilityBackend class >> packageNamesOfBaselines: baselineNames [
	"The packages these baselines list, with those of the baselines they name as projects, and so on. A baseline the image does not have, or whose specification cannot be read, lists none."

	| names visited pending |
	names := Set new.
	visited := Set new.
	pending := OrderedCollection withAll: baselineNames.
	[ pending isEmpty ] whileFalse: [
			| baselineName |
			baselineName := pending removeFirst asSymbol.
			(visited includes: baselineName) ifFalse: [
					visited add: baselineName.
					self environment at: baselineName ifPresent: [ :baseline |
							[
								| version |
								version := baseline project version.
								names addAll: (version packages collect: [ :each | each name asString ]).
								pending addAll: (version projects collect: [ :each | 'BaselineOf' , each name asString ]) ]
								on: Error
								do: [ :error | error return: nil ] ] ] ].
	^ names
]

{ #category : 'reporting' }
MCPOpenTelemetryObservabilityBackend class >> pharoPackageNames [
	"The packages Pharo is made of, as its own baselines list them: its bootstrap, and BaselineOfPharo with the projects it loads. Read once per image session. A user's package is in none of them whatever its name, so it cannot pass for Pharo's by sharing a prefix."

	^ PharoPackageNames ifNil: [ PharoPackageNames := self packageNamesOfBaselines: #( #BaselineOfPharoBootstrap
	                          #BaselineOfPharo ) ]
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
	PharoPackageNames := nil.
	backends := self registeredBackends.
	backends ifEmpty: [ ^ self ].
	[ self reconfigure: backends with: MCPOpenTelemetrySettings current ]
		on: Error
		do: [ :error | error return: nil ]
]

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend class >> wantsTraces: aSettings [
	"Whether aSettings ask for traces, once MCP's settings file, when it gives any, has replaced the environment's."

	^ [
		  aSettings apply.
		  aSettings isConfigured ]
		  on: Error
		  do: [ false ]
]

{ #category : 'private - recording' }
MCPOpenTelemetryObservabilityBackend >> addAttributesFrom: aBlock to: attributes [
	"Adds the attributes aBlock answers, unless it fails: a fact that cannot be read leaves the others, and the span, as they are."

	(self withoutFailingTheCall: aBlock) ifNotNil: [ :more | attributes addAll: more ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> argumentNamesIn: inputObject for: aTool [
	"The names of the arguments a call was given that its tool declares, sorted, at most maxArgumentNames. A name the caller made up is only among the unknown ones, so that what an agent writes in a name it invents reaches a single attribute."

	| declared names |
	declared := self declaredArgumentNamesOf: aTool.
	names := (self reportableArgumentNamesIn: inputObject) select: [ :each | declared includes: each ].
	^ names first: (names size min: self maxArgumentNames)
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> clientAttributesIn: contextDictionary [
	"The client's name and version, as it reports them: self-reported, so only text that reads as a product's name, a letter then letters, digits, spaces, dots, underscores and hyphens, and as a version, a digit then letters, digits, dots, pluses and hyphens, each at most maxClientTextSize once trimmed."

	| info attributes |
	attributes := OrderedCollection new.
	info := self clientInfoIn: contextDictionary.
	info isDictionary ifFalse: [ ^ attributes ].
	(self reportableClientText: (info mcpAt: #name ifAbsent: [ nil ]) startingWith: [ :each | each isLetter ] then: ' ._-')
		ifNotNil: [ :name | attributes add: 'pharo.mcp.client.name' -> name ].
	(self reportableClientText: (info mcpAt: #version ifAbsent: [ nil ]) startingWith: [ :each | each isDigit ] then: '.+-')
		ifNotNil: [ :version | attributes add: 'pharo.mcp.client.version' -> version ].
	^ attributes
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> clientInfoIn: contextDictionary [
	"Who the client says it is: the identity a modern request's _meta carries, else the one the last initialize gave."

	| meta info |
	meta := contextDictionary at: #meta ifAbsent: [ nil ].
	info := meta isDictionary
		        ifTrue: [ meta at: MCP modernClientInfoKey ifAbsent: [ nil ] ]
		        ifFalse: [ nil ].
	info isDictionary ifTrue: [ ^ info ].
	^ contextDictionary at: #client ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> clock [
	"What answers the time a call is made at: the time of day, unless set."

	^ clock ifNil: [ [ DateAndTime now ] ]
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> clock: aBlock [

	clock := aBlock
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
	"Configures this backend from aSettings, and every other backend of its kind the image holds with it: the providers are global, so rebuilding them for one would leave the others recording through providers that were shut down. They are rebuilt only when the settings ask for traces or one of these backends was configured to record through them, since they may be the user's."

	serverInfo := aServerInfo.
	self class reconfigure: ((self class registeredBackends reject: [ :each | each == self ]) copyWith: self) with: aSettings
]

{ #category : 'configuring' }
MCPOpenTelemetryObservabilityBackend >> configureForServer: anMCP [
	"Configures this backend from MCP's settings as they are now: its settings file, or else the OTEL_* environment."

	self
		configureFor: ([ anMCP serverDescription ]
				 on: Error
				 do: [ nil ])
		settings: MCPOpenTelemetrySettings current
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> declaredArgumentNamesOf: aTool [
	"The argument names aTool's input schema declares; none without a tool, or with a schema that cannot be read."

	aTool ifNil: [ ^ Set new ].
	^ [ aTool inputSchema properties collect: [ :each | each name asString ] as: Set ]
		  on: Error
		  do: [ :error | error return: Set new ]
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
	"Instrumentation leaves a successful span's status unset. A failed one is marked without a description, because the conventions would put the error message there and a message is a value. The span ends whatever fails before: one never ended is never exported, as if the image had never received the call."

	span ifNil: [ ^ nil ].
	[
		attributes do: [ :each | self withoutFailingTheCall: [ span attributeAt: each key put: each value ] ].
		self withoutFailingTheCall: [
			aRecord outputBudgetExceeded ifTrue: [ span addEventNamed: 'pharo.mcp.output_budget_exceeded' attributes: #(  ) ] ].
		self withoutFailingTheCall: [ aRecord status = 'error' ifTrue: [ span setStatus: OTSpan error description: '' ] ] ] ensure: [
			(self withoutFailingTheCall: [
					 span end: finishedAt.
					 true ]) ifNil: [ self withoutFailingTheCall: [ span end ] ] ]
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
MCPOpenTelemetryObservabilityBackend >> finishAttributesFor: aRecord result: aToolResult origin: anOrigin error: anError errorType: errorType [
	"What is known once a call is answered: sizes, what a listing found, and for a failure its kind, its code, the class of the exception it raised or its answer names, and, when the input schema refused it, the keywords and paths it refused. An exception is named by its nearest class in Pharo or MCP, and never by its message or stack. Each fact is read on its own, so one that cannot be read leaves the others."

	| attributes |
	attributes := OrderedCollection new.
	self
		addAttributesFrom: [
				{
					('pharo.mcp.input.bytes' -> aRecord inputByteCount).
					('pharo.mcp.output.bytes' -> aRecord outputByteCount).
					('pharo.mcp.output_budget.exceeded' -> aRecord outputBudgetExceeded) } ]
		to: attributes.
	self addAttributesFrom: [ self resultAttributesFor: aToolResult origin: anOrigin ] to: attributes.
	errorType ifNil: [ ^ attributes asArray ].
	attributes add: 'error.type' -> errorType.
	self
		addAttributesFrom: [ aRecord errorKind ifEmpty: [ #(  ) ] ifNotEmpty: [ :kind | { ('pharo.mcp.error.kind' -> kind) } ] ]
		to: attributes.
	self
		addAttributesFrom: [
				(aRecord errorCode isNotEmpty and: [ self isReportableName: aRecord errorCode ])
					ifTrue: [ { ('pharo.mcp.error.code' -> aRecord errorCode) } ]
					ifFalse: [ #(  ) ] ]
		to: attributes.
	self addAttributesFrom: [ self schemaAttributesFor: aRecord result: aToolResult ] to: attributes.
	self
		addAttributesFrom: [
				(anError ifNil: [ self reportableClassNamed: aRecord errorClass ] ifNotNil: [ self reportableClassNameOf: anError class ])
					ifNil: [ #(  ) ]
					ifNotNil: [ :name | { ('pharo.mcp.exception.type' -> name) } ] ]
		to: attributes.
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
	sessionMutex := Mutex new.
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

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isList: anObject [

	^ anObject isCollection and: [ anObject isString not and: [ anObject isDictionary not ] ]
]

{ #category : 'testing' }
MCPOpenTelemetryObservabilityBackend >> isRecordingTraces [
	"Whether it records traces through the providers as they are: unless it was configured from settings that ask for none, or providers that would not describe its server. It records locally either way."

	^ configured ~~ false
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isReportableId: anObject [
	"An id the caller chose leaves the image only when it reads as one, a UUID or a hexadecimal or alphanumeric token: at most 64 ASCII letters, digits, underscores and hyphens."

	(anObject isString and: [ anObject size between: 1 and: 64 ]) ifFalse: [ ^ false ].
	^ anObject allSatisfy: [ :each | each asInteger < 128 and: [ each isAlphaNumeric or: [ each = $_ or: [ each = $- ] ] ] ]
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
	"Pharo's own packages, which its baselines list, and MCP's: a user's package cannot be taken for one of them by sharing a prefix."

	^ (self class pharoPackageNames includes: aName asString) or: [ self class ownPackageNames includes: aName asString ]
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

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> maxClientTextSize [

	^ 64
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> maxSchemaViolations [

	^ 8
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> maxToolRefs [

	^ 16
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> meter [

	meter ifNotNil: [ ^ meter ].
	meter := OTMeterProvider current meterNamed: 'mcp-pharo'.
	^ meter
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> nestedSchemaOf: aProperty [
	"The schema an object-valued property describes, or of the objects in a list."

	| items |
	(aProperty mcpAt: #properties ifAbsent: [ nil ]) ifNotNil: [ ^ aProperty ].
	items := aProperty mcpAt: #items ifAbsent: [ nil ].
	(items isDictionary and: [ (items mcpAt: #properties ifAbsent: [ nil ]) isNotNil ]) ifTrue: [ ^ items ].
	^ nil
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
MCPOpenTelemetryObservabilityBackend >> options: aSet chosenBy: aValue at: aPath property: aProperty required: isRequired [

	| nested default enum types |
	nested := self nestedSchemaOf: aProperty.
	nested ifNotNil: [
			((self isList: aValue)
				 ifTrue: [ aValue ]
				 ifFalse: [ { aValue } ]) do: [ :each |
					self
						options: aSet
						chosenIn: each
						schema: nested
						prefix: aPath ].
			^ aSet ].
	default := aProperty mcpAt: #default ifAbsent: [ Object new ].
	aValue = default ifTrue: [ ^ aSet ].
	enum := aProperty mcpAt: #enum ifAbsent: [ nil ].
	enum ifNotNil: [
			(enum includes: aValue) ifTrue: [ aSet add: aPath , '=' , aValue asString ].
			^ aSet ].
	isRequired ifFalse: [ aSet add: aPath ].
	types := aProperty mcpAt: #type ifAbsent: [ #(  ) ].
	types isString ifTrue: [ types := { types } ].
	((types includes: 'array') and: [ types size > 1 and: [ (self isList: aValue) and: [ aValue size > 1 ] ] ]) ifTrue: [
		aSet add: aPath , '[]' ].
	^ aSet
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> options: aSet chosenIn: arguments schema: aSchema prefix: aPrefix [

	| required properties |
	(arguments isDictionary and: [ aSchema isDictionary ]) ifFalse: [ ^ aSet ].
	required := ((aSchema mcpAt: #required ifAbsent: [ #(  ) ]) ifNil: [ #(  ) ]) collect: [ :each | each asString ] as: Set.
	properties := (aSchema mcpAt: #properties ifAbsent: [ nil ]) ifNil: [ Dictionary new ].
	arguments keysAndValuesDo: [ :key :value |
			| name path property |
			name := key asString.
			path := aPrefix ifEmpty: [ name ] ifNotEmpty: [ aPrefix , '.' , name ].
			property := properties mcpAt: name ifAbsent: [ nil ].
			(property isDictionary and: [ value isNotNil ]) ifTrue: [
					self
						options: aSet
						chosenBy: value
						at: path
						property: property
						required: (required includes: name) ] ].
	^ aSet
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> optionsChosenIn: inputObject for: aTool [
	"The options a call chose among those its tool's schema offers: an optional property it gave, an enumerated value other than the default (side=class), and the list form of a property that also takes a single value (packages[]). Sorted, at most maxArgumentNames."

	| schema options |
	aTool ifNil: [ ^ #(  ) ].
	schema := [ aTool inputSchema asJRPCJSON ]
		          on: Error
		          do: [ :error | ^ #(  ) ].
	options := (self
		            options: Set new
		            chosenIn: inputObject
		            schema: schema
		            prefix: '') asArray sort.
	^ options first: (options size min: self maxArgumentNames)
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
MCPOpenTelemetryObservabilityBackend >> ownSessionId [
	"The server's own session, for a call whose caller names none: a random id, made as OpenTelemetry makes a trace id, at the first such call, and made again when ownSessionIdleTime has passed since the last one, or the clock went back by ownSessionClockTolerance or more, as when the image starts on another machine; a clock set back less, as a time synchronization does, keeps it. Pharo's UUIDs are not used: they hold the time they were made and an identifier derived from the machine."

	^ self sessionMutex critical: [
			  | now idle |
			  now := self clock value.
			  idle := ownSessionLastCallAt ifNotNil: [ now - ownSessionLastCallAt ].
			  (idle isNil or: [ idle >= self class ownSessionIdleTime or: [ idle negated >= self class ownSessionClockTolerance ] ])
				  ifTrue: [ ownSessionId := OTIdGenerator default generateTraceIdHex ].
			  ownSessionLastCallAt := now.
			  ownSessionId ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> parentContextIn: contextDictionary [
	"The context a call's span continues: the caller's trace context, which travels in the request's _meta under the unprefixed W3C keys (SEP-414), or the current context when the request carries none, with the span of the call that dispatched this one as parent when one did. A malformed one is ignored rather than allowed to fail the call."

	| meta context |
	meta := contextDictionary at: #meta ifAbsent: [ nil ].
	context := (meta isDictionary and: [ meta isNotEmpty ])
		           ifTrue: [
				           [ OpenTelemetry textMapPropagator extract: OpenTelemetry currentContext from: meta ]
					           on: Error
					           do: [ :error | OpenTelemetry currentContext ] ]
		           ifFalse: [ OpenTelemetry currentContext ].
	^ (self spanOfRecord: (contextDictionary at: #parentRecord ifAbsent: [ nil ]))
		  ifNil: [ context ]
		  ifNotNil: [ :span | context withSpan: span ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> pathOfViolation: aViolation [
	"The path a violation names; for a missing required property, the validator names the object and the property apart, and the path is the property's."

	| path missing |
	aViolation isDictionary ifFalse: [ ^ nil ].
	path := aViolation mcpAt: #path ifAbsent: [ nil ].
	(self isList: path) ifFalse: [ ^ path ].
	(aViolation mcpAt: #keyword ifAbsent: [ nil ]) asString = 'required' ifFalse: [ ^ path ].
	missing := aViolation mcpAt: #expected ifAbsent: [ nil ].
	^ missing isString
		  ifTrue: [ path asArray copyWith: missing ]
		  ifFalse: [ path ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> pointerFor: aPath [

	(self isList: aPath) ifFalse: [ ^ nil ].
	(aPath allSatisfy: [ :each | (each isInteger and: [ each >= 0 ]) or: [ self isReportableName: each ] ]) ifFalse: [ ^ nil ].
	^ String streamContents: [ :stream |
			  aPath do: [ :each |
					  stream
						  nextPut: $/;
						  nextPutAll: each asString ] ]
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
	"Records the end of the call locally, and ends its span when one was started. Each step is guarded on its own, and the span ends whatever fails before it."

	| entry errorType attributes |
	self withoutFailingTheCall: [ super recordToolCallFinish: aRecord result: aToolResult error: anError ].
	aRecord ifNil: [ ^ nil ].
	entry := self critical: [ recordsById removeKey: aRecord id ifAbsent: [ nil ] ].
	entry ifNil: [ ^ aRecord ].
	errorType := self withoutFailingTheCall: [
			             aRecord status = 'error'
				             ifTrue: [ self errorTypeFor: anError ]
				             ifFalse: [ nil ] ].
	self withoutFailingTheCall: [
			self
				recordMetricsFor: aRecord
				named: (entry at: 2)
				origin: (entry at: 3)
				errorType: errorType ].
	attributes := (self withoutFailingTheCall: [
			               self
				               finishAttributesFor: aRecord
				               result: aToolResult
				               origin: (entry at: 3)
				               error: anError
				               errorType: errorType ]) ifNil: [ #(  ) ].
	self
		endSpan: entry first
		withAttributes: attributes
		record: aRecord
		at: aRecord finishedAt.
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
MCPOpenTelemetryObservabilityBackend >> reportableArgumentNamesIn: inputObject [
	"The names of the arguments a call was given that read as identifiers, sorted, without their values."

	inputObject isDictionary ifFalse: [ ^ #(  ) ].
	^ ((inputObject keys collect: [ :each | each asString ] as: Array) select: [ :each | self isReportableName: each ]) sort
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> reportableClassNameOf: aClass [
	"The nearest class, from aClass up, that Pharo's own packages or MCP's define, so that no class of the user's leaves the image under its own name."

	| class |
	class := aClass.
	[ class isNotNil ] whileTrue: [
			(self isReportablePackageName: class package name) ifTrue: [ ^ class name asString ].
			class := class superclass ].
	^ '_OTHER'
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> reportableClassNamed: aName [
	"The nearest class of Pharo or MCP to the class a result names, or nil when it names no class of the image. A name the image never interned names no class, and is not interned for asking."

	| symbol |
	(aName isString and: [ aName isNotEmpty ]) ifFalse: [ ^ nil ].
	symbol := Symbol findInterned: aName.
	symbol ifNil: [ ^ nil ].
	^ self class environment
		  at: symbol
		  ifPresent: [ :class |
				  class isClass
					  ifTrue: [ self reportableClassNameOf: class ]
					  ifFalse: [ nil ] ]
		  ifAbsent: [ nil ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> reportableClientText: anObject startingWith: firstBlock then: punctuation [
	"anObject trimmed, when it is text that starts with an ASCII character firstBlock accepts and goes on with ASCII letters, digits and punctuation, at most maxClientTextSize of them; else nil."

	| text |
	anObject isString ifFalse: [ ^ nil ].
	text := anObject trimBoth.
	(text size between: 1 and: self maxClientTextSize) ifFalse: [ ^ nil ].
	(text allSatisfy: [ :each | each asInteger < 128 and: [ each isAlphaNumeric or: [ punctuation includes: each ] ] ]) ifFalse: [
		^ nil ].
	^ (firstBlock value: text first)
		  ifTrue: [ text ]
		  ifFalse: [ nil ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> reportableToolName: aToolName in: contextDictionary [
	"A tool the server has is named as it names itself. A name it does not have is the caller's, and leaves the image only when it reads as an identifier."

	^ ((contextDictionary at: #tool ifAbsent: [ nil ]) isNotNil or: [ self isReportableName: aToolName ])
		  ifTrue: [ aToolName ]
		  ifFalse: [ '_OTHER' ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> resultAttributesFor: aToolResult origin: anOrigin [
	"What a result says it found, read from the data its structured content carries, as MCP's tools share it: how many entries a listing matched and whether it showed them all; for a test run, how many tests ran and how it ended; for a tool search or description, the tools it named."

	| content data attributes |
	attributes := OrderedCollection new.
	content := [ aToolResult structuredContent ]
		           on: Error
		           do: [ :error | ^ attributes ].
	content isDictionary ifFalse: [ ^ attributes ].
	data := content mcpAt: #data ifAbsent: [ nil ].
	data isDictionary ifFalse: [ ^ attributes ].
	(data mcpAt: #pagination ifAbsent: [ nil ]) ifNotNil: [ :pagination |
			pagination isDictionary ifTrue: [
					| total truncated |
					total := pagination mcpAt: #totalCount ifAbsent: [ nil ].
					truncated := pagination mcpAt: #truncated ifAbsent: [ nil ].
					total isInteger ifTrue: [ attributes add: 'pharo.mcp.result.count' -> total ].
					(truncated == true or: [ truncated == false ]) ifTrue: [ attributes add: 'pharo.mcp.result.more' -> truncated ] ] ].
	anOrigin = 'mcp' ifFalse: [ ^ attributes ].
	attributes addAll: (self testAttributesIn: data).
	(self toolNamesIn: data) ifNotEmpty: [ :names | attributes add: 'pharo.mcp.tool.refs' -> names ].
	^ attributes
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> schemaAttributesFor: aRecord result: aToolResult [
	"For a call its input schema refused, how many violations, which keywords and where."

	| attributes |
	attributes := OrderedCollection new.
	aRecord schemaViolationCount > 0 ifFalse: [ ^ attributes ].
	attributes add: 'pharo.mcp.error.schema.violation_count' -> aRecord schemaViolationCount.
	(self schemaKeywordsOf: aRecord) ifNotEmpty: [ :keywords | attributes add: 'pharo.mcp.error.schema.keywords' -> keywords ].
	(self schemaPathsIn: aToolResult) ifNotEmpty: [ :paths | attributes add: 'pharo.mcp.error.schema.paths' -> paths ].
	^ attributes
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> schemaKeywordsOf: aRecord [
	"The JSON Schema keywords the input broke, sorted, at most maxSchemaViolations."

	| keywords |
	keywords := ((aRecord schemaViolationKeywords ifNil: [ #(  ) ]) select: [ :each | self isReportableName: each ]) asArray sort.
	^ keywords first: (keywords size min: self maxSchemaViolations)
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> schemaPathsIn: aToolResult [
	"Where in the input the schema refused it, as JSON pointers (/scope/packages/1), sorted, at most maxSchemaViolations. A missing required property is pointed at, not the object that misses it. A path with a segment that does not read as a name or an index is left out."

	| paths |
	paths := Set new.
	(self violationsFromDetails: (self errorDetailsFromToolResult: aToolResult)) do: [ :each |
		(self pointerFor: (self pathOfViolation: each)) ifNotNil: [ :pointer | paths add: pointer ] ].
	paths := paths asArray sort.
	^ paths first: (paths size min: self maxSchemaViolations)
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> serverInfo [
	"What this backend's server says it is, as it was last configured with."

	^ serverInfo
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> sessionIdFor: aContext [
	"The session a call belongs to: the one its caller's baggage names, else the server's own."

	^ (self sessionIdIn: aContext) ifNil: [ self ownSessionId ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> sessionIdIn: aContext [
	"The session.id entry of the caller's W3C baggage, when it reads as an id: the session the call belongs to, as the caller counts sessions."

	| id |
	id := [ (OTBaggage fromContext: aContext) valueAt: 'session.id' ]
		      on: Error
		      do: [ :error | error return: nil ].
	^ (self isReportableId: id)
		  ifTrue: [ id ]
		  ifFalse: [ nil ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> sessionMutex [
	"Made in initialize; made here too for a backend that existed before this was loaded."

	^ sessionMutex ifNil: [ sessionMutex := Mutex new ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> spanOfRecord: aRecord [
	"The span of a call still running, or nil."

	aRecord ifNil: [ ^ nil ].
	^ self critical: [ recordsById at: aRecord id ifPresent: [ :entry | entry first ] ]
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> startAttributesFor: aRecord named: aToolName origin: anOrigin input: inputObject context: contextDictionary parent: aContext [
	"The attributes known when a call starts, set before the span starts so a sampler sees them. They follow the OpenTelemetry conventions for MCP where those name the fact, and say nothing the caller passed but argument names, those its tool declares apart from the others, the options its tool's schema offers that it chose, the session its trace context names, or else the server's own, and the client it says it is. Each fact is read on its own, so one that cannot be read leaves the others."

	| attributes tool |
	tool := contextDictionary at: #tool ifAbsent: [ nil ].
	attributes := OrderedCollection new.
	attributes
		add: 'mcp.method.name' -> 'tools/call';
		add: 'gen_ai.tool.name' -> aToolName;
		add: 'gen_ai.operation.name' -> 'execute_tool';
		add: 'network.transport' -> 'tcp';
		add: 'network.protocol.name' -> 'http';
		add: 'pharo.mcp.tool.origin' -> anOrigin.
	self addAttributesFrom: [ { ('pharo.mcp.dispatch_path' -> aRecord dispatchPath) } ] to: attributes.
	self addAttributesFrom: [ { ('session.id' -> (self sessionIdFor: aContext)) } ] to: attributes.
	self
		addAttributesFrom: [
		(self protocolVersionIn: contextDictionary) ifNil: [ #(  ) ] ifNotNil: [ :version | { ('mcp.protocol.version' -> version) } ] ]
		to: attributes.
	self addAttributesFrom: [ self clientAttributesIn: contextDictionary ] to: attributes.
	self
		addAttributesFrom: [
				(self argumentNamesIn: inputObject for: tool)
					ifEmpty: [ #(  ) ]
					ifNotEmpty: [ :names | { ('pharo.mcp.argument.names' -> names) } ] ]
		to: attributes.
	self
		addAttributesFrom: [
				(self unknownArgumentNamesIn: inputObject for: tool)
					ifEmpty: [ #(  ) ]
					ifNotEmpty: [ :names | { ('pharo.mcp.argument.unknown_names' -> names) } ] ]
		to: attributes.
	self
		addAttributesFrom: [
				(self optionsChosenIn: inputObject for: tool)
					ifEmpty: [ #(  ) ]
					ifNotEmpty: [ :options | { ('pharo.mcp.argument.options' -> options) } ] ]
		to: attributes.
	^ attributes asArray
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> startSpanFor: aRecord named: aToolName input: inputObject context: contextDictionary [
	"Starts the call's span, named as the server names its tool, as a child of the call that dispatched it when one did, else of the caller's trace context."

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
	self critical: [
			recordsById at: aRecord id put: {
					span.
					name.
					origin } ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> testAttributesIn: aContent [

	| run failures errors |
	run := aContent mcpAt: #runCount ifAbsent: [ nil ].
	run isInteger ifFalse: [ ^ #(  ) ].
	failures := aContent mcpAt: #failureCount ifAbsent: [ 0 ].
	errors := aContent mcpAt: #errorCount ifAbsent: [ 0 ].
	^ {
		  ('pharo.mcp.test.count' -> run).
		  ('pharo.mcp.test.outcome' -> ((errors isInteger and: [ errors > 0 ])
			    ifTrue: [ 'errored' ]
			    ifFalse: [
					    (failures isInteger and: [ failures > 0 ])
						    ifTrue: [ 'failed' ]
						    ifFalse: [
								    run > 0
									    ifTrue: [ 'passed' ]
									    ifFalse: [ 'none' ] ] ])) }
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> toolNamesIn: aContent [
	"The tools a search listed or a description described, at most maxToolRefs."

	| entries names |
	entries := (aContent mcpAt: #tools ifAbsent: [ nil ]) ifNil: [ #(  ) ].
	(self isList: entries) ifFalse: [ entries := #(  ) ].
	(aContent mcpAt: #tool ifAbsent: [ nil ]) ifNotNil: [ :tool | entries := entries asArray copyWith: tool ].
	names := OrderedCollection new.
	entries do: [ :each |
			| name |
			name := each isDictionary
				        ifTrue: [ each mcpAt: #name ifAbsent: [ nil ] ]
				        ifFalse: [ nil ].
			((self isReportableName: name) and: [ (names includes: name asString) not ]) ifTrue: [ names add: name asString ] ].
	^ (names first: (names size min: self maxToolRefs)) asArray
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> tracer [

	tracer ifNotNil: [ ^ tracer ].
	tracer := OTTracerProvider current tracerNamed: 'mcp-pharo'.
	^ tracer
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> unknownArgumentNamesIn: inputObject for: aTool [
	"The argument names a call was given that its tool does not declare, all of them for a tool the server does not have: what agents expect a tool to take. Sorted, at most maxArgumentNames."

	| declared names |
	declared := self declaredArgumentNamesOf: aTool.
	names := (self reportableArgumentNamesIn: inputObject) reject: [ :each | declared includes: each ].
	^ names first: (names size min: self maxArgumentNames)
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
