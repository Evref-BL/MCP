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
	"Settings of an environment that asks for traces or not, with no settings file to fall back on."

	| environment |
	environment := Dictionary new.
	environment at: 'XDG_CONFIG_HOME' put: (FileLocator temp asFileReference / 'mcp-no-such-config') fullName.
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
MCPOpenTelemetryObservabilityBackendTest >> testAProviderThatRefusesTheDescriptionLeavesTheOthersDescribed [

	tracerProvider shutdown.
	backend describeServer: (self serverInfoAt: '9.8.7').
	self
		assert: (meterProvider resource attributes at: 'service.name') equals: 'pharo-mcp';
		assert: (loggerProvider resource attributes at: 'service.name') equals: 'pharo-mcp'
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
MCPOpenTelemetryObservabilityBackendTest >> testRecordingThatFailsLeavesTheCallUnrecorded [

	self assert: (self startToolCallWith: nil) isNil.
	self assert: exporter snapshots isEmpty
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
MCPOpenTelemetryObservabilityBackendTest >> testSettingsThatAskForNoTracesRecordNothing [

	| mcp |
	mcp := MCP new.
	backend := mcp useOpenTelemetryObservabilityWith: (self settingsAskingForTraces: false).
	self deny: mcp observabilityEnabled.
	self assert: self startToolCall isNil.
	backend recordSessionStart.
	self assert: exporter snapshots isEmpty
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testStartingTheImageAgainConfiguresItsServersFromTheSettingsItNowHas [

	| traced untraced untracedBackend |
	traced := MCP new.
	traced observability: backend.
	untraced := MCP new.
	untracedBackend := untraced observability.
	MCPOpenTelemetryObservabilityBackend
		reconfigure: {
				traced.
				untraced }
		with: (self settingsAskingForTraces: false).
	self assert: traced observability identicalTo: backend.
	self assert: backend isNoop.
	self assert: untraced observability identicalTo: untracedBackend.
	MCPOpenTelemetryObservabilityBackend reconfigure: { traced } with: (self settingsAskingForTraces: true).
	self deny: backend isNoop
]

{ #category : 'tests' }
MCPOpenTelemetryObservabilityBackendTest >> testStatusDistinguishesErrorsFromResults [

	self assert: (backend statusForResult: self successToolResult error: nil) equals: 'ok'.
	self assert: (backend statusForResult: self errorToolResult error: nil) equals: 'error'.
	self assert: (backend statusForResult: nil error: nil) equals: 'error'.
	self assert: (backend statusForResult: self successToolResult error: Error new) equals: 'error'
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

{ #category : 'private' }
MCPOpenTelemetryObservabilityBackendTest >> withEnvironmentVariable: aName setTo: aString do: aBlock [

	| environment previous |
	environment := OSEnvironment current.
	previous := environment at: aName ifAbsent: [ nil ].
	environment at: aName put: aString.
	^ aBlock ensure: [ previous ifNil: [ environment removeKey: aName ] ifNotNil: [ environment at: aName put: previous ] ]
]
