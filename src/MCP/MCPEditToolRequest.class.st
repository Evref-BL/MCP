"
Parsed edit tool request. It preserves the validated transport request while exposing the selected operation for command dispatch.
"
Class {
	#name : 'MCPEditToolRequest',
	#superclass : 'Object',
	#instVars : [
		'rawRequest',
		'operation'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPEditToolRequest class >> fromRequest: aRequest tool: aTool [

	| operation |
	operation := aTool operationFromRequest: aRequest.
	aTool
		validateRequiredPropertiesForOperation: operation
		inRequest: aRequest.
	^ self new initializeRawRequest: aRequest operation: operation
]

{ #category : 'initialization' }
MCPEditToolRequest >> initializeRawRequest: aRequest operation: anOperation [

	rawRequest := aRequest.
	operation := anOperation.
	^ self
]

{ #category : 'accessing' }
MCPEditToolRequest >> operation [

	^ operation
]

{ #category : 'accessing' }
MCPEditToolRequest >> rawRequest [

	^ rawRequest
]
