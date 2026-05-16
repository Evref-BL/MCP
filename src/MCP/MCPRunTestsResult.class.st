"
Aggregate result DTO produced by the run-tests command.

It carries structured per-selection results plus timeout state and unrun MCPTestRunRequest objects for resumable output. Coverage operation results additionally attach an MCPTestCoverageResult.
"
Class {
	#name : 'MCPRunTestsResult',
	#superclass : 'Object',
	#instVars : [
		'results',
		'timedOut',
		'unrunTests',
		'coverage'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRunTestsResult class >> results: resultCollection timedOut: aBoolean unrunTests: testCollection [

	^ self new
		  initializeResults: resultCollection
		  timedOut: aBoolean
		  unrunTests: testCollection
]

{ #category : 'converting' }
MCPRunTestsResult >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #results put: self resultDictionaries.
	self coverage ifNotNil: [ :coverageResult |
		data at: #coverage put: coverageResult asDictionary ].
	self timedOut ifTrue: [
		data at: #timedOut put: true.
		data at: #unrunTests put: self unrunTestDictionaries ].
	^ data
]

{ #category : 'accessing' }
MCPRunTestsResult >> coverage [

	^ coverage
]

{ #category : 'accessing' }
MCPRunTestsResult >> coverage: aCoverageResult [

	coverage := aCoverageResult
]

{ #category : 'initialization' }
MCPRunTestsResult >> initializeResults: resultCollection timedOut: aBoolean unrunTests: testCollection [

	results := resultCollection asArray.
	timedOut := aBoolean.
	unrunTests := testCollection asArray.
	^ self
]

{ #category : 'converting' }
MCPRunTestsResult >> resultDictionaries [

	^ (self results collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'accessing' }
MCPRunTestsResult >> results [

	^ results
]

{ #category : 'accessing' }
MCPRunTestsResult >> timedOut [

	^ timedOut
]

{ #category : 'converting' }
MCPRunTestsResult >> unrunTestDictionaries [

	^ (self unrunTests collect: [ :each | each asDictionary ]) asArray
]

{ #category : 'accessing' }
MCPRunTestsResult >> unrunTests [

	^ unrunTests
]
