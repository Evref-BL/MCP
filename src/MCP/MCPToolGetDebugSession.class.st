Class {
	#name : 'MCPToolGetDebugSession',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolGetDebugSession class >> toolName [

	^ 'debug_session_get'
]

{ #category : 'private - operations' }
MCPToolGetDebugSession >> sessionOperationSpec [

	^ {
		  (#title -> 'Get Debug Session').
		  (#description
		   ->
		   'Return the registry summary for one tracked Pharo DebugSession.').
		  (#operation -> 'describe').
		  (#inputProperties -> { self sessionIdSchemaProperty }).
		  (#requiredProperties -> #( 'sessionId' )) } asDictionary
]
