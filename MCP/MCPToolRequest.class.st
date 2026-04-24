"
Represents one validated MCP tool call request. It owns the raw input payload, schema validation result, and typed argument accessors used by tools.
"
Class {
	#name : 'MCPToolRequest',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'arguments',
		'violations'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPToolRequest class >> tool: aTool arguments: aDictionary [

	^ self new
		  tool: aTool;
		  arguments: aDictionary;
		  validate;
		  yourself
]

{ #category : 'accessing' }
MCPToolRequest >> arguments [

	^ arguments
]

{ #category : 'accessing' }
MCPToolRequest >> arguments: aDictionary [

	arguments := aDictionary
		             ifNil: [ Dictionary new ]
		             ifNotNil: [ aDictionary ]
]

{ #category : 'converting' }
MCPToolRequest >> asDictionary [

	^ self arguments
]

{ #category : 'accessing' }
MCPToolRequest >> booleanArgumentNamed: anArgumentName default: aBoolean [

	| value |
	value := self argumentNamed: anArgumentName ifAbsent: [ ^ aBoolean ].
	value ifNil: [ ^ aBoolean ].
	^ value
]

{ #category : 'accessing' }
MCPToolRequest >> hasArgumentNamed: anArgumentName [

	^ (self arguments includesKey: anArgumentName asSymbol) or: [
		  self arguments includesKey: anArgumentName asString ]
]

{ #category : 'initialization' }
MCPToolRequest >> initialize [

	super initialize.
	arguments := Dictionary new.
	violations := #(  )
]

{ #category : 'accessing' }
MCPToolRequest >> nonNegativeIntegerArgumentNamed: anArgumentName default: anInteger [

	| value |
	value := self argumentNamed: anArgumentName ifAbsent: [ ^ anInteger ].
	value ifNil: [ ^ anInteger ].
	(value isInteger and: [ value >= 0 ]) ifTrue: [ ^ value ].
	Error signal:
		anArgumentName asString , ' must be a non-negative integer.'
]

{ #category : 'accessing' }
MCPToolRequest >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPToolRequest >> tool: aTool [

	tool := aTool
]

{ #category : 'validating' }
MCPToolRequest >> validate [

	self tool inputSchema ifNil: [ ^ self ].
	violations := MCPJSONSchemaValidator
		              violationsFor: self arguments
		              schema: self tool inputSchema.
	violations ifNotEmpty: [
		MCPInvalidToolInput signalForTool: self tool violations: violations ].
	^ self
]

{ #category : 'accessing' }
MCPToolRequest >> violations [

	^ violations
]
