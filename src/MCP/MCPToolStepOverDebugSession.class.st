Class {
	#name : 'MCPToolStepOverDebugSession',
	#superclass : 'MCPToolDebugControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolStepOverDebugSession class >> toolName [

	^ 'debug_session_step_over'
]

{ #category : 'private - operations' }
MCPToolStepOverDebugSession >> controlOperationSpec [

	^ {
		  (#title -> 'Step Over Debug Session').
		  (#description
		   ->
		   'Step over the selected frame of a tracked Pharo DebugSession and optionally return the post-action debug_state_get snapshot.').
		  (#operation -> 'stepOver').
		  (#usesFrameReference -> true) } asDictionary
]
