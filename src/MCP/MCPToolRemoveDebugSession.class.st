Class {
	#name : 'MCPToolRemoveDebugSession',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRemoveDebugSession class >> toolName [

	^ 'debug_session_remove'
]

{ #category : 'private - operations' }
MCPToolRemoveDebugSession >> sessionOperationSpec [

	^ {
		  (#title -> 'Remove Debug Session').
		  (#description
		   ->
		   'Remove a tracked debug session from the MCP debugger registry and terminate an owned captured worker when applicable.').
		  (#operation -> 'forget').
		  (#inputProperties -> { self sessionIdSchemaProperty }).
		  (#requiredProperties -> #( 'sessionId' )) } asDictionary
]
