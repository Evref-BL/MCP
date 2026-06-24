"
DTO for summarizing one registered debug session.

It exposes session id, lifecycle status, reason, exception summary, top-frame preview, capabilities, and current state token without exposing raw DebugSession objects.
"
Class {
	#name : 'MCPDebugSessionInfo',
	#superclass : 'Object',
	#instVars : [
		'record'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugSessionInfo class >> fromRecord: aRecord [

	^ self new
		  record: aRecord;
		  yourself
]

{ #category : 'converting' }
MCPDebugSessionInfo >> asDictionary [

	^ {
		  (#sessionId -> record sessionId).
		  (#name -> record name).
		  (#status -> record status).
		  (#reason -> record reason).
		  (#lastStateId -> record stateId).
		  (#createdAt -> record createdAt asString).
		  (#topFrame -> nil).
		  (#exception -> nil).
		  (#capabilities -> record capabilities) } asDictionary
]

{ #category : 'accessing' }
MCPDebugSessionInfo >> record [

	^ record
]

{ #category : 'accessing' }
MCPDebugSessionInfo >> record: aRecord [

	record := aRecord
]
