"
Concrete debug_session_get tool. It returns the registry summary for one tracked DebugSession through MCPToolDebugSessionOperation.
"
Class {
	#name : 'MCPToolGetDebugSession',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolGetDebugSession class >> toolName [

	^ 'debug_session_get'
]

{ #category : 'private - specs' }
MCPToolGetDebugSession >> sessionToolSpec [

	^ {
		  (#title -> 'Get Debug Session').
		  (#description
		   ->
		   'Return the registry summary for one tracked Pharo DebugSession.').
		  (#action -> 'get').
		  (#inputProperties -> { self sessionIdSchemaProperty }).
		  (#requiredProperties -> #( 'sessionId' )) } asDictionary
]
