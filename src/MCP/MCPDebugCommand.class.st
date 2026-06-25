"
Abstract command base for debugger tools.

It holds the tool, parsed request, and shared session registry, and provides common lookup and stale-state validation used by debugger commands.
"
Class {
	#name : 'MCPDebugCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'registry'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPDebugCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool
		  request: aRequest
		  registry: MCPDebugSessionRegistry default
]

{ #category : 'private - frames' }
MCPDebugCommand >> frameRefForRecord: aRecord frameIndex: frameIndex [

	frameIndex ifNil: [ ^ nil ].
	^ aRecord sessionId , '/' , aRecord stateId , '/frame-'
		, frameIndex asString
]

{ #category : 'initialization' }
MCPDebugCommand >> initializeTool: aTool request: aRequest registry: aRegistry [

	super initializeTool: aTool request: aRequest.
	registry := aRegistry
]

{ #category : 'private' }
MCPDebugCommand >> integerFromString: aString ifInvalid: invalidBlock [

	(aString isEmpty or: [
		 aString anySatisfy: [ :character | character isDigit not ] ])
		ifTrue: [ ^ invalidBlock value ].
	^ aString asInteger
]

{ #category : 'private - printing' }
MCPDebugCommand >> limitedPrintStringOf: anObject limit: characterLimit [

	anObject ifNil: [ ^ 'nil' ].
	^ [ anObject printStringLimitedTo: characterLimit ]
		  on: Error
		  do: [ :error | anObject class name asString ]
]

{ #category : 'accessing' }
MCPDebugCommand >> registry [

	^ registry
]

{ #category : 'accessing' }
MCPDebugCommand >> registry: aRegistry [

	registry := aRegistry
]

{ #category : 'private' }
MCPDebugCommand >> requestedStateId [

	^ request requestedStateId
]

{ #category : 'private - frames' }
MCPDebugCommand >> selectedContextForRecord: aRecord frameIndex: frameIndex [

	| contexts stateInfo |
	stateInfo := MCPDebugStateInfo fromRecord: aRecord request: request.
	contexts := stateInfo rawContexts.
	^ contexts
		at: frameIndex + 1
		ifAbsent: [ self signalMissingFrameIndex: frameIndex record: aRecord ]
]

{ #category : 'private - frames' }
MCPDebugCommand >> selectedFrameIndex [

	| frameRef frameToken suffix tokens |
	frameRef := request frameRef.
	frameRef ifNil: [ ^ 0 ].
	tokens := frameRef findTokens: '/'.
	tokens size >= 3 ifFalse: [ ^ self signalInvalidFrameReference ].
	frameToken := tokens third.
	(frameToken beginsWith: 'frame-') ifFalse: [
		^ self signalInvalidFrameReference ].
	suffix := frameToken allButFirst: 6.
	^ self
		  integerFromString: suffix
		  ifInvalid: [ ^ self signalInvalidFrameReference ]
]

{ #category : 'private' }
MCPDebugCommand >> sessionRecord [

	| sessionId |
	sessionId := request sessionId.
	sessionId ifNil: [ ^ self signalMissingSession ].
	^ registry sessionRecordAt: sessionId ifAbsent: [
			  MCPCommandError
				  signalErrorCode: #DebugSessionNotFound
				  message: 'Debug session ' , sessionId , ' was not found.'
				  details: { (#sessionId -> sessionId) } asDictionary ]
]

{ #category : 'private' }
MCPDebugCommand >> sessionRecordWithMatchingState [

	| record requestedState |
	record := self sessionRecord.
	self validateFrameReferenceForRecord: record.
	requestedState := self requestedStateId.
	requestedState ifNotNil: [
			requestedState = record stateId ifFalse: [
				self signalStaleState: requestedState forRecord: record ] ].
	^ record
]

{ #category : 'private - errors' }
MCPDebugCommand >> signalInvalidFrameReference [

	| frameRef |
	frameRef := request frameRef.
	^ MCPCommandError
		  signalErrorCode: #DebugFrameReferenceInvalid
		  message:
		  'Invalid debug frame reference: ' , frameRef asString , '.'
		  details: { (#frameRef -> frameRef) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugCommand >> signalInvalidFrameReference: aFrameRef details: detailAssociations [

	| details |
	details := detailAssociations asDictionary copy.
	details at: #frameRef put: aFrameRef.
	^ MCPCommandError
		  signalErrorCode: #DebugFrameReferenceInvalid
		  message:
		  'Invalid debug frame reference: ' , aFrameRef asString , '.'
		  details: details
]

{ #category : 'private - errors' }
MCPDebugCommand >> signalMissingFrameIndex: frameIndex record: aRecord [

	^ MCPCommandError
		signalErrorCode: #DebugFrameNotFound
		message:
			'Debug frame ' , frameIndex asString
			, ' was not found for session ' , aRecord sessionId , '.'
		details: {
				(#sessionId -> aRecord sessionId).
				(#stateId -> aRecord stateId).
				(#frameIndex -> frameIndex).
				(#frameRef -> (self frameRefForRecord: aRecord frameIndex: frameIndex)) }
				asDictionary
]

{ #category : 'private - errors' }
MCPDebugCommand >> signalMissingSession [

	^ MCPCommandError
		  signalErrorCode: #DebugSessionRequired
		  message: 'A debug sessionId is required.'
		  details: Dictionary new
]

{ #category : 'private - errors' }
MCPDebugCommand >> signalStaleState: requestedStateId forRecord: aRecord [

	^ MCPCommandError
		  signalErrorCode: #DebugStateStale
		  message:
			  'Debug state ' , requestedStateId , ' is stale for session '
			  , aRecord sessionId , '.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#requestedStateId -> requestedStateId).
				  (#currentStateId -> aRecord stateId) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugCommand >> signalStaleStateForRecord: aRecord [

	^ self signalStaleState: request stateId forRecord: aRecord
]

{ #category : 'private - errors' }
MCPDebugCommand >> signalUnsupportedOperation: operationName [

	^ MCPCommandError
		  signalErrorCode: #DebugOperationUnsupported
		  message:
		  'Unsupported debug operation: ' , operationName asString , '.'
		  details: { (#operation -> operationName) } asDictionary
]

{ #category : 'private' }
MCPDebugCommand >> validateFrameReferenceForRecord: aRecord [

	| frameRef frameToken suffix tokens |
	frameRef := request frameRef.
	frameRef ifNil: [ ^ self ].
	tokens := frameRef findTokens: '/'.
	tokens size = 3 ifFalse: [
			^ self signalInvalidFrameReference: frameRef details: {
					  (#sessionId -> aRecord sessionId).
					  (#currentStateId -> aRecord stateId) } ].
	tokens first = aRecord sessionId ifFalse: [
			^ self signalInvalidFrameReference: frameRef details: {
					  (#sessionId -> aRecord sessionId).
					  (#referenceSessionId -> tokens first).
					  (#currentStateId -> aRecord stateId) } ].
	frameToken := tokens third.
	(frameToken beginsWith: 'frame-') ifFalse: [
			^ self signalInvalidFrameReference: frameRef details: {
					  (#sessionId -> aRecord sessionId).
					  (#referenceSessionId -> tokens first).
					  (#referenceStateId -> tokens second).
					  (#currentStateId -> aRecord stateId) } ].
	suffix := frameToken allButFirst: 6.
	self integerFromString: suffix ifInvalid: [
			^ self signalInvalidFrameReference: frameRef details: {
					  (#sessionId -> aRecord sessionId).
					  (#referenceSessionId -> tokens first).
					  (#referenceStateId -> tokens second).
					  (#currentStateId -> aRecord stateId) } ]
]
