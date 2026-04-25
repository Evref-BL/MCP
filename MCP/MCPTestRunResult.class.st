"
Result DTO for one run-tests selection.

It carries the structured result entry when any tests ran, timeout state, and remaining test requests for resume output.
"
Class {
	#name : 'MCPTestRunResult',
	#superclass : 'Object',
	#instVars : [
		'timedOut',
		'unrunTestRequests',
		'resultInfo'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPTestRunResult class >> resultInfo: resultInfoOrNil timedOut: aBoolean unrunTestRequests: testRequests [

	^ self new
		  initializeResultInfo: resultInfoOrNil
		  timedOut: aBoolean
		  unrunTestRequests: testRequests
]

{ #category : 'converting' }
MCPTestRunResult >> asDictionary [

	| data |
	data := Dictionary new.
	self resultInfo ifNotNil: [ :entry |
		data at: #result put: entry asDictionary ].
	data at: #timedOut put: self timedOut.
	data at: #unrunTests put: self unrunTestDictionaries.
	^ data
]

{ #category : 'testing' }
MCPTestRunResult >> hasResult [

	^ self resultInfo notNil
]

{ #category : 'initialization' }
MCPTestRunResult >> initializeResultInfo: resultInfoOrNil timedOut: aBoolean unrunTestRequests: testRequests [

	resultInfo := resultInfoOrNil.
	timedOut := aBoolean.
	unrunTestRequests := testRequests ifNil: [ #(  ) ].
	^ self
]

{ #category : 'accessing' }
MCPTestRunResult >> resultInfo [

	^ resultInfo
]

{ #category : 'accessing' }
MCPTestRunResult >> resultInfo: anObject [

	resultInfo := anObject
]

{ #category : 'accessing' }
MCPTestRunResult >> timedOut [

	^ timedOut ifNil: [ false ]
]

{ #category : 'converting' }
MCPTestRunResult >> unrunTestDictionaries [

	^ (self unrunTestRequests collect: [ :each | each asDictionary ])
		  asArray
]

{ #category : 'accessing' }
MCPTestRunResult >> unrunTestRequests [

	^ unrunTestRequests ifNil: [ #(  ) ]
]
