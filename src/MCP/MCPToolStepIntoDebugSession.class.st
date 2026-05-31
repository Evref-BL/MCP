Class {
	#name : 'MCPToolStepIntoDebugSession',
	#superclass : 'MCPToolDebugControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolStepIntoDebugSession class >> toolName [

	^ 'debug_session_step_into'
]

{ #category : 'private - operations' }
MCPToolStepIntoDebugSession >> controlOperationSpec [

	^ {
		  (#title -> 'Step Into Debug Session').
		  (#description
		   ->
		   'Step into the selected frame of a tracked Pharo DebugSession and optionally return a debug_state_get snapshot when execution pauses.').
		  (#operation -> 'stepInto').
		  (#usesFrameReference -> true) } asDictionary
]
