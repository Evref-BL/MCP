"
Result DTO produced by the inspect-method command.
"
Class {
	#name : 'MCPInspectMethodResult',
	#superclass : 'Object',
	#instVars : [
		'data',
		'externalVariableCount'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPInspectMethodResult class >> data: aDictionary externalVariableCount: anIntegerOrNil [

	^ self new
		  initializeData: aDictionary
		  externalVariableCount: anIntegerOrNil
]

{ #category : 'accessing' }
MCPInspectMethodResult >> data [

	^ data
]

{ #category : 'accessing' }
MCPInspectMethodResult >> externalVariableCount [

	^ externalVariableCount
]

{ #category : 'initialization' }
MCPInspectMethodResult >> initializeData: aDictionary externalVariableCount: anIntegerOrNil [

	data := aDictionary.
	externalVariableCount := anIntegerOrNil.
	^ self
]
