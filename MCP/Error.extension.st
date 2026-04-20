Extension { #name : 'Error' }

{ #category : '*MCP' }
Error >> asJRPCJSON [
	| rawMessage rawTag title |
	rawMessage := self messageText ifNil: [ '' ] ifNotNil: #asString.
	rawTag := self tag ifNil: [ '' ] ifNotNil: #asString.
	title := { rawTag. rawMessage. self defaultDescription. self class name }
		detect: [ :each | each isNotNil and: [ each isNotEmpty ] ]
		ifNone: [ self class name ].
	^ {
		'errorClass' -> self className.
		'title' -> title.
		'messageText' -> (rawMessage ifEmpty: [ title ] ifNotEmpty: [ rawMessage ]).
		'tag' -> (rawTag ifEmpty: [ title ] ifNotEmpty: [ rawTag ]).
		'signaler' -> (self signaler ifNotNil: #asString).
		'signalerContext' -> (self signalerContext ifNotNil: #asString)
	} asDictionary
]

{ #category : '*MCP' }
Error >> asJRPCResponseWithId: anInteger [
	| response payload title |
	payload := self asJRPCJSON.
	title := payload at: 'title' ifAbsent: [ self class name ].
	response := JRPCErrorResponseObject id: anInteger error: JRPCErrorObject internalError.
	response error
		message: title;
		data: payload.
	^ response
]
