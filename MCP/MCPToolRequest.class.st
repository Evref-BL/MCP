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
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
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
MCPToolRequest >> argumentNamed: anArgumentName ifAbsent: absentBlock [

	^ self
		  valueNamed: anArgumentName
		  in: self arguments
		  ifAbsent: absentBlock
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

{ #category : 'accessing' }
MCPToolRequest >> arrayArgumentNamed: anArgumentName [

	^ self arrayArgumentNamed: anArgumentName ifAbsent: [ #(  ) ]
]

{ #category : 'accessing' }
MCPToolRequest >> arrayArgumentNamed: anArgumentName ifAbsent: absentBlock [

	| value |
	value := self
		         argumentNamed: anArgumentName
		         ifAbsent: [ ^ absentBlock value ].
	value ifNil: [ ^ absentBlock value ].
	^ value asArray
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
MCPToolRequest >> objectCollectionArgumentNamed: anArgumentName [

	^ self arrayArgumentNamed: anArgumentName
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName [

	^ self stringValue:
		  (self argumentNamed: anArgumentName ifAbsent: [ ^ nil ])
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName default: defaultValue [

	^ (self stringArgumentNamed: anArgumentName)
		  ifNil: [ defaultValue ]
		  ifNotNil: [ :value | value ]
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName in: aDictionary [

	^ self stringValue:
		  (self
			   valueNamed: anArgumentName
			   in: aDictionary
			   ifAbsent: [ ^ nil ])
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName in: aDictionary default: defaultValue [

	^ (self stringArgumentNamed: anArgumentName in: aDictionary)
		  ifNil: [ defaultValue ]
		  ifNotNil: [ :value | value ]
]

{ #category : 'accessing' }
MCPToolRequest >> stringCollectionArgumentNamed: anArgumentName [

	^ self stringCollectionFrom:
		  (self argumentNamed: anArgumentName ifAbsent: [ ^ #(  ) ])
]

{ #category : 'accessing' }
MCPToolRequest >> stringCollectionArgumentNamed: anArgumentName default: defaultCollection [

	(self hasArgumentNamed: anArgumentName) ifFalse: [
		^ defaultCollection ].
	^ self stringCollectionArgumentNamed: anArgumentName
]

{ #category : 'private - accessing' }
MCPToolRequest >> stringCollectionFrom: aValue [

	| values |
	aValue ifNil: [ ^ #(  ) ].
	values := OrderedCollection new.
	aValue do: [ :each |
		(self stringValue: each) ifNotNil: [ :normalized |
			values add: normalized ] ].
	^ values asArray
]

{ #category : 'private - accessing' }
MCPToolRequest >> stringValue: aValue [

	| normalized |
	aValue ifNil: [ ^ nil ].
	normalized := aValue asString trimBoth.
	^ normalized isEmpty
		  ifTrue: [ nil ]
		  ifFalse: [ normalized ]
]

{ #category : 'accessing' }
MCPToolRequest >> symbolCollectionArgumentNamed: anArgumentName [

	^ (self stringCollectionArgumentNamed: anArgumentName)
		  collect: #asSymbol
		  as: Array
]

{ #category : 'accessing' }
MCPToolRequest >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPToolRequest >> tool: aTool [

	tool := aTool
]

{ #category : 'accessing' }
MCPToolRequest >> uniqueStringCollectionArgumentNamed: anArgumentName [

	^ self uniqueStringCollectionFrom:
		  (self stringCollectionArgumentNamed: anArgumentName)
]

{ #category : 'accessing' }
MCPToolRequest >> uniqueStringCollectionArgumentNamed: anArgumentName default: defaultCollection [

	^ self uniqueStringCollectionFrom: (self
			   stringCollectionArgumentNamed: anArgumentName
			   default: defaultCollection)
]

{ #category : 'private - accessing' }
MCPToolRequest >> uniqueStringCollectionFrom: strings [

	| unique |
	unique := OrderedCollection new.
	strings do: [ :each |
		(unique includes: each) ifFalse: [ unique add: each ] ].
	^ unique asArray
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

{ #category : 'private - accessing' }
MCPToolRequest >> valueNamed: anArgumentName in: aDictionary ifAbsent: absentBlock [

	aDictionary ifNil: [ ^ absentBlock value ].
	^ aDictionary
		  at: anArgumentName asSymbol
		  ifAbsent: [
		  aDictionary at: anArgumentName asString ifAbsent: absentBlock ]
]

{ #category : 'accessing' }
MCPToolRequest >> violations [

	^ violations
]
