"
No-op observability backend: what a server without observability uses. It records nothing, and answers empty logs, metrics and traces.
"
Class {
	#name : 'MCPNoopObservabilityBackend',
	#superclass : 'MCPObservabilityBackend',
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'testing' }
MCPNoopObservabilityBackend >> isNoop [

	^ true
]

{ #category : 'recording' }
MCPNoopObservabilityBackend >> recordSessionEnd [

	
]

{ #category : 'recording' }
MCPNoopObservabilityBackend >> recordSessionStart [

	
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

	
]
