"
Returns full metadata and schemas for one catalog tool.

This command is the second step of the discoverable-tool flow: after discovery gives a candidate name, tool_get exposes the exact contract needed for a safe call.
"
Class {
	#name : 'MCPGetToolCommand',
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
MCPGetToolCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPGetToolCommand >> execute [

	| catalogTool |
	catalogTool := MCPToolRegistry
		               toolNamed: request toolName
		               ifAbsent: [
		               Error signal: 'Unknown MCP tool: ' , request toolName ]
		               usingPolicy: tool toolExposurePolicy.
	^ { (#tool -> (MCPToolRegistry
		    contractForTool: catalogTool
		    usingPolicy: tool toolExposurePolicy)) } asDictionary
]

{ #category : 'accessing' }
MCPGetToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPGetToolCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPGetToolCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPGetToolCommand >> tool: anObject [

	tool := anObject
]
