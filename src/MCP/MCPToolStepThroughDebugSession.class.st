"
Concrete debug_session_step_through tool. It steps through the selected DebugSession frame and returns updated state when execution pauses through MCPToolDebugSessionControlOperation.
"
Class {
	#name : 'MCPToolStepThroughDebugSession',
	#superclass : 'MCPToolDebugSessionControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolStepThroughDebugSession class >> toolName [

	^ 'debug_session_step_through'
]

{ #category : 'private - specs' }
MCPToolStepThroughDebugSession >> controlToolSpec [

	^ {
		  (#title -> 'Step Through Debug Session').
		  (#description
		   ->
		   'Step through the selected frame of a tracked Pharo DebugSession and optionally return a debug_state_get snapshot when execution pauses.').
		  (#action -> 'stepThrough').
		  (#usesFrameReference -> true) } asDictionary
]
