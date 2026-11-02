"
Result DTO produced by the evaluate command. It transports either evaluated data or a structured evaluation failure back to the tool, with the warnings raised while the code ran.
"
Class {
	#name : 'MCPEvaluateResult',
	#superclass : 'MCPResult',
	#instVars : [
		'status',
		'data',
		'summary',
		'errorDetails',
		'warnings'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPEvaluateResult class >> errorSummary: aString details: aDictionary [

	^ self new initializeErrorSummary: aString details: aDictionary
]

{ #category : 'instance creation' }
MCPEvaluateResult class >> okData: aDictionary warnings: warningStrings [

	^ self new initializeOkData: aDictionary warnings: warningStrings
]

{ #category : 'converting' }
MCPEvaluateResult >> asDictionary [

	| result |
	result := Dictionary new.
	result at: #status put: self status.
	self data ifNotNil: [ :value | result at: #data put: value ].
	self warnings ifNotEmpty: [ :value | result at: #warnings put: value ].
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
MCPEvaluateResult >> initializeErrorSummary: aString details: detailsDictionary [

	status := #error.
	summary := aString.
	errorDetails := detailsDictionary
]

{ #category : 'initialization' }
MCPEvaluateResult >> initializeOkData: aDictionary warnings: warningStrings [

	status := #ok.
	data := aDictionary.
	warnings := warningStrings ifNil: [ #(  ) ]
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

{ #category : 'accessing' }
MCPEvaluateResult >> warnings [
	"What was raised while the code ran, reported beside the value rather than instead of it."

	^ warnings ifNil: [ #(  ) ]
]
