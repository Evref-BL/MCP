"
Tests the server-to-client notification stream.

Every wait here is bounded, so a stream that never delivers fails the test instead of hanging the run.
"
Class {
	#name : 'MCPEventStreamTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'tests' }
MCPEventStreamTest >> testAGetAcceptingEventStreamOpensAStream [

	| server request response |
	server := MCPHTTPServer new.
	request := ZnRequest get: '/'.
	request headers at: 'Accept' put: 'text/event-stream'.
	response := server answerGet: request with: ZnResponse new.
	self assert: response entity class equals: MCPEventStreamEntity.
	self assert: server eventStreams size equals: 1.
	self assert: server eventStreams first isOpen.
	server closeEventStreams
]

{ #category : 'tests' }
MCPEventStreamTest >> testAGetWithoutEventStreamAcceptIsStillRefused [

	| server response |
	server := MCPHTTPServer new.
	response := server answerGet: (ZnRequest get: '/') with: ZnResponse new.
	self assert: server eventStreams isEmpty.
	self deny: response entity class = MCPEventStreamEntity
]

{ #category : 'tests' }
MCPEventStreamTest >> testAddingAToolTellsListeningClients [

	| mcp stream text |
	mcp := self mcpWithoutObservabilityExport.
	stream := MCPEventStream new.
	mcp server addEventStream: stream.
	text := self
		        text: stream
		        whileDoing: [ mcp addTool: MCPHaltingTestTool ]
		        untilItIncludes: 'notifications/tools/list_changed'.
	self assert: (text beginsWith: 'data: ')
]

{ #category : 'tests' }
MCPEventStreamTest >> testBroadcastDropsListenersWhoseClientHasGone [

	| server open closed |
	server := MCPHTTPServer new.
	open := MCPEventStream new.
	closed := MCPEventStream new.
	server
		addEventStream: open;
		addEventStream: closed.
	closed close.
	server broadcastNotification: 'notifications/tools/list_changed' parameters: nil.
	self assert: server eventStreams asArray equals: { open }.
	server closeEventStreams
]

{ #category : 'tests' }
MCPEventStreamTest >> testCapabilitiesDeclareListChangedNowTheStreamCanCarryIt [

	| capabilities |
	capabilities := self mcpWithoutObservabilityExport advertisedCapabilities asJRPCJSON.
	self assert: ((capabilities at: #tools) at: #listChanged).
	self assert: ((capabilities at: #resources) at: #listChanged)
]

{ #category : 'tests' }
MCPEventStreamTest >> testCapabilitiesStillRefuseSubscribe [
	"Subscribing promises notifications/resources/updated, and no resource here can say it changed."

	| resources |
	resources := self mcpWithoutObservabilityExport advertisedCapabilities asJRPCJSON at: #resources.
	self deny: (resources includesKey: #subscribe)
]

{ #category : 'tests' }
MCPEventStreamTest >> testClosedStreamTakesNoMoreEvents [

	| stream |
	stream := MCPEventStream new.
	stream close.
	stream write: 'ignored'.
	self deny: stream isOpen
]

{ #category : 'tests' }
MCPEventStreamTest >> testEachEventIsOneSseFrameEndedByABlankLine [

	| stream text |
	stream := MCPEventStream new.
	text := self
		        text: stream
		        whileDoing: [
			        stream write: '{"a":1}'.
			        stream write: '{"b":2}' ]
		        untilItIncludes: 'data: {"b":2}'.
	self assert: (text includesSubstring: 'data: {"a":1}' , String lf , String lf)
]

{ #category : 'private' }
MCPEventStreamTest >> text: anEventStream whileDoing: aBlock untilItIncludes: aSubstring [
	"Drive the stream's writer onto a binary stream of our own, so frames can be read back without a socket, and wait only as long as a working stream would need."

	| target writer deadline text |
	target := WriteStream on: (ByteArray new: 0).
	writer := [ anEventStream writeOn: target ] forkAt: Processor userBackgroundPriority.
	[
		aBlock value.
		deadline := DateAndTime now + 5 seconds.
		text := ''.
		[ text includesSubstring: aSubstring ] whileFalse: [
				DateAndTime now > deadline ifTrue: [ self fail: 'timed out waiting for ' , aSubstring printString ].
				(Delay forMilliseconds: 10) wait.
				text := target contents utf8Decoded ] ] ensure: [
			anEventStream close.
			writer terminate ].
	^ text
]
