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

{ #category : 'testing' }
MCPDebugController class >> isAbstract [

	^ self == MCPDebugController
]

{ #category : 'accessing' }
MCPDebugController >> debugSession [

	self subclassResponsibility
]

{ #category : 'controlling' }
MCPDebugController >> dispatchOperationNamed: operationName context: aContext [

	operationName = 'stepInto' ifTrue: [
		^ self stepIntoContext: aContext ].
	operationName = 'stepOver' ifTrue: [
		^ self stepOverContext: aContext ].
	operationName = 'stepThrough' ifTrue: [
		^ self stepThroughContext: aContext ].
	operationName = 'restart' ifTrue: [ ^ self restartContext: aContext ].
	operationName = 'resume' ifTrue: [ ^ self resume ].
	operationName = 'terminate' ifTrue: [ ^ self terminate ].
	self error:
		'Unsupported debug control operation: ' , operationName asString
]

{ #category : 'controlling' }
MCPDebugController >> performOperationNamed: operationName context: aContext [

	^ self dispatchOperationNamed: operationName context: aContext
]

{ #category : 'controlling' }
MCPDebugController >> restartContext: aContext [

	self subclassResponsibility
]

{ #category : 'controlling' }
MCPDebugController >> resume [

	self subclassResponsibility
]

{ #category : 'controlling' }
MCPDebugController >> stepIntoContext: aContext [

	self subclassResponsibility
]

{ #category : 'controlling' }
MCPDebugController >> stepOverContext: aContext [

	self subclassResponsibility
]

{ #category : 'controlling' }
MCPDebugController >> stepThroughContext: aContext [

	self subclassResponsibility
]

{ #category : 'controlling' }
MCPDebugController >> terminate [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPDebugController >> workerProcess [

	^ self debugSession ifNotNil: [ :session |
		  session interruptedProcess ]
]
