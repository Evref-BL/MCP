"
Concrete debug_session_step_into tool. It steps into the selected DebugSession frame and returns updated state when execution pauses through MCPToolDebugSessionControlOperation.
"
Class {
	#name : 'MCPToolStepIntoDebugSession',
	#superclass : 'MCPToolDebugSessionControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolStepIntoDebugSession class >> toolName [

	^ 'debug_session_step_into'
]

{ #category : 'private - specs' }
MCPToolStepIntoDebugSession >> controlToolSpec [

	^ {
		  (#title -> 'Step Into Debug Session').
		  (#description
		   ->
		   'Step into the selected frame of a tracked Pharo DebugSession and optionally return a debug_state_get snapshot when execution pauses.').
		  (#action -> 'stepInto').
		  (#usesFrameReference -> true) } asDictionary
]
