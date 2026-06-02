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

	^ includeReceiver ifNil: [ true ]
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

	^ sourceContextLines ifNil: [ 5 ]
]

{ #category : 'accessing' }
MCPDebugRequest >> sourceContextLines: anInteger [

	sourceContextLines := anInteger
]

{ #category : 'accessing' }
MCPDebugRequest >> stackLimit [

	^ stackLimit ifNil: [ 20 ]
]

{ #category : 'accessing' }
MCPDebugRequest >> stackLimit: anInteger [

	stackLimit := anInteger
]

{ #category : 'accessing' }
MCPDebugRequest >> stackStart [

	^ stackStart ifNil: [ 0 ]
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

	^ variableDepth ifNil: [ 1 ]
]

{ #category : 'accessing' }
MCPDebugRequest >> variableDepth: anInteger [

	variableDepth := anInteger
]

{ #category : 'accessing' }
MCPDebugRequest >> variableLimit [

	^ variableLimit ifNil: [ 50 ]
]

{ #category : 'accessing' }
MCPDebugRequest >> variableLimit: anInteger [

	variableLimit := anInteger
]
