"
JSON-RPC message processor specialized for MCP.

It collects handlers from jrpc pragmas and lets the base JSON-RPC processor dispatch incoming messages to those handlers.
"
Class {
	#name : 'MCPMessageProcessor',
	#superclass : 'JRPCMessageProcessor',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'handlers management' }
MCPMessageProcessor >> addHandler: aJRPCHandler [

	(self handlers includes: aJRPCHandler) ifTrue: [ "handler has been override"
		^ self ].

	handlers add: aJRPCHandler
]

{ #category : 'handlers management' }
MCPMessageProcessor >> addHandlersFromPragmasIn: anObject [

	(Pragma allNamed: #jrpc: in: anObject class) do: [ :pragma |
		self addHandler: (MCPMessageSendHandler new
				 receiver: anObject;
				 methodName: pragma arguments first;
				 messageSelector: pragma methodSelector;
				 yourself) ]
]
