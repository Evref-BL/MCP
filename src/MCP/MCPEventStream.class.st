"
One open server-to-client notification stream, written as Server-Sent Events.

A client opens a stream with GET and an Accept of text/event-stream, and the server writes JSON-RPC notifications onto it as they happen. There is no session identity: a stream is a listener, nothing more, which is why nothing here needs to correlate it with a particular client.

The server process writing the stream parks on the queue until an event arrives, so it costs a process and no polling. ZnManagingMultiThreadedServer runs a process per connection, so parking here cannot starve the request path.

Writing to a stream whose client has gone raises, which is how a stream learns it is closed; the server drops it from the listeners and the process ends.
"
Class {
	#name : 'MCPEventStream',
	#superclass : 'Object',
	#instVars : [
		'queue',
		'isOpen'
	],
	#category : 'MCP-Transport',
	#package : 'MCP',
	#tag : 'Transport'
}

{ #category : 'closing' }
MCPEventStream >> close [
	"Wake the writing process so it can notice the stream is done."

	isOpen := false.
	queue nextPut: nil
]

{ #category : 'initialization' }
MCPEventStream >> initialize [

	super initialize.
	queue := SharedQueue new.
	isOpen := true
]

{ #category : 'testing' }
MCPEventStream >> isOpen [

	^ isOpen
]

{ #category : 'writing' }
MCPEventStream >> frameFor: aJSONString [
	"One SSE frame: a data line and the blank line that ends the event."

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'data: ';
			  nextPutAll: aJSONString;
			  lf;
			  lf ]
]

{ #category : 'writing' }
MCPEventStream >> write: aJSONString [
	"Queue one notification. The writing process picks it up."

	self isOpen ifFalse: [ ^ self ].
	queue nextPut: aJSONString
]

{ #category : 'writing' }
MCPEventStream >> writeOn: aBinaryStream [
	"Park on the queue, writing each notification as it arrives, until the stream is closed or the client goes away."

	[
		[ self isOpen ] whileTrue: [
				| event |
				event := queue next.
				event ifNotNil: [
						aBinaryStream nextPutAll: (self frameFor: event) utf8Encoded.
						aBinaryStream flush ] ] ] on: Error do: [ :error | error return ].
	isOpen := false
]
