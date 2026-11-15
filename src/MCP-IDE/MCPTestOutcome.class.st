"
The outcome of one test case in a test_run call, counted once.

A test that finished is error, failure, skipped or passed, read from SUnit's own bookkeeping of a result that ran that test alone, in that precedence: an unexpected error, then an unexpected failure or a pass of a test marked <expectedFailure>, then a skip; an expected pass or an expected defect passed. Its issues are the exceptions it raised, one per kind, error class and message, with the places they came from; a test that passed shows none.

A test a timeout stopped was interrupted, and says where it was; one the deadline reached first never started. Neither is counted.
"
Class {
	#name : 'MCPTestOutcome',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'className',
		'selector',
		'parameters',
		'outcome',
		'issues',
		'location'
	],
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'instance creation' }
MCPTestOutcome class >> interrupted: aTestCase location: aLocationOrNil [
	"A test a timeout stopped before it finished. aLocationOrNil is where it was, unless that was the test method."

	^ self new
		  initializeTestCase: aTestCase
		  outcome: 'interrupted'
		  issues: #(  )
		  location: aLocationOrNil
]

{ #category : 'instance creation' }
MCPTestOutcome class >> notStarted: aTestCase [
	"A test the deadline reached before it started."

	^ self new
		  initializeTestCase: aTestCase
		  outcome: 'notStarted'
		  issues: #(  )
		  location: nil
]

{ #category : 'private' }
MCPTestOutcome class >> outcomeOf: aTestResult [
	"In SUnit's own precedence: an unexpected error, then an unexpected failure or pass, then a skip. Anything else passed, an expected defect included."

	aTestResult unexpectedErrorCount > 0 ifTrue: [ ^ 'error' ].
	(aTestResult unexpectedFailureCount > 0 or: [ aTestResult unexpectedPassCount > 0 ]) ifTrue: [ ^ 'failure' ].
	aTestResult skippedCount > 0 ifTrue: [ ^ 'skipped' ].
	^ 'passed'
]

{ #category : 'instance creation' }
MCPTestOutcome class >> testCase: aTestCase result: aStructuredTestResult [
	"A test that finished, as the result that ran it alone counts it."

	^ self new
		  initializeTestCase: aTestCase
		  outcome: (self outcomeOf: aStructuredTestResult)
		  issues: aStructuredTestResult issues
		  location: nil
]

{ #category : 'private' }
MCPTestOutcome class >> unexpectedPassIssue [

	^ Dictionary new
		  at: #kind put: 'failure';
		  at: #message put: 'it passed, but it is marked <expectedFailure>';
		  at: #locations put: #(  );
		  yourself
]

{ #category : 'converting' }
MCPTestOutcome >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #test put: self name.
	data at: #outcome put: self outcome.
	self issues ifNotEmpty: [ data at: #issues put: self issues ].
	self location ifNotNil: [ data at: #location put: self location ].
	^ data
]

{ #category : 'accessing' }
MCPTestOutcome >> className [

	^ className
]

{ #category : 'initialization' }
MCPTestOutcome >> initializeTestCase: aTestCase outcome: anOutcome issues: someIssues location: aLocationOrNil [

	className := aTestCase class name asString.
	selector := aTestCase selector asString.
	parameters := aTestCase mcpParameterPrintStrings asArray.
	outcome := anOutcome.
	issues := self issuesShownFor: anOutcome from: someIssues.
	location := aLocationOrNil
]

{ #category : 'testing' }
MCPTestOutcome >> isError [

	^ self outcome = 'error'
]

{ #category : 'testing' }
MCPTestOutcome >> isFailure [

	^ self outcome = 'failure'
]

{ #category : 'testing' }
MCPTestOutcome >> isFinished [
	"Whether the test ran to its end, so that it counts."

	^ (#( 'interrupted' 'notStarted' ) includes: self outcome) not
]

{ #category : 'testing' }
MCPTestOutcome >> isInterrupted [

	^ self outcome = 'interrupted'
]

{ #category : 'testing' }
MCPTestOutcome >> isPassed [

	^ self outcome = 'passed'
]

{ #category : 'testing' }
MCPTestOutcome >> isSkipped [

	^ self outcome = 'skipped'
]

{ #category : 'accessing' }
MCPTestOutcome >> issues [

	^ issues ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestOutcome >> issuesOfKind: aKind [

	^ self issues select: [ :each | (each at: #kind) = aKind ]
]

{ #category : 'private' }
MCPTestOutcome >> issuesShownFor: anOutcome from: someIssues [
	"A test that passed shows no issue, so an expected failure stays hidden. A failure with no issue is a test marked <expectedFailure> that passed, and says so."

	anOutcome = 'passed' ifTrue: [ ^ #(  ) ].
	(anOutcome = 'failure' and: [ someIssues isEmpty ]) ifTrue: [ ^ { self class unexpectedPassIssue } ].
	^ someIssues asArray
]

{ #category : 'accessing' }
MCPTestOutcome >> location [
	"Where an interrupted test was when the timeout fell, unless that was the test method."

	^ location
]

{ #category : 'printing' }
MCPTestOutcome >> name [
	"The test as test_run names it: its reference, and the parameters of a parameterized case."

	^ String streamContents: [ :stream |
			  stream << self reference.
			  self parameters ifNotEmpty: [ :someParameters | stream << ' with ' << (', ' join: someParameters) ] ]
]

{ #category : 'accessing' }
MCPTestOutcome >> outcome [

	^ outcome
]

{ #category : 'accessing' }
MCPTestOutcome >> parameters [

	^ parameters ifNil: [ #(  ) ]
]

{ #category : 'printing' }
MCPTestOutcome >> printOn: aStream [

	super printOn: aStream.
	aStream << '(' << self name << ' ' << self outcome << ')'
]

{ #category : 'printing' }
MCPTestOutcome >> reference [
	"The test as test_run takes it back in methods."

	^ String streamContents: [ :stream | stream << className << '>>#' << selector ]
]

{ #category : 'accessing' }
MCPTestOutcome >> selector [

	^ selector
]
