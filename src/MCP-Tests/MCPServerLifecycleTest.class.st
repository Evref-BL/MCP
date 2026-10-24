"
Tests MCP HTTP server lifecycle behavior that must survive image save and restart boundaries.
"
Class {
	#name : 'MCPServerLifecycleTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Server',
	#package : 'MCP-Tests',
	#tag : 'Server'
}

{ #category : 'tests' }
MCPServerLifecycleTest >> testAbruptClientDisconnectReleasesConnection [

	| clientStream server |
	server := MCPSocketSafeZnServer new.
	server
		bindingAddress: #[ 127 0 0 1 ];
		port: 0.
	[
		server start.
		self assert: (self waitUntil: [ server isListening ] forMilliseconds: 3000).
		clientStream := SocketStream openConnectionToHost: #[ 127 0 0 1 ] port: server port.
		self assert: (self waitUntil: [ server connections notEmpty ] forMilliseconds: 3000).
		clientStream close.
		clientStream := nil.
		self assert: (self waitUntil: [ server connections isEmpty ] forMilliseconds: 3000) ] ensure: [
			clientStream ifNotNil: [ clientStream close ].
			server stop: false ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testBindFailureDestroysTheSocketItCreated [

	| occupiedSocket server |
	occupiedSocket := ZnNetworkingUtils serverSocketOn: 0.
	server := MCPSocketRecordingTestServer new.
	[
		server port: occupiedSocket port.
		3 timesRepeat: [
				[ server initializeServerSocket ]
					on: SocketError
					do: [ :error | error return ] ].
		self assert: server createdSockets size equals: 3.
		self assert: (server createdSockets allSatisfy: [ :each | each isValid not ]) ] ensure: [
			server stop: false.
			occupiedSocket destroy ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testBindFailureIsRememberedUntilTheServerBinds [

	| occupiedSocket server |
	occupiedSocket := ZnNetworkingUtils serverSocketOn: 0.
	server := MCPSocketSafeZnServer new.
	[
		server port: occupiedSocket port.
		self assert: ([ server listenLoop ]
				 on: SocketError
				 do: [ false ]).
		self assert: server lastListenError isNotNil.
		occupiedSocket destroy.
		occupiedSocket := nil.
		server initializeServerSocket.
		self assert: server lastListenError isNil ] ensure: [
			server stop: false.
			occupiedSocket ifNotNil: [ :socket | socket destroy ] ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testBindSuccessKeepsTheSocketItCreated [

	| server |
	server := MCPSocketRecordingTestServer new.
	[
		server
			bindingAddress: #[ 127 0 0 1 ];
			port: 0.
		server initializeServerSocket.
		self assert: server createdSockets size equals: 1.
		self assert: server createdSockets first isValid.
		self deny: server port isZero ] ensure: [ server stop: false ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testMultipleServersCanListenOnDifferentPorts [

	| first second |
	first := self mcpWithoutObservabilityExport.
	second := self mcpWithoutObservabilityExport.
	[
		first
			port: 0;
			start.
		second
			port: 0;
			start.
		self assert: first isListening.
		self assert: second isListening.
		self deny: first port equals: second port ] ensure: [
			second stop.
			first stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testRetryDelayDoublesUpToItsMaximum [

	| server |
	server := MCPSocketSafeZnServer new.
	self assert: (server socketRestartDelayAfter: server initialSocketRestartDelayMilliseconds) equals: 500.
	self assert: (server socketRestartDelayAfter: 500) equals: 1000.
	self
		assert: (server socketRestartDelayAfter: server maximumSocketRestartDelayMilliseconds)
		equals: server maximumSocketRestartDelayMilliseconds
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testSocketSafeServerHandlesBindFailure [

	| occupiedSocket server |
	occupiedSocket := ZnNetworkingUtils serverSocketOn: 0.
	server := MCPSocketSafeZnServer new.
	[
		server port: occupiedSocket port.
		self assert: ([ server listenLoop ]
				 on: SocketError
				 do: [ false ]).
		self deny: server isListening ] ensure: [
			server stop: false.
			occupiedSocket destroy ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testSocketSafeServerRestartsAfterBindFailure [

	| occupiedSocket port server |
	occupiedSocket := ZnNetworkingUtils serverSocketOn: 0.
	port := occupiedSocket port.
	server := MCPSocketSafeZnServer new.
	[
		server port: port.
		server start.
		(Delay forMilliseconds: 100) wait.
		self deny: server isListening.
		occupiedSocket destroy.
		occupiedSocket := nil.
		self assert: (self waitUntil: [ server isListening ] forMilliseconds: 3000) ] ensure: [
			server stop: false.
			occupiedSocket ifNotNil: [ occupiedSocket destroy ] ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testSocketSafeServerRunsDeferredActionsAfterCurrentResponse [

	| actions ran server |
	ran := false.
	server := MCPSocketSafeZnServer new.
	actions := OrderedCollection new.
	MCPPostResponseActions value: actions during: [
			server deferAfterCurrentResponse: [ ran := true ].
			self deny: ran ].
	server runPostResponseActions: actions.
	self assert: ran.
	ran := false.
	server runPostResponseActions: actions.
	self deny: ran
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testSocketSafeServerRunsPostResponseActionsImmediatelyWithoutActiveQueue [

	| ran server |
	ran := false.
	server := MCPSocketSafeZnServer new.
	MCPPostResponseActions value: nil during: [ server deferAfterCurrentResponse: [ ran := true ] ].
	self assert: ran
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testSocketSafeServerSurvivesRepeatedStartStopCycles [

	| server |
	server := MCPSocketSafeZnServer new.
	server bindingAddress: #[ 127 0 0 1 ].
	[
		10 timesRepeat: [
				server port: 0.
				server start.
				self assert: (self waitUntil: [ server isListening ] forMilliseconds: 3000).
				server stop: false.
				self deny: server isRunning.
				self deny: server isListening.
				self assert: server connections isEmpty ] ] ensure: [ server stop: false ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testSocketSafeServerTreatsSocketErrorsAsConnectionTermination [

	| exceptionSet |
	exceptionSet := MCPSocketSafeZnServer new readRequestTerminationExceptionSet.
	self assert: (exceptionSet handles: SocketError new)
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStartRegistersServerForImageStartup [

	| port server |
	server := self mcpWithoutObservabilityExport.
	[
		server port: 0.
		server start.
		port := server port.
		self assert: (ZnServer managedServers anySatisfy: [ :each | each class = MCPSocketSafeZnServer and: [ each port = port ] ]).
		server stop.
		self deny: (ZnServer managedServers anySatisfy: [ :each | each class = MCPSocketSafeZnServer and: [ each port = port ] ]) ]
		ensure: [ server stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStoppingOneServerKeepsOtherListening [

	| first second |
	first := self mcpWithoutObservabilityExport.
	second := self mcpWithoutObservabilityExport.
	[
		first
			port: 0;
			start.
		second
			port: 0;
			start.
		first stop.
		self deny: first isListening.
		self assert: second isListening ] ensure: [
			second stop.
			first stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStoppingServerClosesActiveConnections [

	| clientStream server |
	server := MCPSocketSafeZnServer new.
	server
		bindingAddress: #[ 127 0 0 1 ];
		port: 0.
	[
		server start.
		self assert: (self waitUntil: [ server isListening ] forMilliseconds: 3000).
		clientStream := SocketStream openConnectionToHost: #[ 127 0 0 1 ] port: server port.
		self assert: (self waitUntil: [ server connections notEmpty ] forMilliseconds: 3000).
		server stop: false.
		self deny: server isRunning.
		self assert: server connections isEmpty ] ensure: [
			clientStream ifNotNil: [ clientStream close ].
			server stop: false ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStoppingServerStopsBindRetryLoop [

	| occupiedSocket port server |
	occupiedSocket := ZnNetworkingUtils serverSocketOn: 0.
	port := occupiedSocket port.
	server := MCPSocketSafeZnServer new.
	[
		server port: port.
		server start.
		(Delay forMilliseconds: 100) wait.
		self deny: server isListening.
		server stop: false.
		occupiedSocket destroy.
		occupiedSocket := nil.
		(Delay forMilliseconds: 500) wait.
		self deny: server isRunning.
		self deny: server isListening ] ensure: [
			server stop: false.
			occupiedSocket ifNotNil: [ occupiedSocket destroy ] ]
]

{ #category : 'private' }
MCPServerLifecycleTest >> waitUntil: conditionBlock forMilliseconds: milliseconds [

	| attempts delay |
	delay := Delay forMilliseconds: 50.
	attempts := milliseconds // 50 max: 1.
	attempts timesRepeat: [
			conditionBlock value ifTrue: [ ^ true ].
			delay wait ].
	^ conditionBlock value
]
