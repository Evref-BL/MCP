"
Base request object for debugger tools.

It carries the common debugger request fields: session identity, optional state token, selected frame reference, stack bounds, and variable preview options.
"
Class {
	#name : 'MCPDebugRequest',
	#superclass : 'Object',
	#instVars : [
		'operation',
		'sessionId',
		'stateId',
		'frameRef',
		'sourceContextLines',
		'stackStart',
		'stackLimit',
		'variableDepth',
		'variableLimit',
		'includeReceiver'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'defaults' }
MCPDebugRequest class >> defaultIncludeReceiver [

	^ false
]

{ #category : 'defaults' }
MCPDebugRequest class >> defaultSourceContextLines [

	^ 2
]

{ #category : 'defaults' }
MCPDebugRequest class >> defaultStackLimit [

	^ 5
]

{ #category : 'defaults' }
MCPDebugRequest class >> defaultStackStart [

	^ 0
]

{ #category : 'defaults' }
MCPDebugRequest class >> defaultVariableDepth [

	^ 1
]

{ #category : 'defaults' }
MCPDebugRequest class >> defaultVariableLimit [

	^ 10
]

{ #category : 'accessing' }
MCPDebugRequest >> frameRef [

	^ frameRef
]

{ #category : 'accessing' }
MCPDebugRequest >> frameRef: aString [

	frameRef := aString
]

{ #category : 'accessing' }
MCPDebugRequest >> includeReceiver [

	^ includeReceiver ifNil: [ self class defaultIncludeReceiver ]
]

{ #category : 'accessing' }
MCPDebugRequest >> includeReceiver: aBoolean [

	includeReceiver := aBoolean
]

{ #category : 'accessing' }
MCPDebugRequest >> operation [

	^ operation
]

{ #category : 'accessing' }
MCPDebugRequest >> operation: aString [

	operation := aString
]

{ #category : 'accessing' }
MCPDebugRequest >> requestedStateId [

	self stateId ifNotNil: [ ^ self stateId ].
	^ self frameRef ifNotNil: [ :reference |
		  self stateIdFromReference: reference ]
]

{ #category : 'accessing' }
MCPDebugRequest >> sessionId [

	^ sessionId
]

{ #category : 'accessing' }
MCPDebugRequest >> sessionId: aString [

	sessionId := aString
]

{ #category : 'accessing' }
MCPDebugRequest >> sourceContextLines [

	^ sourceContextLines ifNil: [ self class defaultSourceContextLines ]
]

{ #category : 'accessing' }
MCPDebugRequest >> sourceContextLines: anInteger [

	sourceContextLines := anInteger
]

{ #category : 'accessing' }
MCPDebugRequest >> stackLimit [

	^ stackLimit ifNil: [ self class defaultStackLimit ]
]

{ #category : 'accessing' }
MCPDebugRequest >> stackLimit: anInteger [

	stackLimit := anInteger
]

{ #category : 'accessing' }
MCPDebugRequest >> stackStart [

	^ stackStart ifNil: [ self class defaultStackStart ]
]

{ #category : 'accessing' }
MCPDebugRequest >> stackStart: anInteger [

	stackStart := anInteger
]

{ #category : 'accessing' }
MCPDebugRequest >> stateId [

	^ stateId
]

{ #category : 'accessing' }
MCPDebugRequest >> stateId: aString [

	stateId := aString
]

{ #category : 'private' }
MCPDebugRequest >> stateIdFromReference: aReferenceString [

	| tokens |
	tokens := aReferenceString findTokens: '/'.
	tokens size >= 2 ifFalse: [ ^ nil ].
	^ tokens second
]

{ #category : 'accessing' }
MCPDebugRequest >> variableDepth [

	^ variableDepth ifNil: [ self class defaultVariableDepth ]
]

{ #category : 'accessing' }
MCPDebugRequest >> variableDepth: anInteger [

	variableDepth := anInteger
]

{ #category : 'accessing' }
MCPDebugRequest >> variableLimit [

	^ variableLimit ifNil: [ self class defaultVariableLimit ]
]

{ #category : 'accessing' }
MCPDebugRequest >> variableLimit: anInteger [

	variableLimit := anInteger
]
