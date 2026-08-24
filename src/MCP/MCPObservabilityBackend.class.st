"
Abstract protocol for MCP observability backends.

Core MCP code talks to this protocol so normal tool execution can report observability facts without depending on a concrete telemetry implementation. The core package provides a no-op implementation; optional packages can provide concrete exporters such as OpenTelemetry.
"
Class {
	#name : 'MCPObservabilityBackend',
	#superclass : 'Object',
	#category : 'MCP-Observability',
	#package : 'MCP',
	#tag : 'Observability'
}

{ #category : 'testing' }
MCPObservabilityBackend class >> isAbstract [

	^ self == MCPObservabilityBackend
]

{ #category : 'clearing' }
MCPObservabilityBackend >> clear [


]

{ #category : 'activation' }
MCPObservabilityBackend >> disable [

	self subclassResponsibility
]

{ #category : 'activation' }
MCPObservabilityBackend >> enable [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> enabled [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> enabled: aBoolean [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportDirectory [

	^ nil
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportDirectory: aPath [


]

{ #category : 'testing' }
MCPObservabilityBackend >> exportEnabled [

	^ false
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportInstanceDirectory [

	^ nil
]

{ #category : 'actions' }
MCPObservabilityBackend >> forceFlush [

	self subclassResponsibility
]

{ #category : 'testing' }
MCPObservabilityBackend >> isNoop [

	self subclassResponsibility
]

{ #category : 'logging' }
MCPObservabilityBackend >> logs [

	^ #(  )
]

{ #category : 'accessing' }
MCPObservabilityBackend >> metrics [

	^ #(  )
]

{ #category : 'accessing' }
MCPObservabilityBackend >> recentCallRecords [

	^ #(  )
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordSessionEndFor: anMCP [

	self subclassResponsibility
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordSessionStartFor: anMCP [

	self subclassResponsibility
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [

	self subclassResponsibility
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordToolCallStart: aToolName [

	^ self recordToolCallStart: aToolName input: nil
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordToolCallStart: aToolName input: inputObject [

	^ self
		  recordToolCallStart: aToolName
		  input: inputObject
		  dispatchPath: 'direct'
		  context: Dictionary new
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordToolCallStart: aToolName input: inputObject dispatchPath: dispatchPath context: contextDictionary [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> resourceMetadata [

	^ Dictionary new
]

{ #category : 'accessing' }
MCPObservabilityBackend >> resourceMetadata: aDictionary [


]

{ #category : 'actions' }
MCPObservabilityBackend >> shutdown [

	self subclassResponsibility
]

{ #category : 'displaying' }
MCPObservabilityBackend >> statusText [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> totalCallCount [

	^ 0
]

{ #category : 'accessing' }
MCPObservabilityBackend >> totalErrorCount [

	^ 0
]

{ #category : 'accessing' }
MCPObservabilityBackend >> totalOutputBudgetExceededCount [

	^ 0
]

{ #category : 'accessing' }
MCPObservabilityBackend >> traceRecords [

	^ #(  )
]
