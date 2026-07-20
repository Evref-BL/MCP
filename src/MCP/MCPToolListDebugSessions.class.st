"
Concrete debug_session_list tool. It lists DebugSession records tracked by the MCP debugger registry through MCPToolDebugSessionOperation.
"
Class {
	#name : 'MCPToolListDebugSessions',
	#superclass : 'MCPToolDebugSessionOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolListDebugSessions class >> toolName [

	^ 'debug_session_list'
]

{ #category : 'metadata' }
MCPToolListDebugSessions >> mutability [

	^ 'read'
]

{ #category : 'private - specs' }
MCPToolListDebugSessions >> sessionToolSpec [

	^ {
		  (#title -> 'List Debug Sessions').
		  (#description
		   ->
		   'List Pharo DebugSession records tracked by the MCP debugger registry.').
		  (#action -> 'list') } asDictionary
]
