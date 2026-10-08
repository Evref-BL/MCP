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

{ #category : 'actions' }
MCPNoopObservabilityBackend >> forceFlush [
	"No-op backend has nothing to flush."

	
]

{ #category : 'testing' }
MCPNoopObservabilityBackend >> isNoop [

	^ true
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

{ #category : 'actions' }
MCPNoopObservabilityBackend >> shutdown [
	"No-op backend has nothing to shut down."

	
]

{ #category : 'displaying' }
MCPNoopObservabilityBackend >> statusText [

	^ 'Observability disabled'
]
