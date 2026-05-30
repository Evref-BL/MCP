Class {
	#name : 'MCPToolRestartDebugSession',
	#superclass : 'MCPToolDebugControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRestartDebugSession class >> toolName [

	^ 'debug_session_restart'
]

{ #category : 'private - operations' }
MCPToolRestartDebugSession >> controlOperationSpec [

	^ {
		  (#title -> 'Restart Debug Session').
		  (#description
		   ->
		   'Restart the selected frame of a tracked Pharo DebugSession and optionally return the post-action debug_state_get snapshot.').
		  (#operation -> 'restart').
		  (#usesFrameReference -> true) } asDictionary
]
