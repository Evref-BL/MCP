"
Zinc server used by MCP HTTP transport.

It treats socket errors while reading a request as connection termination. This matters after image restart because serialized connection processes can resume invalid native sockets; they should close quietly instead of opening a debugger.

Any other error reading a request answers it as a request that could not be read, in JSON-RPC, and an error Zinc lets through while serving a connection ends that connection, logged, so that nothing a client sends can quit a headless image.

It also owns the socket it listens on, rather than letting ZnNetworkingUtils create one it drops when binding fails, so retrying on a port another process holds costs nothing.

While it runs, a process of its own tells the virtual machine to read its sockets every few milliseconds. The machine reads them only when told to, which the idle process does once nothing else runs, so code computing below the calls, an evaluation or a process forked below it, would otherwise keep every call from being accepted, read or answered until it ended.
"
Class {
	#name : 'MCPSocketSafeZnServer',
	#superclass : 'ZnManagingMultiThreadedServer',
	#instVars : [
		'lastListenError',
		'socketPoller'
	],
	#category : 'MCP-Transport',
	#package : 'MCP',
	#tag : 'Transport'
}

{ #category : 'request handling' }
MCPSocketSafeZnServer >> executeOneRequestResponseOn: stream [

	| actions shouldStop |
	actions := OrderedCollection new.
	shouldStop := MCPPostResponseActions value: actions during: [ super executeOneRequestResponseOn: stream ].
	self runPostResponseActions: actions.
	^ shouldStop
]

{ #category : 'request handling' }
MCPSocketSafeZnServer >> executeRequestResponseLoopOn: stream [
	"An error Zinc lets through while serving a connection ends that connection, logged. Unhandled in the worker, it would quit a headless image for what one client sent; only a server in debug mode, in an image that can open a debugger, lets it through."

	[ super executeRequestResponseLoopOn: stream ]
		on: Error
		do: [ :error |
				(self debugMode and: [ Smalltalk isInteractive ]) ifTrue: [ error pass ].
				self logServerHandlerError: error ]
]

{ #category : 'private' }
MCPSocketSafeZnServer >> handleErrorDuringListen: anError [

	lastListenError := anError mcpMessageText.
	self releaseServerSocketAfterSocketError
]

{ #category : 'private' }
MCPSocketSafeZnServer >> initialSocketRestartDelayMilliseconds [

	^ 250
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
		(self listensAsAsked: socket) ifFalse: [ SocketError signal: 'Cannot listen on port ' , self port printString ] ] ifCurtailed: [
		socket destroy ].
	serverSocket := socket.
	lastListenError := nil.
	"Binding to port 0 asks the OS for a port, so read back the one it gave."
	self port isZero ifTrue: [ self optionAt: #port put: serverSocket port ].
	self logServerSocketBound
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
	"An error while listening, a socket's or any other while accepting a connection, ends this attempt, and the supervisor loop makes another. Unhandled in the listening process, it would quit a headless image."

	^ [
		  super listenLoop.
		  false ]
		  on: Error
		  do: [ :error |
				  self handleErrorDuringListen: error.
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
MCPSocketSafeZnServer >> pollSockets [
	"The virtual machine reads its sockets only when the image relinquishes the processor, which the idle process does once nothing else runs. Code computing below this process, an evaluation or a process forked below it, would keep every call from being accepted, read or answered until it ended. Woken at this priority, above all of it, this process tells the machine to read them, without waiting."

	[
		(Delay forMilliseconds: self socketPollingMilliseconds) wait.
		ProcessorScheduler relinquishProcessorForMicroseconds: 0 ] repeat
]

{ #category : 'request handling' }
MCPSocketSafeZnServer >> readRequest: stream timing: timing [
	"Zinc answers a request it cannot read only when it fails as Zinc expects. A reader that signals a plain error instead, for a Content-Length or a chunk size that is not a number, or a gzip body that is not gzip, would leave it unhandled in the worker. Any error reading a request, but the connection failing or ending, is a request that could not be read, answered as one."

	| unreadable request |
	request := [ super readRequest: stream timing: timing ]
		           on: Error
		           do: [ :error |
				           ((self readRequestBadExceptionSet handles: error) or: [
					            (self readRequestTerminationExceptionSet handles: error) or: [ NetworkError handles: error ] ]) ifTrue: [
					           error pass ].
				           unreadable := error.
				           nil ].
	unreadable ifNotNil: [ ^ ZnParseError signal: unreadable messageText ].
	^ request
]

{ #category : 'private' }
MCPSocketSafeZnServer >> readRequestTerminationExceptionSet [

	^ super readRequestTerminationExceptionSet , SocketError
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

{ #category : 'accessing' }
MCPSocketSafeZnServer >> socketPoller [
	"The process that tells the virtual machine to read its sockets while the server runs."

	^ socketPoller
]

{ #category : 'private' }
MCPSocketSafeZnServer >> socketPollingMilliseconds [
	"How often the sockets are read while code computes below the calls. Accepting, reading and answering a call each take a read."

	^ 20
]

{ #category : 'private' }
MCPSocketSafeZnServer >> socketRestartDelayAfter: milliseconds [
	"Double the wait between attempts, up to the longest the server should go without noticing that the port came free."

	^ milliseconds * 2 min: self maximumSocketRestartDelayMilliseconds
]

{ #category : 'public' }
MCPSocketSafeZnServer >> start [
	"Start the listener in a small supervisor loop. If a saved image resumes with invalid socket state, retry with a fresh socket instead of staying running but not listening. The socket poller runs at the priority calls are served at, above every evaluation and every process an evaluation forks."

	self stop: false.
	self class default = self ifTrue: [ self register ].
	process := [ self restartableListenLoop ] forkAt: Processor highIOPriority named: self serverProcessName.
	socketPoller := [ self pollSockets ] forkAt: Processor lowIOPriority named: self serverProcessName , ' socket poller'.
	self logStarted
]

{ #category : 'public' }
MCPSocketSafeZnServer >> stop: unregister [
	"Stopping for good closes the open connections. Zinc's restart, around every image save, only stops listening: the connection of the call that saved stays open, and its worker answers after the save."

	socketPoller ifNotNil: [
			socketPoller terminate.
			socketPoller := nil ].
	(process isNil and: [ serverSocket isNil ]) ifTrue: [
			unregister ifTrue: [
					self unregister.
					self closeConnections ].
			^ self ].
	process ifNotNil: [
			process terminate.
			process := nil ].
	unregister ifTrue: [ self unregister ].
	self closeDelegate.
	self releaseServerSocketAfterSocketError.
	unregister ifTrue: [ self closeConnections ].
	self logStopped
]

{ #category : 'private' }
MCPSocketSafeZnServer >> unreadableRequestErrorFor: anException [
	"The JSON-RPC error answering a request that could not be read, naming no request: one too large to read, or a body that is not UTF-8 or a request that is not HTTP, which is a parse error."

	| error |
	error := (ZnEntityTooLarge handles: anException)
		         ifTrue: [
				         JRPCErrorObject
					         code: -32000
					         message:
					         ('Request Entity Too Large: a request body may hold at most {1} bytes.' format:
						          { (ZnCurrentOptions at: #maximumEntitySize) }) ]
		         ifFalse: [
				         JRPCErrorObject code: -32700 message: ((ZnCharacterEncodingError handles: anException)
						          ifTrue: [ 'Parse error: the body is not UTF-8.' ]
						          ifFalse: [ 'Parse error: the request is not HTTP this server reads.' ]) ].
	^ STONJSON toString: (JRPCErrorResponseObject id: nil error: error) asJRPCJSON
]

{ #category : 'private' }
MCPSocketSafeZnServer >> writeResponseBad: anException on: stream timing: timing [
	"A request that could not be read is still answered in JSON-RPC, so a client reads why the way it reads any other error: 413 for one too large to read, 400 for any other. The connection is closed after, as Zinc closes it."

	| response |
	response := ZnResponse new
		            statusLine: ((ZnEntityTooLarge handles: anException)
				             ifTrue: [ ZnStatusLine code: 413 ]
				             ifFalse: [ ZnStatusLine badRequest ]);
		            headers: ZnHeaders defaultResponseHeaders;
		            entity: (ZnEntity json: (self unreadableRequestErrorFor: anException));
		            yourself.
	response setConnectionClose.
	self writeResponseSafely: response on: stream timing: timing
]
