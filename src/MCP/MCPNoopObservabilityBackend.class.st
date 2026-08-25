"
No-op observability backend for MCP.

This is the default backend for MCP core. It deliberately has no external dependencies, including OpenTelemetry.
"
Class {
	#name : 'MCPNoopObservabilityBackend',
	#superclass : 'MCPObservabilityBackend',
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'clearing' }
MCPNoopObservabilityBackend >> clear [
	"No-op backend has no state to clear."

	
]

{ #category : 'activation' }
MCPNoopObservabilityBackend >> disable [
	"No-op backend stays disabled."

	
]

{ #category : 'activation' }
MCPNoopObservabilityBackend >> enable [
	"No-op backend stays disabled."

	
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> enabled [

	^ false
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> enabled: aBoolean [
	"No-op backend stays disabled."

	
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> exportDirectory [

	^ nil
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> exportDirectory: aPath [
	"No-op backend does not export."

	
]

{ #category : 'testing' }
MCPNoopObservabilityBackend >> exportEnabled [

	^ false
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> exportInstanceDirectory [

	^ nil
]

{ #category : 'actions' }
MCPNoopObservabilityBackend >> forceFlush [
	"No-op backend has nothing to flush."

	
]

{ #category : 'testing' }
MCPNoopObservabilityBackend >> isNoop [

	^ true
]

{ #category : 'logging' }
MCPNoopObservabilityBackend >> logs [

	^ #(  )
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> metrics [

	^ #(  )
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> recentCallRecords [

	^ #(  )
]

{ #category : 'recording' }
MCPNoopObservabilityBackend >> recordSessionEndFor: anMCP [
	"No-op backend has no session state."

	
]

{ #category : 'recording' }
MCPNoopObservabilityBackend >> recordSessionStartFor: anMCP [
	"No-op backend has no session state."

	
]

{ #category : 'recording' }
MCPNoopObservabilityBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [

	^ nil
]

{ #category : 'recording' }
MCPNoopObservabilityBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [

	^ nil
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> resourceMetadata [

	^ Dictionary new
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> resourceMetadata: aDictionary [
	"No-op backend does not keep resource metadata."

	
]

{ #category : 'actions' }
MCPNoopObservabilityBackend >> shutdown [
	"No-op backend has nothing to shut down."

	
]

{ #category : 'displaying' }
MCPNoopObservabilityBackend >> statusText [

	^ 'Observability disabled'
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> totalCallCount [

	^ 0
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> totalErrorCount [

	^ 0
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> totalOutputBudgetExceededCount [

	^ 0
]

{ #category : 'accessing' }
MCPNoopObservabilityBackend >> traceRecords [

	^ #(  )
]
