"
Implements debug_search.

It reads the debuggers open in the image and describes them. Nothing is attached, registered or remembered: the debuggers are the state, they are found again on every call, and a person's debugger is left exactly as it was.

Each one is described the way a failure is described, with the frames nearest the stop carrying the receiver and the frame's variables under their own names.
"
Class {
	#name : 'MCPDebugSearchCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - reading' }
MCPDebugSearchCommand >> descriptionOf: aDebugger [

	| session |
	session := [ aDebugger session ] on: Error do: [ :error | nil ].
	session ifNil: [ ^ nil ].
	^ {
		  (#debugger -> ([ session name asString ] on: Error do: [ :error | 'a debugger' ])).
		  (#exception -> (self exceptionTextFor: session exception)).
		  (#stack -> ([ self tool errorStackTraceForContext: session interruptedContext ]
				   on: Error
				   do: [ :error | #(  ) ])) } asDictionary
]

{ #category : 'private - reading' }
MCPDebugSearchCommand >> exceptionTextFor: anException [
	"Some exceptions print a fixed description and keep what actually happened in messageText."

	anException ifNil: [ ^ 'none' ].
	^ [
	  anException messageText
		  ifNil: [ anException printString ]
		  ifNotNil: [ :text | anException class name , ': ' , text ] ]
		  on: Error
		  do: [ :error | anException class name ]
]

{ #category : 'executing' }
MCPDebugSearchCommand >> execute [

	| entries |
	entries := self openDebuggers.
	^ MCPDebugToolResult
		  okSummary: (self tool textForCount: entries size noun: 'open debugger') , '.'
		  data: { (#debuggers -> entries) } asDictionary
]

{ #category : 'private - reading' }
MCPDebugSearchCommand >> openDebuggers [
	"The image already knows which debuggers are open, so nothing has to be kept between calls."

	| entries |
	entries := OrderedCollection new.
	StDebugger allInstancesDo: [ :debugger |
			(self descriptionOf: debugger) ifNotNil: [ :description |
					(request matches: (description at: #debugger) , ' ' , (description at: #exception)) ifTrue: [
						entries add: description ] ] ].
	^ entries asArray
]
