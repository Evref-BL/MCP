"
Top-level MCP server application object.

MCP owns the registered tool instances, the HTTP server, and optional observability state. It exposes the core JSON-RPC MCP handlers, including initialization, tool listing, tool calls, ping, and empty resource listings. Tool calls are delegated to the matching MCPTool after request validation.
"
Class {
	#name : 'MCP',
	#superclass : 'Object',
	#instVars : [
		'server',
		'toolsList',
		'monitoring'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'scripts' }
MCP class >> openToolCatalog [

	<script>
	^ MCPToolsCatalogPresenter open
]

{ #category : 'monitoring' }
MCP >> clearMonitoring [

	self monitoring clear
]

{ #category : 'configuration' }
MCP >> configurePort: aPortNumber debugMode: aBoolean [

	| currentPort wasRunning |
	currentPort := self port.
	wasRunning := self isRunning.

	wasRunning ifFalse: [
		self port: aPortNumber.
		self debugMode: aBoolean.
		^ self ].

	currentPort = aPortNumber ifTrue: [
		self debugMode: aBoolean.
		^ self ].

	self stop.

	[
	self port: aPortNumber.
	self debugMode: aBoolean.
	self start ]
		on: Error
		do: [ :error |
			self port: currentPort.
			self debugMode: aBoolean.
			self start.
			error pass ]
]

{ #category : 'accessing' }
MCP >> debugMode [

	^ self server messageProcessor debugMode
]

{ #category : 'accessing' }
MCP >> debugMode: aBoolean [

	self server debugMode: aBoolean.
	self server messageProcessor debugMode: aBoolean
]

{ #category : 'accessing' }
MCP >> handlersCount [

	^ self server messageProcessor handlersCount
]

{ #category : 'initialization' }
MCP >> initialize [

	super initialize.
	toolsList := Dictionary new.
	MCPTool concreteSubclasses do: [ :toolClass |
		| tool |
		tool := toolClass new.
		toolsList at: tool name put: tool ].
	server := MCPHTTPServer new.
	server addHandlersFromPragmasIn: self
]

{ #category : 'testing' }
MCP >> isListening [

	^ self server isListening
]

{ #category : 'testing' }
MCP >> isRunning [

	^ self server isRunning
]

{ #category : 'accessing' }
MCP >> localUrlString [

	^ self server localUrl asString
]

{ #category : 'accessing' }
MCP >> monitoring [

	^ monitoring ifNil: [ monitoring := MCPMonitoringState new ]
]

{ #category : 'monitoring' }
MCP >> monitoringEnabled [

	^ self monitoring enabled
]

{ #category : 'monitoring' }
MCP >> monitoringEnabled: aBoolean [

	self monitoring enabled: aBoolean
]

{ #category : 'monitoring' }
MCP >> monitoringLogs [

	^ self monitoring logs
]

{ #category : 'monitoring' }
MCP >> monitoringMetrics [

	^ self monitoring metrics
]

{ #category : 'monitoring' }
MCP >> monitoringRecentCalls [

	^ self monitoring recentCallRecords
]

{ #category : 'monitoring' }
MCP >> monitoringStatusText [

	^ self monitoring statusText
]

{ #category : 'start' }
MCP >> onInitialize: protocolVersion capabilities: capabilities clientInfo: clientInfo websiteUrl: websiteUrl [

	<jrpc: #initialize>
	^ MCPStructureInitialize new
		  protocolVersion: '2025-11-25';
		  capabilities:
			  (MCPStructureCapabilities new tools:
					   MCPStructureToolsCapabilities new);
		  serverInfo: (MCPStructureServerInfo new
				   name: 'MCP Pharo';
				   title: 'The MCP server for Pharo';
				   version: '1.0.0';
				   description: 'a MCP server for Pharo';
				   websiteUrl: 'https://badetitou.fr';
				   icons: { (MCPStructureIcon pngIconNamed: #pharo) };
				   yourself)
]

{ #category : 'accessing' }
MCP >> port [

	^ self server port
]

{ #category : 'accessing' }
MCP >> port: aPortNumber [

	self server port: aPortNumber
]

{ #category : 'start' }
MCP >> restart [

	self stop.
	^ self start
]

{ #category : 'as yet unclassified' }
MCP >> rpcNotificationInitialized [

	<jrpc: #'notifications/initialized'>
	^ nil
]

{ #category : 'as yet unclassified' }
MCP >> rpcPing [

	<jrpc: #ping>
	^ Dictionary new
]

{ #category : 'as yet unclassified' }
MCP >> rpcResourcesList [

	<jrpc: #'resources/list'>
	^ { (#resource -> {  }) } asDictionary
]

{ #category : 'as yet unclassified' }
MCP >> rpcResourcesTemplateList [

	<jrpc: #'resources/templates/list'>
	^ { (#resourceTemplates -> {  }) } asDictionary
]

{ #category : 'as yet unclassified' }
MCP >> rpcToolCall: name withParams: arguments [

	<jrpc: #'tools/call'>
	toolsList
		at: name
		ifPresent: [ :tool |
			| monitorRecord request result toolResult |
			monitorRecord := self monitoring recordToolCallStart: name.
			^ [
			  request := tool requestFromToolCallArguments: arguments.
			  result := tool executeWithRequest: request.
			  toolResult := (result isKindOf: MCPStructureCallToolResult)
				                ifTrue: [ result ]
				                ifFalse: [
				                MCPStructureCallToolResult content: result ].
			  self saveImageAfterSuccessfulTool: tool result: toolResult.
			  self monitoring
				  recordToolCallFinish: monitorRecord
				  result: toolResult
				  error: nil.
			  toolResult asJRPCJSON ]
				  on: Error
				  do: [ :error |
					  | errorResult |
					  (error isKindOf: JRPCError) ifTrue: [
						  self monitoring
							  recordToolCallFinish: monitorRecord
							  result: nil
							  error: error.
						  error pass ].
					  errorResult := tool errorResultFor: error.
					  self monitoring
						  recordToolCallFinish: monitorRecord
						  result: errorResult
						  error: error.
					  errorResult asJRPCJSON ] ]
		ifAbsent: [ JRPCNonExistentHandler signal: name ]
]

{ #category : 'as yet unclassified' }
MCP >> rpcToolsList [

	<jrpc: #'tools/list'>
	^ { (#tools -> toolsList values asArray) } asDictionary asJRPCJSON
]

{ #category : 'private - saving' }
MCP >> saveImageAfterSuccessfulTool: aTool result: aResult [

	((aTool shouldSaveImageAfterSuccessfulExecutionForResult: aResult)
		 and: [ aResult isError not ]) ifTrue: [ self saveImageSession ]
]

{ #category : 'private - saving' }
MCP >> saveImageSession [

	^ Smalltalk saveSession
]

{ #category : 'accessing' }
MCP >> server [

	^ server
]

{ #category : 'accessing' }
MCP >> sortedTools [

	^ self toolsList values asSortedCollection: [ :left :right |
		  left name <= right name ]
]

{ #category : 'start' }
MCP >> start [

	server start.
	server addHandlersFromPragmasIn: self
]

{ #category : 'accessing' }
MCP >> stop [

	server stop
]

{ #category : 'accessing' }
MCP >> toolsList [

	^ toolsList
]

{ #category : 'accessing' }
MCP >> toolsList: aToolsList [

	^ toolsList := aToolsList
]
