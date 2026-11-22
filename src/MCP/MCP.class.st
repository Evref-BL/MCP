"
Top-level MCP server application object. MCP owns its tool, resource and prompt registries, the HTTP server and observability. Its methods marked <jrpc:> are the protocol handlers, and a tool call goes to the matching MCPTool once its arguments are validated.

The tool registry owns the registered tools and their exposure policy, and is the source of truth for them. The toolsList instance variable caches the advertised surface as a dictionary keyed by tool name.

Two words govern the tool surface. A *registered* tool is in the catalog, callable by name, and findable through tool_search and tool_get. An *advertised* tool is also in tools/list.

- `mcp addTool: MyToolClass` and `mcp addTools: { A. B }` register tools, as classes or ready instances;
- `mcp removeTool: 'tool_call'` takes one back out, and refuses one the catalog does not hold, as `unadvertiseTool:` does;
- `mcp onlyTools: { A. B }` replaces the catalog with exactly those;
- `mcp advertiseTools: { A. 'class_search' }` chooses what tools/list shows, registering anything not yet in the catalog;
- `mcp advertiseAllTools` and `mcp advertiseToolDefaults` are the other two advertising states;
- a tool class is in the catalog because its package was loaded, wherever it was defined; `MyToolClass class >> shouldAutoRegister` answering `false` keeps one out.
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
		'toolResponseFields',
		'lastClientInfo'
	],
	#classVars : [
		'DefaultObservabilityBackendClass'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'servers' }
MCP class >> allServers [
	"Answer every MCP server this image still holds, ordered by port.

	The heap is the registry. A class-side collection of servers would keep every server its owner forgot alive for the life of the image, and a weak one would still answer servers that are garbage but not yet collected, which in a working image means a dozen corpses from the test suite for each real server. Collecting first is what tells the two apart: a server that was started is held by its own process and socket, so it survives and is answered even when no variable refers to it, which is how an abandoned server still holding a port becomes visible, while an unstarted one nobody refers to is garbage and correctly disappears.

	This costs a full garbage collection, so it is for answering someone who asked, not for a polling loop."

	Smalltalk garbageCollect.
	^ self allSubInstances asArray sort: [ :left :right | left port <= right port ]
]

