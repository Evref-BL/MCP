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
MCPServerLifecycleTest >> testMultipleServersCanListenOnDifferentPorts [

	| first second |
	first := self mcpWithoutObservabilityExport.
	second := self mcpWithoutObservabilityExport.
	[
		first port: 0; start.
		second port: 0; start.
		self assert: first isListening.
		self assert: second isListening.
		self deny: first port equals: second port ] ensure: [
		second stop.
		first stop ]
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
		self assert: (self
				 waitUntil: [ server isListening ]
				 forMilliseconds: 3000) ] ensure: [
		server stop: false.
		occupiedSocket ifNotNil: [ occupiedSocket destroy ] ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testSocketSafeServerRunsDeferredActionsAfterCurrentResponse [

	| ran server |
	ran := false.
	server := MCPSocketSafeZnServer new.
	server deferAfterCurrentResponse: [ ran := true ].
	self deny: ran.
	server runPostResponseActionsForCurrentProcess.
	self assert: ran.
	ran := false.
	server runPostResponseActionsForCurrentProcess.
	self deny: ran
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
		self assert: (ZnServer managedServers anySatisfy: [ :each |
			each class = MCPSocketSafeZnServer and: [ each port = port ] ]).
		server stop.
		self deny: (ZnServer managedServers anySatisfy: [ :each |
			each class = MCPSocketSafeZnServer and: [ each port = port ] ]) ] ensure: [
		server stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStoppingOneServerKeepsOtherListening [

	| first second |
	first := self mcpWithoutObservabilityExport.
	second := self mcpWithoutObservabilityExport.
	[
		first port: 0; start.
		second port: 0; start.
		first stop.
		self deny: first isListening.
		self assert: second isListening ] ensure: [
		second stop.
		first stop ]
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
