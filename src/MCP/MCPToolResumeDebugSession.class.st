Class {
	#name : 'MCPToolResumeDebugSession',
	#superclass : 'MCPToolDebugControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolResumeDebugSession class >> toolName [

	^ 'debug_session_resume'
]

{ #category : 'private - operations' }
MCPToolResumeDebugSession >> controlOperationSpec [

	^ {
		  (#title -> 'Resume Debug Session').
		  (#description
		   ->
		   'Resume a tracked Pharo DebugSession and optionally return a debug_state_get snapshot if execution pauses again.').
		  (#operation -> 'resume') } asDictionary
]
