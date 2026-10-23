"
Top-level MCP server application object. MCP owns one MCPToolRegistry, the HTTP server, and observability state. The registry owns registered tool instances and their exposure policy. MCP exposes the core JSON-RPC handlers, including initialization, tool listing, tool calls, ping, and empty resource listings. Tool calls are delegated to the matching MCPTool after request validation.

The registry is the source of truth for registered tools. The toolsList instance variable caches the advertised surface as a dictionary keyed by tool name.

Two words govern the tool surface. A *registered* tool is in the catalog and reachable through tool_search, tool_get and tool_call. An *advertised* tool is also in tools/list.

- `mcp addTool: MyToolClass` and `mcp addTools: { A. B }` register tools, as classes or ready instances;
- `mcp removeTool: 'image_evaluate'` takes one back out;
- `mcp onlyTools: { A. B }` replaces the catalog with exactly those;
- `mcp advertiseTools: { A. 'class_search' }` chooses what tools/list shows, registering anything not yet in the catalog;
- `mcp advertiseAllTools` and `mcp advertiseToolDefaults` are the other two advertising states;
- for automatic opt-in, override `MyToolClass class >> shouldAutoRegister` to return `true`.
"
Class {
	#name : 'MCP',
	#superclass : 'Object',
	#instVars : [
		'server',
		'toolsList',
		'observability',
		'toolRegistry',
		'resourceRegistry',
		'promptRegistry',
		'toolResponseFields'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'protocol' }
MCP class >> catalogCacheMilliseconds [
	"How long a catalog answer stays good. The catalogs only move when code is loaded or removed, and list_changed invalidates a client's copy the moment they do, so a minute costs a non-listening client at most a minute of staleness and saves everyone else the refetches."

	^ 60000
]

