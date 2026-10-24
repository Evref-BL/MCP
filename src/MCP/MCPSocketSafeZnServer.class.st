"
Zinc server used by MCP HTTP transport.

It treats socket errors while reading a request as connection termination. This matters after image restart because serialized connection processes can resume invalid native sockets; they should close quietly instead of opening a debugger.

It also owns the socket it listens on, rather than letting ZnNetworkingUtils create one it drops when binding fails, so retrying on a port another process holds costs nothing.
"
Class {
	#name : 'MCPSocketSafeZnServer',
	#superclass : 'ZnManagingMultiThreadedServer',
	#instVars : [
		'lastListenError'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'post response' }
MCPSocketSafeZnServer >> deferAfterCurrentResponse: aBlock [

	MCPPostResponseActions value ifNil: [ aBlock value ] ifNotNil: [ :actions | actions add: aBlock ]
]

{ #category : 'request handling' }
MCPSocketSafeZnServer >> executeOneRequestResponseOn: stream [

	| actions shouldStop |
	actions := OrderedCollection new.
	shouldStop := MCPPostResponseActions value: actions during: [ super executeOneRequestResponseOn: stream ].
	self runPostResponseActions: actions.
	^ shouldStop
]

{ #category : 'private' }
MCPSocketSafeZnServer >> handleSocketErrorDuringListen: aSocketError [

	lastListenError := aSocketError messageText.
	self releaseServerSocketAfterSocketError
]

{ #category : 'private' }
MCPSocketSafeZnServer >> initializeServerSocket [
	"Zinc creates the socket inside ZnNetworkingUtils and loses it when binding fails, leaving its three external semaphores registered. A server retrying on a port another process holds fills the external object table within seconds, after which nothing in the image can open a socket. Owning the socket here means a failed attempt destroys it."

	| socket |
	socket := self newServerSocket.
	[
		ZnNetworkingUtils default setServerSocketOptions: socket.
		self bindingAddress
			ifNil: [ socket listenOn: self port backlogSize: ZnNetworkingUtils listenBacklogSize ]
			ifNotNil: [ :address | socket listenOn: self port backlogSize: ZnNetworkingUtils listenBacklogSize interface: address ].
		socket isValid ifFalse: [ SocketError signal: 'Cannot listen on port ' , self port printString ] ] ifCurtailed: [
		socket destroy ].
	serverSocket := socket.
	lastListenError := nil.
	"Binding to port 0 asks the OS for a port, so read back the one it gave."
	self port isZero ifTrue: [ self optionAt: #port put: serverSocket port ].
	self logServerSocketBound
]

{ #category : 'private' }
MCPSocketSafeZnServer >> initialSocketRestartDelayMilliseconds [

	^ 250
]

{ #category : 'testing' }
MCPSocketSafeZnServer >> isListening [

	^ [ super isListening ]
		  on: SocketError
		  do: [ false ]
]

{ #category : 'accessing' }
MCPSocketSafeZnServer >> lastListenError [
	"What stopped the last listening attempt, so a caller that gave up waiting can say why. Cleared once the server binds."

	^ lastListenError
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
MCPSocketSafeZnServer >> maximumSocketRestartDelayMilliseconds [

	^ 2000
]

{ #category : 'private' }
MCPSocketSafeZnServer >> newServerSocket [
	"The socket a listening attempt binds, named so a test can see the one an attempt created."

	^ Socket newTCP
]

{ #category : 'private' }
MCPSocketSafeZnServer >> readRequestTerminationExceptionSet [

	^ super readRequestTerminationExceptionSet , (self exceptionSet: #( #SocketError ))
]

{ #category : 'private' }
MCPSocketSafeZnServer >> releaseServerSocketAfterSocketError [

	[ self releaseServerSocket ]
		on: SocketError
		do: [ :ignored | serverSocket := nil ]
]

{ #category : 'request handling' }
MCPSocketSafeZnServer >> restartableListenLoop [
	"Keep waiting for the port, because a server told to listen on one that another process holds starts listening when that process lets go. The wait doubles, so a held port is not hammered for as long as the image runs, while the first retry is still immediate enough for a socket that died under a running server."

	| milliseconds |
	milliseconds := self initialSocketRestartDelayMilliseconds.
	[ self listenLoop ] whileTrue: [
			(Delay forMilliseconds: milliseconds) wait.
			milliseconds := self socketRestartDelayAfter: milliseconds ]
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
MCPSocketSafeZnServer >> socketRestartDelayAfter: milliseconds [
	"Double the wait between attempts, up to the longest the server should go without noticing that the port came free."

	^ milliseconds * 2 min: self maximumSocketRestartDelayMilliseconds
]

{ #category : 'public' }
MCPSocketSafeZnServer >> start [
	"Start the listener in a small supervisor loop. If a saved image resumes with invalid socket state, retry with a fresh socket instead of staying running but not listening."

	self stop: false.
	self class default = self ifTrue: [ self register ].
	process := [ self restartableListenLoop ] forkAt: Processor highIOPriority named: self serverProcessName.
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
