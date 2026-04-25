"
Top-level MCP server application object.

MCP owns the registered tool instances and the HTTP server. It exposes the core JSON-RPC MCP handlers, including initialization, tool listing, tool calls, ping, and empty resource listings. Tool calls are delegated to the matching MCPTool after request validation.
"
Class {
	#name : 'MCP',
	#superclass : 'Object',
	#instVars : [
		'server',
		'toolsList'
	],
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'as yet unclassified' }
MCP >> debugMode: aBoolean [

	self server debugMode: aBoolean.
	self server messageProcessor debugMode: aBoolean
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
			| request result |
			request := tool requestFromToolCallArguments: arguments.
			^ [
			  result := tool executeWithRequest: request.
			  ((result isKindOf: MCPStructureCallToolResult)
				   ifTrue: [ result ]
				   ifFalse: [ MCPStructureCallToolResult content: result ])
				  asJRPCJSON ]
				  on: Error
				  do: [ :error |
					  (error isKindOf: JRPCError) ifTrue: [ error pass ].
					  (tool errorResultFor: error) asJRPCJSON ] ]
		ifAbsent: [ JRPCNonExistentHandler signal: name ]
]

{ #category : 'as yet unclassified' }
MCP >> rpcToolsList [

	<jrpc: #'tools/list'>
	^ { (#tools -> toolsList values asArray) } asDictionary asJRPCJSON
]

{ #category : 'accessing' }
MCP >> server [

	^ server
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
