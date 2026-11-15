"
Result DTO produced by the method_get command.
"
Class {
	#name : 'MCPGetMethodResult',
	#superclass : 'MCPResult',
	#instVars : [
		'data'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPGetMethodResult class >> data: aDictionary [

	^ self new initializeData: aDictionary
]

{ #category : 'converting' }
MCPGetMethodResult >> asDictionary [

	^ self data copy
]

{ #category : 'accessing' }
MCPGetMethodResult >> data [

	^ data
]

{ #category : 'initialization' }
MCPGetMethodResult >> initializeData: aDictionary [

	data := aDictionary
]
