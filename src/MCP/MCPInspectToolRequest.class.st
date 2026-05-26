Class {
	#name : 'MCPInspectToolRequest',
	#superclass : 'Object',
	#instVars : [
		'toolName'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPInspectToolRequest class >> fromToolRequest: aToolRequest [

	^ self new
		  toolName: (aToolRequest stringArgumentNamed: 'toolName');
		  yourself
]

{ #category : 'accessing' }
MCPInspectToolRequest >> toolName [

	^ toolName
]

{ #category : 'accessing' }
MCPInspectToolRequest >> toolName: aString [

	toolName := aString
]
