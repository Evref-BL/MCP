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
		'previousResourceDetectors'
	],
	#category : 'MCP-OpenTelemetry-Tests',
	#package : 'MCP-OpenTelemetry-Tests'
}

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> attributeNamed: aName in: aSnapshot [

	^ aSnapshot attributes at: aName ifAbsent: [ nil ]
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

{ #category : 'running' }
MCPOpenTelemetryObservabilityBackendTest >> setUp [

	super setUp.
	previousTracerProvider := OTTracerProvider current.
	previousMeterProvider := OTMeterProvider current.
	previousLoggerProvider := OTLoggerProvider current.
	previousResourceDetectors := OTClassStateStore valueAt: #otResourceDetectors forClass: OTTracerProvider ifAbsent: [ nil ].
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
	"Settings of an environment that asks for traces or not."

	| environment |
	environment := Dictionary new.
	aBoolean ifTrue: [ environment at: 'OTEL_EXPORTER_OTLP_ENDPOINT' put: 'http://127.0.0.1:9' ].
	^ MCPOpenTelemetrySettings environment: environment
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

	{
		tracerProvider.
		meterProvider.
		loggerProvider } do: [ :each |
			each ifNotNil: [
					[ each shutdown ]
						on: Error
						do: [ :ignored | nil ] ] ].
	OTTracerProvider current: previousTracerProvider.
	OTMeterProvider current: previousMeterProvider.
	OTLoggerProvider current: previousLoggerProvider.
	OTTracerProvider resourceDetectors: previousResourceDetectors.
	backend := nil.
	super tearDown
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
	"An argument name is the caller's, and so is the name of a tool the server does not have."

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
	self assert: (self attributeNamed: 'pharo.mcp.argument.names' in: snapshot) equals: #( 'name' ).
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

	| result snapshot |
	result := MCPStructureErrorToolResult
		          content: { {
				          (#type -> 'text').
				          (#text -> 'refused') } asDictionary }
		          structuredContent: { (#error -> {
				           (#errorClass -> 'MCPInvalidToolInput').
				           (#violations -> {
					            {
						            (#keyword -> 'type').
						            (#path -> #( 'scope' 'packages' 1 )) } asDictionary.
					            {
						            (#keyword -> 'required').
						            (#path -> #( 'class' )) } asDictionary.
					            {
						            (#keyword -> 'additionalProperties').
						            (#path -> #( 'Object subclass: #Secret' )) } asDictionary }) } asDictionary) } asDictionary.
	backend recordToolCallFinish: self startToolCall result: result error: nil.
	snapshot := exporter onlySnapshot.
	self
		assert: (self attributeNamed: 'pharo.mcp.error.schema.keywords' in: snapshot)
		equals: #( 'additionalProperties' 'required' 'type' ).
	self assert: (self attributeNamed: 'pharo.mcp.error.schema.paths' in: snapshot) equals: #( '/class' '/scope/packages/1' )
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
MCPOpenTelemetryObservabilityBackendTest >> testAnExceptionIsNamedByItsNearestKernelClassAndNeitherItsMessageNorItsStack [

	| snapshot |
	backend
		recordToolCallFinish: self startToolCall
		result: self errorToolResult
		error: (ZnHttpUnsuccessful new messageText: 'secret').
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'pharo.mcp.exception.type' in: snapshot) equals: 'Error'.
	self assert: snapshot events isEmpty.
	self deny: (snapshot attributes values anySatisfy: [ :each | each isString and: [ each includesSubstring: 'secret' ] ])
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAnImageCanMakeEveryServerRecordThroughOpenTelemetry [

	| previous mcp |
	previous := MCP observabilityBackendClass.
	[
		MCP observabilityBackendClass: MCPOpenTelemetryObservabilityBackend.
		mcp := MCP new.
		self assert: mcp observability class equals: MCPOpenTelemetryObservabilityBackend.
		self assert: mcp observability serverInfo isNotNil ] ensure: [
		MCP observabilityBackendClass: (previous = MCPLocalObservabilityBackend ifFalse: [ previous ]) ].
	self assert: MCP new observability class equals: previous
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testArgumentNamesTheToolDoesNotDeclareAreReportedAsUnknown [

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
	self assert: (self attributeNamed: 'pharo.mcp.argument.names' in: snapshot) equals: #( 'colour' 'name' ).
	self assert: (self attributeNamed: 'pharo.mcp.argument.unknown_names' in: snapshot) equals: #( 'colour' )
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testAtMostMaxArgumentNamesAreReported [

	| input |
	input := ((1 to: 40) collect: [ :each | 'a' , each printString -> each ]) asDictionary.
	self assert: (backend argumentNamesIn: input) size equals: backend maxArgumentNames
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
MCPOpenTelemetryObservabilityBackendTest >> testOnlyMCPsOwnPackagesNameAnException [
	"A user's package cannot pass for MCP's by sharing its prefix."

	self assert: (backend isReportablePackageName: 'MCP').
	self assert: (backend isReportablePackageName: 'MCP-OpenTelemetry').
	self assert: (backend isReportablePackageName: 'Kernel-Exceptions').
	self deny: (backend isReportablePackageName: 'MCP-SomeoneElses').
	self deny: (backend isReportablePackageName: 'MCPAcme')
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
	backend describeServer: (self serverInfoAt: '9.8.7').
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
MCPOpenTelemetryObservabilityBackendTest >> testTheSessionInTheCallersBaggageIsReported [

	| snapshot |
	backend
		recordToolCallFinish: (self startToolCallWith: { (#meta -> {
					  ('traceparent' -> self remoteTraceparent).
					  ('baggage' -> 'session.id=s1a2b3c4,other=x') } asDictionary) } asDictionary)
		result: self successToolResult
		error: nil.
	snapshot := exporter onlySnapshot.
	self assert: (self attributeNamed: 'session.id' in: snapshot) equals: 's1a2b3c4'.
	self assert: (self attributeNamed: 'other' in: snapshot) isNil
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testToolCallExportsASpanDescribingTheCall [

	| record snapshot |
	record := self startToolCall.
	backend recordToolCallFinish: record result: self successToolResult error: nil.
	snapshot := exporter onlySnapshot.
	self assert: snapshot name equals: 'tools/call method_compile'.
	self assert: snapshot kind equals: OTSpan server.
	self assert: snapshot status equals: OTSpan unset.
	self assert: (self attributeNamed: 'mcp.method.name' in: snapshot) equals: 'tools/call'.
	self assert: (self attributeNamed: 'gen_ai.tool.name' in: snapshot) equals: 'method_compile'.
	self assert: (self attributeNamed: 'gen_ai.operation.name' in: snapshot) equals: 'execute_tool'.
	self assert: (self attributeNamed: 'pharo.mcp.dispatch_path' in: snapshot) equals: 'tools/call'.
	self assert: (self attributeNamed: 'pharo.mcp.argument.names' in: snapshot) equals: #( 'class' ).
	self deny: (self attributeNamed: 'pharo.mcp.output_budget.exceeded' in: snapshot).
	self assert: (self attributeNamed: 'pharo.mcp.input.bytes' in: snapshot) > 0.
	self assert: (self attributeNamed: 'error.type' in: snapshot) isNil
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
	"How many entries a listing matched and whether it showed them all; for MCP's own tools, how a test run ended and which tools a search named."

	| tool attributes |
	tool := MCPToolRegistry default toolNamed: 'class_get' ifAbsent: [ self skip: 'class_get is not registered' ].
	attributes := (backend
		               resultAttributesFor: (MCPStructureCallToolResult content: #(  ) structuredContent: {
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
MCPOpenTelemetryObservabilityBackendTest >> withEnvironmentVariable: aName setTo: aString do: aBlock [

	| environment previous |
	environment := OSEnvironment current.
	previous := environment at: aName ifAbsent: [ nil ].
	environment at: aName put: aString.
	^ aBlock ensure: [ previous ifNil: [ environment removeKey: aName ] ifNotNil: [ environment at: aName put: previous ] ]
]
