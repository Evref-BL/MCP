"
Parsed request DTO for one run-tests selection.

It represents either a full test class run or one specific test method inside the batch.
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
MCPTestRunRequest class >> className: aClassName testMethodName: aTestMethodName [

	^ self new
		  initializeClassName: aClassName
		  testMethodName: aTestMethodName
]

{ #category : 'instance creation' }
MCPTestRunRequest class >> fromValue: rawValue usingToolRequest: toolRequest [

	| className testMethodName |
	(rawValue respondsTo: #at:ifAbsent:) ifFalse: [
		Error signal:
			'tests must contain only objects with className and optional testMethodName.' ].
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

{ #category : 'printing' }
MCPTestRunRequest >> displayName [

	^ self testMethodName
		  ifNil: [ self className ]
		  ifNotNil: [ :methodName | self className , '>>' , methodName ]
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
