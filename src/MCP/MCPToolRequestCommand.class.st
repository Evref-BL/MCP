"
Abstract command for tool executions that carry the invoking tool and one validated request object.

Subclasses implement #execute and use #tool and #request to collaborate with the owning tool and request.
"
Class {
	#name : 'MCPToolRequestCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPToolRequestCommand class >> isAbstract [

	^ self == MCPToolRequestCommand
]

{ #category : 'instance creation' }
MCPToolRequestCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'initialization' }
MCPToolRequestCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest
]

{ #category : 'accessing' }
MCPToolRequestCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPToolRequestCommand >> tool [

	^ tool
]
