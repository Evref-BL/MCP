Class {
	#name : 'MCPHTTPServer',
	#superclass : 'JRPCHTTPServer',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'initialization' }
MCPHTTPServer >> answer: request with: response [

		self configureResponse: response for: request.
	request method = #OPTIONS ifTrue: [ ^ self answerOptionsWith: response ].
	request method = #GET ifTrue: [ ^ self answerGet: request with: response ].
	request method = #POST ifTrue: [ ^ self answerPost: request with: response ].
	^ self answerUnsupportedMethodWith: response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerGet: request with: response [
	"Codex uses Streamable HTTP. Until this server supports SSE on GET,
	answer explicitly with 405 instead of timing out with an empty reply."

	response statusLine: ZnStatusLine methodNotAllowed.
	^ response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerOptionsWith: response [

	response statusLine: ZnStatusLine noContent.
	^ response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerPost: request with: response [

	| requestContents payload |
	requestContents := request contents.
	payload := self handleJSON: requestContents.

	response entity: (ZnEntity json: payload).
	^ response
]

{ #category : 'initialization' }
MCPHTTPServer >> answerUnsupportedMethodWith: response [

	response statusLine: ZnStatusLine methodNotAllowed.
	^ response
]

{ #category : 'initialization' }
MCPHTTPServer >> configureResponse: response for: request [

	| origin |
	origin := request headers at: 'Origin' ifAbsent: [ '*' ].

	response headers at: #'Access-Control-Allow-Origin' put: origin.
	response headers
		at: #'Access-Control-Allow-Methods'
		put: 'GET, POST, OPTIONS'.
	response headers
		at: #'Access-Control-Allow-Headers'
		put: 'accept, content-type, last-event-id, mcp-protocol-version, mcp-session-id'
]

{ #category : 'initialization' }
MCPHTTPServer >> initialize [

	super initialize.
	messageProcessor := MCPMessageProcessor new.
	server := ZnServer defaultServerClass new.

	server
		port: self defaultPort;
		delegate: (ZnDispatcherDelegate new
				 map: '/'
				 to: [ :request :response | self answer: request with: response ])
]
