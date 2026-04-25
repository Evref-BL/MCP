"
Result DTO produced by the run-tests command.
"
Class {
	#name : 'MCPRunTestsResult',
	#superclass : 'Object',
	#instVars : [
		'results',
		'timedOut',
		'unrunTests'
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
	data at: #results put: self results.
	self timedOut ifTrue: [
		data at: #timedOut put: true.
		data at: #unrunTests put: self unrunTests ].
	^ data
]

{ #category : 'initialization' }
MCPRunTestsResult >> initializeResults: resultCollection timedOut: aBoolean unrunTests: testCollection [

	results := resultCollection asArray.
	timedOut := aBoolean.
	unrunTests := testCollection asArray.
	^ self
]

{ #category : 'accessing' }
MCPRunTestsResult >> results [

	^ results
]

{ #category : 'accessing' }
MCPRunTestsResult >> timedOut [

	^ timedOut
]

{ #category : 'accessing' }
MCPRunTestsResult >> unrunTests [

	^ unrunTests
]
