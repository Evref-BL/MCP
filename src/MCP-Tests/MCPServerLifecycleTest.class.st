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
MCPServerLifecycleTest >> testStartUpRestartsAutoStartServer [

	| port server |
	server := self mcpWithoutObservabilityExport.
	[
		server port: 0.
		server start.
		port := server port.
		server stopForImageShutdown.
		self deny: server isListening.
		MCP startUp: true.
		self assert: server port equals: port.
		self assert: server isListening.
		self assert: MCP autoStartEnabled ] ensure: [ server stop ]
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
