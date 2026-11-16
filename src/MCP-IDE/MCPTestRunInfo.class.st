"
The outcome of one test_run selection: the class it named, the test method if it named one, and the outcome of every test the selection ran to its end.

It counts them: each test counts once, and the run count leaves skipped tests out, as SUnit's does.
"
Class {
	#name : 'MCPTestRunInfo',
	#superclass : 'Object',
	#instVars : [
		'className',
		'testMethodName',
		'outcomes'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPTestRunInfo class >> selection: aSelection outcomes: someOutcomes [

	^ self new initializeSelection: aSelection outcomes: someOutcomes
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
MCPTestRunInfo >> initializeSelection: aSelection outcomes: someOutcomes [

	className := aSelection className.
	testMethodName := aSelection testMethodName.
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
MCPTestRunInfo >> skippedCount [

	^ self countOf: #isSkipped
]

{ #category : 'accessing' }
MCPTestRunInfo >> testMethodName [

	^ testMethodName
]
