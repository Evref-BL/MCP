"
MCPDebugController defines the control surface used by debugger tools after a session has been captured or attached. Subclasses adapt that control surface to either the DebugSession model or a visible debugger presenter without changing tool-level behavior.
"
Class {
	#name : 'MCPDebugController',
	#superclass : 'Object',
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'accessing' }
MCPDebugController >> debugSession [

	self subclassResponsibility
]

{ #category : 'controlling' }
MCPDebugController >> performOperation: selector context: aContext [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPDebugController >> workerProcess [

	| session |
	session := self debugSession.
	session ifNil: [ ^ nil ].
	^ [ session interruptedProcess ]
		  on: Error
		  do: [ :ignored | nil ]
]
