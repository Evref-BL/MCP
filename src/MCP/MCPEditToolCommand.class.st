"
Command wrapper for edit tools. It receives a parsed edit request and dispatches the selected edit operation on the owning tool.
"
Class {
	#name : 'MCPEditToolCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPEditToolCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPEditToolCommand >> execute [

	^ tool executeOperationRequest: request
]

{ #category : 'initialization' }
MCPEditToolCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPEditToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPEditToolCommand >> tool [

	^ tool
]
