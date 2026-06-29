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
MCPServerLifecycleTest >> testSocketSafeServerTreatsSocketErrorsAsConnectionTermination [

	| exceptionSet |
	exceptionSet := MCPSocketSafeZnServer new readRequestTerminationExceptionSet.
	self assert: (exceptionSet handles: SocketError new)
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStartEnablesAutoStartOnAssignedPort [

	| server |
	server := self mcpWithoutObservabilityExport.
	[
		server port: 0.
		server start.
		self assert: server isListening.
		self assert: MCP autoStartEnabled.
		self assert: MCP autoStartPort equals: server port.
		self assert: MCP default == server ] ensure: [ server stop ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStartUpRebuildsAutoStartServer [

	| port restartedServer server |
	server := self mcpWithoutObservabilityExport.
	[
		server port: 0.
		server start.
		port := server port.
		server stopForImageShutdown.
		self deny: server isListening.
		MCP startUp: true.
		restartedServer := MCP default.
		self deny: restartedServer == server.
		self assert: restartedServer port equals: port.
		self assert: restartedServer isListening.
		self assert: MCP autoStartEnabled ] ensure: [
		MCP autoStartEnabled ifTrue: [ MCP default stop ].
		server isListening ifTrue: [ server stop ] ]
]

{ #category : 'tests' }
MCPServerLifecycleTest >> testStopDisablesAutoStart [

	| server |
	server := self mcpWithoutObservabilityExport.
	[
		server port: 0.
		server start.
		self assert: MCP autoStartEnabled.
		server stop.
		self deny: MCP autoStartEnabled.
		MCP startUp: true.
		self deny: server isListening ] ensure: [ server stop ]
]
