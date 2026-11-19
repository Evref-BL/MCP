"
Test fixture server that keeps every socket a listening attempt created, so a test can check that a failed attempt destroyed its own socket instead of leaking it. It retries a failed bind after 20 ms rather than 250, so a test that frees the port sees it bound soon after.
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
MCPSocketRecordingTestServer >> initialSocketRestartDelayMilliseconds [

	^ 20
]

{ #category : 'private' }
MCPSocketRecordingTestServer >> newServerSocket [

	| socket |
	socket := super newServerSocket.
	self createdSockets add: socket.
	^ socket
]
