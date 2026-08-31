"
Tests for the in-memory MCP observability state and its integration at the MCP tool-call boundary.
"
Class {
	#name : 'MCPLocalObservabilityBackendTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-UI-Tests-Observability',
	#package : 'MCP-UI-Tests',
	#tag : 'Observability'
}

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testDefaultExportDirectoryIsImageLocal [

	self
		assert: MCPLocalObservabilityBackend defaultExportDirectory
		equals: Smalltalk imageFile asFileReference parent / 'pharo-local' / 'mcp' / 'observability'
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testEnabledByDefaultRecords [

	| record state |
	state := MCPLocalObservabilityBackend new.
	record := state recordToolCallStart: 'method_metadata_search'.
	self assert: state enabled.
	self assert: record notNil.
	self assert: state totalCallCount equals: 0.
	self assert: state logs notEmpty
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
MCPLocalObservabilityBackendTest >> testInputSnapshotRedactsSensitiveKeys [

	| input record state |
	state := MCPLocalObservabilityBackend new.
	state enable.
	input := {
		         (#limit -> 10).
		         (#apiToken -> 'secret-token').
		         (#nested -> { (#password -> 'secret-password') } asDictionary) } asDictionary.
	record := state recordToolCallStart: 'method_metadata_search' input: input.
	state recordToolCallFinish: record result: nil error: Error new.

	self assert: (record inputSnapshot at: #limit) equals: 10.
	self assert: (record inputSnapshot at: #apiToken) equals: '<redacted>'.
	self assert: ((record inputSnapshot at: #nested) at: #password) equals: '<redacted>'.
	self assert: record inputObject isNil
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testLargeOutputExceedingBudgetBecomesTraceAndGuidance [

	| budgetBytes exceedsBudget largeText record result state stats |
	state := MCPLocalObservabilityBackend new.
	state outputBudgetBytes: 80.
	state enable.
	largeText := String new: 200 withAll: $x.
	record := state recordToolCallStart: 'method_source_search'.
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
	self assert: record outputSnapshot notNil.
	self assert: stats outputBudgetExceededCount equals: 1.
	self assert: stats maxOutputBytes equals: record outputByteCount.
	self assert: (state statusText includesSubstring: 'Output budget:').
	self assert: (state outputBudgetGuidance includesSubstring: 'pagination')
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testMCPConfiguresObservabilityExportDirectory [

	| defaultDirectory directory mcp |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		mcp := MCP new.
		defaultDirectory := MCPLocalObservabilityBackend defaultExportDirectory.
		self deny: mcp observabilityEnabled.
		self assert: mcp observability class equals: MCPNoopObservabilityBackend.
		self assert: mcp observabilityExportDirectory isNil.
		mcp observabilityEnabled: true.
		self assert: mcp observabilityEnabled.
		self assert: mcp observabilityExportDirectory equals: defaultDirectory.
		mcp observabilityExportDirectory: directory.
		self assert: mcp observabilityExportDirectory equals: directory.
		self assert: (mcp observability resourceMetadata at: #'pharo.majorVersion') equals: PharoCompatibility currentMajorVersion.
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
			(#arguments -> { (#limit -> 0) } asDictionary) } asDictionary.
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
		result := mcp rpcToolCall: 'package_search' withParams: { (#limit -> 0) } asDictionary.
		stats := mcp observabilityMetrics first.
		record := mcp observability recentCallRecords first.

		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: mcp observability totalCallCount equals: 1.
		self assert: stats toolName equals: 'package_search'.
		self assert: stats successCount equals: 1.
		self assert: record inputSnapshot isNil.
		self assert: record outputSnapshot isNil.
		self assert: record inputObject isNil.
		self assert: mcp observabilityLogs notEmpty.
		self assert: mcp observability logFileReference exists.
		self assert: mcp observability metricsFileReference exists ] ensure: [ directory exists ifTrue: [ directory deleteAll ] ]
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testMCPTestToolsDoNotRecordObservability [

	| mcp result |
	mcp := MCP new.
	mcp observabilityEnabled: true.

	result := mcp executeTool: MCPExternalTestTool new named: MCPExternalTestTool toolName withParams: Dictionary new.

	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: mcp observability totalCallCount equals: 0.
	self assert: mcp observabilityMetrics isEmpty.
	self assert: mcp observability recentCallRecords isEmpty
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testOutlierExplanationUsesPriorAverage [

	| state stats start record explanation |
	state := MCPLocalObservabilityBackend new.
	state minimumOutlierMilliseconds: 1.
	state outlierFactor: 2.
	stats := MCPToolCallStats forToolNamed: 'slow-tool'.
	start := DateAndTime now.
	1 to: 3 do: [ :index |
			record := MCPToolCallRecord id: index toolName: 'slow-tool' startedAt: start.
			record finishAt: start durationMilliseconds: 10 status: 'ok'.
			stats recordCall: record ].

	explanation := state outlierExplanationForDurationMilliseconds: 25 stats: stats.

	self assert: (explanation beginsWith: '25 ms is').
	self deny: (explanation beginsWith: 'Outlier:').
	self assert: (state outlierExplanationForDurationMilliseconds: 15 stats: stats) isEmpty
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testRecordsErrorCall [

	| recentCall record state stats |
	state := MCPLocalObservabilityBackend new.
	state enable.
	record := state recordToolCallStart: 'method_compile'.
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
	state enable.
	record := state recordToolCallStart: 'method_metadata_search'.
	result := MCPStructureCallToolResult content: #(  ) structuredContent: { (#summary -> 'Small output') } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.
	recordData := record asDictionary.
	statsData := stats asDictionary.

	self assert: record outputByteCount > 0.
	self assert: record inputByteCount equals: 0.
	self assert: record approximateOutputTokenCount equals: (state approximateOutputTokensForBytes: record outputByteCount).
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
	state enable.
	error := MCPInvalidToolInput new
		         toolName: 'class_search';
		         violations: { (MCPInvalidToolInput missingRequiredArgumentViolationNamed: 'name') };
		         messageText: 'Tool input does not match the input schema.';
		         yourself.
	record := state recordToolCallStart: 'class_search'.
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
	state enable.
	details := {
		           (#errorClass -> 'MCPCommandError').
		           (#errorCode -> 'MethodNotFound').
		           (#causeClass -> 'KeyNotFound').
		           (#message -> 'No method found.') } asDictionary.
	record := state recordToolCallStart: 'method_get'.
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
	state enable.
	record := state recordToolCallStart: 'method_metadata_search'.
	result := MCPStructureCallToolResult content: #(  ) structuredContent: { (#summary -> 'Listed methods') } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.

	self assert: state totalCallCount equals: 1.
	self assert: stats toolName equals: 'method_metadata_search'.
	self assert: stats successCount equals: 1.
	self assert: stats errorCount equals: 0.
	self assert: state recentCallRecords size equals: 1.
	self assert: state logs size >= 2.
	self assert: (state logs anySatisfy: [ :each | each includesSubstring: 'Begin tool method_metadata_search #' ]).
	self assert: (state logs anySatisfy: [ :each | each includesSubstring: 'OK tool method_metadata_search #' ]).
	self deny: (state logs anySatisfy: [ :each | each includesSubstring: 'ok tool method_metadata_search #' ]).
	self assert: (state statusText beginsWith: 'Observability enabled. Calls: 1')
]

{ #category : 'tests' }
MCPLocalObservabilityBackendTest >> testSessionLifecycleWritesResourceMarkers [

	| directory resource state |
	directory := FileLocator temp asFileReference / ('mcp-observability-' , UUID new asString).
	[
		directory exists ifTrue: [ directory deleteAll ].
		state := MCPLocalObservabilityBackend new.
		state exportDirectory: directory.
		state recordSessionStartFor: nil.
		resource := STONJSON fromString: state resourceFileReference contents.
		self assert: (resource includesKey: 'sessionStartedAt').
		self deny: (resource includesKey: 'sessionEndedAt').
		state recordSessionEndFor: nil.
		resource := STONJSON fromString: state resourceFileReference contents.
		self assert: (resource includesKey: 'sessionStartedAt').
		self assert: (resource includesKey: 'sessionEndedAt') ] ensure: [ directory exists ifTrue: [ directory deleteAll ] ]
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
		record := state recordToolCallStart: 'package_search'.
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
		input := {
			         (#limit -> 1).
			         (#apiToken -> 'secret-token') } asDictionary.
		record := state recordToolCallStart: 'method_source_search' input: input.
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
		self assert: (payload at: 'toolName') equals: 'method_source_search'.
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
	normal := MCPToolCallRecord id: 1 toolName: 'method_metadata_search' startedAt: start.
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
	record := state recordToolCallStart: 'image_evaluate'.
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
