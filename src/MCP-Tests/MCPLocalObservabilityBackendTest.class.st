"
Tests for the in-memory MCP observability state and its integration at the MCP tool-call boundary.
"
Class {
	#name : 'MCPLocalObservabilityBackendTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPLocalObservabilityBackendTest >> start: aToolName input: anObject on: aBackend [

	^ aBackend
		  recordToolCallStart: aToolName
		  input: anObject
		  dispatchPath: 'direct'
		  context: Dictionary new
]

{ #category : 'private' }
MCPLocalObservabilityBackendTest >> statsOfThreeCallsLasting: milliseconds [

	| start stats |
	stats := MCPToolCallStats forToolNamed: 'slow-tool'.
	start := DateAndTime now.
	1 to: 3 do: [ :index |
			stats recordCall: ((MCPToolCallRecord id: index toolName: 'slow-tool' startedAt: start)
					 finishAt: start durationMilliseconds: milliseconds status: 'ok';
					 yourself) ].
	^ stats
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testACallStartedInAnEarlierImageSessionIsNotRecorded [
	"A save carries the calls running into every start of the saved image, which ends them there: none is counted, logged or traced, since the time it took is the time the image was not running. The call is simulated as started in another image session."

	| state record |
	state := MCPLocalObservabilityBackend new.
	record := self start: 'method_search' input: nil on: state.
	self assert: record imageSession identicalTo: Smalltalk session.
	self deny: record startedInAnEarlierImageSession.
	record imageSession: Object new.
	self assert: record startedInAnEarlierImageSession.
	state recordToolCallFinish: record result: nil error: ZeroDivide new.
	self assert: state totalCallCount equals: 0.
	self assert: state recentCallRecords isEmpty.
	self assert: state traceRecords isEmpty.
	self assert: state logs isEmpty
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testARecordWithoutItsImageSessionIsRecorded [
	"A record made before records knew their image session, as the call that loads this code over an older MCP has, started in this session as far as anyone can tell."

	| state record |
	state := MCPLocalObservabilityBackend new.
	record := (MCPToolCallRecord id: 1 toolName: 'evaluate' startedAt: DateAndTime now)
		          dispatchPath: 'direct';
		          yourself.
	self assert: record imageSession isNil.
	self deny: record startedInAnEarlierImageSession.
	state recordToolCallFinish: record result: nil error: ZeroDivide new.
	self assert: state totalCallCount equals: 1
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testDefaultExportDirectoryIsImageLocal [

	self
		assert: MCPLocalObservabilityBackend defaultExportDirectory
		equals: Smalltalk imageFile asFileReference parent / 'pharo-local' / 'mcp' / 'observability'
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testEachKindOfFailureIsRecordedAsSuch [
	"An exception that escaped the tool is one whatever code its answer carries, unless it is a command error, the tool's own refusal; an error the tool answered is a domain error when it carries a code."

	| state kindOf coded uncoded |
	state := MCPLocalObservabilityBackend new.
	kindOf := [ :result :error |
		          | record |
		          record := self start: 'method_get' input: nil on: state.
		          state recordToolCallFinish: record result: result error: error.
		          record errorKind ].
	coded := MCPToolGetMethod new errorResultText: 'Failed.' details: { (#errorCode -> 'ToolExecutionError') } asDictionary.
	uncoded := MCPToolGetMethod new errorResultText: 'Failed.' details: Dictionary new.
	self assert: (kindOf value: coded value: ZeroDivide new) equals: 'exception'.
	self
		assert: (kindOf value: coded value: (MCPCommandError new
					  errorCode: 'MethodNotFound';
					  yourself))
		equals: 'domain'.
	self assert: (kindOf value: coded value: nil) equals: 'domain'.
	self assert: (kindOf value: uncoded value: nil) equals: 'tool_result'.
	self assert: (kindOf value: nil value: JRPCInvalidRequest new) equals: 'json_rpc'
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testEnabledByDefaultRecords [
	"A call is recorded from its start, and logged only when it ends."

	| record state |
	state := MCPLocalObservabilityBackend new.
	record := self start: 'method_search' input: nil on: state.
	self assert: state enabled.
	self assert: record isNotNil.
	self assert: state totalCallCount equals: 0.
	self assert: state logs isEmpty
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testExportDisabledByDefault [

	| state |
	state := MCPLocalObservabilityBackend new.
	self deny: state exportEnabled.
	self assert: state exportDirectory isNil.
	self assert: state exportInstanceDirectory isNil
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testExportedTextEndsLinesWithLineFeeds [
	"A log or trace file is read outside the image, like an answer."

	| record |
	record := STONJSON fromString: (MCPLocalObservabilityBackend new
			           logRecordJSONFor: (String streamContents: [ :stream | stream << 'one' << String cr << 'two' ])
			           timestamp: DateAndTime now).
	self assert: (record at: 'message') equals: (String streamContents: [ :stream | stream << 'one' << String lf << 'two' ])
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testInputSnapshotRedactsSensitiveKeys [

	| input record state |
	state := MCPLocalObservabilityBackend new.
	input := {
		         (#offset -> 10).
		         (#apiToken -> 'secret-token').
		         (#nested -> { (#password -> 'secret-password') } asDictionary) } asDictionary.
	record := self start: 'method_search' input: input on: state.
	state recordToolCallFinish: record result: nil error: Error new.

	self assert: (record inputSnapshot at: #offset) equals: 10.
	self assert: (record inputSnapshot at: #apiToken) equals: '<redacted>'.
	self assert: ((record inputSnapshot at: #nested) at: #password) equals: '<redacted>'.
	self assert: record inputObject isNil
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testLargeOutputExceedingBudgetBecomesATrace [

	| budgetBytes exceedsBudget largeText record result state stats |
	state := MCPLocalObservabilityBackend new.
	state outputBudgetBytes: 80.
	largeText := String new: 200 withAll: $x.
	record := self start: 'method_source_search' input: nil on: state.
	result := MCPStructureCallToolResult content: #(  ) structuredContent: {
			          (#summary -> 'Large output').
			          (#items -> { largeText }) } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.
	budgetBytes := state outputBudgetBytes.
	exceedsBudget := (record outputByteCount - budgetBytes) positive.

	self assert: exceedsBudget.
	self assert: record outputBudgetExceeded.
	self assert: record outputBudgetExplanation isNotEmpty.
	self assert: record isTraceWorthy.
	self assert: state traceRecords asArray equals: { record }.
	self assert: record outputSnapshot isNotNil.
	self assert: stats outputBudgetExceededCount equals: 1.
	self assert: stats maxOutputBytes equals: record outputByteCount
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testMCPConfiguresObservabilityExportDirectory [

	| defaultDirectory directory mcp |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		mcp := MCP new.
		defaultDirectory := MCPLocalObservabilityBackend defaultExportDirectory.
		self assert: mcp observabilityEnabled.
		self assert: (mcp observability isKindOf: MCPLocalObservabilityBackend).
		self assert: mcp observabilityExportDirectory equals: defaultDirectory.
		mcp observabilityExportDirectory: directory.
		self assert: mcp observabilityExportDirectory equals: directory.
		self assert: (mcp observability resourceMetadata at: #'pharo.majorVersion') equals: SystemVersion current major.
		self assert: (mcp observability resourceMetadata includesKey: #'mcp.port') ] ensure: [
		directory exists ifTrue: [ directory deleteAll ] ]
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testMCPRecordsToolCallDispatchPath [

	| mcp records |
	mcp := MCP new.
	mcp observabilityEnabled: true.

	mcp rpcToolCall: 'tool_call' withParams: {
			(#name -> 'package_search').
			(#arguments -> Dictionary new) } asDictionary.
	records := mcp observability recentCallRecords.

	self assert: records size equals: 2.
	self assert: records first toolName equals: 'tool_call'.
	self assert: records first dispatchPath equals: 'direct'.
	self assert: records second toolName equals: 'package_search'.
	self assert: records second dispatchPath equals: 'via_tool_call'
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testMCPRecordsToolCallsWhenObservabilityIsEnabled [

	| directory mcp record result stats |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		directory exists ifTrue: [ directory deleteAll ].
		mcp := MCP new.
		mcp observabilityExportDirectory: directory.
		result := mcp rpcToolCall: 'class_search' withParams: { (#scope -> { (#classes -> #( 'MCP' )) } asDictionary) } asDictionary.
		stats := mcp observabilityMetrics first.
		record := mcp observability recentCallRecords first.

		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: mcp observability totalCallCount equals: 1.
		self assert: stats toolName equals: 'class_search'.
		self assert: stats successCount equals: 1.
		self assert: record inputSnapshot isNil.
		self assert: record outputSnapshot isNil.
		self assert: record inputObject isNil.
		self assert: mcp observabilityLogs isNotEmpty.
		self assert: mcp observability logFileReference exists.
		self assert: mcp observability metricsFileReference exists ] ensure: [ directory exists ifTrue: [ directory deleteAll ] ]
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testMCPTestToolsDoNotRecordObservability [

	| mcp result |
	mcp := MCP new.
	mcp observabilityEnabled: true.

	result := mcp executeTool: MCPExternalTestTool new withParams: Dictionary new dispatchPath: 'direct'.

	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: mcp observability totalCallCount equals: 0.
	self assert: mcp observabilityMetrics isEmpty.
	self assert: mcp observability recentCallRecords isEmpty
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testMetricsFileIsWrittenAtMostOncePerInterval [

	| directory state calls |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		directory exists ifTrue: [ directory deleteAll ].
		state := MCPLocalObservabilityBackend new.
		state exportDirectory: directory.
		state metricsExportIntervalMilliseconds: 200.
		calls := [ :count |
			         count timesRepeat: [
					         state
						         recordToolCallFinish: (self start: 'class_search' input: nil on: state)
						         result: (MCPStructureCallToolResult content: #(  ))
						         error: nil ] ].
		calls value: 1.
		self assert: ((STONJSON fromString: state metricsFileReference contents) at: 'totalCallCount') equals: 1.
		calls value: 2.
		"Calls within the interval do not rewrite the file..."
		self assert: ((STONJSON fromString: state metricsFileReference contents) at: 'totalCallCount') equals: 1.
		(Delay forMilliseconds: 400) wait.
		"...and one write follows once the interval has passed."
		self assert: ((STONJSON fromString: state metricsFileReference contents) at: 'totalCallCount') equals: 3 ] ensure: [
		directory exists ifTrue: [ directory deleteAll ] ]
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testNoopBackendRecordsNothing [

	self deny: MCPNoopObservabilityBackend new enabled.
	self assert: (self start: 'x' input: nil on: MCPNoopObservabilityBackend new) isNil
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testOutlierExplanationUsesPriorAverage [
	"An outlier is several times the prior average and long enough to matter: 200 ms is four times 50 ms, yet too short."

	| state |
	state := MCPLocalObservabilityBackend new.
	self assert:
		((state outlierExplanationForDurationMilliseconds: 400 stats: (self statsOfThreeCallsLasting: 100)) beginsWith: '400 ms is').
	self assert: (state outlierExplanationForDurationMilliseconds: 280 stats: (self statsOfThreeCallsLasting: 100)) isEmpty.
	self assert: (state outlierExplanationForDurationMilliseconds: 200 stats: (self statsOfThreeCallsLasting: 50)) isEmpty
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testRecordsErrorCall [

	| recentCall record state stats |
	state := MCPLocalObservabilityBackend new.
	record := self start: 'method_compile' input: nil on: state.
	state recordToolCallFinish: record result: nil error: Error new.
	stats := state metrics first.
	recentCall := state recentCallRecords first.

	self assert: state totalCallCount equals: 1.
	self assert: state totalErrorCount equals: 1.
	self assert: stats errorCount equals: 1.
	self assert: (stats errorCountsByClass at: 'Error') equals: 1.
	self assert: recentCall status equals: 'error'.
	self assert: recentCall errorClass equals: 'Error'.
	self assert: (recentCall outputSnapshot at: #errorClass) equals: 'Error'.
	self assert: recentCall inputObject isNil.
	self assert: (state logs anySatisfy: [ :each | each includesSubstring: 'Error tool method_compile #' ]).
	self deny: (state logs anySatisfy: [ :each | each includesSubstring: 'error tool method_compile #' ])
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testRecordsOutputBudgetMetadata [

	| record result state stats recordData statsData |
	state := MCPLocalObservabilityBackend new.
	record := self start: 'method_search' input: nil on: state.
	result := MCPStructureCallToolResult content: #(  ) structuredContent: { (#summary -> 'Small output') } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.
	recordData := record asDictionary.
	statsData := stats asMetricsDictionary.

	self assert: record outputByteCount > 0.
	self assert: record inputByteCount equals: 0.
	self assert: record approximateOutputTokenCount equals: record outputByteCount + 3 // 4.
	self deny: record outputBudgetExceeded.
	self assert: record outputBudgetExplanation isEmpty.
	self assert: record outputSnapshot isNil.
	self assert: stats lastOutputBytes equals: record outputByteCount.
	self assert: stats outputBudgetExceededCount equals: 0.
	self assert: (recordData at: #outputBytes) equals: record outputByteCount.
	self assert: (recordData at: #approximateOutputTokens) equals: record approximateOutputTokenCount.
	self assert: (statsData at: #lastOutputBytes) equals: record outputByteCount.
	self assert: (statsData at: #firstCallAt) isNotEmpty.
	self assert: (statsData at: #lastCallAt) isNotEmpty
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testRecordsSchemaViolationErrorDetails [

	| error record state stats |
	state := MCPLocalObservabilityBackend new.
	error := MCPInvalidToolInput new
		         toolName: 'class_search';
		         violations: { (MCPInvalidToolInput missingRequiredArgumentViolationNamed: 'name') };
		         messageText: 'Tool input does not match the input schema.';
		         yourself.
	record := self start: 'class_search' input: nil on: state.
	state recordToolCallFinish: record result: nil error: error.
	stats := state metrics first.

	self assert: record errorKind equals: 'input_schema'.
	self assert: record errorClass equals: 'MCPInvalidToolInput'.
	self assert: record schemaViolationCount equals: 1.
	self assert: (record schemaViolationKeywords includes: 'required').
	self assert: (stats errorCountsByKind at: 'input_schema') equals: 1.
	self assert: (stats errorCountsByClass at: 'MCPInvalidToolInput') equals: 1
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testRecordsStructuredToolErrorDetails [

	| details record result state stats |
	state := MCPLocalObservabilityBackend new.
	details := {
		           (#errorClass -> 'MCPCommandError').
		           (#errorCode -> 'MethodNotFound').
		           (#causeClass -> 'KeyNotFound').
		           (#message -> 'No method found.') } asDictionary.
	record := self start: 'method_get' input: nil on: state.
	result := MCPToolGetMethod new errorResultText: 'No method found.' details: details.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.

	self assert: record status equals: 'error'.
	self assert: record errorKind equals: 'domain'.
	self assert: record errorClass equals: 'MCPCommandError'.
	self assert: record errorCode equals: 'MethodNotFound'.
	self assert: record causeClass equals: 'KeyNotFound'.
	self assert: (stats errorCountsByKind at: 'domain') equals: 1.
	self assert: (stats errorCountsByCode at: 'MethodNotFound') equals: 1
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testRecordsSuccessfulCallMetricsAndLogs [

	| state record result stats |
	state := MCPLocalObservabilityBackend new.
	record := self start: 'method_search' input: nil on: state.
	result := MCPStructureCallToolResult content: #(  ) structuredContent: { (#summary -> 'Listed methods') } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.

	self assert: state totalCallCount equals: 1.
	self assert: stats toolName equals: 'method_search'.
	self assert: stats successCount equals: 1.
	self assert: stats errorCount equals: 0.
	self assert: state recentCallRecords size equals: 1.
	self assert: (state logs count: [ :each | each includesSubstring: 'tool method_search #' ]) equals: 1.
	self assert: (state logs anySatisfy: [ :each | each includesSubstring: 'OK tool method_search #' ]).
	self deny: (state logs anySatisfy: [ :each | each includesSubstring: 'ok tool method_search #' ])
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testSessionLifecycleWritesResourceMarkers [

	| directory resource state |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		directory exists ifTrue: [ directory deleteAll ].
		state := MCPLocalObservabilityBackend new.
		state exportDirectory: directory.
		state recordSessionStart.
		resource := STONJSON fromString: state resourceFileReference contents.
		self assert: (resource includesKey: 'sessionStartedAt').
		self deny: (resource includesKey: 'sessionEndedAt').
		state recordSessionEnd.
		resource := STONJSON fromString: state resourceFileReference contents.
		self assert: (resource includesKey: 'sessionStartedAt').
		self assert: (resource includesKey: 'sessionEndedAt') ] ensure: [ directory exists ifTrue: [ directory deleteAll ] ]
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testToolCallNamingItselfIsTheCallersMistake [

	| mcp result record |
	mcp := MCP new.
	mcp observabilityEnabled: true.
	result := mcp rpcToolCall: 'tool_call' withParams: { (#name -> 'tool_call') } asDictionary.
	record := mcp observability recentCallRecords first.
	self assert: (result at: #isError ifAbsent: [ false ]).
	self assert: record toolName equals: 'tool_call'.
	self assert: record errorCode equals: 'ToolCallCallsItself'.
	self assert: record errorKind equals: 'domain'
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testTraceExportSkipsNonTraceRecords [

	| directory record result state |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		directory exists ifTrue: [ directory deleteAll ].
		state := MCPLocalObservabilityBackend new.
		state exportDirectory: directory.
		state outputBudgetBytes: 10000.
		record := self start: 'package_search' input: nil on: state.
		result := MCPStructureCallToolResult content: #(  ) structuredContent: { (#summary -> 'Small output') } asDictionary.
		state recordToolCallFinish: record result: result error: nil.
		self assert: directory exists.
		self deny: state traceFileReference exists.
		self assert: state logFileReference exists.
		self assert: state metricsFileReference exists ] ensure: [ directory exists ifTrue: [ directory deleteAll ] ]
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testTraceExportWritesOverBudgetRecordAsJSONLine [

	| directory input line output payload record resource result state traceFile |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		directory exists ifTrue: [ directory deleteAll ].
		state := MCPLocalObservabilityBackend new.
		state resourceMetadata: {
				(#'pharo.majorVersion' -> 13).
				(#'mcp.port' -> 9013) } asDictionary.
		state outputBudgetBytes: 80.
		state exportDirectory: directory.
		input := { (#apiToken -> 'secret-token') } asDictionary.
		record := self start: 'method_source_search' input: input on: state.
		result := MCPStructureCallToolResult content: #(  ) structuredContent: {
				          (#summary -> 'Large output').
				          (#items -> { (String new: 200 withAll: $x) }) } asDictionary.
		state recordToolCallFinish: record result: result error: nil.
		self assert: state exportInstanceDirectory exists.
		self assert: (state exportInstanceDirectory basename beginsWith: 'pharo-13-9013-').
		self assert: state resourceFileReference exists.
		self assert: state logFileReference exists.
		self assert: state metricsFileReference exists.
		resource := STONJSON fromString: state resourceFileReference contents.
		self assert: (resource at: 'service.name') equals: 'mcp-pharo'.
		self assert: (resource at: 'pharo.majorVersion') equals: 13.
		traceFile := state traceFileReference.
		self assert: traceFile exists.
		line := traceFile contents lines first.
		payload := STONJSON fromString: line.
		self assert: (payload at: 'event.name') equals: 'mcp.tool_call.output_budget_exceeded'.
		self assert: (payload at: 'tool') equals: 'method_source_search'.
		self assert: (payload at: 'dispatchPath') equals: 'direct'.
		self assert: ((payload at: 'event.kinds') includes: 'output_budget_exceeded').
		self assert: (payload at: 'inputBytes') > 0.
		self assert: (payload at: 'outputBudgetBytes') equals: 80.
		self deny: (payload includesKey: 'outputBudgetExceeded').
		self deny: (payload includesKey: 'summary').
		self assert: ((payload at: 'input') at: 'apiToken') equals: '<redacted>'.
		output := payload at: 'output'.
		self assert: (output at: 'summary') equals: 'Large output'.
		self assert: (output at: 'items') first size equals: 200 ] ensure: [ directory exists ifTrue: [ directory deleteAll ] ]
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testTraceRecordsIncludeErrorsAndOutliersOnly [

	| error normal outlier start state traces |
	state := MCPLocalObservabilityBackend new.
	start := DateAndTime now.
	normal := MCPToolCallRecord id: 1 toolName: 'method_search' startedAt: start.
	normal finishAt: start durationMilliseconds: 5 status: 'ok'.
	error := MCPToolCallRecord id: 2 toolName: 'method_compile' startedAt: start.
	error finishAt: start durationMilliseconds: 7 status: 'error'.
	outlier := MCPToolCallRecord id: 3 toolName: 'method_rewrite' startedAt: start.
	outlier finishAt: start durationMilliseconds: 250 status: 'ok'.
	outlier outlierExplanation: '250 ms is 5.0x the prior average of 50.0 ms'.
	state recentCalls addAll: {
			outlier.
			error.
			normal }.

	traces := state traceRecords.

	self assert: traces asArray equals: {
			outlier.
			error }.
	self deny: normal isTraceWorthy.
	self assert: error isTraceWorthy.
	self assert: outlier isTraceWorthy
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testTraceSnapshotForCollectionAddsTruncationMarker [

	| snapshot state |
	state := MCPLocalObservabilityBackend new.
	snapshot := state traceSnapshotFor: (1 to: state maxTraceCollectionItems + 2) asArray.
	self assert: snapshot size equals: state maxTraceCollectionItems + 1.
	self assert: snapshot last equals: 'truncated 2 items omitted'
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testTraceSnapshotHasCompactErrorShape [

	| errorData output record result state |
	state := MCPLocalObservabilityBackend new.
	state outputBudgetBytes: 10000.
	record := self start: 'evaluate' input: nil on: state.
	errorData := {
		             (#message -> 'failed').
		             (#stackTrace -> #( 'frame one' 'frame two' )).
		             (#signalerContext -> 'a context') } asDictionary.
	result := MCPStructureCallToolResult content: #(  ) structuredContent: {
			          (#summary -> 'failed').
			          (#error -> errorData) } asDictionary.
	state recordToolCallFinish: record result: result error: Error new.
	output := record outputSnapshot.
	self assert: (output at: #error) equals: { (#message -> 'failed') } asDictionary
]
