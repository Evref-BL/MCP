"
Tests for the OpenTelemetry observability backend.

Each test runs against its own tracer, meter and logger providers so nothing reaches the providers the image is configured with, and so the spans and measurements the backend emits can be read back. The global providers are restored afterwards.
"
Class {
	#name : 'MCPOpenTelemetryObservabilityBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'backend',
		'exporter',
		'loggerProvider',
		'meterProvider',
		'metricReader',
		'previousLoggerProvider',
		'previousMeterProvider',
		'previousTracerProvider',
		'tracerProvider',
		'measurements',
		'previousResourceDetectors',
		'previousBackends',
		'previousSpanProcessor',
		'previousSpanExporter',
		'previousDefaultBackendClass'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> attributeNamed: aName in: aSnapshot [

	^ aSnapshot attributes at: aName ifAbsent: [ nil ]
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> defaultBackendClass [
	"What kind of backend the servers this image makes record with, which a test sets back to the local one: an image that records every server through OpenTelemetry would otherwise configure, for each server a test makes, every backend from the image's settings."

	^ MCP classVariableNamed: #DefaultObservabilityBackendClass
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> errorToolResult [

	^ MCPStructureErrorToolResult
		  content: { {
				  (#type -> 'text').
				  (#text -> 'boom') } asDictionary }
		  structuredContent: { (#error -> {
				   (#errorCode -> 'repositoryNotFound').
				   (#errorClass -> 'MCPCommandError') } asDictionary) } asDictionary
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> errorToolResultWith: someDetails [
	"An error result as a tool answers one, its details in the error of its structured content."

	^ MCPStructureErrorToolResult
		  content: { {
				  (#type -> 'text').
				  (#text -> 'boom') } asDictionary }
		  structuredContent: { (#error -> someDetails asDictionary) } asDictionary
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> mcp [
	"A server recording through the backend under test."

	^ MCP new
		  observability: backend;
		  yourself
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> measurementNamed: aName [

	^ self measurements detect: [ :each | each instrument name = aName ] ifNone: [ nil ]
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> measurements [
	"Collected once, since a reader hands its measurements over on collection."

	measurements ifNotNil: [ ^ measurements ].
	measurements := metricReader collect.
	^ measurements
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> registry [
	"Where the backend keeps the backends of its kind, which a test replaces with its own so that configuring a backend never touches a server the image is running."

	^ MCPOpenTelemetryObservabilityBackend classVariableNamed: #Backends
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> remoteTraceparent [
	"A caller's trace context, as SEP-414 carries it in a request's _meta."

	^ '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01'
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> serverInfoAt: aVersion [

	^ MCPStructureServerInfo new
		  name: 'MCP Pharo';
		  version: aVersion;
		  yourself
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> sessionOfACallAt: aDateAndTime context: aContextDictionary [
	"The session.id the span of a call made at aDateAndTime carries."

	backend clock: [ aDateAndTime ].
	backend recordToolCallFinish: (self startToolCallWith: aContextDictionary) result: self successToolResult error: nil.
	^ self attributeNamed: 'session.id' in: exporter snapshots last
]

{ #category : 'running' }
MCPOpenTelemetryObservabilityBackendTest >> setUp [

	super setUp.
	previousTracerProvider := (OTTracerProvider classVariableNamed: #Current) value.
	previousMeterProvider := OTMeterProvider currentOrNil.
	previousLoggerProvider := OTLoggerProvider currentOrNil.
	previousResourceDetectors := OTClassStateStore valueAt: #otResourceDetectors forClass: OTTracerProvider ifAbsent: [ nil ].
	previousSpanProcessor := OTSpanProcessor currentIfSet.
	previousSpanExporter := (OTSpanExporter classVariableNamed: #Current) value.
	(OTSpanProcessor classVariableNamed: #Current) value: nil.
	(OTSpanExporter classVariableNamed: #Current) value: nil.
	previousBackends := self registry value.
	self registry value: WeakSet new.
	previousDefaultBackendClass := self defaultBackendClass value.
	self defaultBackendClass value: nil.
	exporter := MCPOpenTelemetryRecordingSpanExporter new.
	metricReader := OTInMemoryMetricReader new.
	tracerProvider := OTTracerProvider new
		                  addSpanProcessor: (OTSimpleSpanProcessor new exporter: exporter);
		                  yourself.
	meterProvider := OTMeterProvider new
		                 addMetricReader: metricReader;
		                 yourself.
	loggerProvider := OTLoggerProvider new.
	OTTracerProvider current: tracerProvider.
	OTMeterProvider current: meterProvider.
	OTLoggerProvider current: loggerProvider.
	backend := MCPOpenTelemetryObservabilityBackend new
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> settingsAskingForTraces: aBoolean [
	"Settings of an environment that asks for traces or not, and with no settings file, so that one the user has does not decide."

	| environment |
	environment := Dictionary new.
	aBoolean ifTrue: [ environment at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'http://127.0.0.1:9' ].
	^ (MCPOpenTelemetrySettings environment: environment)
		  home: nil;
		  yourself
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> spanNamed: aName [
	"The one exported span of that name."

	| spans |
	spans := exporter snapshots select: [ :each | each name = aName ].
	self assert: spans size equals: 1.
	^ spans first
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> startToolCall [

	^ self startToolCallWith: Dictionary new
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> startToolCallWith: aContextDictionary [

	^ backend
		  recordToolCallStart: #method_compile
		  input: { (#class -> 'Object') } asDictionary
		  dispatchPath: 'tools/call'
		  context: aContextDictionary
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> successToolResult [

	^ MCPStructureCallToolResult content: { {
			  (#type -> 'text').
			  (#text -> 'ok') } asDictionary }
]

{ #category : 'running' }
MCPOpenTelemetryObservabilityBackendTest >> tearDown [
	"What the test made is shut down, with what a reconfiguration it caused made from the environment; what the image had is put back as it was, untouched, so a server the image runs keeps recording."

	| previous |
	previous := {
		            previousTracerProvider.
		            previousMeterProvider.
		            previousLoggerProvider.
		            previousSpanProcessor.
		            previousSpanExporter }.
	{
		tracerProvider.
		meterProvider.
		loggerProvider.
		(OTTracerProvider classVariableNamed: #Current) value.
		OTMeterProvider currentOrNil.
		OTLoggerProvider currentOrNil.
		OTSpanProcessor currentIfSet.
		(OTSpanExporter classVariableNamed: #Current) value } do: [ :each |
			(each isNil or: [ previous anySatisfy: [ :kept | kept == each ] ]) ifFalse: [
					[ each shutdown ]
						on: Error
						do: [ :ignored | nil ] ] ].
	OTTracerProvider current: previousTracerProvider.
	OTMeterProvider current: previousMeterProvider.
	OTLoggerProvider current: previousLoggerProvider.
	OTTracerProvider resourceDetectors: previousResourceDetectors.
	(OTSpanProcessor classVariableNamed: #Current) value: previousSpanProcessor.
	(OTSpanExporter classVariableNamed: #Current) value: previousSpanExporter.
	self registry value: previousBackends.
	self defaultBackendClass value: previousDefaultBackendClass.
	backend := nil.
	super tearDown
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testACallThroughToolCallIsAChildOfItsSpan [
	"tool_call records the call it makes inside its own span, in the same session, whatever parent the request names."

	| outer inner |
	MCPRequestMeta value: { ('traceparent' -> self remoteTraceparent) } asDictionary during: [
			self mcp rpcToolCall: 'tool_call' withParams: {
					('name' -> 'class_search').
					('arguments' -> { ('query' -> 'Point') } asDictionary) } asDictionary ].
	self assert: exporter snapshots size equals: 2.
	outer := self spanNamed: 'tools/call tool_call'.
	inner := self spanNamed: 'tools/call class_search'.
	self assert: outer parentSpanContext spanIdHex equals: '00f067aa0ba902b7'.
	self assert: inner parentSpanContext spanIdHex equals: outer spanContext spanIdHex.
	self assert: (self attributeNamed: 'pharo.mcp.dispatch_path' in: inner) equals: 'via_tool_call'.
	self assert: (self attributeNamed: 'session.id' in: inner) equals: (self attributeNamed: 'session.id' in: outer).
	self assert: outer status equals: OTSpan unset
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testACallWhoseCallerNamesNoSessionHasTheServersOwn [
	"A caller that sends no baggage, as most do, still has its calls grouped: by a session of the server's own, a random id that carries nothing of the machine."

	| start first second |
	start := DateAndTime
		         year: 2026
		         month: 11
		         day: 22
		         hour: 9
		         minute: 0
		         second: 0.
	first := self sessionOfACallAt: start context: Dictionary new.
	second := self
		          sessionOfACallAt: start + 29 minutes
		          context: { (#meta -> { ('traceparent' -> self remoteTraceparent) } asDictionary) } asDictionary.
	self assert: first size equals: 32.
	self assert: (first allSatisfy: [ :each | each isDigit or: [ 'abcdef' includes: each ] ]).
	self assert: second equals: first
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testACallersSessionIsKeptAndLeavesTheServersOwnAlone [

	| start own callers ownAgain |
	start := DateAndTime
		         year: 2026
		         month: 11
		         day: 22
		         hour: 9
		         minute: 0
		         second: 0.
	own := self sessionOfACallAt: start context: Dictionary new.
	callers := self sessionOfACallAt: start + 20 minutes context: { (#meta -> {
			            ('traceparent' -> self remoteTraceparent).
			            ('baggage' -> 'session.id=3f2b8c1e-9d4a-4e7b-8c2d-1a2b3c4d5e6f') } asDictionary) } asDictionary.
	ownAgain := self sessionOfACallAt: start + 40 minutes context: Dictionary new.
	self assert: callers equals: '3f2b8c1e-9d4a-4e7b-8c2d-1a2b3c4d5e6f'.
	self deny: ownAgain equals: own
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAConfigurationFileThatSaysWhatTheTelemetryDescribesIsLeftToSayIt [

	| file |
	file := (FileLocator temp / 'mcp-telemetry-configuration.yaml') asFileReference.
	[
		file writeStreamDo: [ :stream |
				stream nextPutAll: 'file_format: "1.0"
resource:
  attributes:
    - name: service.name
      value: from-file
' ].
		self withEnvironmentVariable: 'OTEL_CONFIG_FILE' setTo: file fullName do: [
				backend describeServer: (self serverInfoAt: '9.8.7').
				self
					deny: (tracerProvider resource attributes includesKey: 'service.version');
					assert: (OTTracerProvider configuredResource attributes at: 'service.name') equals: 'from-file' ] ] ensure: [
			file ensureDelete.
			OTConfigurationSource reset ]
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testADescriptionPharoCannotCompleteKeepsWhatItCanAndStillRecords [

	backend describeServer: Object new.
	self deny: (tracerProvider resource attributes includesKey: 'service.version').
	backend recordToolCallFinish: self startToolCall result: self successToolResult error: nil.
	self assert: exporter onlySnapshot name equals: 'tools/call method_compile'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAFlushThatHangsHoldsTheCallerAtMostTheFlushTimeout [

	| processor elapsed |
	processor := MCPOpenTelemetryHangingSpanProcessor new.
	tracerProvider addSpanProcessor: processor.
	[
		elapsed := Time millisecondsToRun: [ backend forceFlush ].
		self assert: processor wasEntered.
		self assert: elapsed < (backend flushTimeoutMilliseconds * 3) ] ensure: [ processor open ]
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAMalformedTraceContextStartsARootSpan [

	| snapshot |
	backend
		recordToolCallFinish:
		(self startToolCallWith: { (#meta -> { ('traceparent' -> 'not a trace context') } asDictionary) } asDictionary)
		result: self successToolResult
		error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot parentSpanContext isNil
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testANameReadsAsAnIdentifierOnlyInASCII [

	self assert: (backend isReportableName: 'method_compile').
	self assert: (backend isReportableName: '_private-name').
	self deny: (backend isReportableName: 'café').
	self deny: (backend isReportableName: '9lives').
	self deny: (backend isReportableName: '').
	self deny: (backend isReportableName: (String new: 65 withAll: $a))
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testANameTheCallerChoseIsExportedOnlyWhenItReadsAsAnIdentifier [
	"An argument name is the caller's, and so is the name of a tool the server does not have, which declares no argument."

	| snapshot |
	backend
		recordToolCallFinish: (backend
				 recordToolCallStart: 'Object subclass: #Secret'
				 input: {
						 ('name' -> 'Object').
						 ('Object subclass: #Secret' -> 1) } asDictionary
				 dispatchPath: 'direct'
				 context: { (#tool -> nil) } asDictionary)
		result: self successToolResult
		error: nil.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'pharo.mcp.argument.names' in: snapshot) isNil.
	self assert: (self attributeNamed: 'pharo.mcp.argument.unknown_names' in: snapshot) equals: #( 'name' ).
	self assert: snapshot name equals: 'tools/call _OTHER'.
	self assert: (self attributeNamed: 'gen_ai.tool.name' in: snapshot) equals: '_OTHER'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAProtocolErrorReportsItsJSONRPCCode [
	"A tool that raises a JSON-RPC error of its own is answered with it, so the call is recorded by its code."

	| snapshot |
	backend recordToolCallFinish: self startToolCall result: nil error: JRPCInvalidParameters new.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'error.type' in: snapshot) equals: '-32602'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAProviderThatRefusesTheDescriptionStopsTheTraces [
	"A provider left undescribed would describe the machine through the SDK's default detectors."

	tracerProvider shutdown.
	backend configureFor: (self serverInfoAt: '9.8.7') configured: true.
	self deny: backend isRecordingTraces.
	backend recordToolCallFinish: self startToolCall result: self successToolResult error: nil.
	self assert: exporter snapshots isEmpty.
	self assert: backend totalCallCount equals: 1
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testASchemaRefusalSaysWhichKeywordsAndWhere [
	"As the input schema's validator refuses a real tool's input: where a property is wrong or unknown, and where a required one is missing, rather than the object that misses it."

	| snapshot |
	MCPToolRegistry default toolNamed: 'method_compile' ifAbsent: [ self skip: 'method_compile is not registered' ].
	self mcp rpcToolCall: 'method_compile' withParams: {
			('class' -> 42).
			('colour' -> 'red') } asDictionary.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'pharo.mcp.error.kind' in: snapshot) equals: 'input_schema'.
	self
		assert: (self attributeNamed: 'pharo.mcp.error.schema.keywords' in: snapshot)
		equals: #( 'additionalProperties' 'required' 'type' ).
	self assert: (self attributeNamed: 'pharo.mcp.error.schema.paths' in: snapshot) equals: #( '/class' '/colour' '/source' )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAServerATestMakesRecordsLocallyOnly [
	"A test makes servers to see what they do, which is not use, so what they record stays in the image whatever its servers record with."

	MCP observabilityBackendClass: MCPOpenTelemetryObservabilityBackend.
	self assert: MCP new observability class equals: MCPLocalObservabilityBackend
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testASessionThatDoesNotReadAsAnIdIsLeftOutForTheServersOwn [
	"What the caller's baggage names as its session leaves the image only when it reads as an id; otherwise the call has the server's own session."

	| own |
	own := self sessionOfACallAt: DateAndTime now context: Dictionary new.
	self
		assert: (self sessionOfACallAt: DateAndTime now context: { (#meta -> {
					  ('traceparent' -> self remoteTraceparent).
					  ('baggage' -> 'session.id=a%20value%20with%20spaces') } asDictionary) } asDictionary)
		equals: own
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testATestRunIsReportedAsTestRunAnswersIt [
	"The facts of a run come from the answer test_run builds, not from a result shaped for the test."

	| tool attributes |
	tool := MCPToolRegistry default toolNamed: 'test_run' ifAbsent: [ self skip: 'test_run is not registered' ].
	attributes := (backend
		               resultAttributesFor: (tool
				                successResultText: 'Ran 0 tests (0 passed).'
				                data: (MCPRunTestsResult outcomes: #(  ) timedOut: false unrunTests: #(  )) asDictionary)
		               origin: 'mcp') asDictionary.
	self assert: (attributes at: 'pharo.mcp.test.count') equals: 0.
	self assert: (attributes at: 'pharo.mcp.test.outcome') equals: 'none'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAToolTheServerDoesNotHaveIsRecordedAsAToolError [
	"tools/call answers a name the server does not have with a result reporting the error, as tool_call answers it, so the call is recorded as a tool error and not by a JSON-RPC code."

	| mcp snapshot |
	mcp := MCP new.
	mcp observability: backend.
	mcp rpcToolCall: 'no_such_tool' withParams: Dictionary new.
	snapshot := exporter onlySnapshot.
	self assert: snapshot name equals: 'tools/call no_such_tool'.
	self assert: (self attributeNamed: 'error.type' in: snapshot) equals: 'tool_error'.
	self assert: (self attributeNamed: 'pharo.mcp.error.code' in: snapshot) equals: 'ToolNotFound'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testATraceThatFailsToStartLeavesTheCallRecordedLocally [

	| record |
	record := self startToolCallWith: nil.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	self assert: exporter snapshots isEmpty.
	self assert: backend totalCallCount equals: 1
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testATracedToolsCallRequestParentsTheSpanOnItsCaller [

	| mcp snapshot |
	mcp := MCP new.
	mcp observability: backend.
	mcp server messageProcessor handleJSON: (STONJSON toString: {
				 ('jsonrpc' -> '2.0').
				 ('id' -> 1).
				 ('method' -> 'tools/call').
				 ('params' -> {
					  ('name' -> 'class_search').
					  ('arguments' -> { ('query' -> 'Point') } asDictionary).
					  ('_meta' -> { ('traceparent' -> self remoteTraceparent) } asDictionary) } asDictionary) } asDictionary).
	snapshot := exporter onlySnapshot.
	self assert: snapshot name equals: 'tools/call class_search'.
	self assert: snapshot parentSpanContext spanIdHex equals: '00f067aa0ba902b7'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAWarningWhileRecordingIsPassedOverAndTheCallRecorded [

	| previous snapshot |
	previous := OTTextMapPropagator currentOrNil.
	OTTextMapPropagator current: MCPOpenTelemetryWarningPropagator new.
	[
		backend
			recordToolCallFinish:
			(self startToolCallWith: { (#meta -> { ('traceparent' -> self remoteTraceparent) } asDictionary) } asDictionary)
			result: self successToolResult
			error: nil ] ensure: [ OTTextMapPropagator current: previous ].
	snapshot := exporter onlySnapshot.
	self assert: snapshot parentSpanContext spanIdHex equals: '00f067aa0ba902b7'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAnAnswerThatCannotBeReadStillEndsTheSpan [
	"Recording drops only what it cannot read: a span left open is never exported, which reads as a call the image never received."

	| snapshot |
	backend recordToolCallFinish: self startToolCall result: MCPOpenTelemetryUnreadableToolResult new error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot name equals: 'tools/call method_compile'.
	self assert: snapshot status equals: OTSpan error
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAnErrorAnswerNamingNoClassOfTheImageReportsNoException [

	#( 'ToolError' 'Smalltalk' 'Not a class name' 'MCPNoSuchClassAnywhere' ) do: [ :each |
		self assert: (backend reportableClassNamed: each) isNil description: each ].
	self assert: (Symbol findInterned: 'MCPNoSuchClassAnywhere') isNil.
	self assert: (backend reportableClassNamed: 'KeyNotFound') equals: 'KeyNotFound'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAnExceptionIsNamedByItsNearestKernelClassAndNeitherItsMessageNorItsStack [
	"Named by its nearest class in Pharo's packages or MCP's: here one of a package of neither."

	| snapshot |
	backend
		recordToolCallFinish: self startToolCall
		result: self errorToolResult
		error: (JRPCInvalidParameters new messageText: 'secret').
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'pharo.mcp.exception.type' in: snapshot) equals: 'Error'.
	self assert: snapshot events isEmpty.
	self deny: (snapshot attributes values anySatisfy: [ :each | each isString and: [ each includesSubstring: 'secret' ] ])
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAnExceptionOfPharoOrMCPIsNamedByItsOwnClass [
	"Including the notices a compilation raises, which explain a failed evaluation."

	| classes |
	classes := OrderedCollection withAll: {
			           ZeroDivide.
			           KeyNotFound.
			           MCPCommandError.
			           MCPInvalidToolInput }.
	#( #OCUndeclaredVariableNotice #OCUndeclaredVariableWarning #OCSemanticWarning ) do: [ :each |
		self class environment at: each ifPresent: [ :class | classes add: class ] ].
	classes do: [ :each | self assert: (backend reportableClassNameOf: each) equals: each name asString ].
	self assert: (backend reportableClassNameOf: JRPCInvalidParameters) equals: 'Error'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAnImageCanMakeEveryServerRecordThroughOpenTelemetry [
	"As the image makes its own servers, outside a test."

	| mcp |
	MCP observabilityBackendClass: MCPOpenTelemetryObservabilityBackend.
	DefaultExecutionEnvironment beActiveDuring: [ mcp := MCP new ].
	self assert: mcp observability class equals: MCPOpenTelemetryObservabilityBackend.
	self assert: mcp observability serverInfo isNotNil.
	MCP observabilityBackendClass: nil.
	DefaultExecutionEnvironment beActiveDuring: [ mcp := MCP new ].
	self assert: mcp observability class equals: MCPLocalObservabilityBackend
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testArgumentNamesTheToolDoesNotDeclareAreReportedAsUnknown [
	"Only there: what an agent writes in a name it makes up reaches a single attribute."

	| tool snapshot |
	tool := MCPToolRegistry default toolNamed: 'class_get' ifAbsent: [ self skip: 'class_get is not registered' ].
	backend
		recordToolCallFinish: (backend
				 recordToolCallStart: 'class_get'
				 input: {
						 ('name' -> 'Object').
						 ('colour' -> 'red') } asDictionary
				 dispatchPath: 'direct'
				 context: { (#tool -> tool) } asDictionary)
		result: self successToolResult
		error: nil.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'pharo.mcp.argument.names' in: snapshot) equals: #( 'name' ).
	self assert: (self attributeNamed: 'pharo.mcp.argument.unknown_names' in: snapshot) equals: #( 'colour' )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAtMostMaxArgumentNamesAreReported [

	| input |
	input := ((1 to: 40) collect: [ :each | 'a' , each printString -> each ]) asDictionary.
	self assert: (backend argumentNamesIn: input for: nil) isEmpty.
	self assert: (backend unknownArgumentNamesIn: input for: nil) size equals: backend maxArgumentNames
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testConfiguringABackendReconfiguresEveryOtherOne [
	"The providers belong to the whole image: configuring one server's backend rebuilds them, and another backend left with instruments of the providers that were shut down would record nothing more."

	| other stale |
	other := MCPOpenTelemetryObservabilityBackend new.
	other configureFor: (self serverInfoAt: '9.8.7') settings: (self settingsAskingForTraces: true).
	stale := other tracer.
	backend configureFor: (self serverInfoAt: '9.8.7') settings: (self settingsAskingForTraces: true).
	self assert: other isRecordingTraces.
	self assert: other serverInfo version equals: '9.8.7'.
	self deny: other tracer identicalTo: stale
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testEachCallSaysWhoseToolItWentTo [
	"mcp for MCP's own tools, other for another package's, unknown for a name no tool has."

	| tool |
	tool := MCPToolRegistry default toolNamed: 'class_get' ifAbsent: [ self skip: 'class_get is not registered' ].
	{
		tool.
		Object new.
		nil } do: [ :each |
			backend
				recordToolCallFinish: (backend
						 recordToolCallStart: 'class_get'
						 input: Dictionary new
						 dispatchPath: 'direct'
						 context: { (#tool -> each) } asDictionary)
				result: self successToolResult
				error: nil ].
	self
		assert: (exporter snapshots collect: [ :each | self attributeNamed: 'pharo.mcp.tool.origin' in: each ]) asArray
		equals: #( 'mcp' 'other' 'unknown' )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testFailedToolCallMarksTheSpanAsAnErrorWithoutItsMessage [

	| record snapshot |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self errorToolResult error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot status equals: OTSpan error.
	self assert: snapshot statusDescription isEmptyOrNil.
	self assert: (self attributeNamed: 'error.type' in: snapshot) equals: 'tool_error'.
	self assert: (self attributeNamed: 'pharo.mcp.error.code' in: snapshot) equals: 'repositoryNotFound'.
	self assert: (self attributeNamed: 'pharo.mcp.error.kind' in: snapshot) equals: 'domain'.
	self assert: record eventKinds equals: #( 'error' )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testFailedToolCallRecordsItsErrorTypeOnTheDurationMetric [

	| record |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self errorToolResult error: nil.
	self
		assert: ((self measurementNamed: 'mcp.server.operation.duration') attributes at: 'error.type' ifAbsent: [ nil ])
		equals: 'tool_error'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testOnlyAClientNameAndVersionThatReadAsSuchAreReported [
	"Self-reported, so text that does not read as a product's name or a version is left out."

	| attributesFor |
	attributesFor := [ :name :version |
		                 (backend clientAttributesIn: { (#client -> {
				                   (#name -> name).
				                   (#version -> version) } asDictionary) } asDictionary) asDictionary ].
	self assert: (attributesFor value: 'VS Code' value: '1.95.0-insider+build.7') equals: (Dictionary newFrom: {
				 ('pharo.mcp.client.name' -> 'VS Code').
				 ('pharo.mcp.client.version' -> '1.95.0-insider+build.7') }).
	{
		('Alice Smith <alice@acme.test>' -> 'latest').
		(42 -> 1).
		((String new: 65 withAll: $a) -> '1.0 beta').
		('café' -> '').
		('_private' -> 'v1') } do: [ :each | self assert: (attributesFor value: each key value: each value) isEmpty ].
	self assert: (backend clientAttributesIn: Dictionary new) isEmpty
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testOnlyMCPsOwnPackagesNameAnException [
	"Pharo's own packages, as its baselines list them, and MCP's: a user's package cannot pass for one of them by sharing its prefix."

	self assert: (backend isReportablePackageName: 'MCP').
	self assert: (backend isReportablePackageName: 'MCP-OpenTelemetry').
	self assert: (backend isReportablePackageName: ZeroDivide package name).
	self assert: (backend isReportablePackageName: KeyNotFound package name).
	#( 'MCP-SomeoneElses' 'MCPAcme' 'Collections-AcmeSecret' 'Kernel-AcmeInternal' ) do: [ :each |
		self deny: (backend isReportablePackageName: each) description: each ]
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testOutputBeyondTheBudgetIsFlaggedOnTheSpanAndTheRecord [

	| record snapshot |
	backend outputBudgetBytes: 1.
	record := self startToolCall.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'pharo.mcp.output_budget.exceeded' in: snapshot).
	self assert: record outputBudgetExceeded.
	self assert: record outputBudgetBytes equals: 1.
	self assert: (record outputBudgetExplanation includesSubstring: 'exceeds budget 1 bytes').
	self assert: record eventKinds equals: #( 'output_budget_exceeded' ).
	self assert: (snapshot events anySatisfy: [ :each | each name = 'pharo.mcp.output_budget_exceeded' ])
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testOutputBudgetExplanationNamesTheBudgetOnlyWhenExceeded [

	backend outputBudgetBytes: 100.
	self assert: (backend outputBudgetExplanationForByteCount: 100) isEmpty.
	self
		assert: (backend outputBudgetExplanationForByteCount: 101)
		equals: 'Output 101 bytes exceeds budget 100 bytes; consider pagination, handles, or summary-first output'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testProvidersMadeLaterDescribeTheServerToo [

	| attributes |
	backend describeServer: (self serverInfoAt: '9.8.7').
	attributes := OTTracerProvider configuredResource attributes.
	self
		assert: (attributes at: 'service.version') equals: '9.8.7';
		deny: (attributes includesKey: 'host.name')
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testReconfiguringHandsNoShutDownProcessorToTheNextProvider [

	| saved |
	saved := OTSimpleSpanProcessor new exporter: exporter.
	OTSpanProcessor current: saved.
	MCPOpenTelemetryObservabilityBackend configureProvidersWith: (self settingsAskingForTraces: true).
	self deny: (OTTracerProvider current spanProcessors includes: saved).
	self deny: OTSpanProcessor currentIfSet identicalTo: saved
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testSessionLifecycleGoesThroughTheLogRecordBuilderAndFlushes [
	"The session events build a log record and force a flush on all three
	providers, so this fails if any of that surface moves."

	backend recordSessionStart.
	backend recordSessionEnd.
	self assert: exporter snapshots isEmpty description: 'Session events are logs, not spans.'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testSettingsThatAskForNoTracesRecordOnlyLocally [

	| mcp |
	mcp := MCP new.
	backend := mcp useOpenTelemetryObservabilityWith: (self settingsAskingForTraces: false).
	self deny: backend isRecordingTraces.
	backend recordSessionStart.
	backend recordToolCallFinish: self startToolCall result: self successToolResult error: nil.
	self assert: exporter snapshots isEmpty.
	self assert: backend totalCallCount equals: 1.
	self assert: (backend recentCalls collect: [ :each | each toolName ]) asArray equals: #( #method_compile )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testStartingTheImageAgainConfiguresItsBackendsFromTheSettingsItNowHas [

	| other |
	other := MCPOpenTelemetryObservabilityBackend new.
	backend configureFor: (self serverInfoAt: '9.8.7') configured: true.
	MCPOpenTelemetryObservabilityBackend
		reconfigure: {
				backend.
				other }
		with: (self settingsAskingForTraces: false).
	self deny: backend isRecordingTraces.
	self deny: other isRecordingTraces.
	self deny: OTTracerProvider current identicalTo: tracerProvider.
	MCPOpenTelemetryObservabilityBackend reconfigure: { backend } with: (self settingsAskingForTraces: true).
	self assert: backend isRecordingTraces
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testStartingTheImageAgainWithoutTracesLeavesProvidersNoBackendMade [
	"The providers are global and may be the user's."

	backend configureFor: (self serverInfoAt: '9.8.7') configured: false.
	MCPOpenTelemetryObservabilityBackend reconfigure: { backend } with: (self settingsAskingForTraces: false).
	self assert: OTTracerProvider current identicalTo: tracerProvider
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testStatusDistinguishesErrorsFromResults [

	self assert: (backend statusForResult: self successToolResult error: nil) equals: 'ok'.
	self assert: (backend statusForResult: self errorToolResult error: nil) equals: 'error'.
	self assert: (backend statusForResult: nil error: nil) equals: 'error'.
	self assert: (backend statusForResult: self successToolResult error: Error new) equals: 'error'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testStoppingWithoutTracesMakesNoProviders [
	"Asking a provider for itself makes one from the environment, with the SDK's default exporter and resource."

	backend configureFor: (self serverInfoAt: '9.8.7') configured: false.
	OTTracerProvider current: nil.
	OTMeterProvider current: nil.
	OTLoggerProvider current: nil.
	backend recordSessionStart.
	backend shutdown.
	{
		OTTracerProvider.
		OTMeterProvider.
		OTLoggerProvider } do: [ :each | self assert: (each classVariableNamed: #Current) value isNil ]
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheClientIsTheOneItsRequestNamesElseTheLastToInitialize [
	"A modern request says who sends it in its _meta; a legacy client says so only when it initializes, and this server keeps no session."

	| mcp spans |
	mcp := self mcp.
	mcp onInitialize: '2025-06-18' clientInfo: {
			('name' -> ' opencode ').
			('version' -> '1.2.3') } asDictionary.
	mcp rpcToolCall: 'class_search' withParams: { ('query' -> 'Point') } asDictionary.
	MCPRequestMeta
		value: {
				(MCP modernProtocolVersionKey -> '2026-07-28').
				(MCP modernClientInfoKey -> {
					 ('name' -> 'Claude Code').
					 ('version' -> '2.1.0') } asDictionary) } asDictionary
		during: [ mcp rpcToolCall: 'class_search' withParams: { ('query' -> 'Point') } asDictionary ].
	spans := exporter snapshots.
	self assert: spans size equals: 2.
	self assert: (self attributeNamed: 'pharo.mcp.client.name' in: spans first) equals: 'opencode'.
	self assert: (self attributeNamed: 'pharo.mcp.client.version' in: spans first) equals: '1.2.3'.
	self assert: (self attributeNamed: 'pharo.mcp.client.name' in: spans last) equals: 'Claude Code'.
	self assert: (self attributeNamed: 'pharo.mcp.client.version' in: spans last) equals: '2.1.0'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheEnvironmentAddsAttributesButCannotRenameTheServer [

	| attributes |
	self withEnvironmentVariable: 'OTEL_RESOURCE_ATTRIBUTES' setTo: 'deployment.environment.name=test,service.name=renamed' do: [
			backend describeServer: (self serverInfoAt: '9.8.7').
			attributes := tracerProvider resource attributes ].
	self
		assert: (attributes at: 'deployment.environment.name') equals: 'test';
		assert: (attributes at: 'service.name') equals: 'pharo-mcp'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheExceptionAnErrorAnswerNamesIsReported [
	"A tool that catches what went wrong answers an error naming its class and a code, as evaluate does: no exception escaped, and the answer says which."

	| snapshot |
	backend
		recordToolCallFinish: self startToolCall
		result: (self errorToolResultWith: {
					 (#errorClass -> 'ZeroDivide').
					 (#errorCode -> 'EvaluationRuntimeError') })
		error: nil.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'pharo.mcp.exception.type' in: snapshot) equals: 'ZeroDivide'.
	self assert: (self attributeNamed: 'pharo.mcp.error.code' in: snapshot) equals: 'EvaluationRuntimeError'.
	self assert: (self attributeNamed: 'pharo.mcp.error.kind' in: snapshot) equals: 'domain'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheOptionsACallChoseAreReported [
	"As the evaluation counts them: an optional property given, an enumerated value other than the default, and the list form of a property that also takes one value."

	| schema input |
	schema := {
		          ('required' -> #( 'name' )).
		          ('properties' -> {
			           ('name' -> { ('type' -> 'string') } asDictionary).
			           ('side' -> {
				            ('type' -> 'string').
				            ('enum' -> #( 'instance' 'class' )).
				            ('default' -> 'instance') } asDictionary).
			           ('packages' -> { ('type' -> #( 'string' 'array' )) } asDictionary).
			           ('limit' -> { ('type' -> 'integer') } asDictionary) } asDictionary) } asDictionary.
	input := {
		         ('name' -> 'Object').
		         ('side' -> 'class').
		         ('packages' -> #( 'A' 'B' )).
		         ('limit' -> 5).
		         ('colour' -> 'red') } asDictionary.
	self
		assert: (backend
				 options: Set new
				 chosenIn: input
				 schema: schema
				 prefix: '') asArray sort
		equals: #( 'limit' 'packages' 'packages[]' 'side=class' )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testThePharoVersionCarriesItsBuild [

	self assert: (MCPOpenTelemetryObservabilityBackend pharoVersion matchesRegex: '\d+\.\d+\.\d+\+build\.\d+')
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheResourceDescribesTheServerAndNothingAboutTheMachine [

	| defaults expected attributes |
	defaults := OTTracerProvider resourceFromDetectors: OTTracerProvider defaultResourceDetectors.
	{
		tracerProvider.
		meterProvider.
		loggerProvider } do: [ :each | each resource: defaults ].
	self withEnvironmentVariable: 'OTEL_RESOURCE_ATTRIBUTES' setTo: nil do: [ backend describeServer: (self serverInfoAt: '9.8.7') ].
	backend recordToolCallFinish: self startToolCall result: self successToolResult error: nil.
	attributes := exporter onlySnapshot resource attributes.
	expected := Set withAll:
		            #( 'service.name' 'service.version' 'telemetry.sdk.name' 'telemetry.sdk.language' 'telemetry.sdk.version'
		               'process.runtime.name' 'process.runtime.version' 'process.runtime.description' ).
	OTTracerProvider defaultOsType ifNotNil: [ expected add: 'os.type' ].
	self
		assert: attributes keys asSet equals: expected;
		assert: (attributes at: 'service.name') equals: 'pharo-mcp';
		assert: (attributes at: 'service.version') equals: '9.8.7';
		assert: (attributes at: 'process.runtime.name') equals: 'pharo';
		assert: meterProvider resource attributes equals: attributes;
		assert: loggerProvider resource attributes equals: attributes
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheServersOwnSessionEndsAfterThirtyMinutesWithoutACall [

	| start first second third |
	start := DateAndTime
		         year: 2026
		         month: 11
		         day: 22
		         hour: 9
		         minute: 0
		         second: 0.
	first := self sessionOfACallAt: start context: Dictionary new.
	second := self sessionOfACallAt: start + 29 minutes context: Dictionary new.
	third := self sessionOfACallAt: start + 59 minutes context: Dictionary new.
	self assert: second equals: first.
	self deny: third equals: second
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheServersOwnSessionEndsWhenTheClockGoesBack [
	"An image saved and started on another machine, or whose clock was set back, starts a session of its own; a clock set back by less than a minute, as a time synchronization does, keeps it."

	| start first second third |
	start := DateAndTime
		         year: 2026
		         month: 11
		         day: 22
		         hour: 9
		         minute: 0
		         second: 0.
	first := self sessionOfACallAt: start context: Dictionary new.
	second := self sessionOfACallAt: start - 59 seconds context: Dictionary new.
	third := self sessionOfACallAt: start - 2 minutes context: Dictionary new.
	self assert: second equals: first.
	self deny: third equals: second
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testTheSessionInTheCallersBaggageIsReported [

	| snapshot |
	backend
		recordToolCallFinish: (self startToolCallWith: { (#meta -> {
					  ('traceparent' -> self remoteTraceparent).
					  ('baggage' -> 'session.id=3f2b8c1e-9d4a-4e7b-8c2d-1a2b3c4d5e6f,other=x') } asDictionary) } asDictionary)
		result: self successToolResult
		error: nil.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'session.id' in: snapshot) equals: '3f2b8c1e-9d4a-4e7b-8c2d-1a2b3c4d5e6f'.
	self assert: (self attributeNamed: 'other' in: snapshot) isNil
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallExportsASpanDescribingTheCall [

	| tool record snapshot |
	tool := MCPToolRegistry default toolNamed: 'method_compile' ifAbsent: [ self skip: 'method_compile is not registered' ].
	record := backend
		          recordToolCallStart: 'method_compile'
		          input: { (#class -> 'Object') } asDictionary
		          dispatchPath: 'tools/call'
		          context: { (#tool -> tool) } asDictionary.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot name equals: 'tools/call method_compile'.
	self assert: snapshot kind equals: OTSpan server.
	self assert: snapshot status equals: OTSpan unset.
	self assert: (self attributeNamed: 'mcp.method.name' in: snapshot) equals: 'tools/call'.
	self assert: (self attributeNamed: 'gen_ai.tool.name' in: snapshot) equals: 'method_compile'.
	self assert: (self attributeNamed: 'gen_ai.operation.name' in: snapshot) equals: 'execute_tool'.
	self assert: (self attributeNamed: 'pharo.mcp.dispatch_path' in: snapshot) equals: 'tools/call'.
	self assert: (self attributeNamed: 'pharo.mcp.tool.origin' in: snapshot) equals: 'mcp'.
	self assert: (self attributeNamed: 'pharo.mcp.argument.names' in: snapshot) equals: #( 'class' ).
	self assert: (self attributeNamed: 'pharo.mcp.argument.unknown_names' in: snapshot) isNil.
	self deny: (self attributeNamed: 'pharo.mcp.output_budget.exceeded' in: snapshot).
	self assert: (self attributeNamed: 'pharo.mcp.input.bytes' in: snapshot) > 0.
	self assert: (self attributeNamed: 'error.type' in: snapshot) isNil
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallFailsWhenTheCallItMakesFails [
	"Its own span says only that the call it made failed; that call's span says why."

	| outer inner |
	MCPToolRegistry default toolNamed: 'method_compile' ifAbsent: [ self skip: 'method_compile is not registered' ].
	self mcp rpcToolCall: 'tool_call' withParams: {
			('name' -> 'method_compile').
			('arguments' -> { ('class' -> 'Object') } asDictionary) } asDictionary.
	outer := self spanNamed: 'tools/call tool_call'.
	inner := self spanNamed: 'tools/call method_compile'.
	self assert: outer status equals: OTSpan error.
	self assert: (self attributeNamed: 'error.type' in: outer) equals: 'tool_error'.
	self assert: (self attributeNamed: 'pharo.mcp.error.code' in: outer) equals: 'DispatchedToolFailed'.
	self assert: (self attributeNamed: 'pharo.mcp.error.schema.paths' in: outer) isNil.
	self assert: (self attributeNamed: 'pharo.mcp.exception.type' in: outer) isNil.
	self assert: inner status equals: OTSpan error.
	self assert: (self attributeNamed: 'pharo.mcp.error.kind' in: inner) equals: 'input_schema'.
	self assert: (self attributeNamed: 'pharo.mcp.error.schema.paths' in: inner) equals: #( '/source' ).
	self assert: inner parentSpanContext spanIdHex equals: outer spanContext spanIdHex
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallIsAChildOfTheTraceContextInTheRequestMeta [

	| snapshot |
	backend
		recordToolCallFinish:
		(self startToolCallWith: { (#meta -> { ('traceparent' -> self remoteTraceparent) } asDictionary) } asDictionary)
		result: self successToolResult
		error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot spanContext traceIdHex equals: '4bf92f3577b34da6a3ce929d0e0e4736'.
	self assert: snapshot parentSpanContext spanIdHex equals: '00f067aa0ba902b7'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallRecordsCallDurationAndSizeMetrics [

	| record |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	#( 'mcp.server.operation.duration' 'pharo.mcp.tool.input.size' 'pharo.mcp.tool.output.size' ) do: [ :name |
		self deny: (self measurementNamed: name) isNil description: 'The backend should have recorded ' , name ].
	self
		assert: ((self measurementNamed: 'mcp.server.operation.duration') attributes at: 'error.type' ifAbsent: [ nil ]) isNil
		description: 'A successful call must not carry an error type.'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallWithANameNoToolHasRecordsThatCallToo [
	"As a direct call to that name is recorded: by the caller's name, which the server has no tool for."

	| outer inner |
	self mcp rpcToolCall: 'tool_call' withParams: {
			('name' -> 'no_such_tool').
			('arguments' -> { ('class' -> 'Object') } asDictionary) } asDictionary.
	outer := self spanNamed: 'tools/call tool_call'.
	inner := self spanNamed: 'tools/call no_such_tool'.
	self assert: (self attributeNamed: 'pharo.mcp.tool.origin' in: inner) equals: 'unknown'.
	self assert: (self attributeNamed: 'pharo.mcp.dispatch_path' in: inner) equals: 'via_tool_call'.
	self assert: (self attributeNamed: 'pharo.mcp.error.code' in: inner) equals: 'ToolNotFound'.
	self assert: (self attributeNamed: 'pharo.mcp.argument.unknown_names' in: inner) equals: #( 'class' ).
	self assert: inner parentSpanContext spanIdHex equals: outer spanContext spanIdHex.
	self assert: outer status equals: OTSpan error.
	self assert: (self attributeNamed: 'pharo.mcp.error.code' in: outer) equals: 'DispatchedToolFailed'
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testUsingOpenTelemetryInstallsABackendThatDescribesTheServer [

	| mcp |
	mcp := MCP new.
	backend := mcp useOpenTelemetryObservabilityWith: (self settingsAskingForTraces: true).
	self assert: mcp observability identicalTo: backend.
	self assert: backend class equals: MCPOpenTelemetryObservabilityBackend.
	self assert: mcp observabilityEnabled.
	self assert: (OTTracerProvider current resource attributes at: 'service.version') equals: mcp serverIdentity version
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testUsingOpenTelemetryWithoutTracesLeavesTheProvidersAlone [
	"The providers are global and may be the user's."

	backend := nil.
	Smalltalk garbageCollect.
	MCP new useOpenTelemetryObservabilityWith: (self settingsAskingForTraces: false).
	self assert: OTTracerProvider current identicalTo: tracerProvider
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testWhatAResultFoundIsReported [
	"How many entries a listing matched and whether it showed them all; for MCP's own tools, how a test run ended and which tools a search named. The result is built as MCP's tools build theirs, its facts in the data of its structured content."

	| tool attributes |
	tool := MCPToolRegistry default toolNamed: 'class_get' ifAbsent: [ self skip: 'class_get is not registered' ].
	attributes := (backend
		               resultAttributesFor: (tool successResultText: 'Found.' data: {
					                (#pagination -> {
						                 (#totalCount -> 42).
						                 (#returnedCount -> 20).
						                 (#truncated -> true) } asDictionary).
					                (#runCount -> 3).
					                (#failureCount -> 1).
					                (#errorCount -> 0).
					                (#tools -> {
						                 { (#name -> 'class_get') } asDictionary.
						                 { (#name -> 'not a name') } asDictionary }) } asDictionary)
		               origin: 'mcp') asDictionary.
	self assert: (attributes at: 'pharo.mcp.result.count') equals: 42.
	self assert: (attributes at: 'pharo.mcp.result.more').
	self assert: (attributes at: 'pharo.mcp.test.count') equals: 3.
	self assert: (attributes at: 'pharo.mcp.test.outcome') equals: 'failed'.
	self assert: (attributes at: 'pharo.mcp.tool.refs') equals: #( 'class_get' )
]

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> withEnvironmentVariable: aName setTo: aStringOrNil do: aBlock [
	"Runs aBlock with the image's environment variable set to aStringOrNil, or unset for nil, and puts it back as it was."

	| environment previous |
	environment := OSEnvironment current.
	previous := environment at: aName ifAbsent: [ nil ].
	aStringOrNil ifNil: [ previous ifNotNil: [ environment removeKey: aName ] ] ifNotNil: [ environment at: aName put: aStringOrNil ].
	^ aBlock ensure: [
			  previous
				  ifNil: [ environment at: aName ifPresent: [ :value | environment removeKey: aName ] ]
				  ifNotNil: [ environment at: aName put: previous ] ]
]
