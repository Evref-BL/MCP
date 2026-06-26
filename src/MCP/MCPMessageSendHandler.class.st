"
JSON-RPC handler that invokes a Smalltalk message on a receiver.

It maps dictionary parameters to the target method argument order and sends the configured selector to the configured receiver. MCPMessageProcessor creates these handlers from jrpc pragmas.
"
Class {
	#name : 'MCPMessageSendHandler',
	#superclass : 'JRPCMessageSendHandler',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'accessing' }
MCPMessageSendHandler class >> defaultMethodName [

	^ self shouldNotImplement
]

{ #category : 'private' }
MCPMessageSendHandler >> argumentsFromParameters: parameters [

	parameters ifNil: [ ^ #(  ) ].
	parameters isDictionary ifFalse: [ ^ parameters ].
	^ (self parametersNames collect: [ :name |
		   parameters at: name ifAbsent: [ nil ] ]) asArray
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

{ #category : 'evaluation' }
MCPMessageSendHandler >> executeWithArguments: parameters [

	^ self
		  send: self messageSelector
		  to: self receiver
		  with: (self argumentsFromParameters: parameters)
]

{ #category : 'accessing' }
MCPMessageSendHandler >> parametersNames [

	^ (self receiver class lookupSelector: self messageSelector)
		  argumentNames
]
