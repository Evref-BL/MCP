"
Abstract protocol for MCP observability backends.

Core MCP code talks to this protocol so normal tool execution can report observability facts without depending on a concrete telemetry implementation. A server starts with MCPLocalObservabilityBackend, core's default; one without observability has MCPNoopObservabilityBackend, and optional packages provide exporters such as OpenTelemetry.
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

{ #category : 'configuring' }
MCPObservabilityBackend >> configureForServer: anMCP [
	"Prepares this backend to record anMCP's calls, when it was made for anMCP by default. Nothing to prepare unless a kind of backend says so."

	
]

{ #category : 'testing' }
MCPObservabilityBackend >> enabled [

	^ self isNoop not
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> errorDetailsForResult: aToolResult error: anError [

	| details |
	details := Dictionary new.
	anError ifNotNil: [
			details addAll: (self errorSummaryFor: anError).
			anError mcpAddToolErrorDetailsTo: details ].
	(self errorDetailsFromToolResult: aToolResult) keysAndValuesDo: [ :key :value | details at: key asSymbol put: value ].
	^ details
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> errorDetailsFromToolResult: aToolResult [

	| errorDetails structuredContent |
	aToolResult ifNil: [ ^ Dictionary new ].
	structuredContent := aToolResult structuredContent.
	structuredContent ifNil: [ ^ Dictionary new ].
	structuredContent isDictionary ifFalse: [ ^ Dictionary new ].
	errorDetails := structuredContent mcpAt: #error ifAbsent: [ nil ].
	errorDetails isDictionary ifFalse: [ ^ Dictionary new ].
	^ errorDetails
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> errorKindForDetails: details error: anError violations: violations [

	violations ifNotEmpty: [ ^ 'input_schema' ].
	(self stringValueAtKey: #errorClass in: details) = 'MCPInvalidToolInput' ifTrue: [ ^ 'input_schema' ].
	(self stringValueAtKey: #errorCode in: details) ifNotEmpty: [ ^ 'domain' ].
	anError ifNil: [ ^ 'tool_result' ].
	anError mcpIsProtocolError ifTrue: [ ^ 'json_rpc' ].
	^ 'exception'
]

{ #category : 'private - errors' }
MCPObservabilityBackend >> errorSummaryFor: anError [

	^ {
		  (#errorClass -> anError class name asString).
		  (#message -> anError mcpMessageText) } asDictionary
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportDirectory [

	^ nil
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportDirectory: aPath [

	^ self
]

{ #category : 'accessing' }
MCPObservabilityBackend >> exportInstanceDirectory [

	^ nil
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
MCPObservabilityBackend >> recordSessionEnd [

	self subclassResponsibility
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordSessionStart [

	self subclassResponsibility
]

{ #category : 'recording' }
MCPObservabilityBackend >> recordToolCallFinish: aRecord result: aToolResult error: anError [

	self subclassResponsibility
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

{ #category : 'private - errors' }
MCPObservabilityBackend >> stringValueAtKey: aKey in: aDictionary [

	| value |
	value := aDictionary mcpAt: aKey ifAbsent: [ '' ].
	value ifNil: [ ^ '' ].
	^ value asString
]

{ #category : 'accessing' }
MCPObservabilityBackend >> traceRecords [

	^ #(  )
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
	violations := details mcpAt: #violations ifAbsent: [ #(  ) ].
	violations ifNil: [ ^ #(  ) ].
	^ violations asArray
]
