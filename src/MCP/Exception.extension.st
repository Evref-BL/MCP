Extension { #name : 'Exception' }

{ #category : '*MCP' }
Exception >> asJRPCJSON [

	| rawMessage rawTag title signalerDescription signalerContextDescription |
	rawMessage := self messageText
		              ifNil: [ '' ]
		              ifNotNil: [ :message | message asString ].
	rawTag := self tag
		          ifNil: [ '' ]
		          ifNotNil: [ :tagValue | tagValue asString ].
	signalerDescription := self signaler ifNotNil: [ :signalerObject |
		                       signalerObject asString ].
	signalerContextDescription := self signalerContext ifNotNil: [
		                              :context | context asString ].
	title := {
		         rawTag.
		         rawMessage.
		         self defaultDescription.
		         self class name }
		         detect: [ :each | each isNotNil and: [ each isNotEmpty ] ]
		         ifNone: [ self class name ].
	^ {
		  ('errorClass' -> self className).
		  ('title' -> title).
		  ('messageText'
		   -> (rawMessage ifEmpty: [ title ] ifNotEmpty: [ rawMessage ])).
		  ('tag' -> (rawTag ifEmpty: [ title ] ifNotEmpty: [ rawTag ])).
		  ('signaler' -> signalerDescription).
		  ('signalerContext' -> signalerContextDescription) } asDictionary
]

{ #category : '*MCP' }
Exception >> asJRPCResponse [

	^ self asJRPCResponseWithId: nil
]

{ #category : '*MCP' }
Exception >> asJRPCResponseWithId: anInteger [

	| response payload title |
	payload := self asJRPCJSON.
	title := payload at: 'title' ifAbsent: [ self class name ].
	response := JRPCErrorResponseObject
		            id: anInteger
		            error: JRPCErrorObject internalError.
	response error
		message: title;
		data: payload.
	^ response
]
