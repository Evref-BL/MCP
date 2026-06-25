"
Result DTO produced by the method_get command.
"
Class {
	#name : 'MCPGetMethodResult',
	#superclass : 'MCPResult',
	#instVars : [
		'data',
		'externalVariableCount'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPGetMethodResult class >> data: aDictionary externalVariableCount: anIntegerOrNil [

	^ self new
		  initializeData: aDictionary
		  externalVariableCount: anIntegerOrNil
]

{ #category : 'converting' }
MCPGetMethodResult >> asDictionary [

	| result |
	result := self data copy.
	self externalVariableCount ifNotNil: [ :count |
		result at: #externalVariableCount put: count ].
	^ result
]

{ #category : 'accessing' }
MCPGetMethodResult >> data [

	^ data
]

{ #category : 'accessing' }
MCPGetMethodResult >> externalVariableCount [

	^ externalVariableCount
]

{ #category : 'initialization' }
MCPGetMethodResult >> initializeData: aDictionary externalVariableCount: anIntegerOrNil [

	data := aDictionary.
	externalVariableCount := anIntegerOrNil.
	^ self
]
