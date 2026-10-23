"
HTTP transport wrapper for the MCP JSON-RPC endpoint.

It configures a Zinc server, handles CORS and supported HTTP methods, decodes POST bodies through the message processor, and encodes JSON responses. Protocol dispatch belongs to MCPMessageProcessor and MCP, not to this transport class.
"
Class {
	#name : 'MCPHTTPServer',
	#superclass : 'JRPCHTTPServer',
	#instVars : [
		'eventStreams'
	],
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

{ #category : 'event streams' }
MCPHTTPServer >> addEventStream: anEventStream [

	eventStreams add: anEventStream
]

{ #category : 'initialization' }
MCPHTTPServer >> answerGet: request with: response [
	"A GET that accepts text/event-stream opens a notification stream. A GET that does not has no business on this endpoint, and is told so rather than left to time out on an empty reply."

	| stream |
	(self getAcceptsEventStream: request) ifFalse: [ ^ self answerMethodNotAllowedWith: response ].
	stream := MCPEventStream new.
	self addEventStream: stream.
	response headers
		at: #'Cache-Control' put: 'no-cache';
		at: #Connection put: 'keep-alive'.
	^ response
		  statusLine: ZnStatusLine ok;
		  entity: (MCPEventStreamEntity on: stream);
		  yourself
]

{ #category : 'event streams' }
MCPHTTPServer >> broadcast: aJSONString [
	"Write to every open listener, and forget the ones whose client has gone."

	self eventStreams copy do: [ :each |
			each isOpen
				ifTrue: [ each write: aJSONString ]
				ifFalse: [ eventStreams remove: each ifAbsent: [ nil ] ] ]
]

{ #category : 'event streams' }
MCPHTTPServer >> closeEventStreams [

	self eventStreams copy do: [ :each | each close ].
	eventStreams removeAll
]

{ #category : 'event streams' }
MCPHTTPServer >> eventStreams [

	^ eventStreams ifNil: [ eventStreams := OrderedCollection new ]
]

{ #category : 'private - validation' }
MCPHTTPServer >> getAcceptsEventStream: request [

	| accept |
	accept := request headers at: 'Accept' ifAbsent: [ ^ false ].
	^ accept asLowercase includesSubstring: 'text/event-stream'
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

	| payload mismatch |
	mismatch := self headerMismatchFor: request.
	mismatch ifNotNil: [
			response
				statusLine: ZnStatusLine badRequest;
				entity: (ZnEntity json: mismatch).
			^ response ].
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

{ #category : 'private - modern headers' }
MCPHTTPServer >> bodyOf: request [
	"Answer the parsed request body, or nil when it is not JSON at all. A body that cannot be parsed is the message processor's to refuse, not this check's."

	^ [ STONJSON fromString: request contents ] on: Error do: [ :error | error return: nil ]
]

{ #category : 'private - modern headers' }
MCPHTTPServer >> decodedHeaderValue: aValue [
	"A value that cannot travel as plain ASCII arrives wrapped in a sentinel, and has to be decoded before it can be compared with the body."

	| sentinelStart sentinelEnd |
	sentinelStart := '=?base64?'.
	sentinelEnd := '?='.
	((aValue beginsWith: sentinelStart) and: [ aValue endsWith: sentinelEnd ]) ifFalse: [ ^ aValue ].
	^ [
	  (ZnBase64Encoder new decode: (aValue copyFrom: sentinelStart size + 1 to: aValue size - sentinelEnd size)) utf8Decoded ]
		  on: Error
		  do: [ :error | error return: aValue ]
]

{ #category : 'private - modern headers' }
MCPHTTPServer >> headerMismatchFor: request [
	"Answer the error body for a modern request whose headers do not agree with it, or nil when there is nothing to refuse. Legacy requests carry none of these headers and are not asked to."

	| body |
	body := self bodyOf: request.
	body isDictionary ifFalse: [ ^ nil ].
	(MCP isModernRequest: (body at: 'params' ifAbsent: [ nil ])) ifFalse: [ ^ nil ].
	^ [
	  self validateModernHeadersFor: request body: body.
	  nil ]
		  on: MCPHeaderMismatch
		  do: [ :error | error return: (error asJRPCResponseWithId: (body at: 'id' ifAbsent: [ nil ])) asJRPCJSON ]
]

{ #category : 'private - modern headers' }
MCPHTTPServer >> headerNamed: aName in: request [

	^ request headers at: aName ifAbsent: [ MCPHeaderMismatch signalMissing: aName ]
]

{ #category : 'private - modern headers' }
MCPHTTPServer >> nameHeaderSourceIn: body [
	"The body field Mcp-Name mirrors: the thing the call names. Only the three methods that name something carry it."

	| params |
	params := body at: 'params' ifAbsent: [ ^ nil ].
	params isDictionary ifFalse: [ ^ nil ].
	^ (#( 'tools/call' 'prompts/get' ) includes: (body at: 'method' ifAbsent: [ '' ]))
		  ifTrue: [ params at: 'name' ifAbsent: [ nil ] ]
		  ifFalse: [
			  (body at: 'method' ifAbsent: [ '' ]) = 'resources/read'
				  ifTrue: [ params at: 'uri' ifAbsent: [ nil ] ]
				  ifFalse: [ nil ] ]
]

{ #category : 'private - modern headers' }
MCPHTTPServer >> validate: aHeaderName in: request matches: aBodyValue [

	| headerValue |
	headerValue := self decodedHeaderValue: (self headerNamed: aHeaderName in: request).
	headerValue = aBodyValue ifFalse: [
		MCPHeaderMismatch signalName: aHeaderName header: headerValue doesNotMatch: aBodyValue ]
]

{ #category : 'private - modern headers' }
MCPHTTPServer >> validateModernHeadersFor: request body: body [
	"Every modern request mirrors its method and version into headers, and the three that name something mirror that too."

	self
		validate: 'MCP-Protocol-Version'
		in: request
		matches: (MCP requestedProtocolVersionIn: (body at: 'params' ifAbsent: [ nil ])).
	self validate: 'Mcp-Method' in: request matches: (body at: 'method' ifAbsent: [ nil ]).
	(self nameHeaderSourceIn: body) ifNotNil: [ :named | self validate: 'Mcp-Name' in: request matches: named ]
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
	eventStreams := OrderedCollection new.
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

{ #category : 'starting' }
MCPHTTPServer >> stop [
	"A listener parked on its queue would otherwise keep its process alive after the server is gone."

	self closeEventStreams.
	^ super stop
]
