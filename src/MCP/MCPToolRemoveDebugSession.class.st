"
Concrete debug_session_remove tool. It removes a tracked debug session and terminates an owned captured worker when applicable through MCPToolDebugSessionOperation.
"
Class {
	#name : 'MCPToolRemoveDebugSession',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveDebugSession class >> toolName [

	^ 'debug_session_remove'
]

{ #category : 'private - specs' }
MCPToolRemoveDebugSession >> sessionToolSpec [

	^ {
		  (#title -> 'Remove Debug Session').
		  (#description
		   ->
		   'Remove a tracked debug session from the MCP debugger registry and terminate an owned captured worker when applicable.').
		  (#action -> 'remove').
		  (#inputProperties -> { self sessionIdSchemaProperty }).
		  (#requiredProperties -> #( 'sessionId' )) } asDictionary
]
