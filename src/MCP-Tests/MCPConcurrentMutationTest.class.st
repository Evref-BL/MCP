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
MCPConcurrentMutationTest >> assertCall: anIndex succeeded: aResponse [
	"A tool error is a result too, with isError set: an answer that holds a result proves the call ran, not that it did what it was asked."

	| body |
	self
		assert: (aResponse isKindOf: ZnResponse)
		description:
		(String streamContents: [ :stream | stream << 'Call ' << anIndex asString << ' failed: ' << aResponse printString ]).
	self assert: aResponse code equals: 200.
	body := STONJSON fromString: aResponse contents.
	self
		assert: ((body includesKey: 'result') and: [ ((body at: 'result') at: 'isError' ifAbsent: [ false ]) ~= true ])
		description: (String streamContents: [ :stream | stream << 'Call ' << anIndex asString << ' answered ' << aResponse contents ])
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
MCPConcurrentMutationTest >> mostAtOnceOfThreeCallsTo: aTool on: anMCP [
	"Three calls at once, each in its own process as the server runs them, and how many of them ran together."

	| done |
	done := Semaphore new.
	3 timesRepeat: [ [ [ anMCP rpcToolCall: aTool class toolName withParams: Dictionary new ] ensure: [ done signal ] ] fork ].
	3 timesRepeat: [ self deny: (done waitTimeoutSeconds: 10) description: 'A call never answered.' ].
	^ aTool mostAtOnce
]

{ #category : 'private' }
MCPConcurrentMutationTest >> overlapRecordingToolOn: anMCP changingCode: aBoolean [

	anMCP addTool: MCPOverlapRecordingTestTool.
	^ (anMCP toolRegistry toolNamed: MCPOverlapRecordingTestTool toolName ifAbsent: [ nil ])
		  changes: aBoolean;
		  yourself
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
MCPConcurrentMutationTest >> testCallsThatChangeCodeRunOneAtATime [
	"Pharo's code model is not safe to change from two processes at once, and a server runs each call in its own, so it lets in one call that changes code at a time."

	| mcp |
	mcp := self mcpWithoutObservabilityExport.

	self assert: (self mostAtOnceOfThreeCallsTo: (self overlapRecordingToolOn: mcp changingCode: true) on: mcp) equals: 1
]

{ #category : 'tests' }
MCPConcurrentMutationTest >> testCallsThatChangeNoCodeRunTogether [
	"What makes the test above mean something: the same calls, changing no code, overlap."

	| mcp |
	mcp := self mcpWithoutObservabilityExport.

	self assert: (self mostAtOnceOfThreeCallsTo: (self overlapRecordingToolOn: mcp changingCode: false) on: mcp) > 1
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

		responses doWithIndex: [ :response :index | self assertCall: index succeeded: response ].
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
	responses doWithIndex: [ :response :index | self assertCall: index succeeded: response ].

	target := self classNamed: self scratchClassName.
	1 to: count do: [ :index |
			self assert: (target includesSelector: ('answer' , index asString) asSymbol) description: (String streamContents: [ :stream |
					 stream << 'answer' << index asString << ' was not compiled, though its call answered ' << (responses at: index) contents ]) ]
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
