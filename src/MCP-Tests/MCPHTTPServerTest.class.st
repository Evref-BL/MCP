"
Tests MCP HTTP response behavior, transport validation, and concurrent request handling.
"
Class {
	#name : 'MCPHTTPServerTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPHTTPServerTest >> answerTo: someLines on: aServer [
	"The response aServer gives a request sent as it is, someLines joined by CRLF, as no client library would send it."

	| stream |
	stream := ZnNetworkingUtils socketStreamToUrl: aServer localUrl.
	^ [
		  stream
			  nextPutAll: (String crlf join: someLines) asByteArray;
			  flush.
		  ZnResponse readFrom: stream ] ensure: [ stream close ]
]

{ #category : 'private' }
MCPHTTPServerTest >> post: anEntity to: aPath on: aServer [
	"The response a client gets posting anEntity to aPath of aServer, over HTTP."

	| client |
	client := ZnClient new.
	^ [
		  client
			  url: (aServer localUrl withRelativeReference: aPath);
			  headerAt: 'Accept' put: 'application/json, text/event-stream';
			  entity: anEntity;
			  post.
		  client response ] ensure: [ client close ]
]

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
MCPHTTPServerTest >> refusalIn: response withStatus: anInteger [
	"Answer the JSON-RPC error response a refusal carries, after checking it is one a client can read."

	| body |
	self assert: response code equals: anInteger.
	self assert: response contentType equals: ZnMimeType applicationJson.
	self assert: (response headers at: #'Content-Length') equals: response contents size printString.
	body := STONJSON fromString: response contents.
	self assert: (body at: 'jsonrpc') equals: '2.0'.
	self assert: (body includesKey: 'id').
	self assert: ((body at: 'error') at: 'code') isInteger.
	self assert: ((body at: 'error') at: 'message') isString.
	^ body
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
MCPHTTPServerTest >> testABackgroundForkLeavesCallsAnswered [
	"The virtual machine reads its sockets only when the image tells it to, which the idle process does once nothing else runs. Longer work runs in a fork below every evaluation and computes while nothing else does, and a call must still be accepted, read and answered meanwhile."

	| answer client completed fork server |
	self timeLimit: 30 seconds.
	completed := Semaphore new.
	server := (MCP new
		           observabilityExportDirectory: nil;
		           yourself) server.
	[
		server port: 0.
		server start.
		fork := [ [ true ] whileTrue ] forkAt: Processor userBackgroundPriority named: 'mcp-background-fork-probe'.
		client := [
			          | znClient |
			          znClient := ZnClient new.
			          [
				          znClient
					          url: server localUrl;
					          headerAt: 'Accept' put: 'application/json, text/event-stream';
					          headerAt: 'MCP-Protocol-Version' put: '2025-11-25';
					          entity: (ZnEntity json: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}');
					          post.
				          answer := znClient response ] ensure: [
					          znClient close.
					          completed signal ] ] fork.
		self deny: (completed waitTimeoutSeconds: 5) description: 'A call got no answer while a fork computed below it.'.
		self assert: answer code equals: 200.
		self assert: (answer contents includesSubstring: '"tools"') ] ensure: [
			client ifNotNil: [ client terminate ].
			fork ifNotNil: [ fork terminate ].
			server stop ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testABatchInsideABatchIsAnInvalidRequest [
	"A batch holds requests; a list inside one is answered as an invalid request, and the requests beside it as usual."

	| answers |
	answers := STONJSON fromString: (self
			            responseForRequest:
			            (self postRequestWithContents:
				             '[[{"jsonrpc":"2.0","id":1,"method":"ping"}],{"jsonrpc":"2.0","id":2,"method":"ping"}]')
			            using: (MCP new
					             observabilityExportDirectory: nil;
					             yourself) server) contents.
	self assert: answers size equals: 2.
	self assert: ((answers first at: 'error') at: 'code') equals: -32600.
	self assert: (answers first at: 'id') isNil.
	self assert: (answers second at: 'id') equals: 2.
	self assert: (answers second includesKey: 'result')
]

{ #category : 'tests' }
MCPHTTPServerTest >> testABodyThatIsNotJSONIsAParseErrorWith400 [
	"A body that is not JSON is no message the server can accept, which Streamable HTTP answers with 400."

	| body |
	body := self refusalIn: (self responseForRequest: (self postRequestWithContents: '{') using: MCPHTTPServer new) withStatus: 400.
	self assert: ((body at: 'error') at: 'code') equals: -32700
]

{ #category : 'tests' }
MCPHTTPServerTest >> testABodyThatIsNotUTF8IsAParseError [
	"Zinc refuses such a body before the endpoint sees it; the refusal is still JSON-RPC."

	| body |
	self timeLimit: 30 seconds.
	self withServerDo: [ :server |
			body := self
				        refusalIn:
				        (self post: (ZnEntity with: #[ 123 34 97 34 58 34 255 34 125 ] type: ZnMimeType applicationJson) to: '' on: server)
				        withStatus: 400.
			self assert: ((body at: 'error') at: 'code') equals: -32700 ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testABodyTooLargeToReadIsRefusedWith413 [

	| body |
	self timeLimit: 30 seconds.
	self withServerDo: [ :server |
			(server instVarNamed: #server) maximumEntitySize: 64.
			body := self
				        refusalIn:
				        (self
					         post: (ZnEntity json: (String new: 200 withAll: $ ) , '{"jsonrpc":"2.0","id":1,"method":"ping"}')
					         to: ''
					         on: server)
				        withStatus: 413.
			self assert: ((body at: 'error') at: 'message') isString ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAComputingEvaluationLeavesOtherCallsAnswered [
	"An evaluation runs below the process serving its call, so while one computes the server still answers other calls. The evaluated code computes until the listing has its answer, which the listing asks for once the code computes, so the listing comes first only when it was answered meanwhile; otherwise the evaluation's time limit ends it first. The clients run at the priority calls are served at, since this test's own process gets no turn while the evaluation computes."

	| answers completed server |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	completed := Semaphore new.
	answers := SharedQueue new.
	server := (MCP new
		           observabilityExportDirectory: nil;
		           yourself) server.
	[
		server port: 0.
		server start.
		{
			(#evaluation -> false
			 ->
			 '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"evaluate","arguments":{"code":"MCPEvaluateTestProbe computeUntilReleased","timeoutSeconds":3}}}').
			(#listing -> true -> '{"jsonrpc":"2.0","id":2,"method":"tools/list"}') } do: [ :call |
				[
					| client deadline |
					client := ZnClient new.
					[
						deadline := Time millisecondClockValue + 10000.
						[ call key value and: [ MCPEvaluateTestProbe holder isNil and: [ Time millisecondClockValue < deadline ] ] ] whileTrue: [
							(Delay forMilliseconds: 5) wait ].
						client
							url: server localUrl;
							headerAt: 'Accept' put: 'application/json, text/event-stream';
							headerAt: 'MCP-Protocol-Version' put: '2025-11-25';
							entity: (ZnEntity json: call value);
							post.
						answers nextPut: call key key -> client response ] ensure: [
							client close.
							MCPEvaluateTestProbe release.
							completed signal ] ] forkAt: Processor lowIOPriority ].
		2 timesRepeat: [ self deny: (completed waitTimeoutSeconds: 20) description: 'A call got no answer.' ].
		self assert: answers size equals: 2.
		answers next in: [ :listing |
				self assert: listing key equals: #listing.
				self assert: listing value code equals: 200.
				self assert: (listing value contents includesSubstring: '"tools"') ].
		answers next in: [ :evaluation |
				self assert: evaluation key equals: #evaluation.
				self assert: evaluation value code equals: 200.
				self assert: (evaluation value contents includesSubstring: '"text":"MCPEvaluateTestProbe"') ] ] ensure: [
			MCPEvaluateTestProbe release.
			server stop ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAGetWithoutAnEventStreamIsRefused [

	| response |
	response := self responseForMethod: #GET.
	self refusalIn: response withStatus: 405.
	self assert: (response headers at: #Allow) equals: 'POST, OPTIONS'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAModernRequestMissingAHeaderIsRefused [
	"A modern request mirrors its version and method into headers. One sent without them is refused with an error naming the request it refuses."

	| request body |
	request := self postRequestWithContents: (String streamContents: [ :stream |
				            stream
				            << '{"jsonrpc":"2.0","id":7,"method":"tools/list","params":{"_meta":{"io.modelcontextprotocol/protocolVersion":"'
				            << MCP latestProtocolVersion << '"}}}' ]).
	body := self refusalIn: (self responseForRequest: request using: MCPHTTPServer new) withStatus: 400.
	self assert: (body at: 'id') equals: 7.
	self assert: ((body at: 'error') at: 'code') equals: MCPHeaderMismatch errorCode
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAPathTheEndpointIsNotAtIsNotFound [

	self timeLimit: 30 seconds.
	self withServerDo: [ :server |
			| body |
			body := self
				        refusalIn: (self post: (ZnEntity json: '{"jsonrpc":"2.0","id":1,"method":"ping"}') to: 'mcp/tools' on: server)
				        withStatus: 404.
			self assert: ((body at: 'error') at: 'message') equals: 'Not Found: this server answers at /mcp.' ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAPostToMcpReachesTheEndpoint [
	"/mcp is the path many clients put after the server's address by default, some with a slash after it."

	self timeLimit: 30 seconds.
	self withServerDo: [ :server |
			#( 'mcp' 'mcp/' ) do: [ :each |
					| response |
					response := self post: (ZnEntity json: '{"jsonrpc":"2.0","id":1,"method":"ping"}') to: each on: server.
					self assert: response code equals: 200.
					self assert: ((STONJSON fromString: response contents) includesKey: 'result') ] ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAPreflightAllowsTheHeadersAModernRequestSends [
	"A browser leaves out of the request any header its preflight was not told it may send, and a modern request without these is refused."

	| request response allowed |
	request := ZnRequest method: #OPTIONS url: ZnUrl new.
	request headers at: 'Origin' put: 'http://localhost:3000'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	allowed := ((response headers at: #'Access-Control-Allow-Headers') substrings: ', ') collect: [ :each | each asLowercase ].
	#( 'mcp-protocol-version' 'mcp-method' 'mcp-name' ) do: [ :each | self assert: (allowed includes: each) description: each ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testARequestZincCannotReadIsAParseError [
	"Zinc's readers fail on these with a plain error, which went unhandled in the worker and quit a headless image. Each is answered as a request that could not be read, and the server goes on answering."

	| ping |
	self timeLimit: 30 seconds.
	ping := '{"jsonrpc":"2.0","id":1,"method":"ping"}'.
	self withServerDo: [ :server |
			{
				#( 'POST / HTTP/1.1' 'Host: 127.0.0.1' 'Content-Type: application/json' 'Content-Length: abc' '' '{}' ).
				#( 'POST / HTTP/1.1' 'Host: 127.0.0.1' 'Content-Type: application/json' 'Content-Length: ' '' '{}' ).
				#( 'POST / HTTP/1.1' 'Host: 127.0.0.1' 'Content-Type: application/json' 'Transfer-Encoding: chunked'
				   '' 'zz' '{}' '0' '' '' ).
				#( 'POST / HTTP/1.1' 'Host: 127.0.0.1' 'Content-Type: application/json' 'Content-Encoding: gzip' 'Content-Length: 2'
				   '' '{}' ) } do: [ :each |
					| body |
					body := self refusalIn: (self answerTo: each on: server) withStatus: 400.
					self assert: ((body at: 'error') at: 'code') = -32700 description: (each at: 4) ].
			self assert: (self post: (ZnEntity json: ping) to: '' on: server) code equals: 200 ]
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
MCPHTTPServerTest >> testAnEmptyBodyIsAParseError [

	self timeLimit: 30 seconds.
	self withServerDo: [ :server |
			#( '0' '-1' ) do: [ :each |
					| body |
					body := self
						        refusalIn: (self
								         answerTo: {
										         'POST / HTTP/1.1'.
										         'Host: 127.0.0.1'.
										         'Accept: application/json, text/event-stream'.
										         'Content-Type: application/json'.
										         ('Content-Length: ' , each).
										         ''.
										         '' }
								         on: server)
						        withStatus: 400.
					self assert: ((body at: 'error') at: 'code') = -32700 description: each ] ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAnErrorServingAConnectionEndsOnlyThatConnection [
	"Here the answer to a request that could not be read cannot be written either. Unhandled in the worker, that error would quit a headless image."

	| request |
	request := String crlf join: #( 'POST / HTTP/1.1' 'Host: 127.0.0.1' 'Content-Length: abc' '' '' ).
	self shouldnt: [ MCPSocketSafeZnServer new executeRequestResponseLoopOn: (ReadStream on: request asByteArray) ] raise: Error
]

{ #category : 'tests' }
MCPHTTPServerTest >> testAnUnsupportedMethodIsRefused [

	| response |
	response := self responseForMethod: #DELETE.
	self refusalIn: response withStatus: 405.
	self assert: (response headers at: #Allow) equals: 'POST, OPTIONS'
]

{ #category : 'tests' }
MCPHTTPServerTest >> testHandlesConcurrentPostRequests [

	| completed responses server |
	completed := Semaphore new.
	responses := Array new: 4.
	server := MCP new server.
	"A failure says what was raised."
	server messageProcessor includesErrorData: true.
	[
		server port: 0.
		server start.
		1 to: responses size do: [ :index |
				[
					| client payload |
					client := ZnClient new.
					[
						payload := String streamContents: [ :stream |
								           stream << '{"jsonrpc":"2.0","id":' << index asString
								           << ',"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{}}}' ].
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
				self assert: response isNotNil description: 'No response at index ' , index asString.
				self
					assert: response code = 200
					description:
					(String streamContents: [ :stream |
						 stream << 'Unexpected response at index ' << index asString << ': ' << response printString ]).
				self
					assert: (response contents includesSubstring: '"result"')
					description:
					(String streamContents: [ :stream | stream << 'Unexpected body at index ' << index asString << ': ' << response contents ]) ] ]
		ensure: [ server stop ]
]

{ #category : 'tests' }
MCPHTTPServerTest >> testJSONThatIsNoMessageIsRefusedWith400 [
	"Neither an object nor a list of them, it is no message the server can accept, like a body that is not JSON."

	#( 'null' '42' '"ping"' ) do: [ :each |
			| body |
			body := self
				        refusalIn: (self responseForRequest: (self postRequestWithContents: each) using: MCPHTTPServer new)
				        withStatus: 400.
			self assert: ((body at: 'error') at: 'code') = -32600 description: each ]
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

	| request |
	request := self postRequestWithContents: '{}'.
	request headers at: 'Content-Type' put: 'text/plain'.
	self refusalIn: (self responseForRequest: request using: MCPHTTPServer new) withStatus: 415
]

{ #category : 'tests' }
MCPHTTPServerTest >> testPostRequiresSupportedAcceptTypes [

	| request |
	request := self postRequestWithContents: '{}'.
	request headers at: 'Accept' put: 'application/json'.
	self refusalIn: (self responseForRequest: request using: MCPHTTPServer new) withStatus: 406
]

{ #category : 'tests' }
MCPHTTPServerTest >> testRejectsNonLoopbackOrigin [

	| request response |
	request := ZnRequest method: #GET url: ZnUrl new.
	request headers at: 'Origin' put: 'https://attacker.example'.
	response := self responseForRequest: request using: MCPHTTPServer new.
	self assert: ((self refusalIn: response withStatus: 403) at: 'id') isNil.
	self deny: (response headers includesKey: #'Access-Control-Allow-Origin')
]

{ #category : 'tests' }
MCPHTTPServerTest >> testRejectsUnsupportedProtocolVersion [
	"The refusal lists the versions this server supports, so a client can retry with one of them."

	| request error |
	request := ZnRequest method: #GET url: ZnUrl new.
	request headers at: 'MCP-Protocol-Version' put: '1900-01-01'.
	error := (self refusalIn: (self responseForRequest: request using: MCPHTTPServer new) withStatus: 400) at: 'error'.
	self assert: (error at: 'code') equals: MCPUnsupportedProtocolVersion errorCode.
	self assert: ((error at: 'data') at: 'requested') equals: '1900-01-01'.
	self assert: ((error at: 'data') at: 'supported') asArray equals: MCP supportedProtocolVersions asArray
]

{ #category : 'tests' }
MCPHTTPServerTest >> testServerBindsToLoopbackByDefault [

	self assert: MCPHTTPServer new bindingAddress equals: #[ 127 0 0 1 ]
]

{ #category : 'private' }
MCPHTTPServerTest >> withServerDo: aBlock [
	"Runs aBlock with a server listening on a port the system chose, and stops it after."

	| server |
	server := (MCP new
		           observabilityExportDirectory: nil;
		           yourself) server.
	server port: 0.
	server start.
	^ [ aBlock value: server ] ensure: [ server stop ]
]
