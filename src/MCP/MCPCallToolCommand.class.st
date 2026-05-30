"
Executes one tool selected from the discoverable MCP tool catalog.

This command is the dynamic dispatch path behind call-tool: it validates the requested catalog entry, invokes the selected MCPTool with nested arguments, and preserves the selected tool's normal output contract.
"
Class {
	#name : 'MCPCallToolCommand',
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
MCPCallToolCommand class >> tool: aTool request: aRequest [

	^ self new
		  tool: aTool;
		  request: aRequest;
		  yourself
]

{ #category : 'executing' }
MCPCallToolCommand >> execute [

	Error signal: 'call-tool requires MCP server call context.'
]

{ #category : 'accessing' }
MCPCallToolCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPCallToolCommand >> request: anObject [

	request := anObject
]

{ #category : 'accessing' }
MCPCallToolCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPCallToolCommand >> tool: anObject [

	tool := anObject
]
