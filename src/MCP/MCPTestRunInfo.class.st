"
DTO for one completed run-tests selection.

It records the selected test class or method, the number of executed tests, and structured issue dictionaries captured during the run.
"
Class {
	#name : 'MCPTestRunInfo',
	#superclass : 'Object',
	#instVars : [
		'className',
		'testMethodName',
		'runCount',
		'issues'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPTestRunInfo class >> className: aClassName testMethodName: aTestMethodName runCount: anInteger issues: issueCollection [

	^ self new
		  initializeClassName: aClassName
		  testMethodName: aTestMethodName
		  runCount: anInteger
		  issues: issueCollection
]

{ #category : 'converting' }
MCPTestRunInfo >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #className put: self className.
	self testMethodName ifNotNil: [ :methodName |
		data at: #testMethodName put: methodName ].
	data at: #runCount put: self runCount.
	data at: #issues put: self issues.
	^ data
]

{ #category : 'accessing' }
MCPTestRunInfo >> className [

	^ className
]

{ #category : 'initialization' }
MCPTestRunInfo >> initializeClassName: aClassName testMethodName: aTestMethodName runCount: anInteger issues: issueCollection [

	className := aClassName.
	testMethodName := aTestMethodName.
	runCount := anInteger.
	issues := issueCollection ifNil: [ #(  ) ].
	^ self
]

{ #category : 'accessing' }
MCPTestRunInfo >> issues [

	^ issues ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> runCount [

	^ runCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> testMethodName [

	^ testMethodName
]
