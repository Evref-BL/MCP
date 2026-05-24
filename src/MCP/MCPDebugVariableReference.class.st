Class {
	#name : 'MCPDebugVariableReference',
	#superclass : 'Object',
	#instVars : [
		'rawReference',
		'sessionId',
		'stateId',
		'frameIndex',
		'scopeName',
		'variableName',
		'pathSegments'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugVariableReference class >> fromString: aReferenceString [

	| tokens frameToken scopeToken variableToken frameIndex pathSegments |
	tokens := aReferenceString findTokens: '/'.
	tokens size >= 4 ifFalse: [
		^ self signalInvalidReference: aReferenceString ].
	frameToken := tokens third.
	(frameToken beginsWith: 'frame-') ifFalse: [
		^ self signalInvalidReference: aReferenceString ].
	scopeToken := tokens fourth.
	(scopeToken beginsWith: 'scope-') ifFalse: [
		^ self signalInvalidReference: aReferenceString ].
	frameIndex := [ (frameToken allButFirst: 6) asInteger ]
		              on: Error
		              do: [ :error |
		              ^ self signalInvalidReference: aReferenceString ].
	pathSegments := OrderedCollection new.
	variableToken := nil.
	tokens size >= 5 ifTrue: [
			variableToken := tokens fifth.
			(variableToken beginsWith: 'var-') ifFalse: [
				^ self signalInvalidReference: aReferenceString ].
			6 to: tokens size do: [ :index |
			pathSegments add: (tokens at: index) ] ].
	^ self new
		  initializeRawReference: aReferenceString
		  sessionId: tokens first
		  stateId: tokens second
		  frameIndex: frameIndex
		  scopeName: (scopeToken allButFirst: 6)
		  variableName: (variableToken
				   ifNil: [ nil ]
				   ifNotNil: [ variableToken allButFirst: 4 ])
		  pathSegments: pathSegments asArray
]

{ #category : 'private - errors' }
MCPDebugVariableReference class >> signalInvalidReference: aReferenceString [

	^ MCPCommandError
		  signalErrorCode: #DebugVariableReferenceInvalid
		  message:
		  'Invalid debug variable reference: ' , aReferenceString asString
		  , '.'
		  details: { (#variableRef -> aReferenceString) } asDictionary
]

{ #category : 'accessing' }
MCPDebugVariableReference >> frameIndex [

	^ frameIndex
]

{ #category : 'initialization' }
MCPDebugVariableReference >> initializeRawReference: rawString sessionId: sessionString stateId: stateString frameIndex: frameInteger scopeName: scopeString variableName: variableString pathSegments: segmentArray [

	rawReference := rawString.
	sessionId := sessionString.
	stateId := stateString.
	frameIndex := frameInteger.
	scopeName := scopeString.
	variableName := variableString.
	pathSegments := segmentArray.
	^ self
]

{ #category : 'testing' }
MCPDebugVariableReference >> isScopeReference [

	^ variableName isNil
]

{ #category : 'testing' }
MCPDebugVariableReference >> isVariableReference [

	^ variableName notNil
]

{ #category : 'converting' }
MCPDebugVariableReference >> kind [

	^ self isScopeReference
		  ifTrue: [ 'scope' ]
		  ifFalse: [ 'variable' ]
]

{ #category : 'accessing' }
MCPDebugVariableReference >> pathSegments [

	^ pathSegments ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPDebugVariableReference >> rawReference [

	^ rawReference
]

{ #category : 'accessing' }
MCPDebugVariableReference >> scopeName [

	^ scopeName
]

{ #category : 'accessing' }
MCPDebugVariableReference >> sessionId [

	^ sessionId
]

{ #category : 'accessing' }
MCPDebugVariableReference >> stateId [

	^ stateId
]

{ #category : 'accessing' }
MCPDebugVariableReference >> variableName [

	^ variableName
]
