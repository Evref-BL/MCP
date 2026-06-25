"
Parsed test_run selection.

A request represents either a whole test class or one test method. Package selections are expanded into class requests before execution.
"
Class {
	#name : 'MCPTestRunRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'testMethodName'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPTestRunRequest class >> className: aClassName [

	^ self className: aClassName testMethodName: nil
]

{ #category : 'instance creation' }
MCPTestRunRequest class >> className: aClassName testMethodName: aTestMethodName [

	^ self new
		  initializeClassName: aClassName
		  testMethodName: aTestMethodName
]

{ #category : 'instance creation' }
MCPTestRunRequest class >> fromMethodReference: aString [

	| className delimiterIndex selector |
	delimiterIndex := aString findString: '>>' startingAt: 1.
	delimiterIndex isZero ifTrue: [
		Error signal: 'methods must use Class>>#selector references.' ].
	className := (aString copyFrom: 1 to: delimiterIndex - 1) trimBoth.
	selector := (aString
		copyFrom: delimiterIndex + 2
		to: aString size) trimBoth.
	(selector notEmpty and: [ selector first = $# ]) ifTrue: [
		selector := selector allButFirst ].
	(className isEmpty or: [ selector isEmpty ]) ifTrue: [
		Error signal: 'methods must use Class>>#selector references.' ].
	^ self className: className testMethodName: selector
]

{ #category : 'instance creation' }
MCPTestRunRequest class >> fromValue: rawValue usingToolRequest: toolRequest [

	| className testMethodName |
	className := toolRequest
		             stringArgumentNamed: 'className'
		             in: rawValue.
	className ifNil: [
		Error signal: 'tests must contain only non-empty class names.' ].
	testMethodName := toolRequest
		                  stringArgumentNamed: 'testMethodName'
		                  in: rawValue.
	^ self className: className testMethodName: testMethodName
]

{ #category : 'converting' }
MCPTestRunRequest >> asDictionary [

	| data |
	data := { (#className -> self className) } asDictionary.
	self testMethodName ifNotNil: [
		data at: #testMethodName put: self testMethodName ].
	^ data
]

{ #category : 'accessing' }
MCPTestRunRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPTestRunRequest >> displayName [

	^ self testMethodName
		ifNil: [ self className ]
		ifNotNil: [ :methodName | self className , '>>#' , methodName ]
]

{ #category : 'testing' }
MCPTestRunRequest >> hasTestMethod [

	^ self testMethodName notNil
]

{ #category : 'initialization' }
MCPTestRunRequest >> initializeClassName: aClassName testMethodName: aTestMethodName [

	className := aClassName.
	testMethodName := aTestMethodName.
	^ self
]

{ #category : 'printing' }
MCPTestRunRequest >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: self displayName;
		nextPutAll: ')'
]

{ #category : 'accessing' }
MCPTestRunRequest >> testMethodName [

	^ testMethodName
]
