Class {
	#name : 'MCPToolListDebugSessions',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolListDebugSessions class >> toolName [

	^ 'debug_session_list'
]

{ #category : 'private - operations' }
MCPToolListDebugSessions >> sessionOperationSpec [

	^ {
		  (#title -> 'List Debug Sessions').
		  (#description
		   ->
		   'List Pharo DebugSession records tracked by the MCP debugger registry.').
		  (#operation -> 'list') } asDictionary
]
