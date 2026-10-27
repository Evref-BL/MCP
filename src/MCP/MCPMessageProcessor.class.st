"
JSON-RPC message processor specialized for MCP.

It collects handlers from jrpc pragmas and lets the base JSON-RPC processor dispatch incoming messages to those handlers.
"
Class {
	#name : 'MCPMessageProcessor',
	#superclass : 'JRPCMessageProcessor',
	#category : 'MCP-Transport',
	#package : 'MCP',
	#tag : 'Transport'
}

{ #category : 'private - results' }
MCPMessageProcessor >> addCachingHintsFor: aMethodName to: aResult [
	"The revision requires a freshness hint on the answers worth caching. A client that listens for list_changed is told immediately when a catalog moves, so the hint saves it refetches in between rather than standing in for the notification."

	| hint |
	hint := self cachingHints at: aMethodName ifAbsent: [ ^ aResult ].
	^ aResult
		  at: #ttlMs put: (hint at: #ttlMs);
		  at: #cacheScope put: (hint at: #cacheScope);
		  yourself
]

{ #category : 'handlers management' }
MCPMessageProcessor >> addHandler: aJRPCHandler [

	(self handlers includes: aJRPCHandler) ifTrue: [ "handler has been override" ^ self ].

	handlers add: aJRPCHandler
]

{ #category : 'handlers management' }
MCPMessageProcessor >> addHandlersFromPragmasFrom: aSubClass to: aSuperClass for: anObject [

	(Pragma allNamed: #jrpc: from: aSubClass to: aSuperClass) do: [ :pragma |
			self addHandler: (MCPMessageSendHandler new
					 receiver: anObject;
					 methodName: pragma arguments first;
					 messageSelector: pragma methodSelector;
					 yourself) ]
]

{ #category : 'handlers management' }
MCPMessageProcessor >> addHandlersFromPragmasIn: anObject [

	self addHandlersFromPragmasFrom: anObject class to: MCP for: anObject
]

{ #category : 'private - results' }
MCPMessageProcessor >> cachingHints [
	"Public for the catalogs: they describe one image and are the same for everyone asking it, with nothing in them belonging to a caller. Private for a resource's contents, which is where anything caller-specific would first appear."

	| catalog |
	catalog := Dictionary new
		           at: #ttlMs put: MCP catalogCacheMilliseconds;
		           at: #cacheScope put: 'public';
		           yourself.
	^ Dictionary new
		  at: 'server/discover' put: catalog;
		  at: 'tools/list' put: catalog;
		  at: 'prompts/list' put: catalog;
		  at: 'resources/list' put: catalog;
		  at: 'resources/templates/list' put: catalog;
		  at: 'resources/read' put: (Dictionary new
				   at: #ttlMs put: MCP resourceContentsCacheMilliseconds;
				   at: #cacheScope put: 'private';
				   yourself);
		  yourself
]

{ #category : 'private - errors' }
MCPMessageProcessor >> errorResponseFor: anException inEraOf: aJRPCRequestObject [
	"Some conditions were renumbered between the eras, so a modern request is answered with the code its revision gives the condition."

	| response |
	response := anException asJRPCResponseWithId: aJRPCRequestObject id.
	(MCP isModernRequest: aJRPCRequestObject params) ifFalse: [ ^ response ].
	response error code: (self modernErrorCodes at: response error code ifAbsent: [ response error code ]).
	^ response
]

{ #category : 'handling - jrpc' }
MCPMessageProcessor >> handleJRPCRequestObject: aJRPCRequestObject [

	^ [
		  | handler result |
		  self validateProtocolVersionFor: aJRPCRequestObject.
		  handler := self handlerFor: aJRPCRequestObject.
		  handler checkParametersForRequest: aJRPCRequestObject.
		  result := handler executeWithArguments: aJRPCRequestObject params.
		  JRPCSuccessResponseObject
			  id: aJRPCRequestObject id
			  result: (self resultFor: result inEraOf: aJRPCRequestObject) ]
		  on: Exception
		  do: [ :exception |
				  self debugMode
					  ifTrue: [ exception pass ]
					  ifFalse: [ exception return: (self responseForException: exception request: aJRPCRequestObject) ] ]
]

{ #category : 'handling - json' }
MCPMessageProcessor >> handleJSON: aJSONString [

	| jrpcResponse |
	jrpcResponse := [ (self parseSupposedJRPCMessageObjectFromString: aJSONString) beHandledBy: self ]
		                on: Exception
		                do: [ :exception |
				                self debugMode
					                ifTrue: [ exception pass ]
					                ifFalse: [ exception return: exception asJRPCResponse ] ].
	^ jrpcResponse beConvertedBy: self
]

{ #category : 'private - errors' }
MCPMessageProcessor >> modernErrorCodes [
	"The conditions the 2026-07-28 revision renumbered, old code to new. Everything absent here answers the same code in both eras."

	^ { (-32002 -> -32602) } asDictionary
]

{ #category : 'private - errors' }
MCPMessageProcessor >> responseForException: anException request: aJRPCRequestObject [

	aJRPCRequestObject isNotification ifTrue: [
			anException isIncorrectJSON ifTrue: [ ^ anException asJRPCResponseWithId: aJRPCRequestObject id ].
			^ JRPCEmptyResponseObject new ].
	^ self errorResponseFor: anException inEraOf: aJRPCRequestObject
]

{ #category : 'private - results' }
MCPMessageProcessor >> resultFor: aResult inEraOf: aJRPCRequestObject [
	"A request that declares its own protocol version is answered in that era's shape, where every result says what kind it is. This server never produces the other kind, input_required, because it asks the client for nothing."

	aResult ifNil: [ ^ nil ].
	(MCP isModernRequest: aJRPCRequestObject params) ifFalse: [ ^ aResult ].
	^ self
		  addCachingHintsFor: aJRPCRequestObject method
		  to: (aResult asJRPCJSON
				   at: #resultType put: 'complete';
				   yourself)
]

{ #category : 'handling - jrpc' }
MCPMessageProcessor >> validateProtocolVersionFor: aJRPCRequestObject [
	"A request that declares its own protocol version is answered only if the server implements that version. server/discover is exempt: it is how a client learns which versions those are, so refusing it would leave a client nothing to retry with."

	| requested |
	aJRPCRequestObject method = 'server/discover' ifTrue: [ ^ self ].
	requested := MCP requestedProtocolVersionIn: aJRPCRequestObject params.
	requested ifNil: [ ^ self ].
	(MCP supportedProtocolVersions includes: requested) ifFalse: [ MCPUnsupportedProtocolVersion signalRequested: requested ]
]
