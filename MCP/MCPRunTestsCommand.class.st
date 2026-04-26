"
Command that validates and runs parsed run-tests selections.

It resolves MCPTestRunRequest objects to MCPValidatedTestRunRequest objects, executes them, and returns MCPRunTestsResult DTOs.
"
Class {
	#name : 'MCPRunTestsCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRunTestsCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private' }
MCPRunTestsCommand >> addTestCasesFrom: aTestOrSuite to: testCases [

	(aTestOrSuite respondsTo: #tests) ifTrue: [
		aTestOrSuite tests do: [ :each |
			self addTestCasesFrom: each to: testCases ].
		^ self ].
	testCases add: aTestOrSuite
]

{ #category : 'private' }
MCPRunTestsCommand >> aggregateDataForResults: resultEntries timedOut: timedOut unrunTests: unrunTests [

	^ MCPRunTestsResult
		  results: resultEntries
		  timedOut: timedOut
		  unrunTests: unrunTests
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> deadlineForTimeoutMilliseconds: timeoutMilliseconds [

	^ Time millisecondClockValue + timeoutMilliseconds
]

{ #category : 'executing' }
MCPRunTestsCommand >> execute [

	| deadline validatedRequests |
	validatedRequests := self validatedRequestsFrom: request testRequests.
	deadline := self deadlineForTimeoutMilliseconds:
		            request timeoutMilliseconds.
	^ self runValidatedRequests: validatedRequests deadline: deadline
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> hasTimedOutAt: deadline [

	^ (self millisecondsRemainingUntil: deadline) <= 0
]

{ #category : 'initialization' }
MCPRunTestsCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> millisecondsRemainingUntil: deadline [

	^ 0 max: deadline - Time millisecondClockValue
]

{ #category : 'accessing' }
MCPRunTestsCommand >> request [

	^ request
]

{ #category : 'private' }
MCPRunTestsCommand >> resultForValidatedRequest: validatedRequest deadline: deadline [

	| includeResult result testCases timedOutIndex unrunTestRequests |
	testCases := self testCasesForValidatedRequest: validatedRequest.
	result := MCPStructuredTestResult new.
	timedOutIndex := nil.
	testCases doWithIndex: [ :testCase :index |
		timedOutIndex ifNil: [
			(self runTestCase: testCase into: result deadline: deadline)
				ifTrue: [ timedOutIndex := index ] ] ].
	includeResult := timedOutIndex isNil or: [
		                 result runCount > 0 or: [
			                 result issueDetails notEmpty ] ].
	unrunTestRequests := timedOutIndex
		                     ifNil: [ #(  ) ]
		                     ifNotNil: [
		                     self
			                     testRequestsForTestCases: testCases
			                     startingAt: timedOutIndex ].
	^ MCPTestRunResult
		  resultInfo: (includeResult
				   ifTrue: [
					   self
						   testRunInfoForTestResult: result
						   validatedRequest: validatedRequest ]
				   ifFalse: [ nil ])
		  timedOut: timedOutIndex notNil
		  unrunTestRequests: unrunTestRequests
]

{ #category : 'private - timeout' }
MCPRunTestsCommand >> runTestCase: aTestCase into: aResult deadline: deadline [

	| remaining |
	remaining := self millisecondsRemainingUntil: deadline.
	remaining <= 0 ifTrue: [ ^ true ].
	^ [
	  aTestCase run: aResult.
	  false ] valueWithinMilliseconds: remaining onTimeout: [ true ]
]

{ #category : 'private' }
MCPRunTestsCommand >> runValidatedRequests: validatedRequests deadline: deadline [

	| outcome resultEntries unrunTests |
	resultEntries := OrderedCollection new.
	1 to: validatedRequests size do: [ :index |
		(self hasTimedOutAt: deadline) ifTrue: [
			unrunTests := self
				              unrunTestsFrom: validatedRequests
				              startingAt: index.
			^ self
				  aggregateDataForResults: resultEntries
				  timedOut: true
				  unrunTests: unrunTests ].
		outcome := self
			           resultForValidatedRequest: (validatedRequests at: index)
			           deadline: deadline.
		outcome hasResult ifTrue: [ resultEntries add: outcome resultInfo ].
		outcome timedOut ifTrue: [
			unrunTests := OrderedCollection new.
			unrunTests addAll: outcome unrunTestRequests.
			unrunTests addAll:
				(self unrunTestsFrom: validatedRequests startingAt: index + 1).
			^ self
				  aggregateDataForResults: resultEntries
				  timedOut: true
				  unrunTests: unrunTests ] ].
	^ self
		  aggregateDataForResults: resultEntries
		  timedOut: false
		  unrunTests: #(  )
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesForValidatedRequest: validatedRequest [

	| suite |
	validatedRequest testMethodName ifNotNil: [ :testMethodName |
		^ { (validatedRequest testClass selector: testMethodName asSymbol) } ].
	suite := validatedRequest testClass suite.
	^ self testCasesFromSuite: suite
]

{ #category : 'private' }
MCPRunTestsCommand >> testCasesFromSuite: aSuite [

	| testCases |
	testCases := OrderedCollection new.
	self addTestCasesFrom: aSuite to: testCases.
	^ testCases asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestForTestCase: aTestCase [

	^ MCPTestRunRequest
		  className: aTestCase class name asString
		  testMethodName: aTestCase selector asString
]

{ #category : 'private' }
MCPRunTestsCommand >> testRequestsForTestCases: testCases startingAt: startIndex [

	| requests |
	requests := OrderedCollection new.
	startIndex to: testCases size do: [ :index |
		requests add: (self testRequestForTestCase: (testCases at: index)) ].
	^ requests asArray
]

{ #category : 'private - tests' }
MCPRunTestsCommand >> testRunInfoForTestResult: aResult validatedRequest: validatedRequest [

	| issues |
	issues := (aResult issueDetails asSortedCollection: [ :left :right |
		           (left at: #testName) <= (right at: #testName) ])
		          collect: [ :each |
			          | issue |
			          issue := each copy.
			          issue removeKey: #testName ifAbsent: [  ].
			          issue ].
	^ MCPTestRunInfo
		  className: validatedRequest className
		  testMethodName: validatedRequest testMethodName
		  runCount: aResult runCount
		  issues: issues asArray
]

{ #category : 'accessing' }
MCPRunTestsCommand >> tool [

	^ tool
]

{ #category : 'private' }
MCPRunTestsCommand >> unrunTestsFrom: validatedRequests startingAt: startIndex [

	| unrun |
	unrun := OrderedCollection new.
	startIndex to: validatedRequests size do: [ :index |
		unrun addAll: (self
				 testRequestsForTestCases:
				 (self testCasesForValidatedRequest: (validatedRequests at: index))
				 startingAt: 1) ].
	^ unrun asArray
]

{ #category : 'private' }
MCPRunTestsCommand >> validatedRequestsFrom: testRequests [

	^ testRequests collect: [ :each |
		  | testClass |
		  testClass := Smalltalk globals
			               at: each className asSymbol
			               ifAbsent: [
			               MCPCommandError signalMissingClassNamed:
				               each className ].
		  each testMethodName ifNotNil: [ :testMethodName |
			  testClass compiledMethodAt: testMethodName asSymbol ifAbsent: [
				  MCPCommandError
					  signalMissingMethodInClassName: each className
					  classSide: false
					  selector: testMethodName ] ].
		  MCPValidatedTestRunRequest request: each testClass: testClass ]
]
