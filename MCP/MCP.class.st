Class {
	#name : 'MCP',
	#superclass : 'Object',
	#instVars : [
		'server',
		'toolsList'
	],
	#category : 'MCP',
	#package : 'MCP'
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
	MCPTool allSubclasses do: [ :subclass |
			| tool |
			tool := subclass new.
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
				   yourself)
]

{ #category : 'as yet unclassified' }
MCP >> rpcNotificationInitialized [

	<jrpc: #'notifications/initialized'>
	
	
]

{ #category : 'as yet unclassified' }
MCP >> rpcPing [

	<jrpc: #ping>
	^ Dictionary new
]

{ #category : 'as yet unclassified' }
MCP >> rpcToolCall: name withParams: arguments [

	<jrpc: #'tools/call'>
	toolsList
		at: name
		ifPresent: [ :tool |
				^ (MCPStructureCallToolResult content:
					   (tool executeWithArguments: arguments)) asJRPCJSON ]
		ifAbsent: [ ToolNotFound signal ]
]

{ #category : 'as yet unclassified' }
MCP >> rpcToolsList [

	<jrpc: #'tools/list'>
	^ {(#tools -> toolsList values asArray)} asDictionary asJRPCJSON
]

{ #category : 'accessing' }
MCP >> server [
	^ server
]

{ #category : 'start' }
MCP >> start [

	
	server start.
	server addHandlersFromPragmasIn: self.
]

{ #category : 'accessing' }
MCP >> stop [
	server stop
]

{ #category : 'as yet unclassified' }
MCP >> toolsList [

	^ toolsList
]

{ #category : 'as yet unclassified' }
MCP >> toolsList: aToolsList [

	^ toolsList := aToolsList
]
