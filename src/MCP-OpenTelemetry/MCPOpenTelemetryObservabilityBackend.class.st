"
OpenTelemetry observability backend for MCP.

This class lives in the optional MCP-OpenTelemetry package so MCP core can remain free of OpenTelemetry dependencies.
"
Class {
	#name : 'MCPOpenTelemetryObservabilityBackend',
	#superclass : 'MCPRecordingObservabilityBackend',
	#instVars : [
		'tracer',
		'meter',
		'logger',
		'inputSizeHistogram',
		'outputSizeHistogram',
		'outputBudgetExceededCounter',
		'recordsById',
		'operationDurationHistogram'
	],
	#category : 'MCP-OpenTelemetry',
	#package : 'MCP-OpenTelemetry'
}

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

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> argumentNamesIn: inputObject [
	"The names of the arguments a call was given, sorted, without their values."

	inputObject isDictionary ifFalse: [ ^ #(  ) ].
	^ ((inputObject keys collect: [ :each | each asString ] as: Array) select: [ :each | self isReportableName: each ]) sort
]

{ #category : 'resource' }
MCPOpenTelemetryObservabilityBackend >> describeServer: aServerInfo [
	"Makes the image's OpenTelemetry providers describe this server and nothing that identifies the machine, its user or the image, now and whenever they are made again, unless a configuration file says what they describe. A step the SDK refuses is skipped: the calls are recorded however little the providers could be told."

	| detectors resource |
	self class resourceIsConfigured ifTrue: [ ^ self ].
	[
		detectors := self class resourceDetectorsFor: aServerInfo.
		resource := OTTracerProvider resourceFromDetectors: detectors ]
		on: Error
		do: [ ^ self ].
	[ OTTracerProvider resourceDetectors: detectors ]
		on: Error
		do: [ nil ].
	{
		OTTracerProvider.
		OTMeterProvider.
		OTLoggerProvider } do: [ :each |
			[ each current resource: resource ]
				on: Error
				do: [ nil ] ]
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

{ #category : 'actions' }
MCPOpenTelemetryObservabilityBackend >> forceFlush [

	OTTracerProvider current forceFlush.
	OTMeterProvider current forceFlush.
	OTLoggerProvider current forceFlush
]

{ #category : 'initialization' }
MCPOpenTelemetryObservabilityBackend >> initialize [

	super initialize.
	recordsById := Dictionary new
]

{ #category : 'private - instruments' }
MCPOpenTelemetryObservabilityBackend >> inputSizeHistogram [

	inputSizeHistogram ifNotNil: [ ^ inputSizeHistogram ].
	inputSizeHistogram := self meter histogramNamed: 'pharo.mcp.tool.input.size' unit: 'By' description: 'MCP tool-call input size'.
	^ inputSizeHistogram
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isReportableName: aString [
	"A name the caller chose leaves the image only when it reads as an identifier, so a value put where a name belongs is never exported."

	^ aString size <= 64 and: [ aString matchesRegex: '[A-Za-z_][A-Za-z0-9_-]*' ]
]

{ #category : 'private - reporting' }
MCPOpenTelemetryObservabilityBackend >> isReportablePackageName: aName [

	^ #( 'Kernel' 'Collections' 'MCP' ) anySatisfy: [ :prefix | aName = prefix or: [ aName beginsWith: prefix , '-' ] ]
]

{ #category : 'accessing' }
MCPOpenTelemetryObservabilityBackend >> logger [

	logger ifNotNil: [ ^ logger ].
	logger := OTLoggerProvider current loggerNamed: 'mcp-pharo'.
	^ logger
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
MCPOpenTelemetryObservabilityBackend >> recordMetricsForRecord: aRecord errorType: errorType [

	| attributes |
	attributes := OrderedCollection new.
	attributes
		add: 'mcp.method.name' -> 'tools/call';
		add: 'gen_ai.tool.name' -> aRecord toolName;
		add: 'gen_ai.operation.name' -> 'execute_tool'.
	errorType ifNotNil: [ attributes add: 'error.type' -> errorType ].
	attributes := attributes asArray.
	self operationDurationHistogram record: aRecord durationMilliseconds / 1000.0 attributes: attributes.
	self inputSizeHistogram record: aRecord inputByteCount attributes: attributes.
	self outputSizeHistogram record: aRecord outputByteCount attributes: attributes.
	aRecord outputBudgetExceeded ifTrue: [ self outputBudgetExceededCounter add: 1 attributes: attributes ]
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordSessionEnd [

	self emitEventNamed: 'mcp.session.end' body: 'MCP session ended'.
	self forceFlush
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordSessionStart [

	self emitEventNamed: 'mcp.session.start' body: 'MCP session started'
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [

	| errorType finishedAt span |
	^ self withoutFailingTheCall: [
			  aRecord ifNil: [ ^ nil ].
			  span := recordsById removeKey: aRecord id ifAbsent: [ nil ].
			  finishedAt := DateAndTime now.
			  self
				  finishRecord: aRecord
				  result: aToolResult
				  error: anError
				  at: finishedAt.
			  aRecord inputObject: nil.
			  errorType := aRecord status = 'error'
				               ifTrue: [ self errorTypeFor: anError ]
				               ifFalse: [ nil ].
			  self recordMetricsForRecord: aRecord errorType: errorType.
			  self
				  endSpan: span
				  withAttributes: (self finishAttributesFor: aRecord error: anError errorType: errorType)
				  record: aRecord
				  at: finishedAt.
			  ^ aRecord ]
]

{ #category : 'recording' }
MCPOpenTelemetryObservabilityBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [

	| record span |
	^ self withoutFailingTheCall: [
			  record := self newRecordFor: aToolName input: inputObject dispatchPath: dispatchPath.
			  span := (self tracer spanBuilderNamed: 'tools/call ' , record toolName)
				          kind: OTSpan server;
				          inContext: (self parentContextIn: contextDictionary);
				          attributes: (self startAttributesFor: record input: inputObject context: contextDictionary);
				          startSpan.
			  recordsById at: record id put: span.
			  ^ record ]
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

{ #category : 'actions' }
MCPOpenTelemetryObservabilityBackend >> shutdown [

	self forceFlush
]

{ #category : 'private - spans' }
MCPOpenTelemetryObservabilityBackend >> startAttributesFor: aRecord input: inputObject context: contextDictionary [
	"The attributes known when a call starts, set before the span starts so a sampler sees them. They follow the OpenTelemetry conventions for MCP where those name the fact, and say nothing the caller passed but argument names."

	| attributes tool |
	attributes := OrderedCollection new.
	attributes
		add: 'mcp.method.name' -> 'tools/call';
		add: 'gen_ai.tool.name' -> aRecord toolName;
		add: 'gen_ai.operation.name' -> 'execute_tool';
		add: 'network.transport' -> 'tcp';
		add: 'network.protocol.name' -> 'http';
		add: 'pharo.mcp.dispatch_path' -> aRecord dispatchPath.
	(self protocolVersionIn: contextDictionary) ifNotNil: [ :version | attributes add: 'mcp.protocol.version' -> version ].
	(self argumentNamesIn: inputObject) ifNotEmpty: [ :names | attributes add: 'pharo.mcp.argument.names' -> names ].
	tool := contextDictionary at: #tool ifAbsent: [ nil ].
	(self unknownArgumentNamesIn: inputObject for: tool) ifNotEmpty: [ :names |
		attributes add: 'pharo.mcp.argument.unknown_names' -> names ].
	^ attributes asArray
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
	"Recording is never a reason for a tool call to fail. A warning while recording, such as a deprecation the SDK runs into, is passed over and the recording goes on; anything else that goes wrong is dropped, and the call goes on unrecorded."

	^ [
		  aBlock
			  on: Warning
			  do: [ :warning | warning resume: nil ] ]
		  on: Error
		  do: [ :error | error return: nil ]
]
