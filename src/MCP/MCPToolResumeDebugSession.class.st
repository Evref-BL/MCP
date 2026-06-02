"
Concrete debug_session_resume tool. It resumes a tracked DebugSession and returns updated state when execution pauses again through MCPToolDebugSessionControlOperation.
"
Class {
	#name : 'MCPToolResumeDebugSession',
	#superclass : 'MCPToolDebugSessionControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolResumeDebugSession class >> toolName [

	^ 'debug_session_resume'
]

{ #category : 'private - specs' }
MCPToolResumeDebugSession >> controlToolSpec [

	^ {
		  (#title -> 'Resume Debug Session').
		  (#description
		   ->
		   'Resume a tracked Pharo DebugSession and optionally return a debug_state_get snapshot if execution pauses again.').
		  (#action -> 'resume') } asDictionary
]
