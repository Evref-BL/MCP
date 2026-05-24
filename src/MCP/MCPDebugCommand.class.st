Class {
	#name : 'MCPDebugCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request',
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

{ #category : 'executing' }
MCPDebugCommand >> execute [

	self subclassResponsibility
]

{ #category : 'initialization' }
MCPDebugCommand >> initializeTool: aTool request: aRequest registry: aRegistry [

	tool := aTool.
	request := aRequest.
	registry := aRegistry.
	^ self
]

{ #category : 'accessing' }
MCPDebugCommand >> registry [

	^ registry
]

{ #category : 'accessing' }
MCPDebugCommand >> registry: aRegistry [

	registry := aRegistry
]

{ #category : 'accessing' }
MCPDebugCommand >> request [

	^ request
]

{ #category : 'private' }
MCPDebugCommand >> requestedStateId [

	request stateId ifNotNil: [ ^ request stateId ].
	(request respondsTo: #frameRef) ifTrue: [
			request frameRef ifNotNil: [
				^ self stateIdFromReference: request frameRef ] ].
	(request respondsTo: #variableRef) ifTrue: [
			request variableRef ifNotNil: [
				^ self stateIdFromReference: request variableRef ] ].
	^ nil
]

{ #category : 'private' }
MCPDebugCommand >> sessionRecord [

	request sessionId ifNil: [ ^ self signalMissingSession ].
	^ registry sessionRecordAt: request sessionId ifAbsent: [
			  MCPCommandError
				  signalErrorCode: #DebugSessionNotFound
				  message:
				  'Debug session ' , request sessionId , ' was not found.'
				  details: { (#sessionId -> request sessionId) } asDictionary ]
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
MCPDebugCommand >> stateIdFromReference: aReferenceString [

	| tokens |
	tokens := aReferenceString findTokens: '/'.
	tokens size >= 2 ifFalse: [ ^ nil ].
	^ tokens second
]

{ #category : 'accessing' }
MCPDebugCommand >> tool [

	^ tool
]

{ #category : 'private' }
MCPDebugCommand >> validateFrameReferenceForRecord: aRecord [

	| frameIndex frameRef frameToken suffix tokens |
	(request respondsTo: #frameRef) ifFalse: [ ^ self ].
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
	frameIndex := [ suffix asInteger ]
		              on: Error
		              do: [ :error |
				              ^ self
					                signalInvalidFrameReference: frameRef
					                details: {
							                (#sessionId -> aRecord sessionId).
							                (#referenceSessionId -> tokens first).
							                (#referenceStateId -> tokens second).
							                (#currentStateId -> aRecord stateId) } ].
	frameIndex < 0 ifTrue: [
			^ self signalInvalidFrameReference: frameRef details: {
					  (#sessionId -> aRecord sessionId).
					  (#referenceSessionId -> tokens first).
					  (#referenceStateId -> tokens second).
					  (#currentStateId -> aRecord stateId).
					  (#frameIndex -> frameIndex) } ].
	^ self
]
