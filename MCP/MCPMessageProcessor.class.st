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

{ #category : 'as yet unclassified' }
MCPMessageProcessor >> handleJRPCSuccessResponseObject: aJRPCSuccessResponseObject [

	^ JRPCEmptyResponseObject new
]