{ #category : 'protocol' }
MCP class >> resourceContentsCacheMilliseconds [
	"Shorter than a catalog, because nothing announces that a resource's contents changed. Until a resource can signal that, the only protection a client has is a short freshness window."

	^ 5000
]

{ #category : 'protocol' }
MCP class >> isModernRequest: someParams [
	"A modern request declares a modern protocol version in _meta. A legacy one opens with initialize and says nothing per request; one that declares a legacy version is answered the legacy way, which is what it named."

	| declared |
	declared := self requestedProtocolVersionIn: someParams.
	declared ifNil: [ ^ false ].
	^ self modernProtocolVersions includes: declared
]

{ #category : 'protocol' }
MCP class >> modernProtocolVersionKey [

	^ 'io.modelcontextprotocol/protocolVersion'
]

{ #category : 'protocol' }
MCP class >> requestedProtocolVersionIn: someParams [
	"Answer the protocol version a request declares for itself, or nil when it declares none."

	| meta |
	someParams isDictionary ifFalse: [ ^ nil ].
	meta := someParams at: '_meta' ifAbsent: [ ^ nil ].
	meta isDictionary ifFalse: [ ^ nil ].
	^ meta at: self modernProtocolVersionKey ifAbsent: [ nil ]
]

{ #category : 'protocol' }
MCP class >> latestLegacyProtocolVersion [

	^ self legacyProtocolVersions last
]

{ #category : 'protocol' }
MCP class >> latestProtocolVersion [

	^ self supportedProtocolVersions last
]

{ #category : 'protocol' }
MCP class >> legacyProtocolVersions [
	"The revisions that open with an initialize handshake and carry a session."

	^ #( '2025-03-26' '2025-06-18' '2025-11-25' )
]

{ #category : 'protocol' }
MCP class >> modernProtocolVersions [
	"The revisions that declare their version on every request and keep no session."

	^ #( '2026-07-28' )
]

{ #category : 'protocol' }
MCP class >> negotiatedProtocolVersionFor: requestedVersion [
	"initialize is how a legacy client opens, so it negotiates among legacy versions only. Answering a modern version here would name one the client cannot speak, since the modern era has no handshake to answer with."

	^ (self legacyProtocolVersions includes: requestedVersion)
		  ifTrue: [ requestedVersion ]
		  ifFalse: [ self latestLegacyProtocolVersion ]
]

{ #category : 'instance creation' }
MCP class >> onlyTools: toolsOrToolClasses [

	^ self new
		  onlyTools: toolsOrToolClasses;
		  yourself
]

{ #category : 'protocol' }
MCP class >> supportedProtocolVersions [

	^ self legacyProtocolVersions , self modernProtocolVersions
]

{ #category : 'observability' }
MCP >> clearObservability [

	self observability clear
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

{ #category : 'private - tools' }
MCP >> dispatchToolCallWith: callTool arguments: arguments observabilityRecord: observabilityRecord [

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
	self finishToolCallWrapper: observabilityRecord result: wrapperResult.
	^ targetResponse
]

{ #category : 'observability' }
MCP >> ensureLocalObservabilityBackend [

	self observability isNoop ifTrue: [ observability := self newLocalObservabilityBackend ].
	^ self observability
]

{ #category : 'private - start' }
MCP >> ensureServerIsListening [

	(self waitUntilListeningForMilliseconds: 1000) ifTrue: [ ^ self ].
	server stop.
	server start.
	(self waitUntilListeningForMilliseconds: 1000) ifTrue: [ ^ self ].
	Error signal: 'MCP server is not listening on port ' , self port asString
		, (server lastListenError ifNil: [ '' ] ifNotNil: [ :reason | ': ' , reason ])
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

	| observabilityRecord request result toolResult |
	observabilityRecord := nil.
	tool shouldRecordObservability ifTrue: [
			observabilityRecord := self observability
				                       recordToolCallStart: toolName
				                       input: arguments
				                       dispatchPath: dispatchPath
				                       context: Dictionary new ].
	^ [
		  request := tool requestFromToolCallArguments: arguments.
		  result := tool executeWithRequest: request.
		  toolResult := result asMCPStructureCallToolResult.
		  self observability recordToolCallFinish: observabilityRecord result: toolResult error: nil.
		  toolResult asJRPCJSONForResponseFields: self toolResponseFields ]
		  on: Exception
		  do: [ :error |
				  | errorResult |
				  error mcpIsJRPCError ifTrue: [
						  self observability recordToolCallFinish: observabilityRecord result: nil error: error.
						  error pass ].
				  errorResult := tool errorResultFor: error.
				  self observability recordToolCallFinish: observabilityRecord result: errorResult error: error.
				  errorResult asJRPCJSONForResponseFields: self toolResponseFields ]
]

{ #category : 'private - tools' }
MCP >> finishToolCallWrapper: observabilityRecord result: wrapperResult [

	self observability recordToolCallFinish: observabilityRecord result: wrapperResult asMCPStructureCallToolResult error: nil
]

{ #category : 'private - tools' }
MCP >> handleToolCallWrapperError: error tool: callTool observabilityRecord: observabilityRecord [

	| errorResult |
	error mcpIsJRPCError ifTrue: [
			self observability recordToolCallFinish: observabilityRecord result: nil error: error.
			error pass ].
	errorResult := callTool errorResultFor: error.
	self observability recordToolCallFinish: observabilityRecord result: errorResult error: error.
	^ errorResult asJRPCJSONForResponseFields: self toolResponseFields
]

{ #category : 'accessing' }
MCP >> handlersCount [

	^ self server messageProcessor handlersCount
]

{ #category : 'initialization' }
MCP >> initialize [

	super initialize.
	server := MCPHTTPServer new.
	server addHandlersFromPragmasIn: self.
	observability := self newLocalObservabilityBackend
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

{ #category : 'observability' }
MCP >> newLocalObservabilityBackend [

	^ MCPLocalObservabilityBackend new
		  resourceMetadata: self observabilityResourceMetadata;
		  exportDirectory: MCPLocalObservabilityBackend defaultExportDirectory;
		  yourself
]

{ #category : 'accessing' }
MCP >> observability [

	^ observability ifNil: [ observability := MCPNoopObservabilityBackend new ]
]

{ #category : 'accessing' }
MCP >> observability: anObservabilityBackend [

	observability := anObservabilityBackend
]

{ #category : 'observability' }
MCP >> observabilityEnabled [

	^ self observability enabled
]

{ #category : 'observability' }
MCP >> observabilityEnabled: aBoolean [

	aBoolean
		ifTrue: [ self ensureLocalObservabilityBackend enabled: true ]
		ifFalse: [ observability := MCPNoopObservabilityBackend new ]
]

{ #category : 'observability' }
MCP >> observabilityExportDirectory [

	^ self observability exportDirectory
]

{ #category : 'observability' }
MCP >> observabilityExportDirectory: aPath [

	| localObservability |
	localObservability := self ensureLocalObservabilityBackend.
	localObservability resourceMetadata: self observabilityResourceMetadata.
	localObservability exportDirectory: aPath
]

{ #category : 'observability' }
MCP >> observabilityExportInstanceDirectory [

	^ self observability exportInstanceDirectory
]

{ #category : 'observability' }
MCP >> observabilityLogs [

	^ self observability logs
]

{ #category : 'observability' }
MCP >> observabilityMetrics [

	^ self observability metrics
]

{ #category : 'observability' }
MCP >> observabilityRecentCalls [

	^ self observability recentCallRecords
]

{ #category : 'observability' }
MCP >> observabilityResourceMetadata [

	| metadata |
	metadata := self observability resourceMetadata copy.
	metadata at: #'pharo.majorVersion' put: SystemVersion current major.
	metadata at: #'mcp.port' put: self port.
	^ metadata
]

{ #category : 'observability' }
MCP >> observabilityStatusText [

	^ self observability statusText
]

{ #category : 'observability' }
MCP >> observabilityTraces [

	^ self observability traceRecords
]

{ #category : 'start' }
MCP >> advertisedCapabilities [
	"Only what this server actually has. A capability for an empty catalog promises methods that would answer nothing. listChanged is declared because the stream can carry it; subscribe is not, because no resource here can say it changed."

	| capabilities |
	capabilities := MCPStructureCapabilities new
		                tools: (MCPStructureToolsCapabilities new
				                 listChanged: true;
				                 yourself);
		                yourself.
	self resourceRegistry entries ifNotEmpty: [
		capabilities resources: (MCPStructureResourcesCapabilities new
				 listChanged: true;
				 yourself) ].
	self promptRegistry entries ifNotEmpty: [
		capabilities prompts: (MCPStructurePromptsCapabilities new
				 listChanged: true;
				 yourself) ].
	self hasCompletableReferences ifTrue: [ capabilities completions: MCPStructureCompletionsCapabilities new ].
	^ capabilities
]

{ #category : 'private - notifications' }
MCP >> listeningRegistry: aRegistry notifying: aDomainName [
	"Have a registry tell listening clients their cached list is stale whenever it changes."

	aRegistry changeListener: [ self notifyListChangedFor: aDomainName ].
	^ aRegistry
]

{ #category : 'private - notifications' }
MCP >> notifyListChangedFor: aDomainName [
	"Not guarded: a client that has gone is handled where the write happens, so anything raising here is a fault in the server rather than a condition to absorb. An earlier guard here hid exactly that for a whole round."

	server broadcastNotification: 'notifications/' , aDomainName , '/list_changed' parameters: nil
]

{ #category : 'private - completion' }
MCP >> completionTargetFor: aReference [
	"Answer the prompt or resource template a completion reference names, or raise. The protocol defines two reference types and nothing else completes."

	| referenceType |
	referenceType := aReference at: #type ifAbsent: [ nil ].
	referenceType = 'ref/prompt' ifTrue: [
			^ self promptRegistry
				  promptNamed: (aReference at: #name ifAbsent: [ '' ])
				  ifAbsent: [ MCPUnknownCompletionReference signalFor: aReference ] ].
	referenceType = 'ref/resource' ifTrue: [
			| uri |
			uri := aReference at: #uri ifAbsent: [ '' ].
			^ self resourceRegistry resourceTemplates
				  detect: [ :each | each uriTemplate = uri ]
				  ifNone: [ MCPUnknownCompletionReference signalFor: aReference ] ].
	^ MCPUnknownCompletionReference signalFor: aReference
]

{ #category : 'private - completion' }
MCP >> hasCompletableReferences [
	"Nothing can be completed without a prompt or a resource template to complete it for."

	^ self promptRegistry entries notEmpty or: [ self resourceRegistry resourceTemplates notEmpty ]
]

{ #category : 'start' }
MCP >> discoveryInstructions [
	"Natural-language guidance a client may put in front of a model. The catalog is larger than what tools/list shows, so the one thing worth saying is how to reach the rest of it."

	^ 'Pharo image tools. tools/list shows the advertised surface; tool_search finds the rest of the catalog and tool_call runs any of them. image_evaluate is the escape hatch when no tool fits.'
]

{ #category : 'start' }
MCP >> serverIdentity [
	"Who this server says it is. Self-reported and unverified, so it is for display and logging rather than for a client to act on."

	^ MCPStructureServerInfo new
		  name: 'MCP Pharo';
		  title: 'The MCP server for Pharo';
		  version: '1.0.0';
		  description: 'a MCP server for Pharo';
		  websiteUrl: 'https://badetitou.fr';
		  icons: { (MCPStructureIcon pngIconNamed: #pharo) };
		  yourself
]

{ #category : 'start' }
MCP >> onInitialize: protocolVersion capabilities: capabilities clientInfo: clientInfo websiteUrl: websiteUrl [

	<jrpc: #initialize>
	^ MCPStructureInitialize new
		  protocolVersion: (self class negotiatedProtocolVersionFor: protocolVersion);
		  capabilities: self advertisedCapabilities;
		  metadata: self serverInfrastructureMetadata;
		  serverInfo: self serverIdentity
]

{ #category : 'infrastructure metadata' }
MCP >> pharoRuntimeMetadata [

	^ {
		  (#runtimeVersion -> SystemVersion current version).
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

{ #category : 'configuration' }
MCP >> onlyTools: toolsOrToolClasses [
	"Replace the catalog with exactly these tools, advertising all of them. A server built this way discovers nothing, so it keeps the surface it was given."

	self toolRegistry: (MCPToolRegistry empty
			 addTools: toolsOrToolClasses;
			 advertiseAllTools;
			 yourself)
]

{ #category : 'configuration' }
MCP >> onlyPrompts: promptsOrPromptClasses [
	"Replace the prompt catalog with exactly these. A server built this way discovers nothing, so it keeps what it was given."

	promptRegistry := MCPPromptRegistry empty
		                  addPrompts: promptsOrPromptClasses;
		                  yourself
]

{ #category : 'configuration' }
MCP >> onlyResources: resourcesOrResourceClasses [
	"Replace the resource catalog with exactly these. A server built this way discovers nothing, so it keeps what it was given."

	resourceRegistry := MCPResourceRegistry empty
		                    addResources: resourcesOrResourceClasses;
		                    yourself
]

{ #category : 'configuration' }
MCP >> removeResource: aUri [

	self resourceRegistry removeResourceAt: aUri
]

{ #category : 'configuration' }
MCP >> resourceUris [

	^ self resourceRegistry resourceUris
]

{ #category : 'configuration' }
MCP >> promptNames [

	^ self promptRegistry promptNames
]

{ #category : 'accessing' }
MCP >> promptRegistry [

	^ promptRegistry ifNil: [ promptRegistry := self listeningRegistry: MCPPromptRegistry default notifying: 'prompts' ]
]

{ #category : 'accessing' }
MCP >> promptRegistry: aPromptRegistry [

	promptRegistry := self listeningRegistry: (aPromptRegistry ifNil: [ MCPPromptRegistry default ]) notifying: 'prompts'
]

{ #category : 'configuration' }
MCP >> removePrompt: aName [

	self promptRegistry removePromptNamed: aName
]

{ #category : 'accessing' }
MCP >> resourceRegistry [

	^ resourceRegistry ifNil: [ resourceRegistry := self listeningRegistry: MCPResourceRegistry default notifying: 'resources' ]
]

{ #category : 'accessing' }
MCP >> resourceRegistry: aResourceRegistry [

	resourceRegistry := self listeningRegistry: (aResourceRegistry ifNil: [ MCPResourceRegistry default ]) notifying: 'resources'
]

{ #category : 'configuration' }
MCP >> removeTool: aToolName [

	self toolRegistry removeToolNamed: aToolName.
	self refreshToolsList
]

{ #category : 'private - tools' }
MCP >> recordToolCallWrapperStartFor: callTool arguments: arguments [

	^ self observability
		  recordToolCallStart: callTool name
		  input: arguments
		  dispatchPath: 'direct'
		  context: Dictionary new
]

{ #category : 'private - tools' }
MCP >> refreshToolsList [
	"Refresh the cached tools/list response surface from the registry's current static tools."

	toolsList := self toolRegistry advertisedToolsDictionary.
	^ toolsList
]

{ #category : 'configuration' }
MCP >> addPrompt: aPromptOrPromptClass [
	"Register one prompt, as a class or as a ready instance. Every registered prompt is listed by prompts/list."

	^ self promptRegistry addPrompt: aPromptOrPromptClass
]

{ #category : 'configuration' }
MCP >> addPrompts: promptsOrPromptClasses [

	^ self promptRegistry addPrompts: promptsOrPromptClasses
]

{ #category : 'configuration' }
MCP >> addResource: aResourceOrResourceClass [
	"Register one resource, as a class or as a ready instance. Every registered resource is listed by resources/list."

	^ self resourceRegistry addResource: aResourceOrResourceClass
]

{ #category : 'configuration' }
MCP >> addResources: resourcesOrResourceClasses [

	^ self resourceRegistry addResources: resourcesOrResourceClasses
]

{ #category : 'configuration' }
MCP >> addTool: aToolOrToolClass [
	"Register one tool, as a class or as a ready instance. It becomes reachable through tool_search, tool_get and tool_call; whether tools/list shows it is the advertising question."

	| tool |
	tool := self toolRegistry addTool: aToolOrToolClass.
	self refreshToolsList.
	^ tool
]

{ #category : 'configuration' }
MCP >> addTools: toolsOrToolClasses [

	| added |
	added := self toolRegistry addTools: toolsOrToolClasses.
	self refreshToolsList.
	^ added
]

{ #category : 'start' }
MCP >> restart [

	self stop.
	^ self start
]

{ #category : 'private - tools' }
MCP >> rpcCallToolCallWithParams: arguments [

	| callTool observabilityRecord |
	callTool := self toolCallTool.
	observabilityRecord := self recordToolCallWrapperStartFor: callTool arguments: arguments.
	^ [ self dispatchToolCallWith: callTool arguments: arguments observabilityRecord: observabilityRecord ]
		  on: Exception
		  do: [ :error | self handleToolCallWrapperError: error tool: callTool observabilityRecord: observabilityRecord ]
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
MCP >> rpcCompletionComplete: ref argument: argument context: context [

	<jrpc: #'completion/complete'>
	| target suggestions |
	ref isDictionary ifFalse: [ MCPUnknownCompletionReference signalFor: ref ].
	target := self completionTargetFor: ref.
	suggestions := target
		               completionsFor: (argument at: #name ifAbsent: [ '' ])
		               value: (argument at: #value ifAbsent: [ '' ])
		               context: ((context ifNil: [ Dictionary new ]) at: #arguments ifAbsent: [ Dictionary new ]).
	^ { (#completion -> (MCPStructureCompletion values: suggestions) asJRPCJSON) } asDictionary
]

{ #category : 'rpc' }
MCP >> rpcServerDiscover [
	"What a client needs before it can talk: the versions this server implements, what it can do, and who it is. A client may call it first or never, so it answers whatever version was asked for."

	<jrpc: #'server/discover'>
	^ {
		  (#supportedVersions -> self class supportedProtocolVersions).
		  (#capabilities -> self advertisedCapabilities asJRPCJSON).
		  (#instructions -> self discoveryInstructions).
		  (#_meta -> { ('io.modelcontextprotocol/serverInfo' -> self serverIdentity asJRPCJSON) } asDictionary) }
			  asDictionary
]

{ #category : 'rpc' }
MCP >> rpcPromptGet: name arguments: arguments [

	<jrpc: #'prompts/get'>
	| prompt suppliedArguments result |
	prompt := self promptRegistry
		          promptNamed: name
		          ifAbsent: [ ^ MCPUnknownPrompt signalNamed: name known: self promptRegistry promptNames ].
	suppliedArguments := arguments ifNil: [ Dictionary new ].
	prompt validateArguments: suppliedArguments.
	result := Dictionary new
		          at: #messages
		          put: ((prompt messagesFor: suppliedArguments) collect: [ :each | each asJRPCJSON ]);
		          yourself.
	prompt description ifNotNil: [ :value | result at: #description put: value asJRPCJSON ].
	^ result
]

{ #category : 'rpc' }
MCP >> rpcPromptsList [

	<jrpc: #'prompts/list'>
	^ { (#prompts -> (self promptRegistry prompts collect: [ :each | each asJRPCJSON ])) } asDictionary
]

{ #category : 'rpc' }
MCP >> rpcResourceRead: uri [

	<jrpc: #'resources/read'>
	| resource |
	resource := self resourceRegistry resourceAt: uri ifAbsent: [ ^ MCPResourceNotFound signalForUri: uri ].
	^ { (#contents -> (resource readContents collect: [ :each | each asJRPCJSON ])) } asDictionary
]

{ #category : 'rpc' }
MCP >> rpcResourcesList [

	<jrpc: #'resources/list'>
	^ { (#resources -> (self resourceRegistry resources collect: [ :each | each asJRPCJSON ])) } asDictionary
]

{ #category : 'rpc' }
MCP >> rpcResourcesTemplateList [

	<jrpc: #'resources/templates/list'>
	^ { (#resourceTemplates -> (self resourceRegistry resourceTemplates collect: [ :each | each asJRPCJSON ])) } asDictionary
]

{ #category : 'rpc' }
MCP >> rpcToolCall: name withParams: arguments [

	<jrpc: #'tools/call'>
	self toolsList
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
	^ { (#tools -> self toolsList values asArray) } asDictionary asJRPCJSON
]

{ #category : 'accessing' }
MCP >> server [

	^ server
]

{ #category : 'infrastructure metadata' }
MCP >> serverInfrastructureMetadata [

	^ { (#'io.github.evref-bl/pharo' -> self pharoRuntimeMetadata) } asDictionary
]

{ #category : 'private - tools' }
MCP >> signalMissingToolNamed: aToolName [
	"A name that does not resolve is the caller's mistake, not the server's, so it reads as one."

	| suggestions details |
	suggestions := MCPSelectorSuggestion namesLike: aToolName among: self toolRegistry toolNames.
	details := Dictionary new
		           at: #tool put: aToolName;
		           yourself.
	suggestions ifNotEmpty: [ details at: #suggestedTools put: suggestions ].
	MCPCommandError
		signalErrorCode: #ToolNotFound
		message: 'No MCP tool named ' , aToolName , '.'
			, (suggestions ifEmpty: [ ' Use tool_search to find one.' ] ifNotEmpty: [ ' Did you mean: ' , (', ' join: suggestions) , '?' ])
		details: details
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
	self observability recordSessionStartFor: self
]

{ #category : 'configuration' }
MCP >> advertiseAllTools [

	self toolRegistry advertiseAllTools.
	self refreshToolsList
]

{ #category : 'configuration' }
MCP >> advertiseToolDefaults [
	"Leave tools/list to each tool's own default exposure, which is where a fresh server starts."

	self toolRegistry advertiseToolDefaults.
	self refreshToolsList
]

{ #category : 'configuration' }
MCP >> advertiseTools: toolsOrToolClassesOrNames [
	"Say which tools tools/list should show, as classes, tool instances or names. Anything not in the catalog yet is registered, so this can be called before or after adding them."

	self toolRegistry advertiseTools: toolsOrToolClassesOrNames.
	self refreshToolsList
]

{ #category : 'configuration' }
MCP >> advertisedToolNames [

	^ self toolRegistry advertisedToolNames
]

{ #category : 'start' }
MCP >> stop [

	[ server stop ] ensure: [ self observability shutdown ]
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

	^ self toolRegistry toolNamed: callRequest toolName ifAbsent: [ self signalMissingToolNamed: callRequest toolName ]
]

{ #category : 'private - tools' }
MCP >> toolCallTool [

	^ self toolRegistry toolNamed: MCPToolCallTool toolName ifAbsent: [ Error signal: 'tool_call is not registered.' ]
]

{ #category : 'private - tools' }
MCP >> toolCallWrapperResultFor: callTool request: callRequest [

	^ callTool
		  successResultText: 'Dispatched tool ' , callRequest toolName
		  data: { (#tool -> callRequest toolName) } asDictionary
]

{ #category : 'configuration' }
MCP >> toolNames [

	^ self toolRegistry toolNames
]

{ #category : 'accessing' }
MCP >> toolRegistry [

	^ toolRegistry ifNil: [ toolRegistry := self listeningRegistry: MCPToolRegistry default notifying: 'tools' ]
]

{ #category : 'accessing' }
MCP >> toolRegistry: aToolRegistry [

	toolRegistry := self listeningRegistry: (aToolRegistry ifNil: [ MCPToolRegistry default ]) notifying: 'tools'.
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
	"Answer the cached advertised surface. The registry remains the source of truth for registered tools."

	^ toolsList ifNil: [ self refreshToolsList ]
]

{ #category : 'accessing' }
MCP >> toolsList: aToolsList [
	"Replace the cached advertised surface. Intended for tests and controlled presenter setup; normal configuration goes through addTool: and advertiseTools:."

	^ toolsList := aToolsList
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
