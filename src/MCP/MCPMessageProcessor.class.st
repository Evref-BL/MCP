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

{ #category : 'handling - jrpc' }
MCPMessageProcessor >> handleJRPCRequestObject: aJRPCRequestObject [

	^ [
	  | handler result |
	  handler := self handlerFor: aJRPCRequestObject.
	  handler checkParametersForRequest: aJRPCRequestObject.
	  result := handler executeWithArguments: aJRPCRequestObject params.
	  JRPCSuccessResponseObject id: aJRPCRequestObject id result: result ]
		  on: Exception
		  do: [ :exception |
			  self debugMode
				  ifTrue: [ exception pass ]
				  ifFalse: [
					  exception return:
						  (self
							   responseForException: exception
							   request: aJRPCRequestObject) ] ]
]

{ #category : 'handling - json' }
MCPMessageProcessor >> handleJSON: aJSONString [

	| jrpcResponse |
	jrpcResponse := [
	                (self parseSupposedJRPCMessageObjectFromString:
		                 aJSONString) beHandledBy: self ]
		                on: Exception
		                do: [ :exception |
			                self debugMode
				                ifTrue: [ exception pass ]
				                ifFalse: [
				                exception return: exception asJRPCResponse ] ].
	^ jrpcResponse beConvertedBy: self
]

{ #category : 'private - errors' }
MCPMessageProcessor >> responseForException: anException request: aJRPCRequestObject [

	aJRPCRequestObject isNotification ifTrue: [
			anException isIncorrectJSON ifTrue: [
				^ anException asJRPCResponseWithId: aJRPCRequestObject id ].
			^ JRPCEmptyResponseObject new ].
	^ anException asJRPCResponseWithId: aJRPCRequestObject id
]
