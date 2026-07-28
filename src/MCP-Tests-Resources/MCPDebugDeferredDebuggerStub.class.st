"
MCPDebugDeferredDebuggerStub is a test double for a visible debugger presenter. It records deferred UI actions so debugger continuation tests can verify that attached debugger control is scheduled through the presenter instead of run directly from the MCP worker.
"
Class {
	#name : 'MCPDebugDeferredDebuggerStub',
	#superclass : 'Object',
	#instVars : [
		'session',
		'deferredAction',
		'proceeded',
		'closed',
		'operation',
		'context'
	],
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'debugger actions' }
MCPDebugDeferredDebuggerStub >> close [

	closed := true.
	operation := #close
]

{ #category : 'accessing' }
MCPDebugDeferredDebuggerStub >> closed [

	^ closed ifNil: [ false ]
]

{ #category : 'accessing' }
MCPDebugDeferredDebuggerStub >> context [

	^ context
]

{ #category : 'debugger actions' }
MCPDebugDeferredDebuggerStub >> debuggerActionModel [

	^ self
]

{ #category : 'deferred actions' }
MCPDebugDeferredDebuggerStub >> defer: aBlock [

	deferredAction := aBlock
]

{ #category : 'testing' }
MCPDebugDeferredDebuggerStub >> hasDeferredAction [

	^ deferredAction notNil
]

{ #category : 'accessing' }
MCPDebugDeferredDebuggerStub >> operation [

	^ operation
]

{ #category : 'debugger actions' }
MCPDebugDeferredDebuggerStub >> proceedDebugSession [

	proceeded := true.
	operation := #proceedDebugSession
]

{ #category : 'accessing' }
MCPDebugDeferredDebuggerStub >> proceeded [

	^ proceeded ifNil: [ false ]
]

{ #category : 'debugger actions' }
MCPDebugDeferredDebuggerStub >> restartContext: aContext [

	operation := #restartContext:.
	context := aContext
]

{ #category : 'deferred actions' }
MCPDebugDeferredDebuggerStub >> runDeferredAction [

	deferredAction value
]

{ #category : 'accessing' }
MCPDebugDeferredDebuggerStub >> session [

	^ session
]

{ #category : 'accessing' }
MCPDebugDeferredDebuggerStub >> session: aDebugSession [

	session := aDebugSession.
	^ self
]

{ #category : 'debugger actions' }
MCPDebugDeferredDebuggerStub >> stepInto: aContext [

	operation := #stepInto:.
	context := aContext
]

{ #category : 'debugger actions' }
MCPDebugDeferredDebuggerStub >> stepOver: aContext [

	operation := #stepOver:.
	context := aContext
]

{ #category : 'debugger actions' }
MCPDebugDeferredDebuggerStub >> stepThrough: aContext [

	operation := #stepThrough:.
	context := aContext
]
