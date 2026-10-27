"
Tests MCP HTTP server lifecycle behavior that must survive image save and restart boundaries.
"
Class {
	#name : 'MCPServerLifecycleTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPServerLifecycleTest >> aFreePort [
	"A port nothing holds, found by holding one for as long as it takes to read its number."

	| socket port |
	socket := ZnNetworkingUtils serverSocketOn: 0.
	port := socket port.
	socket destroy.
	^ port
]

{ #category : 'private' }
MCPServerLifecycleTest >> stopAndForget: anMCP [
	"A server made by startOnPort: has the observability export a plain MCP has, so what it wrote goes with it."

	| directory |
	anMCP ifNil: [ ^ self ].
	directory := [ anMCP observabilityExportInstanceDirectory ]
		             on: Error
		             do: [ :error | nil ].
	[ anMCP stop ]
		on: Error
		do: [ :error | error return ].
	directory ifNotNil: [ directory asFileReference exists ifTrue: [ directory asFileReference deleteAll ] ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testAPortHeldByAnotherServerIsNamedInTheError [
	"The socket error says the address is in use; it does not say that the image itself is using it."

	| holder blocked message |
	holder := self mcpWithoutObservabilityExport
		          port: 0;
		          start;
		          yourself.
	blocked := self mcpWithoutObservabilityExport
		           port: holder port;
		           yourself.
	[
		message := [
			           blocked start.
			           nil ]
			           on: Error
			           do: [ :error | error messageText ].
		self assert: message isNotNil description: 'Starting on a held port should fail.'.
		self assert: (message includesSubstring: 'Another MCP in this image is listening on that port').
		self assert: (message includesSubstring: holder port asString) ] ensure: [
			blocked stop.
			holder stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testAStartedServerIsListedEvenWhenNothingHoldsIt [
	"A started server is held by its own process and socket, which is what turns a port held by a forgotten server into something visible."

	| before appeared |
	before := MCP allServers.

	(self mcpWithoutObservabilityExport port: 0) start.

	appeared := MCP allServers reject: [ :each | before identityIncludes: each ].
	[
		self assert: appeared size equals: 1.
		self assert: appeared first isRunning.
		self assert: appeared first isListening ] ensure: [ appeared do: [ :each | each stop ] ]
]

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
MCPServerLifecycleTest >> testServersAreListedByPort [

	| created ports |
	created := (1 to: 2) collect: [ :ignored |
			           self mcpWithoutObservabilityExport
				           port: 0;
				           yourself ].
	[
		created do: [ :each | each start ].
		ports := (MCP allServers collect: [ :each | each port ]) asArray.
		self assert: ports equals: ports sorted ] ensure: [ created do: [ :each | each stop ] ]
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
MCPServerLifecycleTest >> testStartOnPortAnswersTheServerAlreadyThere [
	"Two servers cannot share a port, so asking for a port is asking for the server on it."

	| running found |
	running := self mcpWithoutObservabilityExport
		           port: 0;
		           start;
		           yourself.
	[
		found := MCP startOnPort: running port.
		self assert: found == running.
		self assert: found isListening ] ensure: [ running stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStartOnPortMakesOneWhenTheImageHasNoneThere [

	| port made |
	port := self aFreePort.
	made := nil.
	[
		made := MCP startOnPort: port.
		self assert: made port equals: port.
		self assert: made isListening ] ensure: [ self stopAndForget: made ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStartOnPortStartsAServerItFindsStopped [

	| stopped found |
	stopped := self mcpWithoutObservabilityExport
		           port: 0;
		           start;
		           yourself.
	stopped stop.
	[
		found := MCP startOnPort: stopped port.
		self assert: found == stopped.
		self assert: found isRunning ] ensure: [ stopped stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStartOnPortZeroMakesANewServerEveryTime [
	"Port 0 asks for any free port, so it names no particular server."

	| first second |
	first := nil.
	second := nil.
	[
		first := MCP startOnPort: 0.
		second := MCP startOnPort: 0.
		self deny: first == second.
		self deny: first port = second port ] ensure: [
			self stopAndForget: first.
			self stopAndForget: second ]
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

{ #category : 'tests' }
MCPServerLifecycleTest >> testUnstartedServersNobodyHoldsAreNotListed [
	"The heap is the registry. A class-side collection would answer all five forever, and a weak one would answer them until they happened to be collected."

	| listed |
	listed := MCP allServers size.

	5 timesRepeat: [ self mcpWithoutObservabilityExport port: 1234 ].

	self assert: MCP allServers size equals: listed
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
