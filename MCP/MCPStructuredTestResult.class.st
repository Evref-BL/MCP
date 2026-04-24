Class {
	#name : 'MCPStructuredTestResult',
	#superclass : 'TestResult',
	#instVars : [
		'issueDetails'
	],
	#category : 'MCP-DTOs',
	#package : 'MCP',
	#tag : 'DTOs'
}

{ #category : 'initialization' }
MCPStructuredTestResult >> initialize [

	super initialize.
	issueDetails := OrderedCollection new
]

{ #category : 'accessing' }
MCPStructuredTestResult >> issueDetails [

	^ issueDetails asArray
]

{ #category : 'private' }
MCPStructuredTestResult >> issueKindFor: aTestCase [

	(self isError: aTestCase) ifTrue: [ ^ 'error' ].
	(self isFailure: aTestCase) ifTrue: [ ^ 'failure' ].
	(self skipped includes: aTestCase) ifTrue: [ ^ 'skipped' ].
	^ 'issue'
]

{ #category : 'private' }
MCPStructuredTestResult >> recordIssueFrom: anException forTestCase: aTestCase [

	| detail message className methodName |
	detail := Dictionary new.
	message := anException messageText
		           ifNil: [ '' ]
		           ifNotNil: [ :text | text asString ].
	className := aTestCase class name asString.
	methodName := aTestCase selector asString.
	detail at: #kind put: (self issueKindFor: aTestCase).
	detail at: #className put: className.
	detail at: #testMethodName put: methodName.
	detail at: #testName put: className , '>>#' , methodName.
	detail at: #errorClass put: anException class name.
	detail at: #message put: message.
	(anException description ~= anException class name and: [
		 anException description ~= message ]) ifTrue: [
		detail at: #description put: anException description ].
	anException signalerContext ifNotNil: [ :context |
		detail at: #signalerContext put: context printString ].
	issueDetails add: detail
]

{ #category : 'running' }
MCPStructuredTestResult >> runCase: aTestCase [

	[
	aTestCase announce: TestCaseStarted withResult: self.
	aTestCase runCaseManaged.
	aTestCase announce: TestCaseEnded withResult: self.
	self addPass: aTestCase ]
		on: self class failure , self class skip , self class warning
			, self class error
		do: [ :ex |
			ex sunitAnnounce: aTestCase toResult: self.
			self recordIssueFrom: ex forTestCase: aTestCase ]
]
