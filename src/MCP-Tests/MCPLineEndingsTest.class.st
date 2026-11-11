"
Tests that text crosses the protocol boundary with the line endings each side expects: carriage returns inside the image, line feeds outside it, whichever message, tool or argument carries it.
"
Class {
	#name : 'MCPLineEndingsTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPLineEndingsTest >> answerTextOf: aToolName arguments: someArgumentsInJSON [
	"The text a client reads after calling the tool with these arguments, written as a client writes them, in JSON."

	| answer |
	answer := STONJSON fromString: (self handleJSON: (String streamContents: [ :stream |
					            stream << '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"' << aToolName << '","arguments":'
					            << someArgumentsInJSON << '}}' ])).
	^ ((answer at: 'result') at: 'content') first at: 'text'
]

{ #category : 'private' }
MCPLineEndingsTest >> handleJSON: aJSONString [

	^ self mcpWithoutObservabilityExport server messageProcessor handleJSON: aJSONString
]

{ #category : 'private' }
MCPLineEndingsTest >> targetClassName [

	^ 'MCPLineEndingsTestTarget'
]

{ #category : 'tests' }
MCPLineEndingsTest >> testAMethodWrittenWithLineFeedsIsCompiledWithCarriageReturns [
	"A client writes code with line feeds, and Pharo keeps it with carriage returns, a string literal spanning lines included."

	| target |
	target := self
		          createClassNamed: self targetClassName
		          superclassName: 'Object'
		          slots: #(  )
		          classSlots: #(  ).
	[
		self answerTextOf: 'method_compile' arguments: (String streamContents: [ :stream |
				 stream << '{"class":"' << self targetClassName << '","protocol":"tests","source":"answer\n\t^ ''one\ntwo''"}' ]).
		self deny: ((target >> #answer) sourceCode includes: Character lf).
		self assert: target new answer equals: (String streamContents: [ :stream | stream << 'one' << String cr << 'two' ]) ] ensure: [
		self removeClassNamed: self targetClassName ]
]

{ #category : 'tests' }
MCPLineEndingsTest >> testANotificationLeavesWithLineFeeds [

	| notification |
	notification := STONJSON fromString: (MCPEventStream new
			                 notificationFor: 'notifications/message'
			                 parameters:
			                 { ('data' -> (String streamContents: [ :stream | stream << 'one' << String cr << 'two' ])) } asDictionary).
	self
		assert: ((notification at: 'params') at: 'data')
		equals: (String streamContents: [ :stream | stream << 'one' << String lf << 'two' ])
]

{ #category : 'tests' }
MCPLineEndingsTest >> testAnAnswerLeavesWithLineFeeds [

	self
		assert: (self answerTextOf: 'image_evaluate' arguments: '{"code":"''one'' , String cr , ''two''"}')
		equals: (String streamContents: [ :stream | stream << '''one' << String lf << 'two''' ])
]

{ #category : 'tests' }
MCPLineEndingsTest >> testAnArgumentArrivesWithCarriageReturns [
	"Evaluated code is read as a Playground reads it: a newline written inside a string literal is a carriage return there too."

	self
		assert: (self answerTextOf: 'image_evaluate' arguments: '{"code":"''one\ntwo'' = (''one'' , String cr , ''two'')"}')
		equals: 'true'
]

{ #category : 'tests' }
MCPLineEndingsTest >> testEnteringEndsEveryLineWithACarriageReturn [

	self
		assert: (MCPLineEndings entering:
				 (String streamContents: [ :stream | stream << 'one' << String lf << 'two' << String crlf << 'three' << String cr << 'four' ]))
		equals:
		(String streamContents: [ :stream | stream << 'one' << String cr << 'two' << String cr << 'three' << String cr << 'four' ])
]

{ #category : 'tests' }
MCPLineEndingsTest >> testEveryStringOfAMessageIsConverted [
	"A tool's arguments sit deep in a message, in objects and arrays. Numbers, booleans and null carry no text and stay as they are."

	self
		assert: (MCPLineEndings entering: (STONJSON fromString:
					  '{"params":{"arguments":{"source":["one\ntwo",{"comment":"three\nfour"}],"count":2,"force":true,"protocol":null}}}'))
		equals: (STONJSON fromString:
				 '{"params":{"arguments":{"source":["one\rtwo",{"comment":"three\rfour"}],"count":2,"force":true,"protocol":null}}}')
]

{ #category : 'tests' }
MCPLineEndingsTest >> testLeavingEndsEveryLineWithALineFeed [

	self
		assert: (MCPLineEndings leaving:
				 (String streamContents: [ :stream | stream << 'one' << String cr << 'two' << String crlf << 'three' << String lf << 'four' ]))
		equals:
		(String streamContents: [ :stream | stream << 'one' << String lf << 'two' << String lf << 'three' << String lf << 'four' ])
]
