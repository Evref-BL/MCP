Class {
	#name : 'MCPToolTerminateDebugSession',
	#superclass : 'MCPToolDebugControlOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolTerminateDebugSession class >> toolName [

	^ 'debug_session_terminate'
]

{ #category : 'private - operations' }
MCPToolTerminateDebugSession >> controlOperationSpec [

	^ {
		  (#title -> 'Terminate Debug Session').
		  (#description -> 'Terminate a tracked Pharo DebugSession.').
		  (#operation -> 'terminate').
		  (#usesStateSnapshotOptions -> false) } asDictionary
]
