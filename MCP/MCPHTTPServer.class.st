Class {
	#name : 'MCPHTTPServer',
	#superclass : 'JRPCHTTPServer',
	#category : 'MCP-Server',
	#package : 'MCP',
	#tag : 'Server'
}

{ #category : 'initialization' }
MCPHTTPServer >> answer: request with: response [

	| origin |
	origin := request headers at: 'Origin' ifAbsent: [ '*' ].

	response headers at: #'Access-Control-Allow-Origin' put: origin.
	response headers
		at: #'Access-Control-Allow-Methods'
		put: 'GET, POST, OPTIONS'.
	response headers
		at: #'Access-Control-Allow-Headers'
		put: 'content-type, mcp-protocol-version'.
	request method = #OPTIONS
		ifTrue: [ response statusLine: ZnStatusLine noContent ]
		ifFalse: [
			response entity:
				(ZnEntity json: (self handleJSON: request contents)) ].
	^ response
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
