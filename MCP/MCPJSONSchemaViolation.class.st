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
		'actual'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
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

{ #category : 'converting' }
MCPJSONSchemaViolation >> asDictionary [

	| dictionary |
	dictionary := {
		              (#path -> self path).
		              (#keyword -> self keyword).
		              (#message -> self message) } asDictionary.
	self expected ifNotNil: [
		dictionary at: #expected put: self expected ].
	self actual ifNotNil: [ dictionary at: #actual put: self actual ].
	^ dictionary
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

	path := aCollection
		        ifNil: [ #(  ) ]
		        ifNotNil: [ aCollection asArray ]
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
