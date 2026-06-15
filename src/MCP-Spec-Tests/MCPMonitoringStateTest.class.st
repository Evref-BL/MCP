"
Tests for the in-memory MCP monitoring state and its integration at the MCP tool-call boundary.
"
Class {
	#name : 'MCPMonitoringStateTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Spec-Tests-Monitoring',
	#package : 'MCP-Spec-Tests',
	#tag : 'Monitoring'
}

{ #category : 'tests' }
MCPMonitoringStateTest >> testDisabledByDefaultDoesNotRecord [

	| state record |
	state := MCPMonitoringState new.
	record := state recordToolCallStart: 'method_metadata_search'.
	self deny: state enabled.
	self assert: record isNil.
	self assert: state totalCallCount equals: 0.
	self assertEmpty: state logs
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testInputSnapshotRedactsSensitiveKeys [

	| input record state |
	state := MCPMonitoringState new.
	state enable.
	input := {
		         (#limit -> 10).
		         (#apiToken -> 'secret-token').
		         (#nested
		          -> { (#password -> 'secret-password') } asDictionary) }
		         asDictionary.
	record := state
		          recordToolCallStart: 'method_metadata_search'
		          input: input.
	state recordToolCallFinish: record result: nil error: Error new.

	self assert: (record inputSnapshot at: #limit) equals: 10.
	self
		assert: (record inputSnapshot at: #apiToken)
		equals: '<redacted>'.
	self
		assert: ((record inputSnapshot at: #nested) at: #password)
		equals: '<redacted>'.
	self assert: record inputObject isNil
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testLargeOutputExceedingBudgetBecomesTraceAndGuidance [

	| budgetBytes exceedsBudget largeText record result state stats |
	state := MCPMonitoringState new.
	state outputBudgetBytes: 80.
	state enable.
	largeText := String new: 200 withAll: $x.
	record := state recordToolCallStart: 'method_source_search'.
	result := MCPStructureCallToolResult
		          content: #(  )
		          structuredContent: {
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
	self assert:
		(state outputBudgetGuidance includesSubstring: 'pagination')
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testMCPRecordsToolCallsWhenMonitoringIsEnabled [

	| mcp record result stats |
	mcp := MCP new.
	mcp monitoringEnabled: true.
	result := mcp
		          rpcToolCall: 'package_search'
		          withParams: { (#limit -> 0) } asDictionary.
	stats := mcp monitoringMetrics first.
	record := mcp monitoring recentCallRecords first.

	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: mcp monitoring totalCallCount equals: 1.
	self assert: stats toolName equals: 'package_search'.
	self assert: stats successCount equals: 1.
	self assert: record inputSnapshot isNil.
	self assert: record outputSnapshot isNil.
	self assert: record inputObject isNil.
	self assert: mcp monitoringLogs notEmpty
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testOutlierExplanationUsesPriorAverage [

	| state stats start record explanation |
	state := MCPMonitoringState new.
	state minimumOutlierMilliseconds: 1.
	state outlierFactor: 2.
	stats := MCPToolCallStats forToolNamed: 'slow-tool'.
	start := DateAndTime now.
	1 to: 3 do: [ :index |
		record := MCPToolCallRecord
			          id: index
			          toolName: 'slow-tool'
			          startedAt: start.
		record finishAt: start durationMilliseconds: 10 status: 'ok'.
		stats recordCall: record ].

	explanation := state
		               outlierExplanationForDurationMilliseconds: 25
		               stats: stats.

	self assert: (explanation beginsWith: '25 ms is').
	self deny: (explanation beginsWith: 'Outlier:').
	self assert:
		(state outlierExplanationForDurationMilliseconds: 15 stats: stats)
			isEmpty
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testRecordsErrorCall [

	| recentCall record state stats |
	state := MCPMonitoringState new.
	state enable.
	record := state recordToolCallStart: 'method_create'.
	state recordToolCallFinish: record result: nil error: Error new.
	stats := state metrics first.
	recentCall := state recentCallRecords first.

	self assert: state totalCallCount equals: 1.
	self assert: state totalErrorCount equals: 1.
	self assert: stats errorCount equals: 1.
	self assert: recentCall status equals: 'error'.
	self assert: recentCall errorClass equals: 'Error'.
	self
		assert: (recentCall outputSnapshot at: #errorClass)
		equals: 'Error'.
	self assert: recentCall inputObject isNil.
	self assert: (state logs anySatisfy: [ :each |
			 each includesSubstring: 'Error tool method_create #' ]).
	self deny: (state logs anySatisfy: [ :each |
			 each includesSubstring: 'error tool method_create #' ])
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testRecordsOutputBudgetMetadata [

	| record result state stats recordData statsData |
	state := MCPMonitoringState new.
	state enable.
	record := state recordToolCallStart: 'method_metadata_search'.
	result := MCPStructureCallToolResult
		          content: #(  )
		          structuredContent:
		          { (#summary -> 'Small output') } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.
	recordData := record asDictionary.
	statsData := stats asDictionary.

	self assert: record outputByteCount > 0.
	self
		assert: record approximateOutputTokenCount
		equals:
		(state approximateOutputTokensForBytes: record outputByteCount).
	self deny: record outputBudgetExceeded.
	self assert: record outputBudgetExplanation isEmpty.
	self assert: record outputSnapshot isNil.
	self assert: stats lastOutputBytes equals: record outputByteCount.
	self assert: stats outputBudgetExceededCount equals: 0.
	self
		assert: (recordData at: #outputBytes)
		equals: record outputByteCount.
	self
		assert: (recordData at: #approximateOutputTokens)
		equals: record approximateOutputTokenCount.
	self
		assert: (statsData at: #lastOutputBytes)
		equals: record outputByteCount
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testRecordsSuccessfulCallMetricsAndLogs [

	| state record result stats |
	state := MCPMonitoringState new.
	state enable.
	record := state recordToolCallStart: 'method_metadata_search'.
	result := MCPStructureCallToolResult
		          content: #(  )
		          structuredContent:
		          { (#summary -> 'Listed methods') } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.

	self assert: state totalCallCount equals: 1.
	self assert: stats toolName equals: 'method_metadata_search'.
	self assert: stats successCount equals: 1.
	self assert: stats errorCount equals: 0.
	self assert: state recentCallRecords size equals: 1.
	self assert: state logs size >= 2.
	self assert: (state logs anySatisfy: [ :each |
			 each includesSubstring: 'Begin tool method_metadata_search #' ]).
	self assert: (state logs anySatisfy: [ :each |
			 each includesSubstring: 'OK tool method_metadata_search #' ]).
	self deny: (state logs anySatisfy: [ :each |
			 each includesSubstring: 'ok tool method_metadata_search #' ]).
	self assert:
		(state statusText beginsWith: 'Observability enabled. Calls: 1')
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testTraceRecordsIncludeErrorsAndOutliersOnly [

	| error normal outlier start state traces |
	state := MCPMonitoringState new.
	start := DateAndTime now.
	normal := MCPToolCallRecord
		          id: 1
		          toolName: 'method_metadata_search'
		          startedAt: start.
	normal finishAt: start durationMilliseconds: 5 status: 'ok'.
	error := MCPToolCallRecord
		         id: 2
		         toolName: 'method_create'
		         startedAt: start.
	error finishAt: start durationMilliseconds: 7 status: 'error'.
	outlier := MCPToolCallRecord
		           id: 3
		           toolName: 'method_rewrite'
		           startedAt: start.
	outlier finishAt: start durationMilliseconds: 250 status: 'ok'.
	outlier outlierExplanation:
		'250 ms is 5.0x the prior average of 50.0 ms'.
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
