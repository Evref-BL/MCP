"
Request object for reading one tool contract from the catalog.

It carries the public tool name and leaves lookup, validation, and schema rendering to MCPGetToolCommand.
"
Class {
	#name : 'MCPGetToolRequest',
	#superclass : 'Object',
	#instVars : [
		'toolName'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPGetToolRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  toolName: (aToolRequest stringArgumentNamed: 'name');
		  yourself
]

{ #category : 'accessing' }
MCPGetToolRequest >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPGetToolRequest >> toolName: aString [

	toolName := aString
]
