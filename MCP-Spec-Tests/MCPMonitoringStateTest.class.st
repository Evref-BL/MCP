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
	record := state recordToolCallStart: 'find-methods'.
	self deny: state enabled.
	self assert: record isNil.
	self assert: state totalCallCount equals: 0.
	self assertEmpty: state logs
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testMCPRecordsToolCallsWhenMonitoringIsEnabled [

	| mcp result stats |
	mcp := MCP new.
	mcp monitoringEnabled: true.
	result := mcp
		          rpcToolCall: 'find-packages'
		          withParams: { (#limit -> 0) } asDictionary.
	stats := mcp monitoringMetrics first.

	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: mcp monitoring totalCallCount equals: 1.
	self assert: stats toolName equals: 'find-packages'.
	self assert: stats successCount equals: 1.
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

	self assert: (explanation beginsWith: 'Outlier:').
	self assert:
		(state outlierExplanationForDurationMilliseconds: 15 stats: stats)
			isEmpty
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testRecordsErrorCall [

	| state record stats recentCall |
	state := MCPMonitoringState new.
	state enable.
	record := state recordToolCallStart: 'edit-method'.
	state recordToolCallFinish: record result: nil error: Error new.
	stats := state metrics first.
	recentCall := state recentCallRecords first.

	self assert: state totalCallCount equals: 1.
	self assert: state totalErrorCount equals: 1.
	self assert: stats errorCount equals: 1.
	self assert: recentCall status equals: 'error'.
	self assert: recentCall errorClass equals: 'Error'
]

{ #category : 'tests' }
MCPMonitoringStateTest >> testRecordsSuccessfulCallMetricsAndLogs [

	| state record result stats |
	state := MCPMonitoringState new.
	state enable.
	record := state recordToolCallStart: 'find-methods'.
	result := MCPStructureCallToolResult
		          content: #(  )
		          structuredContent:
		          { (#summary -> 'Listed methods') } asDictionary.
	state recordToolCallFinish: record result: result error: nil.
	stats := state metrics first.

	self assert: state totalCallCount equals: 1.
	self assert: stats toolName equals: 'find-methods'.
	self assert: stats successCount equals: 1.
	self assert: stats errorCount equals: 0.
	self assert: state activeCallRecords isEmpty.
	self assert: state recentCallRecords size equals: 1.
	self assert: state logs size >= 2.
	self assert:
		(state statusText beginsWith: 'Observability enabled, idle')
]
