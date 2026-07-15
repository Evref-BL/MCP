"
HTTP transport wrapper for the MCP JSON-RPC endpoint.

It configures a Zinc server, handles CORS and supported HTTP methods, decodes POST bodies through the message processor, and encodes JSON responses. Protocol dispatch belongs to MCPMessageProcessor and MCP, not to this transport class.
"
Class {
	#name : 'MCPHTTPServer',
	#superclass : 'JRPCHTTPServer',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'accessing' }
MCPHTTPServer >> allowedOrigins [

	^ server optionAt: #mcpAllowedOrigins ifAbsent: [ #(  ) ]
]

{ #category : 'accessing' }
MCPHTTPServer >> allowedOrigins: originStrings [

	server optionAt: #mcpAllowedOrigins put: originStrings asSet
]

{ #category : 'initialization' }
MCPHTTPServer >> answer: request with: response [

	(self hasValidOriginFor: request) ifFalse: [ ^ self answerWithoutBody: response statusLine: ZnStatusLine forbidden ].
	self configureResponse: response for: request.
	request method = #OPTIONS ifTrue: [ ^ self answerOptionsWith: response ].
	(self hasSupportedProtocolVersionFor: request) ifFalse: [ ^ self answerWithoutBody: response statusLine: ZnStatusLine badRequest ].
	request method = #GET ifTrue: [ ^ self answerGet: request with: response ].
	request method = #POST ifTrue: [
			(self postAcceptsSupportedMediaTypes: request) ifFalse: [
				^ self answerWithoutBody: response statusLine: (ZnStatusLine code: 406) ].
			(self postHasJSONContentType: request) ifFalse: [ ^ self answerWithoutBody: response statusLine: (ZnStatusLine code: 415) ].
			^ self answerPost: request with: response ].
	^ self answerUnsupportedMethodWith: response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerGet: request with: response [
	"Codex uses Streamable HTTP. Until this server supports SSE on GET,
	answer explicitly with 405 instead of timing out with an empty reply."

	^ self answerMethodNotAllowedWith: response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerMethodNotAllowedWith: response [

	response headers at: #Allow put: 'POST, OPTIONS'.
	^ self answerWithoutBody: response statusLine: ZnStatusLine methodNotAllowed
]

{ #category : 'initialization' }
MCPHTTPServer >> answerOptionsWith: response [

	response statusLine: ZnStatusLine noContent.
	^ response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerPost: request with: response [

	| payload |
	payload := self handleJSON: request contents.
	(payload isString and: [ payload isEmpty ]) ifTrue: [ ^ self answerWithoutBody: response statusLine: ZnStatusLine accepted ].
	response
		statusLine: ZnStatusLine ok;
		entity: (ZnEntity json: payload).
	^ response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerUnsupportedMethodWith: response [

	^ self answerMethodNotAllowedWith: response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerWithoutBody: response statusLine: statusLine [

	response statusLine: statusLine.
	response headers at: #'Content-Length' put: '0'.
	^ response
]

{ #category : 'accessing' }
MCPHTTPServer >> bindingAddress [

	^ server bindingAddress
]

{ #category : 'accessing' }
MCPHTTPServer >> bindingAddress: anAddress [

	server bindingAddress: anAddress
]

{ #category : 'initialization' }
MCPHTTPServer >> configureResponse: response for: request [

	| origin |
	origin := request headers at: 'Origin' ifAbsent: [ nil ].
	origin ifNotNil: [
			response headers
				at: #'Access-Control-Allow-Origin' put: origin;
				at: #Vary put: 'Origin' ].
	response headers at: #'Access-Control-Allow-Methods' put: 'GET, POST, OPTIONS'.
	response headers
		at: #'Access-Control-Allow-Headers'
		put: 'accept, content-type, last-event-id, mcp-protocol-version, mcp-session-id'
]

{ #category : 'post response' }
MCPHTTPServer >> deferAfterCurrentResponse: aBlock [

	server deferAfterCurrentResponse: aBlock
]

{ #category : 'private - validation' }
MCPHTTPServer >> hasSupportedProtocolVersionFor: request [

	| protocolVersion |
	protocolVersion := request headers at: 'MCP-Protocol-Version' ifAbsent: [ ^ true ].
	^ MCP supportedProtocolVersions includes: protocolVersion
]

{ #category : 'private - validation' }
MCPHTTPServer >> hasValidOriginFor: request [

	| origin |
	origin := request headers at: 'Origin' ifAbsent: [ ^ true ].
	^ self isAllowedOrigin: origin
]

{ #category : 'initialization' }
MCPHTTPServer >> initialize [

	super initialize.
	messageProcessor := MCPMessageProcessor new.
	server := MCPSocketSafeZnServer new.

	server
		bindingAddress: #[ 127 0 0 1 ];
		port: self defaultPort;
		delegate: (ZnDispatcherDelegate new map: '/' to: [ :request :response | self answer: request with: response ])
]

{ #category : 'private - validation' }
MCPHTTPServer >> isAllowedOrigin: originString [

	| host url |
	(self allowedOrigins includes: originString) ifTrue: [ ^ true ].
	url := [ ZnUrl fromString: originString ]
		       on: Error
		       do: [ ^ false ].
	(#( http https ) includes: url scheme) ifFalse: [ ^ false ].
	host := url host ifNil: [ ^ false ].
	^ #( 'localhost' '127.0.0.1' '::1' ) includes: host asLowercase
]

{ #category : 'testing' }
MCPHTTPServer >> isListening [

	^ server isListening
]

{ #category : 'testing' }
MCPHTTPServer >> isRunning [

	^ server isRunning
]

{ #category : 'accessing' }
MCPHTTPServer >> localUrl [

	^ server localUrl
]

{ #category : 'private - validation' }
MCPHTTPServer >> postAcceptsSupportedMediaTypes: request [

	| accept |
	accept := request headers at: 'Accept' ifAbsent: [ ^ false ].
	accept := accept asLowercase.
	^ (accept includesSubstring: 'application/json') and: [ accept includesSubstring: 'text/event-stream' ]
]

{ #category : 'private - validation' }
MCPHTTPServer >> postHasJSONContentType: request [

	| contentType |
	contentType := request headers at: 'Content-Type' ifAbsent: [ ^ false ].
	^ contentType asLowercase beginsWith: 'application/json'
]

{ #category : 'starting' }
MCPHTTPServer >> start [

	server register.
	server start
]
