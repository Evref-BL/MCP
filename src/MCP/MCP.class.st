"
Top-level MCP server application object. MCP owns one MCPToolRegistry, the HTTP server, and observability state. The registry owns registered tool instances and their exposure policy. MCP exposes the core JSON-RPC handlers, including initialization, tool listing, tool calls, ping, and empty resource listings. Tool calls are delegated to the matching MCPTool after request validation.

The registry is the source of truth for registered tools. The toolsList instance variable caches the current tools/list static tool surface as a dictionary keyed by tool name.

Adding new tools to the server (its `registry`) can be done:
- call `mcp registerToolClass: MyToolClass` before starting the server;
- (for several tool classes) call `mcp registerToolClasses: { MyToolClass. MyOtherToolClass }`;
- for automatic opt-in: override `MyToolClass class >> shouldAutoRegister` to return `true`.
"
Class {
	#name : 'MCP',
	#superclass : 'Object',
	#instVars : [
		'server',
		'toolsList',
		'monitoring',
		'toolRegistry',
		'toolResponseFields'
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

{ #category : 'private - tools' }
MCP >> dispatchToolCallWith: callTool arguments: arguments monitorRecord: monitorRecord [

	| callRequest request targetResponse targetTool wrapperResult |
	request := callTool requestFromToolCallArguments: arguments.
	callRequest := callTool parsedRequestFromToolRequest: request.
	self validateToolCallRequest: callRequest wrapperTool: callTool.
	targetTool := self targetToolForCallRequest: callRequest.
	targetResponse := self
		                  executeTool: targetTool
		                  named: targetTool name
		                  withParams: callRequest arguments
		                  dispatchPath: 'via_tool_call'.
	wrapperResult := self toolCallWrapperResultFor: callTool request: callRequest.
	self finishToolCallWrapper: monitorRecord result: wrapperResult.
	^ targetResponse
]

{ #category : 'monitoring' }
MCP >> ensureConcreteMonitoring [

	self monitoring isNoop ifTrue: [ monitoring := self newMonitoringState ].
	^ self monitoring
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

	^ self
		  executeTool: tool
		  named: toolName
		  withParams: arguments
		  dispatchPath: 'direct'
]

{ #category : 'private - tools' }
MCP >> executeTool: tool named: toolName withParams: arguments dispatchPath: dispatchPath [

	| monitorRecord request result toolResult |
	monitorRecord := self monitoring
		                 recordToolCallStart: toolName
		                 input: arguments
		                 dispatchPath: dispatchPath
		                 context: Dictionary new.
	^ [
		  request := tool requestFromToolCallArguments: arguments.
		  result := tool executeWithRequest: request.
		  toolResult := result asMCPStructureCallToolResult.
		  self saveImageAfterSuccessfulTool: tool result: toolResult.
		  self monitoring recordToolCallFinish: monitorRecord result: toolResult error: nil.
		  toolResult asJRPCJSONForResponseFields: self toolResponseFields ]
		  on: Exception
		  do: [ :error |
				  | errorResult |
				  error mcpIsJRPCError ifTrue: [
						  self monitoring recordToolCallFinish: monitorRecord result: nil error: error.
						  error pass ].
				  errorResult := tool errorResultFor: error.
				  self monitoring recordToolCallFinish: monitorRecord result: errorResult error: error.
				  errorResult asJRPCJSONForResponseFields: self toolResponseFields ]
]

{ #category : 'private - tools' }
MCP >> finishToolCallWrapper: monitorRecord result: wrapperResult [

	self monitoring recordToolCallFinish: monitorRecord result: wrapperResult asMCPStructureCallToolResult error: nil
]

{ #category : 'private - tools' }
MCP >> handleToolCallWrapperError: error tool: callTool monitorRecord: monitorRecord [

	| errorResult |
	error mcpIsJRPCError ifTrue: [
			self monitoring recordToolCallFinish: monitorRecord result: nil error: error.
			error pass ].
	errorResult := callTool errorResultFor: error.
	self monitoring recordToolCallFinish: monitorRecord result: errorResult error: error.
	^ errorResult asJRPCJSONForResponseFields: self toolResponseFields
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
	monitoring := MCPNoopObservabilityBackend new
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

	^ monitoring ifNil: [ monitoring := MCPNoopObservabilityBackend new ]
]

{ #category : 'accessing' }
MCP >> monitoring: anObservabilityBackend [

	monitoring := anObservabilityBackend
]

{ #category : 'monitoring' }
MCP >> monitoringEnabled [

	^ self monitoring enabled
]

{ #category : 'monitoring' }
MCP >> monitoringEnabled: aBoolean [

	aBoolean
		ifTrue: [ self ensureConcreteMonitoring enabled: true ]
		ifFalse: [ monitoring := MCPNoopObservabilityBackend new ]
]

{ #category : 'monitoring' }
MCP >> monitoringExportDirectory [

	^ self monitoring exportDirectory
]

{ #category : 'monitoring' }
MCP >> monitoringExportDirectory: aPath [

	| concreteMonitoring |
	concreteMonitoring := self ensureConcreteMonitoring.
	concreteMonitoring resourceMetadata: self monitoringResourceMetadata.
	concreteMonitoring exportDirectory: aPath
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
	metadata at: #'pharo.majorVersion' put: PharoCompatibility currentMajorVersion.
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

{ #category : 'monitoring' }
MCP >> newMonitoringState [

	^ MCPMonitoringState new
		  resourceMetadata: self monitoringResourceMetadata;
		  exportDirectory: MCPMonitoringState defaultExportDirectory;
		  yourself
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
		  (#supportedLauncherVersions -> self supportedPharoLauncherVersions) } asDictionary
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
MCP >> recordToolCallWrapperStartFor: callTool arguments: arguments [

	^ self monitoring
		  recordToolCallStart: callTool name
		  input: arguments
		  dispatchPath: 'direct'
		  context: Dictionary new
]

{ #category : 'private - tools' }
MCP >> refreshToolsList [
	"Refresh the cached tools/list response surface from the registry's current static tools."

	toolsList := self toolRegistry staticToolsDictionary.
	^ toolsList
]

{ #category : 'configuration' }
MCP >> registerTool: aTool [

	| registration |
	registration := self toolRegistry registerTool: aTool.
	self refreshToolsList.
	^ registration
]

{ #category : 'configuration' }
MCP >> registerToolClass: aToolClass [

	^ self registerTool: (aToolClass newForRegistry: self toolRegistry)
]

{ #category : 'configuration' }
MCP >> registerToolClasses: toolClasses [

	^ toolClasses collect: [ :eachToolClass | self registerToolClass: eachToolClass ]
]

{ #category : 'start' }
MCP >> restart [

	self stop.
	^ self start
]

{ #category : 'private - tools' }
MCP >> rpcCallToolCallWithParams: arguments [

	| callTool monitorRecord |
	callTool := self toolCallTool.
	monitorRecord := self recordToolCallWrapperStartFor: callTool arguments: arguments.
	^ [ self dispatchToolCallWith: callTool arguments: arguments monitorRecord: monitorRecord ]
		  on: Exception
		  do: [ :error | self handleToolCallWrapperError: error tool: callTool monitorRecord: monitorRecord ]
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
				name = MCPToolCallTool toolName ifTrue: [ ^ self rpcCallToolCallWithParams: arguments ].
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
	(aTool shouldSaveImageAfterSuccessfulExecutionForResult: aResult) ifTrue: [ self deferSaveImageAfterCurrentResponse ]
]

{ #category : 'private - saving' }
MCP >> saveImageSession [
	"MCP autosave must not run SessionManager shutdown/startup hooks: Zinc stops managed servers during cycle, breaking active Streamable HTTP transports."

	| snapshotOperation |
	snapshotOperation := SnapshotOperation save: true andQuit: false withSessionManager: SessionManager default.
	snapshotOperation doSnapshot.
	^ snapshotOperation isImageStarting
]

{ #category : 'accessing' }
MCP >> server [

	^ server
]

{ #category : 'infrastructure metadata' }
MCP >> serverInfrastructureMetadata [

	^ { (#'io.github.evref-bl/pharo' -> self pharoRuntimeMetadata) } asDictionary
]

{ #category : 'accessing' }
MCP >> sortedTools [

	^ self toolsList values asSortedCollection: [ :left :right | left name <= right name ]
]

{ #category : 'start' }
MCP >> start [

	self refreshToolsList.
	server addHandlersFromPragmasIn: self.
	server start.
	self ensureServerIsListening.
	self monitoring recordSessionStartFor: self
]

{ #category : 'configuration' }
MCP >> staticToolNames [

	^ self toolRegistry staticToolNames
]

{ #category : 'configuration' }
MCP >> staticToolNames: aCollection [

	self toolRegistry staticToolNames: aCollection.
	self refreshToolsList
]

{ #category : 'start' }
MCP >> stop [

	[ server stop ] ensure: [ self monitoring shutdown ]
]

{ #category : 'infrastructure metadata' }
MCP >> supportedPharoLauncherVersions [

	^ #( '120' '130' '140' )
]

{ #category : 'infrastructure metadata' }
MCP >> supportedPharoMajorVersions [

	^ #( 12 13 14 )
]

{ #category : 'private - tools' }
MCP >> targetToolForCallRequest: callRequest [

	^ self toolRegistry toolNamed: callRequest toolName ifAbsent: [ Error signal: 'Unknown MCP tool: ' , callRequest toolName ]
]

{ #category : 'private - tools' }
MCP >> toolCallTool [

	^ self toolRegistry toolNamed: MCPToolCallTool toolName ifAbsent: [ Error signal: 'tool_call is not registered.' ]
]

{ #category : 'private - tools' }
MCP >> toolCallWrapperResultFor: callTool request: callRequest [

	^ callTool
		  successResultText: 'Dispatched tool ' , callRequest toolName
		  data: { (#toolName -> callRequest toolName) } asDictionary
]

{ #category : 'accessing' }
MCP >> toolExposurePolicy [

	^ self toolRegistry exposurePolicy
]

{ #category : 'accessing' }
MCP >> toolExposurePolicy: aToolExposurePolicy [

	self toolRegistry exposurePolicy: (aToolExposurePolicy ifNil: [ MCPToolExposurePolicy default ]).
	self refreshToolsList
]

{ #category : 'accessing' }
MCP >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := MCPToolRegistry new ]
]

{ #category : 'accessing' }
MCP >> toolRegistry: aToolRegistry [

	toolRegistry := aToolRegistry ifNil: [ MCPToolRegistry new ].
	self refreshToolsList
]

{ #category : 'configuration' }
MCP >> toolResponseFields [

	^ toolResponseFields ifNil: [ toolResponseFields := #content ]
]

{ #category : 'configuration' }
MCP >> toolResponseFields: aSymbolOrString [

	| normalized |
	normalized := aSymbolOrString asSymbol.
	(self validToolResponseFields includes: normalized) ifFalse: [
		Error signal: 'Unsupported MCP tool response fields: ' , aSymbolOrString asString ].
	toolResponseFields := normalized
]

{ #category : 'accessing' }
MCP >> toolsList [
	"Answer the cached tools/list static tool surface. The registry remains the source of truth for registered tools."

	^ toolsList
]

{ #category : 'accessing' }
MCP >> toolsList: aToolsList [
	"Replace the cached tools/list surface. Intended for tests and controlled presenter setup; normal registration should go through the registry-facing MCP configuration API."

	^ toolsList := aToolsList
]

{ #category : 'configuration' }
MCP >> unregisterToolNamed: aToolName [

	self toolRegistry unregisterToolNamed: aToolName.
	self refreshToolsList
]

{ #category : 'configuration' }
MCP >> useContentAndStructuredContentToolResponses [

	self toolResponseFields: #both
]

{ #category : 'configuration' }
MCP >> useContentOnlyToolResponses [

	self toolResponseFields: #content
]

{ #category : 'configuration' }
MCP >> useStructuredContentOnlyToolResponses [

	self toolResponseFields: #structuredContent
]

{ #category : 'configuration' }
MCP >> validToolResponseFields [

	^ #( content structuredContent both )
]

{ #category : 'private - tools' }
MCP >> validateToolCallRequest: callRequest wrapperTool: callTool [

	callRequest toolName = callTool name ifTrue: [ Error signal: 'tool_call cannot call itself.' ]
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
