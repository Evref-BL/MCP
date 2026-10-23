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
		'isOpen',
		'subscriptionId',
		'acceptedNotifications'
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

{ #category : 'accessing' }
MCPEventStream >> acceptedNotifications: someMethodNames [
	"The notification methods this stream agreed to carry. A legacy stream agrees to all of them, which nil says."

	acceptedNotifications := someMethodNames
]

{ #category : 'testing' }
MCPEventStream >> accepts: aMethodName [
	"The revision is explicit that a server must not send a notification type the client did not ask for."

	acceptedNotifications ifNil: [ ^ true ].
	^ acceptedNotifications includes: aMethodName
]

{ #category : 'accessing' }
MCPEventStream >> pendingEvents [
	"What has been queued and not yet written to the socket, without consuming it. For tests and for looking at a stream that is not moving."

	^ queue contents
]

{ #category : 'accessing' }
MCPEventStream >> subscriptionId [

	^ subscriptionId
]

{ #category : 'accessing' }
MCPEventStream >> subscriptionId: anId [
	"The id of the subscriptions/listen request that opened this stream. A legacy stream was opened by a GET and has none."

	subscriptionId := anId
]

{ #category : 'writing' }
MCPEventStream >> write: aJSONString [
	"Queue one notification. The writing process picks it up."

	self isOpen ifFalse: [ ^ self ].
	queue nextPut: aJSONString
]

{ #category : 'writing' }
MCPEventStream >> keepAliveInterval [
	"How long a stream may stay silent before saying something that means nothing. Intermediaries and client idle timeouts close a connection that has gone quiet, and a notification stream is quiet most of the time."

	^ 15 seconds
]

{ #category : 'writing' }
MCPEventStream >> notificationFor: aMethodName parameters: someParameters [
	"A notification as this stream will send it: the method, whatever it carries, and the subscription it belongs to when it belongs to one."

	| parameters message |
	parameters := someParameters ifNil: [ Dictionary new ] ifNotNil: [ :given | given copy ].
	self subscriptionId ifNotNil: [ :id |
		parameters at: '_meta' put: { ('io.modelcontextprotocol/subscriptionId' -> id) } asDictionary ].
	message := Dictionary new
		           at: 'jsonrpc' put: '2.0';
		           at: 'method' put: aMethodName;
		           yourself.
	parameters ifNotEmpty: [ message at: 'params' put: parameters ].
	^ STONJSON toString: message
]

{ #category : 'writing' }
MCPEventStream >> pollInterval [

	^ 200 milliSeconds
]

{ #category : 'writing' }
MCPEventStream >> writeNotification: aMethodName parameters: someParameters [

	(self accepts: aMethodName) ifFalse: [ ^ self ].
	self write: (self notificationFor: aMethodName parameters: someParameters)
]

{ #category : 'writing' }
MCPEventStream >> writeOn: aBinaryStream [
	"Drain the queue, writing each notification as it arrives, until the stream is closed or the client goes away. A stream that has said nothing for a while emits an SSE comment, which carries no event and keeps the connection from being closed underneath it."

	| silentSince |
	silentSince := DateAndTime now.
	[
		[ self isOpen ] whileTrue: [
				| event |
				event := queue nextOrNil.
				event
					ifNil: [
							DateAndTime now - silentSince > self keepAliveInterval ifTrue: [
									aBinaryStream nextPutAll: (String with: $: ; yourself) utf8Encoded.
									aBinaryStream nextPutAll: (String with: Character lf) utf8Encoded.
									aBinaryStream flush.
									silentSince := DateAndTime now ].
							self isOpen ifTrue: [ self pollInterval wait ] ]
					ifNotNil: [
							aBinaryStream nextPutAll: (self frameFor: event) utf8Encoded.
							aBinaryStream flush.
							silentSince := DateAndTime now ] ] ] on: Error do: [ :error | error return ].
	isOpen := false
]
