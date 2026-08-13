"
Abstract protocol for MCP observability backends.

Core MCP code talks to this protocol so normal tool execution can report observability facts without depending on a concrete telemetry implementation. The core package provides a no-op implementation; optional packages can provide concrete exporters such as OpenTelemetry.
"
Class {
	#name : 'MCPObservabilityBackend',
	#superclass : 'Object',
	#category : 'MCP-Monitoring',
	#package : 'MCP',
	#tag : 'Monitoring'
}

{ #category : 'testing' }
MCPObservabilityBackend class >> isAbstract [

	^ self == MCPObservabilityBackend
]

{ #category : 'clearing' }
MCPObservabilityBackend >> clear [

	self subclassResponsibility
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

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportDirectory: aPath [

	self subclassResponsibility
]

{ #category : 'testing' }
MCPObservabilityBackend >> exportEnabled [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportInstanceDirectory [

	self subclassResponsibility
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

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> metrics [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> recentCallRecords [

	self subclassResponsibility
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

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> resourceMetadata: aDictionary [

	self subclassResponsibility
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

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> totalErrorCount [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> totalOutputBudgetExceededCount [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPObservabilityBackend >> traceRecords [

	self subclassResponsibility
]
