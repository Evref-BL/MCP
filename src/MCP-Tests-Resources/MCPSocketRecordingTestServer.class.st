"
Test fixture server that keeps every socket a listening attempt created, so a test can check that a failed attempt destroyed its own socket instead of leaking it.
"
Class {
	#name : 'MCPSocketRecordingTestServer',
	#superclass : 'MCPSocketSafeZnServer',
	#instVars : [
		'createdSockets'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'accessing' }
MCPSocketRecordingTestServer >> createdSockets [

	^ createdSockets ifNil: [ createdSockets := OrderedCollection new ]
]

{ #category : 'private' }
MCPSocketRecordingTestServer >> newServerSocket [

	| socket |
	socket := super newServerSocket.
	self createdSockets add: socket.
	^ socket
]
