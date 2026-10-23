"
Parsed input for debug_session.

It carries at most one reference: a debugger a person has open, or a session already attached. With none, the tool lists what is open. The snapshot options are not exposed; the defaults are what an agent reading a frame wants.
"
Class {
	#name : 'MCPDebugSessionsRequest',
	#superclass : 'MCPDebugRequest',
	#instVars : [
		'candidateRef'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPDebugSessionsRequest class >> fromRequest: aRequest tool: aTool [

	^ self new
		  operation: 'session';
		  candidateRef: (aRequest stringArgumentNamed: 'session');
		  includeReceiver: true;
		  yourself
]

{ #category : 'accessing' }
MCPDebugSessionsRequest >> candidateRef [

	^ candidateRef
]

{ #category : 'accessing' }
MCPDebugSessionsRequest >> candidateRef: aString [

	candidateRef := aString
]
