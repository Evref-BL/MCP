"
JSON-RPC handler that invokes a Smalltalk message on a receiver.

It is a JRPCMessageSendHandler that takes its arguments by name only: an MCP client always sends a parameters object, never a list, so a request that sends a list is invalid parameters rather than a call that happened to have the right arity. Placing the named parameters, and leaving the absent ones nil, is JRPC's own behaviour.

MCPMessageProcessor creates these handlers from jrpc pragmas.
"
Class {
	#name : 'MCPMessageSendHandler',
	#superclass : 'JRPCMessageSendHandler',
	#category : 'MCP-Transport',
	#package : 'MCP',
	#tag : 'Transport'
}

{ #category : 'accessing' }
MCPMessageSendHandler class >> defaultMethodName [

	^ self shouldNotImplement
]

{ #category : 'parameters-checking' }
MCPMessageSendHandler >> checkParametersForRequest: aJRPCRequestObject [

	| params |
	params := aJRPCRequestObject params.
	params ifNil: [
			self parametersCount = 0 ifFalse: [ JRPCInvalidParameters signal ].
			^ self ].
	params isDictionary ifFalse: [ JRPCInvalidParameters signal ]
]
