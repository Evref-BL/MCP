Extension { #name : 'Exception' }

{ #category : '*MCP' }
Exception >> asJRPCJSON [

	^ self mcpJRPCJSON
]

{ #category : '*MCP' }
Exception >> asJRPCResponse [

	^ self asJRPCResponseWithId: nil
]

{ #category : '*MCP' }
Exception >> asJRPCResponseWithId: anInteger [

	^ self mcpJRPCResponseWithId: anInteger
]

{ #category : '*MCP' }
Exception >> isIncorrectJSON [

	^ false
]

{ #category : '*MCP' }
Exception >> mcpAddNoteTo: aDictionary ifItLeavesOutSuggestions: aBlock [
	"Core reads no Pharo code, so it has no note to add."

	
]

{ #category : '*MCP' }
Exception >> mcpAddToolErrorDetailsTo: aDictionary [
	"Default: ordinary exceptions do not add tool-specific fields."

	^ aDictionary
]

{ #category : '*MCP' }
Exception >> mcpCommandErrorDo: commandBlock otherwise: fallbackBlock [

	^ fallbackBlock cull: self
]

{ #category : '*MCP' }
Exception >> mcpIsProtocolError [

	^ false
]

{ #category : '*MCP' }
Exception >> mcpJRPCJSON [
	"What MCP says about this exception in a JSON-RPC error's data: its class, a title, its message text and tag, and what signalled it."

	| rawDefaultDescription rawMessage rawTag title signalerDescription signalerContextDescription |
	rawMessage := self messageText ifNil: [ '' ] ifNotNil: [ :message | message asString ].
	rawTag := self tag ifNil: [ '' ] ifNotNil: [ :tagValue | tagValue asString ].
	rawDefaultDescription := self defaultDescription ifNil: [ '' ] ifNotNil: [ :description | description asString ].
	signalerDescription := self signaler ifNotNil: [ :signalerObject | signalerObject asString ].
	signalerContextDescription := self signalerContext ifNotNil: [ :context | context asString ].
	title := {
		         rawTag.
		         rawMessage.
		         rawDefaultDescription.
		         self class name } detect: [ :each | each isNotEmpty ] ifNone: [ self class name ].
	^ {
		  ('errorClass' -> self className).
		  ('title' -> title).
		  ('messageText' -> (rawMessage ifEmpty: [ title ] ifNotEmpty: [ rawMessage ])).
		  ('tag' -> (rawTag ifEmpty: [ title ] ifNotEmpty: [ rawTag ])).
		  ('signaler' -> signalerDescription).
		  ('signalerContext' -> signalerContextDescription) } asDictionary
]

{ #category : '*MCP' }
Exception >> mcpJRPCResponseWithId: anId [
	"The JSON-RPC error answering this exception, which the server did not expect: an internal error whose message says what was raised, with data saying more, which the processor withholds unless told its clients may see it. JRPC's answer for an Error, which wins over this class's for every exception that is one, says only that something went wrong."

	| payload response |
	payload := self mcpJRPCJSON.
	response := JRPCErrorResponseObject id: anId error: JRPCErrorObject internalError.
	response error
		message: (payload at: 'title');
		data: payload.
	^ response
]

{ #category : '*MCP' }
Exception >> mcpMessageText [
	"What a failure's text says after its colon: the message text, or for an error signalled without one, its description, which names its class."

	^ (self messageText ifNil: [ '' ]) asString ifEmpty: [ self description ]
]

{ #category : '*MCP' }
Exception >> mcpSignalerContext [

	^ self signalerContext
]
