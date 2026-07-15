"
Tests MCP HTTP response behavior, transport validation, and concurrent request handling.
"
Class {
	#name : 'MCPHTTPServerTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Server',
	#package : 'MCP-Tests',
	#tag : 'Server'
}

{ #category : 'private' }
MCPHTTPServerTest >> postRequestWithContents: contents [

	| request |
	request := ZnRequest method: #POST url: ZnUrl new.
	request entity: (ZnEntity json: contents).
	request headers
		at: 'Accept' put: 'application/json, text/event-stream';
		at: 'Content-Type' put: 'application/json'.
	^ request
]

{ #category : 'private' }
MCPHTTPServerTest >> responseForMethod: method [

	| request |
	request := ZnRequest method: method url: ZnUrl new.
	^ self responseForRequest: request using: MCPHTTPServer new
]

{ #category : 'private' }
MCPHTTPServerTest >> responseForRequest: request using: server [

	^ server answer: request with: ZnResponse new
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAcceptsSupportedProtocolVersion [

	| request response |
	request := ZnRequest method: #GET url: ZnUrl new.
	request headers at: 'MCP-Protocol-Version' put: '2025-11-25'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 405
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAllowsExplicitlyConfiguredOrigin [

	| request response server |
	server := MCPHTTPServer new.
	server allowedOrigins: #( 'https://tools.example' ).
	request := ZnRequest method: #GET url: ZnUrl new.
	request headers at: 'Origin' put: 'https://tools.example'.
	response := self responseForRequest: request using: server.
	self assert: response code equals: 405.
	self assert: (response headers at: #'Access-Control-Allow-Origin') equals: 'https://tools.example'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAllowsLoopbackOriginAndReturnsCORSHeaders [

	| request response |
	request := ZnRequest method: #GET url: ZnUrl new.
	request headers at: 'Origin' put: 'http://localhost:3000'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 405.
	self assert: (response headers at: #'Access-Control-Allow-Origin') equals: 'http://localhost:3000'.
	self assert: (response headers at: #Vary) equals: 'Origin'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testGetResponseIsExplicitlyEmpty [

	| response |
	response := self responseForMethod: #GET.
	self assert: response code equals: 405.
	self assert: (response headers at: #'Content-Length') equals: '0'.
	self assert: (response headers at: #Allow) equals: 'POST, OPTIONS'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testHandlesConcurrentPostRequests [

	| completed responses server |
	completed := Semaphore new.
	responses := Array new: 4.
	server := MCP new server.
	[
		server port: 0.
		server start.
		1 to: responses size do: [ :index |
				[
					| client payload |
					client := ZnClient new.
					[
						payload := '{"jsonrpc":"2.0","id":' , index asString
						           ,
						           ',"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{},"websiteUrl":null}}'.
						client
							url: server localUrl;
							headerAt: 'Accept' put: 'application/json, text/event-stream';
							headerAt: 'MCP-Protocol-Version' put: '2025-11-25';
							entity: (ZnEntity json: payload);
							post.
						responses at: index put: client response ] ensure: [
							client close.
							completed signal ] ] fork ].
		responses size timesRepeat: [ self deny: (completed waitTimeoutSeconds: 10) description: 'Concurrent HTTP request timed out.' ].
		responses doWithIndex: [ :response :index |
				self assert: response notNil description: 'No response at index ' , index asString.
				self assert: response code = 200 description: 'Unexpected response at index ' , index asString , ': ' , response printString.
				self
					assert: (response contents includesSubstring: '"result"')
					description: 'Unexpected body at index ' , index asString , ': ' , response contents ] ] ensure: [ server stop ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testMalformedJSONReturnsJSONRPCError [

	| request response |
	request := self postRequestWithContents: '{'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 200.
	self assert: response contentType equals: ZnMimeType applicationJson.
	self assert: (response contents includesSubstring: '"error"')
]

{ #category : 'tests' }
MCPHTTPServerTest >> testNotificationReturnsExplicitlyEmptyAcceptedResponse [

	| request response |
	request := self postRequestWithContents: '{"jsonrpc":"2.0","method":"notifications/initialized"}'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 202.
	self assert: (response headers at: #'Content-Length') equals: '0'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testOptionsRemainsBodylessWithoutContentLength [

	| response |
	response := self responseForMethod: #OPTIONS.
	self assert: response code equals: 204.
	self deny: (response headers includesKey: #'Content-Length')
]

{ #category : 'tests' }
MCPHTTPServerTest >> testPostRequiresJSONContentType [

	| request response |
	request := self postRequestWithContents: '{}'.
	request headers at: 'Content-Type' put: 'text/plain'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 415.
	self assert: (response headers at: #'Content-Length') equals: '0'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testPostRequiresSupportedAcceptTypes [

	| request response |
	request := self postRequestWithContents: '{}'.
	request headers at: 'Accept' put: 'application/json'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 406.
	self assert: (response headers at: #'Content-Length') equals: '0'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testRejectsNonLoopbackOrigin [

	| request response |
	request := ZnRequest method: #GET url: ZnUrl new.
	request headers at: 'Origin' put: 'https://attacker.example'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 403.
	self assert: (response headers at: #'Content-Length') equals: '0'.
	self deny: (response headers includesKey: #'Access-Control-Allow-Origin')
]

{ #category : 'tests' }
MCPHTTPServerTest >> testRejectsUnsupportedProtocolVersion [

	| request response |
	request := ZnRequest method: #GET url: ZnUrl new.
	request headers at: 'MCP-Protocol-Version' put: '1900-01-01'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: response code equals: 400.
	self assert: (response headers at: #'Content-Length') equals: '0'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testServerBindsToLoopbackByDefault [

	self assert: MCPHTTPServer new bindingAddress equals: #[ 127 0 0 1 ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testUnsupportedMethodResponseIsExplicitlyEmpty [

	| response |
	response := self responseForMethod: #DELETE.
	self assert: response code equals: 405.
	self assert: (response headers at: #'Content-Length') equals: '0'.
	self assert: (response headers at: #Allow) equals: 'POST, OPTIONS'
]
