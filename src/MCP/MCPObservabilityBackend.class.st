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

	^ self
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

{ #category : 'private - errors' }
MCPObservabilityBackend >> errorDetailsForResult: aToolResult error: anError [

	| details resultDetails |
	details := Dictionary new.
	anError ifNotNil: [
			details at: #errorClass put: anError class name asString.
			details at: #message put: (anError messageText ifNil: [ anError asString ]).
			anError mcpAddToolErrorDetailsTo: details ].
	resultDetails := self errorDetailsFromToolResult: aToolResult.
	resultDetails keysAndValuesDo: [ :key :value | details at: key asSymbol put: value ].
	^ details
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> errorDetailsFromToolResult: aToolResult [

	| errorDetails structuredContent |
	aToolResult ifNil: [ ^ Dictionary new ].
	structuredContent := aToolResult structuredContent.
	structuredContent ifNil: [ ^ Dictionary new ].
	structuredContent isDictionary ifFalse: [ ^ Dictionary new ].
	errorDetails := self valueAtKey: #error in: structuredContent ifAbsent: [ nil ].
	errorDetails isDictionary ifFalse: [ ^ Dictionary new ].
	^ errorDetails
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> errorKindForDetails: details error: anError violations: violations [

	violations ifNotEmpty: [ ^ 'input_schema' ].
	(self stringValueAtKey: #errorClass in: details) = 'MCPInvalidToolInput' ifTrue: [ ^ 'input_schema' ].
	(self stringValueAtKey: #errorCode in: details) ifNotEmpty: [ ^ 'domain' ].
	anError ifNil: [ ^ 'tool_result' ].
	anError mcpIsJRPCError ifTrue: [ ^ 'json_rpc' ].
	^ 'exception'
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportDirectory [

	^ nil
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportDirectory: aPath [

	^ self
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

{ #category : 'private - errors' }
MCPObservabilityBackend >> recordErrorDetailsFor: aRecord result: aToolResult error: anError [

	| details violations |
	aRecord status = 'error' ifFalse: [ ^ self ].
	details := self errorDetailsForResult: aToolResult error: anError.
	violations := self violationsFromDetails: details.
	aRecord errorClass: (self stringValueAtKey: #errorClass in: details).
	aRecord errorCode: (self stringValueAtKey: #errorCode in: details).
	aRecord causeClass: (self stringValueAtKey: #causeClass in: details).
	aRecord schemaViolationKeywords: (self violationKeywordsFor: violations).
	aRecord schemaViolationCount: violations size.
	aRecord errorKind: (self errorKindForDetails: details error: anError violations: violations)
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

	^ self
]

{ #category : 'actions' }
MCPObservabilityBackend >> shutdown [

	self subclassResponsibility
]

{ #category : 'displaying' }
MCPObservabilityBackend >> statusText [

	self subclassResponsibility
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> stringValueAtKey: aKey in: aDictionary [

	| value |
	value := self valueAtKey: aKey in: aDictionary ifAbsent: [ '' ].
	value ifNil: [ ^ '' ].
	^ value asString
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

{ #category : 'private - errors' }
MCPObservabilityBackend >> valueAtKey: aKey in: aDictionary ifAbsent: absentBlock [

	(aDictionary includesKey: aKey) ifTrue: [ ^ aDictionary at: aKey ].
	^ aDictionary at: aKey asString ifAbsent: absentBlock
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> violationKeywordFor: aViolation [

	aViolation isDictionary ifTrue: [ ^ self stringValueAtKey: #keyword in: aViolation ].
	^ ''
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> violationKeywordsFor: violations [

	^ ((violations collect: [ :each | self violationKeywordFor: each ]) reject: [ :each | each isEmpty ]) asSet asArray
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> violationsFromDetails: details [

	| violations |
	violations := self valueAtKey: #violations in: details ifAbsent: [ #(  ) ].
	violations ifNil: [ ^ #(  ) ].
	^ violations asArray
]
