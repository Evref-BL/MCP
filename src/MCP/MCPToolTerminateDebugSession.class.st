"
Concrete debug_session_terminate tool. It terminates a tracked DebugSession through MCPToolDebugSessionControlOperation.
"
Class {
	#name : 'MCPToolTerminateDebugSession',
	#superclass : 'MCPToolDebugSessionControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolTerminateDebugSession class >> toolName [

	^ 'debug_session_terminate'
]

{ #category : 'private - specs' }
MCPToolTerminateDebugSession >> controlToolSpec [

	^ {
		  (#title -> 'Terminate Debug Session').
		  (#description -> 'Terminate a tracked Pharo DebugSession.').
		  (#action -> 'terminate').
		  (#usesStateSnapshotOptions -> false) } asDictionary
]
