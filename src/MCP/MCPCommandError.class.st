"
Structured error raised by MCP commands and queries.

It carries a stable error code and details dictionary so tools can return useful structured error output instead of only message text.
"
Class {
	#name : 'MCPCommandError',
	#superclass : 'Error',
	#instVars : [
		'errorCode',
		'details'
	],
	#category : 'MCP-Errors',
	#package : 'MCP',
	#tag : 'Errors'
}

{ #category : 'phrasing' }
MCPCommandError class >> joinedNames: someNames [
	"A, A and B, A, B and C."

	^ String streamContents: [ :stream |
			  someNames withIndexDo: [ :each :index |
					  index > 1 ifTrue: [
							  stream nextPutAll: (index = someNames size
									   ifTrue: [ ' and ' ]
									   ifFalse: [ ', ' ]) ].
					  stream nextPutAll: each asString ] ]
]

{ #category : 'phrasing' }
MCPCommandError class >> joinedNames: someNames upTo: aLimit [
	"A, B, C and 4 more: past aLimit names, how many more rather than each of them."

	^ self joinedNames: (someNames size > aLimit
			   ifTrue: [ (someNames first: aLimit) copyWith: (someNames size - aLimit) printString , ' more' ]
			   ifFalse: [ someNames ])
]

{ #category : 'signaling' }
MCPCommandError class >> signalErrorCode: anErrorCode message: aMessage details: aDictionary [

	^ self new
		  errorCode: anErrorCode;
		  details: aDictionary;
		  messageText: aMessage;
		  signal
]

{ #category : 'accessing' }
MCPCommandError >> details [

	^ details ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPCommandError >> details: aDictionary [

	details := aDictionary ifNil: [ Dictionary new ] ifNotNil: [ aDictionary copy ]
]

{ #category : 'accessing' }
MCPCommandError >> errorCode [

	^ errorCode
]

{ #category : 'accessing' }
MCPCommandError >> errorCode: anObject [

	errorCode := anObject
]

{ #category : 'dispatching' }
MCPCommandError >> mcpCommandErrorDo: commandBlock otherwise: fallbackBlock [

	^ commandBlock cull: self
]

{ #category : 'accessing' }
MCPCommandError >> structuredDetails [

	| structured |
	structured := self details copy.
	structured at: #errorClass put: self class name.
	structured at: #errorCode put: self errorCode asString.
	structured at: #message put: self messageText.
	^ structured
]
