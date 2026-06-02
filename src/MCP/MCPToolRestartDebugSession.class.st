"
Concrete debug_session_restart tool. It restarts a selected DebugSession frame and returns updated state when execution pauses through MCPToolDebugSessionControlOperation.
"
Class {
	#name : 'MCPToolRestartDebugSession',
	#superclass : 'MCPToolDebugSessionControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolRestartDebugSession class >> toolName [

	^ 'debug_session_restart'
]

{ #category : 'private - specs' }
MCPToolRestartDebugSession >> controlToolSpec [

	^ {
		  (#title -> 'Restart Debug Session').
		  (#description
		   ->
		   'Restart the selected frame of a tracked Pharo DebugSession and optionally return a debug_state_get snapshot when execution pauses.').
		  (#action -> 'restart').
		  (#usesFrameReference -> true) } asDictionary
]
