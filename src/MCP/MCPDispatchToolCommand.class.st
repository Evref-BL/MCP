Class {
	#name : 'MCPDispatchToolCommand',
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
MCPDispatchToolCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPDispatchToolCommand >> execute [

	Error signal: 'dispatch-tool requires MCP server dispatch context.'
]

{ #category : 'accessing' }
MCPDispatchToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPDispatchToolCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPDispatchToolCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPDispatchToolCommand >> tool: anObject [

	tool := anObject
]
