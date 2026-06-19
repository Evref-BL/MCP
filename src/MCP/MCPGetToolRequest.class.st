"
Request object for reading one tool contract from the catalog.

It carries the public tool name and leaves lookup, validation, and schema rendering to MCPGetToolCommand.
"
Class {
	#name : 'MCPGetToolRequest',
	#superclass : 'Object',
	#instVars : [
		'toolName',
		'includeOutputSchema'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPGetToolRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  toolName: (aToolRequest stringArgumentNamed: 'toolName');
		  includeOutputSchema: (aToolRequest
				   booleanArgumentNamed: 'includeOutputSchema'
				   default: false);
		  yourself
]

{ #category : 'accessing' }
MCPGetToolRequest >> includeOutputSchema [

	^ includeOutputSchema ifNil: [ false ]
]

{ #category : 'accessing' }
MCPGetToolRequest >> includeOutputSchema: aBoolean [

	includeOutputSchema := aBoolean
]

{ #category : 'accessing' }
MCPGetToolRequest >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPGetToolRequest >> toolName: aString [

	toolName := aString
]
