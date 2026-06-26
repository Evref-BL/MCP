"
Structured result wrapper used by debugger tools.

It normalizes debugger success, warning, and error payloads before they are rendered into MCP text and structured content.
"
Class {
	#name : 'MCPDebugToolResult',
	#superclass : 'MCPResult',
	#instVars : [
		'status',
		'summary',
		'data',
		'warnings',
		'errorDetails'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPDebugToolResult class >> errorSummary: aSummary details: aDictionary [

	^ self new
		  initializeStatus: #error
		  summary: aSummary
		  data: nil
		  warnings: #(  )
		  errorDetails: aDictionary
]

{ #category : 'instance creation' }
MCPDebugToolResult class >> okSummary: aSummary data: aDictionary [

	^ self okSummary: aSummary data: aDictionary warnings: #(  )
]

{ #category : 'instance creation' }
MCPDebugToolResult class >> okSummary: aSummary data: aDictionary warnings: warningCollection [

	^ self new
		  initializeStatus: #ok
		  summary: aSummary
		  data: aDictionary
		  warnings: warningCollection
		  errorDetails: nil
]

{ #category : 'converting' }
MCPDebugToolResult >> asDictionary [

	| result |
	result := Dictionary new.
	result at: #status put: self status.
	self summary ifNotNil: [ :text | result at: #summary put: text ].
	self data ifNotEmpty: [ :value | result at: #data put: value ].
	self warnings ifNotEmpty: [ :value | result at: #warnings put: value ].
	self errorDetails ifNotEmpty: [ :value |
		result at: #error put: value ].
	^ result
]

{ #category : 'accessing' }
MCPDebugToolResult >> data [

	^ data ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPDebugToolResult >> errorDetails [

	^ errorDetails ifNil: [ Dictionary new ]
]

{ #category : 'initialization' }
MCPDebugToolResult >> initializeStatus: aStatus summary: aSummary data: aDictionary warnings: warningCollection errorDetails: detailsDictionary [

	status := aStatus.
	summary := aSummary.
	data := aDictionary.
	warnings := warningCollection.
	errorDetails := detailsDictionary.
	^ self
]

{ #category : 'testing' }
MCPDebugToolResult >> isError [

	^ status = #error
]

{ #category : 'accessing' }
MCPDebugToolResult >> status [

	^ status
]

{ #category : 'accessing' }
MCPDebugToolResult >> summary [

	^ summary
]

{ #category : 'accessing' }
MCPDebugToolResult >> warnings [

	^ warnings ifNil: [ #(  ) ]
]
