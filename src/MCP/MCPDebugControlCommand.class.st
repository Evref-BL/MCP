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

{ #category : 'private - actions' }
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
		at: #action put: request operation;
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
	record continuation ifNotNil: [
			(operationName = 'resume' or: [
				 self operationRequiresContext: operationName ]) ifTrue: [
					^ self
						  performContinuationOperationForRecord: record
						  previousStateId: previousStateId ] ].
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

{ #category : 'private - actions' }
MCPDebugControlCommand >> operationRequiresContext: operationName [

	^ self contextOperations includes: operationName
]

{ #category : 'private - actions' }
MCPDebugControlCommand >> pausedAfterOperation: operationName [

	^ self contextOperations includes: operationName
]

{ #category : 'private - actions' }
MCPDebugControlCommand >> performContinuationOperationForRecord: aRecord previousStateId: previousStateId [

	| context data frameIndex operationName status |
	operationName := request operation.
	frameIndex := nil.
	context := nil.
	(self operationRequiresContext: operationName) ifTrue: [
			frameIndex := self selectedFrameIndex.
			context := self
				           selectedContextForRecord: aRecord
				           frameIndex: frameIndex ].
	aRecord debugSession ifNil: [
		^ self signalMissingDebugSessionForRecord: aRecord ].
	status := [
		          aRecord continuation proceedUsing: [
				          (aRecord continuation debugControllerForSession:
					           aRecord debugSession)
					          performOperationNamed: operationName
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

{ #category : 'private - actions' }
MCPDebugControlCommand >> performOperationOn: aDebugSession context: aContext record: aRecord frameIndex: frameIndex [

	aDebugSession ifNil: [
		^ self signalMissingDebugSessionForRecord: aRecord ].
	^ [
		  (MCPDebugSessionController debugSession: aDebugSession)
			  performOperationNamed: request operation
			  context: aContext.
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

	| data state warnings |
	state := self
		         stateSnapshotForRecord: aRecord
		         operation: operationName.
	warnings := self controlWarnings.
	data := {
		        (#sessionId -> aRecord sessionId).
		        (#action -> operationName).
		        (#previousStateId -> previousStateId).
		        (#stateId -> aRecord stateId).
		        (#status -> aRecord status).
		        (#reason -> aRecord reason).
		        (#frameRef
		         -> (self frameRefForRecord: aRecord frameIndex: frameIndex)).
		        (#state -> state).
		        (#capabilities -> self capabilities) } asDictionary.
	warnings ifNotEmpty: [ data at: #warnings put: warnings ].
	^ data
]

{ #category : 'private - data' }
MCPDebugControlCommand >> shouldReturnStateForRecord: aRecord operation: operationName [

	request returnState ifFalse: [ ^ false ].
	(self pausedAfterOperation: operationName) ifTrue: [ ^ true ].
	^ aRecord status = 'paused'
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

{ #category : 'private - data' }
MCPDebugControlCommand >> stateSnapshotForRecord: aRecord operation: operationName [

	(self shouldReturnStateForRecord: aRecord operation: operationName)
		ifFalse: [ ^ nil ].
	^ (MCPDebugStateInfo fromRecord: aRecord request: request)
		  asDictionary
]

{ #category : 'private - actions' }
MCPDebugControlCommand >> statusAfterOperation: operationName [

	operationName = 'resume' ifTrue: [ ^ 'running' ].
	operationName = 'terminate' ifTrue: [ ^ 'terminated' ].
	^ 'paused'
]

{ #category : 'private - actions' }
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
