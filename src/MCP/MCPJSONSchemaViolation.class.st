"
Represents one JSON Schema validation problem found while checking a tool input payload. The path identifies the nested input location and the keyword identifies the schema rule that failed.
"
Class {
	#name : 'MCPJSONSchemaViolation',
	#superclass : 'Object',
	#instVars : [
		'path',
		'keyword',
		'message',
		'expected',
		'actual',
		'keys',
		'example'
	],
	#category : 'MCP-Schema',
	#package : 'MCP',
	#tag : 'Schema'
}

{ #category : 'instance creation' }
MCPJSONSchemaViolation class >> path: aPath keyword: aKeyword message: aMessage expected: expectedValue actual: actualValue [

	^ self new
		  path: aPath;
		  keyword: aKeyword;
		  message: aMessage;
		  expected: expectedValue;
		  actual: actualValue;
		  yourself
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> actual [

	^ actual
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> actual: anObject [

	actual := anObject
]

{ #category : 'printing' }
MCPJSONSchemaViolation >> alternatives: anObject [
	"One expected value, or several listed as a sentence lists them."

	(anObject isString or: [ anObject isCollection not ]) ifTrue: [ ^ anObject asString ].
	^ String streamContents: [ :stream |
			  anObject doWithIndex: [ :each :index |
					  index > 1 ifTrue: [
							  stream << (index = anObject size
								   ifTrue: [ ' or ' ]
								   ifFalse: [ ', ' ]) ].
					  stream << each asString ] ]
]

{ #category : 'converting' }
MCPJSONSchemaViolation >> asDictionary [

	| dictionary |
	dictionary := {
		              (#path -> self path).
		              (#keyword -> self keyword).
		              (#message -> self message) } asDictionary.
	self expected ifNotNil: [ dictionary at: #expected put: self expected ].
	self actual ifNotNil: [ dictionary at: #actual put: self actual ].
	self keys ifNotEmpty: [ :names | dictionary at: #keys put: names ].
	self example ifNotNil: [ :anObject | dictionary at: #example put: anObject ].
	^ dictionary
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> example [
	"An object of the expected shape, made of what was sent, or nil when none could be made of it."

	^ example
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> example: aDictionary [

	example := aDictionary
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> expected [

	^ expected
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> expected: anObject [

	expected := anObject
]

{ #category : 'initialization' }
MCPJSONSchemaViolation >> initialize [

	super initialize.
	path := #(  )
]

{ #category : 'printing' }
MCPJSONSchemaViolation >> jsonFor: anObject [
	"A value as the caller sent it, so a string reads quoted and nil reads null."

	^ [ STONJSON toString: anObject ]
		  on: Error
		  do: [ :error | anObject printString ]
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> keys [
	"The keys of the object the schema expected where another type was sent, sorted, or none when it expected no object or names no keys."

	^ keys ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> keys: someNames [

	keys := someNames asArray
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> keyword [

	^ keyword
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> keyword: aKeyword [

	keyword := aKeyword asString
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> message [

	^ message
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> message: aString [

	message := aString asString
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> path [

	^ path
]

{ #category : 'accessing' }
MCPJSONSchemaViolation >> path: aCollection [

	path := aCollection ifNil: [ #(  ) ] ifNotNil: [ aCollection asArray ]
]

{ #category : 'printing' }
MCPJSONSchemaViolation >> placeAt: aPath [
	"A path as a caller writes it: dotted property names, and array positions in brackets."

	aPath ifEmpty: [ ^ 'the arguments' ].
	^ String streamContents: [ :stream |
			  aPath doWithIndex: [ :each :index |
					  each isInteger
						  ifTrue: [ stream << '[' << each printString << ']' ]
						  ifFalse: [
								  index > 1 ifTrue: [ stream nextPut: $. ].
								  stream << each asString ] ] ]
]

{ #category : 'printing' }
MCPJSONSchemaViolation >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self keyword;
		nextPutAll: ' at ';
		print: self path;
		nextPutAll: ')'
]

{ #category : 'printing' }
MCPJSONSchemaViolation >> printSentenceOn: aStream [
	"A rule a tool checks itself, beyond the schema, words its own sentence: which arguments to give, or which go together."

	keyword = 'required' ifTrue: [ ^ aStream << (self placeAt: (path copyWith: expected)) << ' is required.' ].
	(keyword = 'selectionRequired' or: [ keyword = 'dependentRequired' ]) ifTrue: [ ^ aStream << message ].
	aStream << (self placeAt: path).
	keyword = 'notBlank' ifTrue: [ ^ aStream << ' is blank; leave it out or give it a value.' ].
	keyword = 'notEmpty' ifTrue: [ ^ aStream << ' names nothing to act on; give at least one value that is not blank.' ].
	keyword = 'additionalProperties' ifTrue: [
			aStream << ' is not accepted here'.
			expected isEmptyOrNil ifFalse: [ aStream << '; expected one of ' << (', ' join: expected) ].
			^ aStream nextPut: $. ].
	keyword = 'type' ifTrue: [
			aStream << ' must be ' << (self alternatives: expected) << ', not ' << actual asString << '.'.
			^ self printShapeOn: aStream ].
	keyword = 'enum' ifTrue: [
			^ aStream << ' must be ' << (self alternatives: (expected collect: [ :each | self jsonFor: each ])) << ', not '
			  << (self jsonFor: actual) << '.' ].
	keyword = 'minItems' ifTrue: [ ^ aStream << ' needs at least ' << expected printString << ' item(s).' ].
	keyword = 'minLength' ifTrue: [ ^ aStream << ' needs at least ' << expected printString << ' character(s).' ].
	keyword = 'minimum' ifTrue: [ ^ aStream << ' must be at least ' << expected printString << ', not ' << actual printString << '.' ].
	keyword = 'maximum' ifTrue: [ ^ aStream << ' must be at most ' << expected printString << ', not ' << actual printString << '.' ].
	aStream << ': ' << message
]

{ #category : 'printing' }
MCPJSONSchemaViolation >> printShapeOn: aStream [
	"The keys of the object expected, with an example where there is one: a caller that sent a list or a string where an object goes seldom knows its shape."

	self keys ifEmpty: [ ^ self ].
	aStream << ' Give it as an object with the keys ' << (self alternatives: self keys).
	self example ifNotNil: [ :anObject | aStream << ', for example ' << (self jsonFor: anObject) ].
	aStream nextPut: $.
]

{ #category : 'printing' }
MCPJSONSchemaViolation >> sentence [
	"The violation as a caller would put it, naming the argument at fault. A client may show the model this text and drop the structured violation."

	^ String streamContents: [ :stream | self printSentenceOn: stream ]
]
