"
The Zn entity that hands an MCPEventStream to the socket.

Zn writes a response by asking its entity to write itself, so the entity is where a long-lived stream lives. It declares no content length, because the length of a stream that stays open is not known.
"
Class {
	#name : 'MCPEventStreamEntity',
	#superclass : 'ZnEntity',
	#instVars : [
		'eventStream'
	],
	#category : 'MCP-Transport',
	#package : 'MCP',
	#tag : 'Transport'
}

{ #category : 'instance creation' }
MCPEventStreamEntity class >> on: anEventStream [

	^ self new
		  eventStream: anEventStream;
		  yourself
]

{ #category : 'accessing' }
MCPEventStreamEntity class >> designatedMimeType [

	^ ZnMimeType main: 'text' sub: 'event-stream'
]

{ #category : 'accessing' }
MCPEventStreamEntity >> contentLength [
	"A stream that stays open has no length to declare."

	^ nil
]

{ #category : 'accessing' }
MCPEventStreamEntity >> eventStream [

	^ eventStream
]

{ #category : 'accessing' }
MCPEventStreamEntity >> eventStream: anEventStream [

	eventStream := anEventStream
]

{ #category : 'accessing' }
MCPEventStreamEntity >> contents [
	"A stream has no contents to answer: what it carries has already gone to the socket."

	^ nil
]

{ #category : 'reading' }
MCPEventStreamEntity >> readFrom: aStream [
	"A notification stream is written to a client, never read from one."

	^ self error: 'An MCP event stream is written, not read.'
]

{ #category : 'testing' }
MCPEventStreamEntity >> isEmpty [
	"An open stream is a body, however little has crossed it so far."

	^ false
]

{ #category : 'initialization' }
MCPEventStreamEntity >> initialize [

	super initialize.
	contentType := ZnMimeType main: 'text' sub: 'event-stream'
]

{ #category : 'writing' }
MCPEventStreamEntity >> writeOn: aBinaryStream [

	self eventStream writeOn: aBinaryStream
]
