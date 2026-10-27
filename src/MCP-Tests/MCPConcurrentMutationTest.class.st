"
Tests that mutating tool calls arriving at the same time all land.

The server gives every connection its own process, so two method_compile calls really do compile at once. This was reported as the image becoming unstable under parallel calls, at a time when every successful mutation also saved the image.
"
Class {
	#name : 'MCPConcurrentMutationTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPConcurrentMutationTest >> anyOverlapBetween: startTimes and: endTimes [
	"Two calls overlapped when each began before the other ended. Without that the test would pass on a server that answered them one at a time."

	^ (1 to: startTimes size) anySatisfy: [ :left |
			  (left + 1 to: startTimes size) anySatisfy: [ :right |
				  (startTimes at: left) < (endTimes at: right) and: [ (startTimes at: right) < (endTimes at: left) ] ] ]
]

{ #category : 'private' }
MCPConcurrentMutationTest >> compilePayloadFor: anIndex [

	^ String streamContents: [ :stream |
			  stream << '{"jsonrpc":"2.0","id":' << anIndex asString
			  << ',"method":"tools/call","params":{"name":"method_compile","arguments":{"class":"' << self scratchClassName
			  << '","protocol":"generated","source":"answer' << anIndex asString << '\n\n\t^ ' << anIndex asString << '"}}}' ]
]

{ #category : 'private' }
MCPConcurrentMutationTest >> createPayloadFor: anIndex [

	^ String streamContents: [ :stream |
			  stream << '{"jsonrpc":"2.0","id":' << anIndex asString
			  << ',"method":"tools/call","params":{"name":"class_create","arguments":{"name":"' << (self generatedClassNameFor: anIndex)
			  << '","superclass":"Object","package":"' << self generatedPackageName << '"}}}' ]
]

{ #category : 'private' }
MCPConcurrentMutationTest >> generatedClassNameFor: anIndex [

	^ 'MCPConcurrentMutationMade' , anIndex asString
]

{ #category : 'private' }
MCPConcurrentMutationTest >> generatedPackageName [

	^ 'MCPConcurrentMutationGenerated'
]

{ #category : 'private' }
MCPConcurrentMutationTest >> postPayload: aPayload to: anMCP [

	| client |
	client := ZnClient new.
	^ [
		  client
			  url: anMCP server localUrl;
			  headerAt: 'Accept' put: 'application/json, text/event-stream';
			  headerAt: 'MCP-Protocol-Version' put: MCP latestProtocolVersion;
			  entity: (ZnEntity json: aPayload);
			  post.
		  client response ] ensure: [ client close ]
]

{ #category : 'private' }
MCPConcurrentMutationTest >> scratchClassName [

	^ #MCPConcurrentMutationTarget
]

{ #category : 'running' }
MCPConcurrentMutationTest >> setUp [

	super setUp.
	self
		createClassNamed: self scratchClassName
		superclassName: #Object
		slots: #(  )
		classSlots: #(  )
]

{ #category : 'running' }
MCPConcurrentMutationTest >> tearDown [

	self removeClassNamed: self scratchClassName.
	super tearDown
]

{ #category : 'tests' }
MCPConcurrentMutationTest >> testConcurrentClassCreationsAllLand [
	"The heavier mutation: the class builder rather than a method dictionary. Six classes into one package at once."

	| count completed responses |
	count := 6.
	completed := Semaphore new.
	responses := Array new: count.
	[
		self withStartedServerDo: [ :mcp |
				1 to: count do: [ :index |
						[
							[ responses at: index put: (self postPayload: (self createPayloadFor: index) to: mcp) ]
								on: Error
								do: [ :error | responses at: index put: error messageText ].
							completed signal ] fork ].
				count timesRepeat: [ self deny: (completed waitTimeoutSeconds: 30) description: 'A concurrent class creation never answered.' ] ].

		responses doWithIndex: [ :response :index |
				self assert: (response isKindOf: ZnResponse) description: 'Call ' , index asString , ' failed: ' , response printString.
				self
					assert: (response contents includesSubstring: '"result"')
					description: 'Call ' , index asString , ' answered ' , response contents ].
		1 to: count do: [ :index |
				self
					assert: (self classNamed: (self generatedClassNameFor: index)) isNotNil
					description: (self generatedClassNameFor: index) , ' was not created' ] ] ensure: [
			1 to: count do: [ :index | self removeClassNamed: (self generatedClassNameFor: index) ].
			self removePackageNamed: self generatedPackageName ]
]

{ #category : 'tests' }
MCPConcurrentMutationTest >> testConcurrentCompilesAllLand [
	"Evref-BL/MCP#169: parallel mutating calls were reported to destabilise the image, at a time when every successful mutation also saved it. Six compiles into one class at once, through the server's own transport, each on its own connection and so in its own process."

	| count completed responses startedAt finishedAt target |
	count := 6.
	completed := Semaphore new.
	responses := Array new: count.
	startedAt := Array new: count.
	finishedAt := Array new: count.
	self withStartedServerDo: [ :mcp |
			1 to: count do: [ :index |
					[
						startedAt at: index put: Time millisecondClockValue.
						[ responses at: index put: (self postPayload: (self compilePayloadFor: index) to: mcp) ]
							on: Error
							do: [ :error | responses at: index put: error messageText ].
						finishedAt at: index put: Time millisecondClockValue.
						completed signal ] fork ].
			count timesRepeat: [ self deny: (completed waitTimeoutSeconds: 30) description: 'A concurrent tool call never answered.' ] ].

	self
		assert: (self anyOverlapBetween: startedAt and: finishedAt)
		description: 'The calls did not overlap, so this proves nothing about concurrency.'.
	responses doWithIndex: [ :response :index |
			self assert: (response isKindOf: ZnResponse) description: 'Call ' , index asString , ' failed: ' , response printString.
			self assert: response code equals: 200.
			self
				assert: (response contents includesSubstring: '"result"')
				description: 'Call ' , index asString , ' answered ' , response contents ].

	target := self classNamed: self scratchClassName.
	1 to: count do: [ :index |
			self
				assert: (target includesSelector: ('answer' , index asString) asSymbol)
				description: 'answer' , index asString , ' was not compiled' ]
]

{ #category : 'private' }
MCPConcurrentMutationTest >> withStartedServerDo: aBlock [

	| mcp |
	mcp := self mcpWithoutObservabilityExport.
	mcp port: 0.
	^ [
		  mcp start.
		  aBlock value: mcp ] ensure: [ mcp stop ]
]
