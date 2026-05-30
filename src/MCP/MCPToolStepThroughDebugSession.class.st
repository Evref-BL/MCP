Class {
	#name : 'MCPToolStepThroughDebugSession',
	#superclass : 'MCPToolDebugControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolStepThroughDebugSession class >> toolName [

	^ 'debug_session_step_through'
]

{ #category : 'private - operations' }
MCPToolStepThroughDebugSession >> controlOperationSpec [

	^ {
		  (#title -> 'Step Through Debug Session').
		  (#description
		   ->
		   'Step through the selected frame of a tracked Pharo DebugSession and optionally return the post-action debug_state_get snapshot.').
		  (#operation -> 'stepThrough').
		  (#usesFrameReference -> true) } asDictionary
]
