"
Represents one validated MCP tool call request. It owns the raw input payload, schema validation result, and typed argument accessors used by tools.
"
Class {
	#name : 'MCPToolRequest',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'arguments',
		'violations',
		'defaults',
		'nestedDefaults'
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

	^ self valueNamed: anArgumentName in: self arguments ifAbsent: absentBlock
]

{ #category : 'accessing' }
MCPToolRequest >> argumentOrDefaultNamed: anArgumentName [
	"The argument, or the default its schema declares when the caller left it out. The accessors built on it or on another OrDefault accessor answer that default too; every other accessor answers only what the caller supplied, so that code can tell an argument left out from one given, as an inferred side or a patch must."

	^ self valueNamed: anArgumentName in: self arguments ifAbsent: [ defaults at: anArgumentName asString ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
MCPToolRequest >> argumentOrDefaultNamed: anArgumentName in: aDictionary [
	"The argument inside aDictionary, an object argument or one an array argument holds, or else the default the schema declares for that name inside the arguments, unless two arguments declare it with different defaults."

	^ self valueNamed: anArgumentName in: aDictionary ifAbsent: [ nestedDefaults at: anArgumentName asString ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
MCPToolRequest >> arguments [

	^ arguments
]

{ #category : 'accessing' }
MCPToolRequest >> arguments: aDictionary [

	arguments := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPToolRequest >> arrayArgumentNamed: anArgumentName [

	^ self arrayArgumentNamed: anArgumentName ifAbsent: [ #(  ) ]
]

{ #category : 'accessing' }
MCPToolRequest >> arrayArgumentNamed: anArgumentName ifAbsent: absentBlock [

	| value |
	value := self argumentNamed: anArgumentName ifAbsent: [ ^ absentBlock value ].
	value ifNil: [ ^ absentBlock value ].
	^ value asArray
]

{ #category : 'converting' }
MCPToolRequest >> asDictionary [

	^ self arguments
]

{ #category : 'accessing' }
MCPToolRequest >> booleanArgumentNamed: anArgumentName [
	"The argument, else its schema default, else false."

	^ (self argumentOrDefaultNamed: anArgumentName) ifNil: [ false ]
]

{ #category : 'accessing' }
MCPToolRequest >> booleanArgumentNamed: anArgumentName in: aDictionary [
	"The argument inside aDictionary, else its schema default, else false."

	^ (self argumentOrDefaultNamed: anArgumentName in: aDictionary) ifNil: [ false ]
]

{ #category : 'private - validating' }
MCPToolRequest >> clampArgumentNamed: anArgumentName maximum: maximumValue in: normalizedArguments [

	| key value |
	key := self keyForArgumentNamed: anArgumentName in: normalizedArguments ifAbsent: [ ^ self ].
	value := normalizedArguments at: key.
	(value isNumber and: [ value > maximumValue ]) ifTrue: [ normalizedArguments at: key put: maximumValue ]
]

{ #category : 'accessing' }
MCPToolRequest >> hasArgumentNamed: anArgumentName [

	self argumentNamed: anArgumentName ifAbsent: [ ^ false ].
	^ true
]

{ #category : 'initialization' }
MCPToolRequest >> initialize [

	super initialize.
	arguments := Dictionary new.
	defaults := Dictionary new.
	nestedDefaults := Dictionary new.
	violations := #(  )
]

{ #category : 'accessing' }
MCPToolRequest >> integerArgumentNamed: anArgumentName [
	"The argument, else its schema default. The schema has already checked its type and range, and clamped it to its maximum."

	^ self argumentOrDefaultNamed: anArgumentName
]

{ #category : 'private - validating' }
MCPToolRequest >> keyForArgumentNamed: anArgumentName in: aDictionary ifAbsent: absentBlock [
	"The key the dictionary holds the argument under: arguments read from the wire have String keys, and those built in the image often Symbol ones."

	aDictionary ifNil: [ ^ absentBlock value ].
	^ {
		  anArgumentName asString.
		  anArgumentName asSymbol } detect: [ :each | aDictionary includesKey: each ] ifNone: absentBlock
]

{ #category : 'testing' }
MCPToolRequest >> namesAListAt: anArgumentName [
	"Whether the caller wrote a list there, however many usable values it turned out to hold."

	| value |
	value := self argumentNamed: anArgumentName ifAbsent: [ ^ false ].
	^ value isCollection and: [ value isString not ]
]

{ #category : 'accessing' }
MCPToolRequest >> nonNegativeIntegerArgumentNamed: anArgumentName default: anInteger [

	| value |
	value := self argumentNamed: anArgumentName ifAbsent: [ ^ anInteger ].
	value ifNil: [ ^ anInteger ].
	(value isInteger and: [ value >= 0 ]) ifTrue: [ ^ value ].
	Error signal: anArgumentName asString , ' must be a non-negative integer.'
]

{ #category : 'private - validating' }
MCPToolRequest >> normalizeArgumentsForInputSchema: anInputSchema [

	| normalizedArguments |
	normalizedArguments := self arguments copy.
	anInputSchema properties do: [ :property |
			| maximum |
			maximum := property extraProperties at: #maximum ifAbsent: [ nil ].
			maximum ifNotNil: [ self clampArgumentNamed: property name maximum: maximum in: normalizedArguments ] ].
	arguments := normalizedArguments
]

{ #category : 'private - validating' }
MCPToolRequest >> rememberDefaultsIn: aSchema [
	"The default each property of aSchema, the input schema as JSON, declares, which the accessors that answer defaults answer when the caller leaves the argument out, so that a tool states a default once, in its schema. One declared inside an object argument, or inside the objects an array argument holds, is remembered under its own name for the accessors that read inside an argument. Those are given the object, not the argument it came from, so a name two arguments declare with different defaults, or one with a default and one without, is remembered with none rather than with the wrong one."

	(aSchema at: #properties ifAbsent: [ ^ self ]) keysAndValuesDo: [ :name :property |
			property at: #default ifPresent: [ :value | defaults at: name asString put: value ].
			((property at: #items ifAbsent: [ property ]) at: #properties ifAbsent: [ #(  ) ]) keysAndValuesDo: [ :nestedName :nested |
					| default |
					default := nested at: #default ifAbsent: [ nil ].
					(nestedDefaults at: nestedName asString ifAbsentPut: [ default ]) = default ifFalse: [
						nestedDefaults at: nestedName asString put: nil ] ] ]
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName [

	^ self stringValue: (self argumentNamed: anArgumentName ifAbsent: [ ^ nil ])
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName default: defaultValue [

	^ (self stringArgumentNamed: anArgumentName) ifNil: [ defaultValue ]
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName in: aDictionary [

	^ self stringValue: (self valueNamed: anArgumentName in: aDictionary ifAbsent: [ ^ nil ])
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentNamed: anArgumentName in: aDictionary default: defaultValue [

	^ (self stringArgumentNamed: anArgumentName in: aDictionary) ifNil: [ defaultValue ]
]

{ #category : 'accessing' }
MCPToolRequest >> stringArgumentOrDefaultNamed: anArgumentName [
	"The argument as stringArgumentNamed: reads it, else the default its schema declares."

	^ (self stringArgumentNamed: anArgumentName) ifNil: [ defaults at: anArgumentName asString ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
MCPToolRequest >> stringCollectionArgumentNamed: anArgumentName [

	^ self stringCollectionFrom: (self argumentNamed: anArgumentName ifAbsent: [ ^ #(  ) ])
]

{ #category : 'accessing' }
MCPToolRequest >> stringCollectionArgumentNamed: anArgumentName in: aDictionary [

	^ self stringCollectionFrom: (self valueNamed: anArgumentName in: aDictionary ifAbsent: [ ^ #(  ) ])
]

{ #category : 'accessing' }
MCPToolRequest >> stringCollectionFrom: aValue [

	| values |
	aValue ifNil: [ ^ #(  ) ].
	aValue isString ifTrue: [ ^ (self stringValue: aValue) ifNil: [ #(  ) ] ifNotNil: [ :normalized | { normalized } ] ].
	values := OrderedCollection new.
	aValue do: [ :each | (self stringValue: each) ifNotNil: [ :normalized | values add: normalized ] ].
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

	^ (self stringCollectionArgumentNamed: anArgumentName) collect: #asSymbol as: Array
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

	^ self uniqueStringCollectionFrom: (self stringCollectionArgumentNamed: anArgumentName)
]

{ #category : 'private - accessing' }
MCPToolRequest >> uniqueStringCollectionFrom: strings [

	| unique |
	unique := OrderedCollection new.
	strings do: [ :each | (unique includes: each) ifFalse: [ unique add: each ] ].
	^ unique asArray
]

{ #category : 'validating' }
MCPToolRequest >> validate [

	| inputSchema schema |
	inputSchema := self tool inputSchema ifNil: [ ^ self ].
	self normalizeArgumentsForInputSchema: inputSchema.
	schema := inputSchema asJRPCJSON.
	self rememberDefaultsIn: schema.
	violations := MCPJSONSchemaValidator violationsFor: self arguments schema: schema.
	violations ifNotEmpty: [ MCPInvalidToolInput signalForTool: self tool violations: violations ].
	self tool validateRequest: self
]

{ #category : 'accessing' }
MCPToolRequest >> valueNamed: anArgumentName in: aDictionary ifAbsent: absentBlock [

	^ (aDictionary ifNil: [ ^ absentBlock value ]) mcpAt: anArgumentName ifAbsent: absentBlock
]

{ #category : 'accessing' }
MCPToolRequest >> violations [

	^ violations
]

{ #category : 'copying' }
MCPToolRequest >> withArgumentNamed: anArgumentName setTo: aValue [
	"Answer a request like this one, but naming a single value where this one may name several."

	| newArguments key |
	newArguments := self arguments copy.
	key := self keyForArgumentNamed: anArgumentName in: newArguments ifAbsent: [ anArgumentName ].
	newArguments at: key put: aValue.
	^ self class tool: self tool arguments: newArguments
]
