"
Result DTO produced by the evaluate command. It transports either evaluated data or a structured evaluation failure back to the tool.
"
Class {
	#name : 'MCPEvaluateResult',
	#superclass : 'MCPResult',
	#instVars : [
		'status',
		'data',
		'summary',
		'errorDetails'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPEvaluateResult class >> errorSummary: aString details: aDictionary [

	^ self new
		  initializeStatus: #error
		  data: nil
		  summary: aString
		  errorDetails: aDictionary
]

{ #category : 'instance creation' }
MCPEvaluateResult class >> okData: aDictionary [

	^ self new
		  initializeStatus: #ok
		  data: aDictionary
		  summary: nil
		  errorDetails: nil
]

{ #category : 'converting' }
MCPEvaluateResult >> asDictionary [

	| result |
	result := Dictionary new.
	result at: #status put: self status.
	self data ifNotNil: [ :value | result at: #data put: value ].
	self summary ifNotNil: [ :text | result at: #summary put: text ].
	self errorDetails ifNotNil: [ :value | result at: #error put: value ].
	^ result
]

{ #category : 'accessing' }
MCPEvaluateResult >> data [

	^ data
]

{ #category : 'accessing' }
MCPEvaluateResult >> errorDetails [

	^ errorDetails
]

{ #category : 'initialization' }
MCPEvaluateResult >> initializeStatus: aStatus data: aDictionary summary: aString errorDetails: detailsDictionary [

	status := aStatus.
	data := aDictionary.
	summary := aString.
	errorDetails := detailsDictionary.
	^ self
]

{ #category : 'testing' }
MCPEvaluateResult >> isError [

	^ status = #error
]

{ #category : 'accessing' }
MCPEvaluateResult >> status [

	^ status
]

{ #category : 'accessing' }
MCPEvaluateResult >> summary [

	^ summary
]
