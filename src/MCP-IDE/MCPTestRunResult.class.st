"
Result DTO for one test_run selection.

It carries the outcomes of the tests the selection ran, whether the deadline stopped it, the test the timeout interrupted, and what is left of the selection to run, as test_run arguments, with how many tests that is.
"
Class {
	#name : 'MCPTestRunResult',
	#superclass : 'MCPResult',
	#instVars : [
		'timedOut',
		'unrunTestRequests',
		'resultInfo',
		'interruption',
		'notRunCount'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPTestRunResult class >> resultInfo: resultInfoOrNil timedOut: aBoolean unrunTestRequests: testRequests [

	^ self new initializeResultInfo: resultInfoOrNil timedOut: aBoolean unrunTestRequests: testRequests
]

{ #category : 'converting' }
MCPTestRunResult >> asDictionary [

	| data |
	data := Dictionary new.
	self resultInfo ifNotNil: [ :entry | data at: #result put: entry asDictionary ].
	data at: #timedOut put: self timedOut.
	data at: #unrunTests put: self unrunTestDictionaries.
	^ data
]

{ #category : 'initialization' }
MCPTestRunResult >> initializeResultInfo: resultInfoOrNil timedOut: aBoolean unrunTestRequests: testRequests [

	resultInfo := resultInfoOrNil.
	timedOut := aBoolean.
	unrunTestRequests := testRequests ifNil: [ #(  ) ].
	^ self
]

{ #category : 'accessing' }
MCPTestRunResult >> interruption [
	"The test the timeout interrupted in this selection, or nil."

	^ interruption
]

{ #category : 'accessing' }
MCPTestRunResult >> interruption: anOutcomeOrNil [

	interruption := anOutcomeOrNil
]

{ #category : 'accessing' }
MCPTestRunResult >> notRunCount [
	"How many of the selection's tests were left unrun, the interrupted one included."

	^ notRunCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPTestRunResult >> notRunCount: anInteger [

	notRunCount := anInteger
]

{ #category : 'accessing' }
MCPTestRunResult >> resultInfo [

	^ resultInfo
]

{ #category : 'accessing' }
MCPTestRunResult >> timedOut [

	^ timedOut ifNil: [ false ]
]

{ #category : 'converting' }
MCPTestRunResult >> unrunTestDictionaries [

	^ self unrunTestRequests collect: [ :each | each asDictionary ] as: Array
]

{ #category : 'accessing' }
MCPTestRunResult >> unrunTestRequests [

	^ unrunTestRequests ifNil: [ #(  ) ]
]
