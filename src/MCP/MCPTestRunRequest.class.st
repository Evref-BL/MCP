"
Parsed test_run selection.

A request represents one package, one whole test class, or one test method. Package selections remain package requests until execution so timeout reporting can distinguish unentered packages from interrupted classes.
"
Class {
	#name : 'MCPTestRunRequest',
	#superclass : 'Object',
	#instVars : [
		'packageName',
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

	^ self new initializePackageName: nil className: aClassName testMethodName: aTestMethodName
]

{ #category : 'instance creation' }
MCPTestRunRequest class >> fromMethodReference: aString [

	| className delimiterIndex selector |
	delimiterIndex := aString findString: '>>' startingAt: 1.
	delimiterIndex isZero ifTrue: [ Error signal: 'methods must use Class>>#selector references.' ].
	className := (aString copyFrom: 1 to: delimiterIndex - 1) trimBoth.
	selector := (aString copyFrom: delimiterIndex + 2 to: aString size) trimBoth.
	(selector notEmpty and: [ selector first = $# ]) ifTrue: [ selector := selector allButFirst ].
	(className isEmpty or: [ selector isEmpty ]) ifTrue: [ Error signal: 'methods must use Class>>#selector references.' ].
	^ self className: className testMethodName: selector
]

{ #category : 'instance creation' }
MCPTestRunRequest class >> packageName: aPackageName [

	^ self new initializePackageName: aPackageName className: nil testMethodName: nil
]

{ #category : 'converting' }
MCPTestRunRequest >> asDictionary [

	| data |
	data := Dictionary new.
	self isPackageRequest ifTrue: [
			data at: #packageName put: self packageName.
			^ data ].
	data at: #className put: self className.
	self testMethodName ifNotNil: [ data at: #testMethodName put: self testMethodName ].
	^ data
]

{ #category : 'accessing' }
MCPTestRunRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPTestRunRequest >> displayName [

	self isPackageRequest ifTrue: [ ^ self packageName ].
	^ self testMethodName ifNil: [ self className ] ifNotNil: [ :methodName | self className , '>>#' , methodName ]
]

{ #category : 'testing' }
MCPTestRunRequest >> hasTestMethod [

	^ self testMethodName notNil
]

{ #category : 'initialization' }
MCPTestRunRequest >> initializeClassName: aClassName testMethodName: aTestMethodName [

	self initializePackageName: nil className: aClassName testMethodName: aTestMethodName
]

{ #category : 'initialization' }
MCPTestRunRequest >> initializePackageName: aPackageName className: aClassName testMethodName: aTestMethodName [

	packageName := aPackageName.
	className := aClassName.
	testMethodName := aTestMethodName
]

{ #category : 'testing' }
MCPTestRunRequest >> isPackageRequest [

	^ self packageName notNil
]

{ #category : 'accessing' }
MCPTestRunRequest >> packageName [

	^ packageName
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
