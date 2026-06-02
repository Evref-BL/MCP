"
Concrete debug_session_step_over tool. It steps over the selected DebugSession frame and returns updated state when execution pauses through MCPToolDebugSessionControlOperation.
"
Class {
	#name : 'MCPToolStepOverDebugSession',
	#superclass : 'MCPToolDebugSessionControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolStepOverDebugSession class >> toolName [

	^ 'debug_session_step_over'
]

{ #category : 'private - specs' }
MCPToolStepOverDebugSession >> controlToolSpec [

	^ {
		  (#title -> 'Step Over Debug Session').
		  (#description
		   ->
		   'Step over the selected frame of a tracked Pharo DebugSession and optionally return a debug_state_get snapshot when execution pauses.').
		  (#action -> 'stepOver').
		  (#usesFrameReference -> true) } asDictionary
]
