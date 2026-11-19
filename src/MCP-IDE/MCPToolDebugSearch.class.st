"
Concrete debug_search tool. It answers the debuggers a person has open in the image.

It is a query and nothing else. No session is started, attached, registered or remembered, so there is no reference to keep and nothing to clean up: ask again and the answer reflects whatever is open then. To act on what it shows, use the ordinary class and method tools.
"
Class {
	#name : 'MCPToolDebugSearch',
	#superclass : 'MCPToolDebug',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDebugSearch class >> toolName [

	^ 'debug_search'
]

{ #category : 'metadata' }
MCPToolDebugSearch >> additionalKeywords [

	^ #( 'debug' 'debugger' 'open' 'paused' 'stack' 'frame' 'exception' 'halt' )
]

{ #category : 'metadata' }
MCPToolDebugSearch >> description [

	^ 'Answer the debuggers open in the image, each with its exception and the frames nearest the stop, including what those frames hold. Nothing is attached or kept, so ask again for the current picture.'
]

{ #category : 'private - reading' }
MCPToolDebugSearch >> descriptionOf: aDebugger [
	"A debugger as a failure is described: its exception, and the frames nearest the stop carrying the receiver and the frame's variables under their own names."

	| session |
	session := [ aDebugger session ]
		           on: Error
		           do: [ :error | nil ].
	session ifNil: [ ^ nil ].
	^ {
		  (#debugger -> ([ session name asString ]
			    on: Error
			    do: [ :error | 'a debugger' ])).
		  (#exception -> (self exceptionTextFor: session exception)).
		  (#stack -> ([ self errorStackTraceForContext: session interruptedContext ]
			    on: Error
			    do: [ :error | #(  ) ])) } asDictionary
]

{ #category : 'private - reading' }
MCPToolDebugSearch >> exceptionTextFor: anException [
	"Some exceptions print a fixed description and keep what actually happened in messageText."

	anException ifNil: [ ^ 'none' ].
	^ [
		  anException messageText
			  ifNil: [ anException printString ]
			  ifNotNil: [ :text | String streamContents: [ :stream | stream << anException class name << ': ' << text ] ] ]
		  on: Error
		  do: [ :error | anException class name ]
]

{ #category : 'metadata' }
MCPToolDebugSearch >> inputProperties [

	^ { (self
		   schemaPropertyNamed: 'query'
		   type: 'string'
		   description: 'Only answer debuggers whose name or exception contains this text. Left out, all of them are answered.') }
]

{ #category : 'private - reading' }
MCPToolDebugSearch >> openDebuggersMatching: aQuery [
	"The image already knows which debuggers are open, so nothing has to be kept between calls, and a person's debugger is left exactly as it was."

	| entries |
	entries := OrderedCollection new.
	StDebugger allInstancesDo: [ :debugger |
			(self descriptionOf: debugger) ifNotNil: [ :description |
					(self
						 text: (String streamContents: [ :stream | stream << (description at: #debugger) << ' ' << (description at: #exception) ])
						 matches: aQuery) ifTrue: [ entries add: description ] ] ].
	^ entries asArray
]

{ #category : 'executing' }
MCPToolDebugSearch >> resultFor: request [

	| entries |
	entries := self openDebuggersMatching: (request stringArgumentNamed: 'query').
	^ self
		  successResultText: (self textForCount: entries size noun: 'open debugger') , '.'
		  data: { (#debuggers -> entries) } asDictionary
]

{ #category : 'private - reading' }
MCPToolDebugSearch >> text: aString matches: aQuery [
	"Whether aString contains the query, whatever their case. No query matches every text."

	aQuery ifNil: [ ^ true ].
	^ aString asString asLowercase includesSubstring: aQuery asLowercase
]

{ #category : 'metadata' }
MCPToolDebugSearch >> title [

	^ 'Open Debuggers'
]
