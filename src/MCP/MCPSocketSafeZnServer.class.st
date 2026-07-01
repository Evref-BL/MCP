"
Zinc server used by MCP HTTP transport.

It treats socket errors while reading a request as connection termination. This matters after image restart because serialized connection processes can resume invalid native sockets; they should close quietly instead of opening a debugger.
"
Class {
	#name : 'MCPSocketSafeZnServer',
	#superclass : 'ZnManagingMultiThreadedServer',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'post response' }
MCPSocketSafeZnServer >> deferAfterCurrentResponse: aBlock [

	MCPPostResponseActions value
		ifNil: [ aBlock value ]
		ifNotNil: [ :actions | actions add: aBlock ]
]

{ #category : 'request handling' }
MCPSocketSafeZnServer >> executeOneRequestResponseOn: stream [

	| actions shouldStop |
	actions := OrderedCollection new.
	shouldStop := MCPPostResponseActions
		value: actions
		during: [ super executeOneRequestResponseOn: stream ].
	self runPostResponseActions: actions.
	^ shouldStop
]

{ #category : 'private' }
MCPSocketSafeZnServer >> handleSocketErrorDuringListen: aSocketError [

	self releaseServerSocketAfterSocketError
]

{ #category : 'testing' }
MCPSocketSafeZnServer >> isListening [

	^ [ super isListening ]
		on: SocketError
		do: [ false ]
]

{ #category : 'request handling' }
MCPSocketSafeZnServer >> listenLoop [

	^ [
	  super listenLoop.
	  false ]
		on: SocketError
		do: [ :error |
			self handleSocketErrorDuringListen: error.
			true ]
]

{ #category : 'private' }
MCPSocketSafeZnServer >> readRequestTerminationExceptionSet [

	^ super readRequestTerminationExceptionSet
	  , (self exceptionSet: #( #SocketError ))
]

{ #category : 'private' }
MCPSocketSafeZnServer >> releaseServerSocketAfterSocketError [

	[ self releaseServerSocket ]
		on: SocketError
		do: [ :ignored | serverSocket := nil ]
]

{ #category : 'request handling' }
MCPSocketSafeZnServer >> restartableListenLoop [

	[ self listenLoop ] whileTrue: [
		self socketRestartDelay wait ]
]

{ #category : 'private - post response' }
MCPSocketSafeZnServer >> runPostResponseActions: actions [

	| actionsToRun |
	actionsToRun := actions copy.
	actions removeAll.
	actionsToRun do: [ :action |
		[ action value ]
			on: Error
			do: [ :error | self logServerHandlerError: error ] ]
]

{ #category : 'private' }
MCPSocketSafeZnServer >> socketRestartDelay [

	^ Delay forMilliseconds: 250
]

{ #category : 'public' }
MCPSocketSafeZnServer >> start [
	"Start the listener in a small supervisor loop. If a saved image resumes with invalid socket state, retry with a fresh socket instead of staying running but not listening."

	self stop: false.
	self class default = self ifTrue: [ self register ].
	process := [ self restartableListenLoop ]
		           forkAt: Processor highIOPriority
		           named: self serverProcessName.
	self logStarted
]

{ #category : 'public' }
MCPSocketSafeZnServer >> stop: unregister [

	(process isNil and: [ serverSocket isNil ]) ifTrue: [
		unregister ifTrue: [ self unregister ].
		self closeConnections.
		^ self ].
	process ifNotNil: [
		process terminate.
		process := nil ].
	unregister ifTrue: [ self unregister ].
	self closeDelegate.
	self releaseServerSocketAfterSocketError.
	self closeConnections.
	self logStopped
]
