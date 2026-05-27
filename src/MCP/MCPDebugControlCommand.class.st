"
Applies conventional control operations to a registered DebugSession.

It handles resume, terminate, restart, and stepping, invalidates stale state-scoped references, and keeps externally attached debugger sessions from spawning replacement debuggers during control.
"
Class {
	#name : 'MCPDebugControlCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - data' }
MCPDebugControlCommand >> capabilities [

	^ {
		  (#operations -> MCPDebugControlRequest supportedOperations).
		  (#stateInvalidation -> true).
		  (#postActionState -> true).
		  (#mutating -> true) } asDictionary
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> contextOperations [

	^ #( 'stepInto' 'stepOver' 'stepThrough' 'restart' )
]

{ #category : 'private - errors' }
MCPDebugControlCommand >> controlFailureFor: anError record: aRecord frameIndex: frameIndex [

	| details |
	details := tool errorDetailsFor: anError.
	details
		at: #errorCode put: 'DebugControlFailed';
		at: #sessionId put: aRecord sessionId;
		at: #stateId put: aRecord stateId;
		at: #operation put: request operation;
		at: #frameRef
		put: (self frameRefForRecord: aRecord frameIndex: frameIndex);
		at: #controlErrorClass put: anError class name.
	^ MCPDebugToolResult
		  errorSummary:
		  (tool
			   controlFailureMessageFor: anError
			   operation: request operation)
		  details: details
]

{ #category : 'private - data' }
MCPDebugControlCommand >> controlWarnings [

	^ #( 'Debug control may execute Smalltalk code, mutate image state, or resume/terminate a suspended process.' )
]

{ #category : 'executing' }
MCPDebugControlCommand >> execute [

	| context controlResult data frameIndex operationName previousStateId record |
	record := self sessionRecordWithMatchingState.
	operationName := request operation.
	previousStateId := record stateId.
	(record continuation notNil and: [
			 operationName = 'resume' or: [
				 self operationRequiresContext: operationName ] ]) ifTrue: [
			^ self
				  performContinuationOperationForRecord: record
				  previousStateId: previousStateId ].
	frameIndex := nil.
	context := nil.
	(self operationRequiresContext: operationName) ifTrue: [
			frameIndex := self selectedFrameIndex.
			context := self
				           selectedContextForRecord: record
				           frameIndex: frameIndex ].
	controlResult := self
		                 performOperationOn: record debugSession
		                 context: context
		                 record: record
		                 frameIndex: frameIndex.
	controlResult ifNotNil: [ ^ controlResult ].
	record
		advanceStateForStatus: (self statusAfterOperation: operationName)
		reason: operationName.
	data := self
		        resultDataForRecord: record
		        previousStateId: previousStateId
		        frameIndex: frameIndex
		        operation: operationName.
	^ MCPDebugToolResult
		  okSummary:
			  'Debug control ' , operationName , ' applied to '
			  , record sessionId , '.'
		  data: data
		  warnings: (data at: #warnings)
]

{ #category : 'private - frames' }
MCPDebugControlCommand >> frameRefForRecord: aRecord frameIndex: frameIndex [

	frameIndex ifNil: [ ^ nil ].
	^ aRecord sessionId , '/' , aRecord stateId , '/frame-'
	  , frameIndex asString
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> operationRequiresContext: operationName [

	^ self contextOperations includes: operationName
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> pausedAfterOperation: operationName [

	^ self contextOperations includes: operationName
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> performContinuationOperationForRecord: aRecord previousStateId: previousStateId [

	| context data frameIndex operationName selector status |
	operationName := request operation.
	frameIndex := nil.
	context := nil.
	(self operationRequiresContext: operationName) ifTrue: [
			frameIndex := self selectedFrameIndex.
			context := self
				           selectedContextForRecord: aRecord
				           frameIndex: frameIndex ].
	selector := self selectorForOperation: operationName.
	selector ifNil: [ ^ self signalUnsupportedOperation: operationName ].
	aRecord debugSession ifNil: [
		^ self signalMissingDebugSessionForRecord: aRecord ].
	(aRecord debugSession respondsTo: selector) ifFalse: [
			^ self
				  signalDebugSession: aRecord debugSession
				  doesNotSupport: selector
				  record: aRecord ].
	status := [
		          aRecord continuation proceedUsing: [
				          (aRecord continuation debugControllerForSession:
					           aRecord debugSession)
					          performOperation: selector
					          context: context ] ]
		          on: Exception
		          do: [ :error |
			          ^ self
				            controlFailureFor: error
				            record: aRecord
				            frameIndex: frameIndex ].
	self
		updateRecord: aRecord
		afterContinuationStatus: status
		operation: operationName.
	data := self
		        resultDataForRecord: aRecord
		        previousStateId: previousStateId
		        frameIndex: frameIndex
		        operation: operationName.
	^ MCPDebugToolResult
		  okSummary:
			  'Debug control ' , operationName , ' applied to '
			  , aRecord sessionId , '.'
		  data: data
		  warnings: (data at: #warnings)
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> performOperationOn: aDebugSession context: aContext record: aRecord frameIndex: frameIndex [

	| selector |
	aDebugSession ifNil: [
		^ self signalMissingDebugSessionForRecord: aRecord ].
	selector := self selectorForOperation: request operation.
	selector ifNil: [
		^ self signalUnsupportedOperation: request operation ].
	(aDebugSession respondsTo: selector) ifFalse: [
			^ self
				  signalDebugSession: aDebugSession
				  doesNotSupport: selector
				  record: aRecord ].
	^ [
		  selector numArgs = 0
			  ifTrue: [ aDebugSession perform: selector ]
			  ifFalse: [ aDebugSession perform: selector with: aContext ].
		  nil ]
		  on: Exception
		  do: [ :error |
			  self
				  controlFailureFor: error
				  record: aRecord
				  frameIndex: frameIndex ]
]

{ #category : 'private - data' }
MCPDebugControlCommand >> resultDataForRecord: aRecord previousStateId: previousStateId frameIndex: frameIndex operation: operationName [

	| state warnings |
	state := self
		         stateSnapshotForRecord: aRecord
		         operation: operationName.
	warnings := self controlWarnings.
	^ {
		  (#sessionId -> aRecord sessionId).
		  (#operation -> operationName).
		  (#previousStateId -> previousStateId).
		  (#stateId -> aRecord stateId).
		  (#status -> aRecord status).
		  (#reason -> aRecord reason).
		  (#frameRef
		   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)).
		  (#state -> state).
		  (#warnings -> warnings).
		  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'private - frames' }
MCPDebugControlCommand >> selectedContextForRecord: aRecord frameIndex: frameIndex [

	| contexts stateInfo |
	stateInfo := MCPDebugStateInfo fromRecord: aRecord request: request.
	contexts := stateInfo rawContexts.
	^ contexts
		  at: frameIndex + 1
		  ifAbsent: [
		  self signalMissingFrameIndex: frameIndex record: aRecord ]
]

{ #category : 'private - frames' }
MCPDebugControlCommand >> selectedFrameIndex [

	| frameToken index suffix tokens |
	request frameRef ifNil: [ ^ 0 ].
	tokens := request frameRef findTokens: '/'.
	tokens size >= 3 ifFalse: [ ^ self signalInvalidFrameReference ].
	frameToken := tokens third.
	(frameToken beginsWith: 'frame-') ifFalse: [
		^ self signalInvalidFrameReference ].
	suffix := frameToken allButFirst: 6.
	index := [ suffix asInteger ]
		         on: Error
		         do: [ :error | ^ self signalInvalidFrameReference ].
	index < 0 ifTrue: [ ^ self signalInvalidFrameReference ].
	^ index
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> selectorForOperation: operationName [

	operationName = 'stepInto' ifTrue: [ ^ #stepInto: ].
	operationName = 'stepOver' ifTrue: [ ^ #stepOver: ].
	operationName = 'stepThrough' ifTrue: [ ^ #stepThrough: ].
	operationName = 'restart' ifTrue: [ ^ #restart: ].
	operationName = 'resume' ifTrue: [ ^ #resume ].
	operationName = 'terminate' ifTrue: [ ^ #terminate ].
	^ nil
]

{ #category : 'private - data' }
MCPDebugControlCommand >> shouldReturnStateForOperation: operationName [

	^ request returnState and: [
		  self pausedAfterOperation: operationName ]
]

{ #category : 'private - errors' }
MCPDebugControlCommand >> signalDebugSession: aDebugSession doesNotSupport: selector record: aRecord [

	^ MCPCommandError
		  signalErrorCode: #DebugControlUnsupported
		  message:
			  'Debug session ' , aRecord sessionId , ' does not support '
			  , selector asString , '.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#operation -> request operation).
				  (#selector -> selector asString).
				  (#debugSessionClassName -> aDebugSession class name asString) }
				  asDictionary
]

{ #category : 'private - errors' }
MCPDebugControlCommand >> signalInvalidFrameReference [

	^ MCPCommandError
		  signalErrorCode: #DebugFrameReferenceInvalid
		  message:
		  'Invalid debug frame reference: ' , request frameRef asString
		  , '.'
		  details: { (#frameRef -> request frameRef) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugControlCommand >> signalMissingDebugSessionForRecord: aRecord [

	^ MCPCommandError
		  signalErrorCode: #DebugSessionDetached
		  message:
		  'Debug session ' , aRecord sessionId
		  , ' has no DebugSession object.'
		  details: { (#sessionId -> aRecord sessionId) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugControlCommand >> signalMissingFrameIndex: frameIndex record: aRecord [

	^ MCPCommandError
		  signalErrorCode: #DebugFrameNotFound
		  message:
			  'Debug frame ' , frameIndex asString
			  , ' was not found for session ' , aRecord sessionId , '.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#frameIndex -> frameIndex).
				  (#frameRef
				   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)) }
				  asDictionary
]

{ #category : 'private - data' }
MCPDebugControlCommand >> stateSnapshotForRecord: aRecord operation: operationName [

	(request returnState and: [
			 (self pausedAfterOperation: operationName) or: [
				 aRecord status = 'paused' ] ]) ifFalse: [ ^ nil ].
	^ (MCPDebugStateInfo fromRecord: aRecord request: request)
		  asDictionary
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> statusAfterOperation: operationName [

	operationName = 'resume' ifTrue: [ ^ 'running' ].
	operationName = 'terminate' ifTrue: [ ^ 'terminated' ].
	^ 'paused'
]

{ #category : 'private - operations' }
MCPDebugControlCommand >> updateRecord: aRecord afterContinuationStatus: status operation: operationName [

	status = #captured ifTrue: [
			aRecord
				debugSession: aRecord continuation capturedDebugSession;
				advanceStateForStatus: 'paused' reason: 'capturedException'.
			^ self ].
	status = #paused ifTrue: [
			aRecord advanceStateForStatus: 'paused' reason: operationName.
			^ self ].
	status = #running ifTrue: [
			aRecord advanceStateForStatus: 'running' reason: operationName.
			^ self ].
	status = #terminated ifTrue: [
			aRecord
				continuation: nil;
				advanceStateForStatus: 'terminated' reason: operationName.
			^ self ].
	aRecord advanceStateForStatus: status asString reason: operationName
]
