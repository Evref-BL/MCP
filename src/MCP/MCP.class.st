"
Top-level MCP server application object. MCP owns the registered tool instances, the HTTP server, and observability state. It exposes the core JSON-RPC MCP handlers, including initialization, tool listing, tool calls, ping, and empty resource listings. Tool calls are delegated to the matching MCPTool after request validation.
"
Class {
	#name : 'MCP',
	#superclass : 'Object',
	#instVars : [
		'server',
		'toolsList',
		'monitoring',
		'toolExposurePolicy'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'protocol' }
MCP class >> latestProtocolVersion [

	^ self supportedProtocolVersions last
]

{ #category : 'protocol' }
MCP class >> negotiatedProtocolVersionFor: requestedVersion [

	^ (self supportedProtocolVersions includes: requestedVersion)
		  ifTrue: [ requestedVersion ]
		  ifFalse: [ self latestProtocolVersion ]
]

{ #category : 'protocol' }
MCP class >> supportedProtocolVersions [

	^ #( '2025-03-26' '2025-06-18' '2025-11-25' )
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

{ #category : 'private - saving' }
MCP >> deferSaveImageAfterCurrentResponse [

	server deferAfterCurrentResponse: [ self saveImageSession ]
]

{ #category : 'private - start' }
MCP >> ensureServerIsListening [

	(self waitUntilListeningForMilliseconds: 1000) ifTrue: [ ^ self ].
	server stop.
	server start.
	(self waitUntilListeningForMilliseconds: 1000) ifTrue: [ ^ self ].
	Error signal: 'MCP server is not listening on port ' , self port asString
]

{ #category : 'private - tools' }
MCP >> executeTool: tool named: toolName withParams: arguments [

	| monitorRecord request result toolResult |
	monitorRecord := self monitoring
		                 recordToolCallStart: toolName
		                 input: arguments.
	^ [
		  request := tool requestFromToolCallArguments: arguments.
		  result := tool
			            executeWithRequest: request
			            usingPolicy: self toolExposurePolicy.
		  toolResult := result asMCPStructureCallToolResult.
		  self saveImageAfterSuccessfulTool: tool result: toolResult.
		  self monitoring
			  recordToolCallFinish: monitorRecord
			  result: toolResult
			  error: nil.
		  toolResult asJRPCJSON ]
		  on: Exception
		  do: [ :error |
				  | errorResult |
				  error mcpIsJRPCError ifTrue: [
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
				  errorResult asJRPCJSON ]
]

{ #category : 'accessing' }
MCP >> handlersCount [

	^ self server messageProcessor handlersCount
]

{ #category : 'initialization' }
MCP >> initialize [

	super initialize.
	self refreshToolsList.
	server := MCPHTTPServer new.
	server addHandlersFromPragmasIn: self.
	self monitoringExportDirectory:
		MCPMonitoringState defaultExportDirectory
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
MCP >> monitoringExportDirectory [

	^ self monitoring exportDirectory
]

{ #category : 'monitoring' }
MCP >> monitoringExportDirectory: aPath [

	self monitoring resourceMetadata: self monitoringResourceMetadata.
	self monitoring exportDirectory: aPath
]

{ #category : 'monitoring' }
MCP >> monitoringExportInstanceDirectory [

	^ self monitoring exportInstanceDirectory
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
MCP >> monitoringResourceMetadata [

	| metadata |
	metadata := self monitoring resourceMetadata copy.
	metadata
		at: #'pharo.majorVersion'
		put: PharoCompatibility currentMajorVersion.
	metadata at: #'mcp.port' put: self port.
	^ metadata
]

{ #category : 'monitoring' }
MCP >> monitoringStatusText [

	^ self monitoring statusText
]

{ #category : 'monitoring' }
MCP >> monitoringTraces [

	^ self monitoring traceRecords
]

{ #category : 'start' }
MCP >> onInitialize: protocolVersion capabilities: capabilities clientInfo: clientInfo websiteUrl: websiteUrl [

	<jrpc: #initialize>
	^ MCPStructureInitialize new
		  protocolVersion: (self class negotiatedProtocolVersionFor: protocolVersion);
		  capabilities: (MCPStructureCapabilities new tools: MCPStructureToolsCapabilities new);
		  metadata: self serverInfrastructureMetadata;
		  serverInfo: (MCPStructureServerInfo new
				   name: 'MCP Pharo';
				   title: 'The MCP server for Pharo';
				   version: '1.0.0';
				   description: 'a MCP server for Pharo';
				   websiteUrl: 'https://badetitou.fr';
				   icons: { (MCPStructureIcon pngIconNamed: #pharo) };
				   yourself)
]

{ #category : 'infrastructure metadata' }
MCP >> pharoRuntimeMetadata [

	^ {
		  (#runtimeVersion -> PharoCompatibility runtimeVersionString).
		  (#supportedMajorVersions -> self supportedPharoMajorVersions).
		  (#supportedLauncherVersions -> self supportedPharoLauncherVersions) }
		  asDictionary
]

{ #category : 'accessing' }
MCP >> port [

	^ self server port
]

{ #category : 'accessing' }
MCP >> port: aPortNumber [

	self server port: aPortNumber
]

{ #category : 'private - tools' }
MCP >> refreshToolsList [

	toolsList := MCPToolRegistry staticToolsDictionaryUsingPolicy:
		             self toolExposurePolicy.
	^ toolsList
]

{ #category : 'start' }
MCP >> restart [

	self stop.
	^ self start
]

{ #category : 'private - tools' }
MCP >> rpcCallToolCallWithParams: arguments [

	| callRequest callTool request targetTool |
	callTool := MCPToolRegistry
		            toolNamed: MCPToolCallTool toolName
		            ifAbsent: [
		            Error signal: 'tool_call is not registered.' ]
		            usingPolicy: self toolExposurePolicy.
	^ [
		  request := callTool requestFromToolCallArguments: arguments.
		  callRequest := callTool parsedRequestFromToolRequest: request.
		  callRequest toolName = callTool name ifTrue: [
			  Error signal: 'tool_call cannot call itself.' ].
		  targetTool := MCPToolRegistry
			                toolNamed: callRequest toolName
			                ifAbsent: [
			                Error signal:
				                'Unknown MCP tool: ' , callRequest toolName ]
			                usingPolicy: self toolExposurePolicy.
		  self
			  executeTool: targetTool
			  named: targetTool name
			  withParams: callRequest arguments ]
		  on: Exception
		  do: [ :error |
				  | errorResult |
				  error mcpIsJRPCError ifTrue: [ error pass ].
				  errorResult := callTool errorResultFor: error.
				  errorResult asJRPCJSON ]
]

{ #category : 'rpc' }
MCP >> rpcNotificationInitialized [

	<jrpc: #'notifications/initialized'>
	^ nil
]

{ #category : 'rpc' }
MCP >> rpcPing [

	<jrpc: #ping>
	^ Dictionary new
]

{ #category : 'rpc' }
MCP >> rpcResourcesList [

	<jrpc: #'resources/list'>
	^ { (#resource -> {  }) } asDictionary
]

{ #category : 'rpc' }
MCP >> rpcResourcesTemplateList [

	<jrpc: #'resources/templates/list'>
	^ { (#resourceTemplates -> {  }) } asDictionary
]

{ #category : 'rpc' }
MCP >> rpcToolCall: name withParams: arguments [

	<jrpc: #'tools/call'>
	toolsList
		at: name
		ifPresent: [ :tool |
				name = MCPToolCallTool toolName ifTrue: [
					^ self rpcCallToolCallWithParams: arguments ].
				^ self executeTool: tool named: name withParams: arguments ]
		ifAbsent: [ JRPCNonExistentHandler signal: name ]
]

{ #category : 'rpc' }
MCP >> rpcToolsList [

	<jrpc: #'tools/list'>
	self refreshToolsList.
	^ { (#tools -> toolsList values asArray) } asDictionary asJRPCJSON
]

{ #category : 'private - saving' }
MCP >> saveImageAfterSuccessfulTool: aTool result: aResult [

	aResult isError ifTrue: [ ^ self ].
	(aTool shouldSaveImageAfterSuccessfulExecutionForResult: aResult)
		ifTrue: [ self deferSaveImageAfterCurrentResponse ]
]

{ #category : 'private - saving' }
MCP >> saveImageSession [
	"MCP autosave must not run SessionManager shutdown/startup hooks: Zinc stops managed servers during cycle, breaking active Streamable HTTP transports."

	| snapshotOperation |
	snapshotOperation := SnapshotOperation
		save: true
		andQuit: false
		withSessionManager: SessionManager default.
	snapshotOperation doSnapshot.
	^ snapshotOperation isImageStarting
]

{ #category : 'accessing' }
MCP >> server [

	^ server
]

{ #category : 'infrastructure metadata' }
MCP >> serverInfrastructureMetadata [

	^ { (#'io.github.evref-bl/pharo' -> self pharoRuntimeMetadata) }
		  asDictionary
]

{ #category : 'accessing' }
MCP >> sortedTools [

	^ self toolsList values asSortedCollection: [ :left :right |
		  left name <= right name ]
]

{ #category : 'start' }
MCP >> start [

	self refreshToolsList.
	server addHandlersFromPragmasIn: self.
	server start.
	self ensureServerIsListening
]

{ #category : 'configuration' }
MCP >> staticToolNames [

	^ self toolExposurePolicy staticToolNames
]

{ #category : 'configuration' }
MCP >> staticToolNames: aCollection [

	self toolExposurePolicy:
		(MCPToolExposurePolicy staticToolNames: aCollection).
	^ self
]

{ #category : 'start' }
MCP >> stop [

	server stop
]

{ #category : 'infrastructure metadata' }
MCP >> supportedPharoLauncherVersions [

	^ #( '120' '130' '140' )
]

{ #category : 'infrastructure metadata' }
MCP >> supportedPharoMajorVersions [

	^ #( 12 13 14 )
]

{ #category : 'accessing' }
MCP >> toolExposurePolicy [

	^ toolExposurePolicy ifNil: [
		  toolExposurePolicy := MCPToolExposurePolicy default ]
]

{ #category : 'accessing' }
MCP >> toolExposurePolicy: aToolExposurePolicy [

	toolExposurePolicy := aToolExposurePolicy ifNil: [
		                      MCPToolExposurePolicy default ].
	self refreshToolsList.
	^ toolExposurePolicy
]

{ #category : 'accessing' }
MCP >> toolsList [

	^ toolsList
]

{ #category : 'accessing' }
MCP >> toolsList: aToolsList [

	^ toolsList := aToolsList
]

{ #category : 'private - start' }
MCP >> waitUntilListeningForMilliseconds: milliseconds [

	| delay attempts |
	delay := Delay forMilliseconds: 50.
	attempts := milliseconds // 50 max: 1.
	attempts timesRepeat: [
		self isListening ifTrue: [ ^ true ].
		delay wait ].
	^ self isListening
]