{ #category : 'accessing' }
MCP class >> catalogCacheMilliseconds [
	"How long a catalog answer stays good. The catalogs only move when code is loaded or removed, and list_changed invalidates a client's copy the moment they do, so a minute costs a non-listening client at most a minute of staleness and saves everyone else the refetches."

	^ 60000
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
MCP class >> metaIn: someParams [
	"Answer the _meta a request carries, or nil when it carries none."

	| meta |
	someParams isDictionary ifFalse: [ ^ nil ].
	meta := someParams at: '_meta' ifAbsent: [ ^ nil ].
	^ meta isDictionary
		  ifTrue: [ meta ]
		  ifFalse: [ nil ]
]

{ #category : 'protocol' }
MCP class >> modernClientInfoKey [
	"Where a modern request's _meta carries the client's identity, its name and version."

	^ 'io.modelcontextprotocol/clientInfo'
]

{ #category : 'protocol' }
MCP class >> modernProtocolVersionKey [

	^ 'io.modelcontextprotocol/protocolVersion'
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

{ #category : 'observability' }
MCP class >> observabilityBackendClass [
	"The kind of local backend the servers this image makes record with."

	^ DefaultObservabilityBackendClass ifNil: [ MCPLocalObservabilityBackend ]
]

{ #category : 'observability' }
MCP class >> observabilityBackendClass: aLocalBackendClass [
	"Makes the servers this image makes from now on record with aLocalBackendClass, a kind of local backend, but for those a test makes, which record locally only; nil goes back to MCPLocalObservabilityBackend. Saved with the image."

	DefaultObservabilityBackendClass := aLocalBackendClass
]

{ #category : 'instance creation' }
MCP class >> onlyTools: toolsOrToolClasses [

	^ self new
		  onlyTools: toolsOrToolClasses;
		  yourself
]

{ #category : 'protocol' }
MCP class >> requestedProtocolVersionIn: someParams [
	"Answer the protocol version a request declares for itself, or nil when it declares none."

	^ (self metaIn: someParams) ifNotNil: [ :meta | meta at: self modernProtocolVersionKey ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
MCP class >> resourceContentsCacheMilliseconds [
	"Shorter than a catalog, because nothing announces that a resource's contents changed. Until a resource can signal that, the only protection a client has is a short freshness window."

	^ 5000
]

{ #category : 'servers' }
MCP class >> runningServers [
	"Answer the MCP servers this image is running, ordered by port.

	Unlike allServers this needs no garbage collection: a running server is held by its own process and socket, so it is never garbage, and the unstarted corpses a collection would remove are not running."

	^ (self allSubInstances select: [ :each | each isRunning ]) asArray sort: [ :left :right | left port <= right port ]
]

{ #category : 'private - servers' }
MCP class >> startNewOnPort: aPortNumber [

	^ self new
		  port: aPortNumber;
		  start;
		  yourself
]

{ #category : 'servers' }
MCP class >> startOnPort: aPortNumber [
	"Answer a running server on this port, which is the one already there when the image has one. Two servers cannot share a port, so asking for a port is asking for the server on it.

	Port 0 asks the operating system for a free one, so it names no particular server and always makes a new one."

	aPortNumber isZero ifTrue: [ ^ self startNewOnPort: aPortNumber ].
	^ self allServers
		  detect: [ :each | each port = aPortNumber ]
		  ifFound: [ :server |
				  server isRunning ifFalse: [ server start ].
				  server ]
		  ifNone: [ self startNewOnPort: aPortNumber ]
]

{ #category : 'protocol' }
MCP class >> supportedProtocolVersions [

	^ self legacyProtocolVersions , self modernProtocolVersions
]

{ #category : 'accessing' }
MCP class >> version [
	"The MCP release this code belongs to. The release pull request sets it."

	^ '4.2.1'
]

{ #category : 'configuration' }
MCP >> addPrompt: aPromptOrPromptClass [
	"Register one prompt, as a class or as a ready instance. Every registered prompt is listed by prompts/list."

	^ self promptRegistry addPrompt: aPromptOrPromptClass
]

{ #category : 'configuration' }
MCP >> addResource: aResourceOrResourceClass [
	"Register one resource, as a class or as a ready instance. Every registered resource is listed by resources/list."

	^ self resourceRegistry addResource: aResourceOrResourceClass
]

{ #category : 'configuration' }
MCP >> addTool: aToolOrToolClass [
	"Register one tool, as a class or as a ready instance. It becomes callable, and findable through tool_search and tool_get; whether tools/list shows it is the advertising question."

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

{ #category : 'configuration' }
MCP >> advertiseAllTools [

	self toolRegistry advertiseAllTools.
	self refreshToolsList
]

{ #category : 'configuration' }
MCP >> advertiseTool: aToolOrToolClassOrName [

	self toolRegistry advertiseTool: aToolOrToolClassOrName.
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

{ #category : 'configuration' }
MCP >> advertisedToolNames [

	^ self toolRegistry advertisedToolNames
]

{ #category : 'private - start' }
MCP >> anotherServerListeningOnThisPortDo: aBlock [
	"A port is most often held by another server in the same image. That server is listening, so it is running and found without the full garbage collection allServers makes."

	self class runningServers
		detect: [ :each | each ~~ self and: [ each port = self port and: [ each isListening ] ] ]
		ifFound: aBlock
]

{ #category : 'private - tools' }
MCP >> answerMissingToolNamed: aName withParams: arguments [

	^ self
		  answerMissingToolNamed: aName
		  withParams: arguments
		  dispatchPath: 'direct'
		  parentRecord: nil
]

{ #category : 'private - tools' }
MCP >> answerMissingToolNamed: aName withParams: arguments dispatchPath: dispatchPath parentRecord: aRecord [
	"A name the server does not have is the caller's mistake, answered as tool_call answers it, with the tools it may have meant, which a JSON-RPC error would lose in a client that shows only its message, and recorded as a call to that name, within the call aRecord records when one dispatched it. A call naming no tool at all has invalid parameters."

	| record |
	(aName isString and: [ aName isNotEmpty ]) ifFalse: [ JRPCInvalidParameters signal ].
	record := self observability
		          recordToolCallStart: aName
		          input: arguments
		          dispatchPath: dispatchPath
		          context: (self observabilityContextFor: nil parentRecord: aRecord).
	^ [ self toolRegistry signalMissingToolNamed: aName ]
		  on: Exception
		  do: [ :error | self answerToolError: error tool: MCPToolCallTool new record: record ]
]

{ #category : 'private - tools' }
MCP >> answerToolError: error tool: aTool record: aRecord [
	"A protocol error is the transport's to answer, as JSON-RPC; any other failure is the tool's answer."

	| errorResult |
	error mcpIsProtocolError ifTrue: [
			self observability recordToolCallFinish: aRecord result: nil error: error.
			error pass ].
	errorResult := aTool errorResultFor: error.
	self observability recordToolCallFinish: aRecord result: errorResult error: error.
	^ errorResult asJRPCJSONForResponseFields: self toolResponseFields
]

{ #category : 'private - tools' }
MCP >> callToolCall: callTool withParams: arguments [

	| record |
	record := self recordStartOf: callTool input: arguments dispatchPath: 'direct'.
	^ [
		  [ self dispatchToolCallWith: callTool arguments: arguments observabilityRecord: record ]
			  on: Exception
			  do: [ :error | self answerToolError: error tool: callTool record: record ] ] ensure: [ self endRecordOfACallCutShort: record ]
]

{ #category : 'configuration' }
MCP >> changePortTo: aPortNumber [
	"Move the server to another port. A running one is restarted there, and goes back to the port it had if the new one cannot be bound."

	^ self configurePort: aPortNumber debugMode: self debugMode
]

{ #category : 'observability' }
MCP >> clearObservability [

	self observability clear
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

{ #category : 'start' }
MCP >> discoveryInstructions [
	"Natural-language guidance a client may put in front of a model, or nil when this server has none to give: the everyday workflows that loaded packages contribute as class-side methods of MCP marked <discoveryInstructions>, each step named by its tool, then how to reach what tools/list leaves out. The workflows come in selector order, which adding a method does not change, since a client may cache the text. A host may let a model call only what its own list holds, so a tool found that way goes through tool_call, and a sentence naming a tool this server does not advertise is left out."

	| advertised sentences |
	advertised := self advertisedToolNames.
	sentences := (((Pragma allNamed: #discoveryInstructions in: MCP class) collect: #methodSelector) sorted collect: [ :selector |
		              MCP perform: selector ]) , #( 'tool_search finds more; tool_call runs them.' ) select: [ :sentence |
		             ((sentence substrings: ' ,.;:()') select: [ :word | word includes: $_ ]) allSatisfy: [ :name |
			             advertised includes: name ] ].
	^ sentences ifEmpty: [ nil ] ifNotEmpty: [ ' ' join: sentences ]
]

{ #category : 'private - tools' }
MCP >> dispatchToolCallWith: callTool arguments: arguments observabilityRecord: aRecord [
	"tool_call answers what the call it makes answers, a name the server does not have included, and that call is recorded within tool_call's own. tool_call's record fails when that call did, and says only that: the dispatched call's record says why."

	| request toolName toolArguments tool response |
	request := callTool requestFromToolCallArguments: arguments.
	toolName := request stringArgumentNamed: 'name'.
	toolName = callTool name ifTrue: [
			MCPCommandError
				signalErrorCode: #ToolCallCallsItself
				message: 'tool_call cannot call itself; call the tool it would call.'
				details: { (#tool -> toolName) } asDictionary ].
	toolArguments := (request argumentNamed: 'arguments' ifAbsent: [ nil ]) ifNil: [ Dictionary new ].
	tool := self toolRegistry toolNamed: toolName ifAbsent: [ nil ].
	response := tool
		            ifNil: [
				            self
					            answerMissingToolNamed: toolName
					            withParams: toolArguments
					            dispatchPath: 'via_tool_call'
					            parentRecord: aRecord ]
		            ifNotNil: [
				            self
					            executeTool: tool
					            withParams: toolArguments
					            dispatchPath: 'via_tool_call'
					            parentRecord: aRecord ].
	self observability
		recordToolCallFinish: aRecord
		result: (self resultOf: callTool dispatching: toolName answered: response)
		error: nil.
	^ response
]

{ #category : 'private - tools' }
MCP >> endRecordOfACallCutShort: aRecord [
	"A call whose process was terminated before it answered still ends its record, as failed, so that nothing the record keeps open, such as its span, outlives the call. A call that answered, or failed with a protocol error, ended its record already."

	(aRecord isNil or: [ aRecord isRunning not ]) ifTrue: [ ^ self ].
	self observability recordToolCallFinish: aRecord result: nil error: nil
]

{ #category : 'private - start' }
MCP >> ensureServerIsListening [
	"The listener binds in a process above its caller's priority, so a bind that fails has usually failed by now. A port another MCP in this image listens on stays held however long this one waits for it, so that failure is signalled as soon as it is seen: at once, or after the first wait when the bind had not failed yet."

	server lastListenError ifNotNil: [
		self anotherServerListeningOnThisPortDo: [ :holder | Error signal: self notListeningDescription ] ].
	(self waitUntilListeningForMilliseconds: 1000) ifTrue: [ ^ self ].
	self anotherServerListeningOnThisPortDo: [ :holder | Error signal: self notListeningDescription ].
	server stop.
	server start.
	(self waitUntilListeningForMilliseconds: 1000) ifTrue: [ ^ self ].
	Error signal: self notListeningDescription
]

{ #category : 'private - tools' }
MCP >> executeTool: aTool withParams: arguments dispatchPath: dispatchPath [

	^ self
		  executeTool: aTool
		  withParams: arguments
		  dispatchPath: dispatchPath
		  parentRecord: nil
]

{ #category : 'private - tools' }
MCP >> executeTool: aTool withParams: arguments dispatchPath: dispatchPath parentRecord: aRecord [
	"Runs the tool and answers its result, recorded within the call aRecord records when one dispatched it."

	| record result |
	record := self
		          recordStartOf: aTool
		          input: arguments
		          dispatchPath: dispatchPath
		          parentRecord: aRecord.
	^ [
		  [
			  result := (aTool executeWithRequest: (aTool requestFromToolCallArguments: arguments)) asMCPStructureCallToolResult.
			  self observability recordToolCallFinish: record result: result error: nil.
			  result asJRPCJSONForResponseFields: self toolResponseFields ]
			  on: Exception
			  do: [ :error | self answerToolError: error tool: aTool record: record ] ] ensure: [ self endRecordOfACallCutShort: record ]
]

{ #category : 'private - completion' }
MCP >> hasCompletableReferences [
	"Nothing can be completed without a prompt or a resource template to complete it for."

	^ self promptRegistry entries isNotEmpty or: [ self resourceRegistry resourceTemplates isNotEmpty ]
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

{ #category : 'private - notifications' }
MCP >> listeningRegistry: aRegistry notifying: aDomainName [
	"Have a registry tell listening clients their cached list is stale whenever it changes."

	aRegistry changeListener: [ self notifyListChangedFor: aDomainName ].
	^ aRegistry
]

{ #category : 'accessing' }
MCP >> localUrlString [

	^ self server localUrl asString
]

{ #category : 'observability' }
MCP >> newLocalObservabilityBackend [
	"The backend a new server records with: the image's kind, except in a test, which makes servers to see what they do, where it is the plain local one, so that what a test does never leaves the image as if it were use."

	| backendClass |
	backendClass := CurrentExecutionEnvironment value isTest
		                ifTrue: [ MCPLocalObservabilityBackend ]
		                ifFalse: [ self class observabilityBackendClass ].
	^ (self newObservabilityBackend: backendClass)
		  configureForServer: self;
		  yourself
]

{ #category : 'observability' }
MCP >> newObservabilityBackend: aLocalBackendClass [
	"A new backend of aLocalBackendClass, a kind of local backend, set up as this server's local backend is: describing this server and exporting to the default directory."

	^ aLocalBackendClass new
		  resourceMetadata: self observabilityResourceMetadata;
		  exportDirectory: aLocalBackendClass defaultExportDirectory;
		  yourself
]

{ #category : 'private - start' }
MCP >> notListeningDescription [
	"The socket error alone does not say that the port is held by another server in the same image."

	^ String streamContents: [ :stream |
			  stream << 'MCP server is not listening on port ' << self port asString.
			  server lastListenError ifNotNil: [ :reason | stream << ': ' << reason ].
			  self anotherServerListeningOnThisPortDo: [ :holder |
				  stream << '. Another MCP in this image is listening on that port; MCP startOnPort: ' << self port asString << ' answers it.' ] ]
]

{ #category : 'private - observability' }
MCP >> noteInitializedClient: clientInfo [
	"Keeps the name and version a client gave initialize, and nothing else it said."

	lastClientInfo := clientInfo isDictionary ifTrue: [
			                  {
				                  (#name -> (clientInfo mcpAt: #name ifAbsent: [ nil ])).
				                  (#version -> (clientInfo mcpAt: #version ifAbsent: [ nil ])) } asDictionary ]
]

{ #category : 'private - notifications' }
MCP >> notifyListChangedFor: aDomainName [
	"Not guarded: a client that has gone is handled where the write happens, so anything raising here is a fault in the server rather than a condition to absorb. An earlier guard here hid exactly that for a whole round."

	server
		broadcastNotification: (String streamContents: [ :stream | stream << 'notifications/' << aDomainName << '/list_changed' ])
		parameters: nil
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
MCP >> observabilityContextFor: aTool [
	"What a backend may want to know about a call beyond its name and arguments: the tool, for its schema, the request's _meta, for the caller's trace context and identity, and the client that last initialized, for a caller whose requests do not say who it is."

	^ self observabilityContextFor: aTool parentRecord: nil
]

{ #category : 'observability' }
MCP >> observabilityContextFor: aTool parentRecord: aRecord [
	"What a backend may want to know about a call beyond its name and arguments: the tool, for its schema, the request's _meta, for the caller's trace context and identity, the client that last initialized, for a caller whose requests do not say who it is, and the record of the call that dispatched this one, if one did."

	^ {
		  (#tool -> aTool).
		  (#meta -> (MCPRequestMeta value ifNil: [ Dictionary new ])).
		  (#client -> lastClientInfo).
		  (#parentRecord -> aRecord) } asDictionary
]

{ #category : 'observability' }
MCP >> observabilityEnabled [

	^ self observability enabled
]

{ #category : 'observability' }
MCP >> observabilityEnabled: aBoolean [

	aBoolean
		ifTrue: [ self recordingObservability ]
		ifFalse: [ observability := MCPNoopObservabilityBackend new ]
]

{ #category : 'observability' }
MCP >> observabilityExportDirectory [

	^ self observability exportDirectory
]

{ #category : 'observability' }
MCP >> observabilityExportDirectory: aPath [

	self recordingObservability
		resourceMetadata: self observabilityResourceMetadata;
		exportDirectory: aPath
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
MCP >> observabilityResourceMetadata [

	| metadata |
	metadata := self observability resourceMetadata copy.
	metadata at: #'pharo.majorVersion' put: SystemVersion current major.
	metadata at: #'mcp.port' put: self port.
	^ metadata
]

{ #category : 'observability' }
MCP >> observabilityTraces [

	^ self observability traceRecords
]

{ #category : 'rpc' }
MCP >> onInitialize: protocolVersion [
	"A client that opens with initialize has no server/discover to call, so this answer carries the instructions too."

	^ self onInitialize: protocolVersion clientInfo: nil
]

{ #category : 'rpc' }
MCP >> onInitialize: protocolVersion clientInfo: clientInfo [
	"A client that opens with initialize has no server/discover to call, so this answer carries the instructions too. Such a client says who it is only here, so its name and version are kept for the calls that follow, which observability may report: the last client to initialize, since this server keeps no session."

	<jrpc: #initialize>
	self noteInitializedClient: clientInfo.
	^ MCPStructureInitialize new
		  protocolVersion: (self class negotiatedProtocolVersionFor: protocolVersion);
		  capabilities: self advertisedCapabilities;
		  instructions: self discoveryInstructions;
		  metadata: self serverInfrastructureMetadata;
		  serverInfo: self serverIdentity
]

{ #category : 'configuration' }
MCP >> onlyPrompts: promptsOrPromptClasses [
	"Replace the prompt catalog with exactly these. A server built this way discovers nothing, so it keeps what it was given."

	self promptRegistry: (MCPPromptRegistry empty
			 addPrompts: promptsOrPromptClasses;
			 yourself)
]

{ #category : 'configuration' }
MCP >> onlyResources: resourcesOrResourceClasses [
	"Replace the resource catalog with exactly these. A server built this way discovers nothing, so it keeps what it was given."

	self resourceRegistry: (MCPResourceRegistry empty
			 addResources: resourcesOrResourceClasses;
			 yourself)
]

{ #category : 'configuration' }
MCP >> onlyTools: toolsOrToolClasses [
	"Replace the catalog with exactly these tools, advertising all of them. A server built this way discovers nothing, so it keeps the surface it was given."

	self toolRegistry: (MCPToolRegistry empty
			 addTools: toolsOrToolClasses;
			 advertiseAllTools;
			 yourself)
]

{ #category : 'infrastructure metadata' }
MCP >> pharoRuntimeMetadata [

	^ {
		  (#runtimeVersion -> SystemVersion current version).
		  (#supportedMajorVersions -> self supportedPharoMajorVersions) } asDictionary
]

{ #category : 'accessing' }
MCP >> port [

	^ self server port
]

{ #category : 'accessing' }
MCP >> port: aPortNumber [

	self server port: aPortNumber
]

{ #category : 'accessing' }
MCP >> promptRegistry [

	^ promptRegistry ifNil: [ promptRegistry := self listeningRegistry: MCPPromptRegistry default notifying: 'prompts' ]
]

{ #category : 'accessing' }
MCP >> promptRegistry: aPromptRegistry [

	promptRegistry := self listeningRegistry: (aPromptRegistry ifNil: [ MCPPromptRegistry default ]) notifying: 'prompts'
]

{ #category : 'private - tools' }
MCP >> recordStartOf: aTool input: arguments dispatchPath: dispatchPath [
	"The record of a call starting, or nil for a tool that keeps out of observability."

	^ self
		  recordStartOf: aTool
		  input: arguments
		  dispatchPath: dispatchPath
		  parentRecord: nil
]

{ #category : 'private - tools' }
MCP >> recordStartOf: aTool input: arguments dispatchPath: dispatchPath parentRecord: aRecord [
	"The record of a call starting, within the call aRecord records when one dispatched it, or nil for a tool that keeps out of observability."

	aTool shouldRecordObservability ifFalse: [ ^ nil ].
	^ self observability
		  recordToolCallStart: aTool name
		  input: arguments
		  dispatchPath: dispatchPath
		  context: (self observabilityContextFor: aTool parentRecord: aRecord)
]

{ #category : 'observability' }
MCP >> recordingObservability [
	"The backend recording this server's calls: the one it has, or a new local one when it had none."

	self observability isNoop ifTrue: [ observability := self newLocalObservabilityBackend ].
	^ self observability
]

{ #category : 'private - tools' }
MCP >> refreshToolsList [
	"Refresh the cached tools/list surface from the registry's advertised tools."

	toolsList := self toolRegistry advertisedToolsDictionary.
	^ toolsList
]

{ #category : 'configuration' }
MCP >> removeTool: aToolOrToolClassOrName [

	self toolRegistry removeTool: aToolOrToolClassOrName.
	self refreshToolsList
]

{ #category : 'accessing' }
MCP >> resourceRegistry [

	^ resourceRegistry ifNil: [ resourceRegistry := self listeningRegistry: MCPResourceRegistry default notifying: 'resources' ]
]

{ #category : 'accessing' }
MCP >> resourceRegistry: aResourceRegistry [

	resourceRegistry := self listeningRegistry: (aResourceRegistry ifNil: [ MCPResourceRegistry default ]) notifying: 'resources'
]

{ #category : 'start' }
MCP >> restart [

	self stop.
	^ self start
]

{ #category : 'private - tools' }
MCP >> resultOf: callTool dispatching: aToolName answered: aResponse [
	"What tool_call's own record says it answered: that it dispatched the call, or that the call it dispatched failed, and nothing of why, which that call's record says."

	| failed |
	failed := aResponse isDictionary and: [ (aResponse mcpAt: #isError ifAbsent: [ false ]) == true ].
	failed ifFalse: [
			^ (callTool successResultText: 'Dispatched tool ' , aToolName data: { (#tool -> aToolName) } asDictionary)
				  asMCPStructureCallToolResult ].
	^ callTool errorResultText: ('Dispatched tool {1} failed' format: { aToolName }) details: {
			  (#errorCode -> 'DispatchedToolFailed').
			  (#tool -> aToolName) } asDictionary
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
MCP >> rpcServerDiscover [
	"What a client needs before it can talk: the versions this server implements, what it can do, and who it is. A client may call it first or never, so it answers whatever version was asked for."

	<jrpc: #'server/discover'>
	| answer |
	answer := {
		          (#supportedVersions -> self class supportedProtocolVersions).
		          (#capabilities -> self advertisedCapabilities asJRPCJSON).
		          (#_meta -> { ('io.modelcontextprotocol/serverInfo' -> self serverIdentity asJRPCJSON) } asDictionary) } asDictionary.
	self discoveryInstructions ifNotNil: [ :instructions | answer at: #instructions put: instructions ].
	^ answer
]

{ #category : 'rpc' }
MCP >> rpcToolCall: name withParams: arguments [
	"Dispatch any registered tool. Advertising decides what tools/list shows, not what a client may call: tool_call reaches an unadvertised tool already, so refusing one here buys no privacy and costs the caller a round trip and a nested argument object."

	<jrpc: #'tools/call'>
	| tool |
	tool := self toolRegistry toolNamed: name ifAbsent: [ ^ self answerMissingToolNamed: name withParams: arguments ].
	name = MCPToolCallTool toolName ifTrue: [ ^ self callToolCall: tool withParams: arguments ].
	^ self executeTool: tool withParams: arguments dispatchPath: 'direct'
]

{ #category : 'rpc' }
MCP >> rpcToolsList [

	<jrpc: #'tools/list'>
	self refreshToolsList.
	^ { (#tools -> (self toolRegistry listingsOf: self toolsList values) asArray) } asDictionary asJRPCJSON
]

{ #category : 'accessing' }
MCP >> server [

	^ server
]

{ #category : 'start' }
MCP >> serverDescription [
	"Who this server says it is, without the icon a client shows, which takes rendering an image: what a record of the server's work needs."

	^ MCPStructureServerInfo new
		  name: 'MCP Pharo';
		  title: 'The MCP server for Pharo';
		  version: self class version;
		  websiteUrl: 'https://github.com/Evref-BL/MCP';
		  yourself
]

{ #category : 'start' }
MCP >> serverIdentity [
	"Who this server says it is. Self-reported and unverified, so it is for display and logging rather than for a client to act on."

	^ self serverDescription
		  icons: { (MCPStructureIcon pngIconNamed: #pharo) };
		  yourself
]

{ #category : 'infrastructure metadata' }
MCP >> serverInfrastructureMetadata [

	^ { (#'io.github.evref-bl/pharo' -> self pharoRuntimeMetadata) } asDictionary
]

{ #category : 'start' }
MCP >> start [

	self refreshToolsList.
	server addHandlersFromPragmasIn: self.
	server start.
	self ensureServerIsListening.
	self observability recordSessionStart
]

{ #category : 'start' }
MCP >> stop [

	[ server stop ] ensure: [ self observability shutdown ]
]

{ #category : 'infrastructure metadata' }
MCP >> supportedPharoMajorVersions [

	^ #( 10 11 12 13 14 15 )
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
	"Replace the cached advertised surface, a seam for tests; configuration goes through addTool: and advertiseTools:."

	^ toolsList := aToolsList
]

{ #category : 'configuration' }
MCP >> unadvertiseTool: aToolOrToolClassOrName [

	self toolRegistry unadvertiseTool: aToolOrToolClassOrName.
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
