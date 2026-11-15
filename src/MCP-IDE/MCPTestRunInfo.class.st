"
Internal DTO for one executed test_run selection.

It holds the outcome of every test the selection ran to its end, and counts them: each test counts once, and the run count leaves skipped tests out, as SUnit's does.
"
Class {
	#name : 'MCPTestRunInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'className',
		'testMethodName',
		'selectedTestCount',
		'outcomes'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPTestRunInfo class >> validatedRequest: validatedRequest selectedTestCount: selectedCount outcomes: someOutcomes [

	^ self new initializeValidatedRequest: validatedRequest selectedTestCount: selectedCount outcomes: someOutcomes
]

{ #category : 'converting' }
MCPTestRunInfo >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #class put: self className.
	self testMethodName ifNotNil: [ :methodName | data at: #testMethod put: methodName ].
	data at: #selectedTestCount put: self selectedTestCount.
	data at: #runCount put: self runCount.
	data at: #passedCount put: self passedCount.
	data at: #skippedCount put: self skippedCount.
	data at: #failureCount put: self failureCount.
	data at: #errorCount put: self errorCount.
	self outcomes ifNotEmpty: [ :finished | data at: #outcomes put: (finished collect: [ :each | each asDictionary ]) ].
	^ data
]

{ #category : 'accessing' }
MCPTestRunInfo >> className [

	^ className
]

{ #category : 'accessing' }
MCPTestRunInfo >> countOf: aSelector [

	^ self outcomes count: [ :each | each perform: aSelector ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> errorCount [

	^ self countOf: #isError
]

{ #category : 'accessing' }
MCPTestRunInfo >> failureCount [

	^ self countOf: #isFailure
]

{ #category : 'initialization' }
MCPTestRunInfo >> initializeValidatedRequest: validatedRequest selectedTestCount: selectedCount outcomes: someOutcomes [

	className := validatedRequest className.
	testMethodName := validatedRequest testMethodName.
	selectedTestCount := selectedCount.
	outcomes := someOutcomes asArray
]

{ #category : 'accessing' }
MCPTestRunInfo >> outcomes [
	"One per test that finished, in the order they ran."

	^ outcomes ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> passedCount [

	^ self countOf: #isPassed
]

{ #category : 'accessing' }
MCPTestRunInfo >> runCount [
	"As SUnit counts a run: the tests that passed, failed or erred, skipped ones left out. Each test counts once, however many exceptions it raised."

	^ self passedCount + self failureCount + self errorCount
]

{ #category : 'accessing' }
MCPTestRunInfo >> selectedTestCount [

	^ selectedTestCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunInfo >> skippedCount [

	^ self countOf: #isSkipped
]

{ #category : 'accessing' }
MCPTestRunInfo >> testMethodName [

	^ testMethodName
]
