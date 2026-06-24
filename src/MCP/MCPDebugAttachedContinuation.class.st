"
Coordinates MCP control of a debugger that was opened outside MCP.

When the attached process opens another debugger while MCP is controlling it, the continuation captures the new DebugSession for MCP state and suppresses replacement debugger windows. It intentionally does not retarget the visible debugger widget because updating Spec/Morphic debugger UI during exception handling can destabilize the image UI.
"
Class {
	#name : 'MCPDebugAttachedContinuation',
	#superclass : 'Object',
	#instVars : [
		'debugger',
		'outcome',
		'semaphore',
		'timeoutMilliseconds',
		'resultPreviewCharacterLimit'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugAttachedContinuation class >> debugger: aDebugger timeoutMilliseconds: timeoutMillis resultPreviewCharacterLimit: previewLimit [

	^ self new
		  debugger: aDebugger;
		  outcome: Dictionary new;
		  semaphore: Semaphore new;
		  timeoutMilliseconds: timeoutMillis;
		  resultPreviewCharacterLimit: previewLimit;
		  yourself
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> captureDebugSession: aDebugSession [

	outcome
		removeKey: #answer ifAbsent: [ nil ];
		at: #status put: #captured;
		at: #debugSession put: aDebugSession;
		at: #exception put: aDebugSession exception.
	self signal
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> capturedDebugSession [

	^ outcome at: #debugSession ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> completedAnswer [

	^ nil
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> currentStatus [

	^ outcome at: #status ifAbsent: [ #missing ]
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> debugController [

	^ self debugControllerForSession: self debugSession
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> debugControllerForSession: aDebugSession [

	(self shouldProceedUsingAttachedDebuggerFor: aDebugSession) ifTrue: [
			^ MCPDebugAttachedDebuggerController
				  debugger: debugger
				  debugSession: aDebugSession
				  onFailure: [ :error | self handleDeferredDebuggerError: error ] ].
	^ MCPDebugSessionController debugSession: aDebugSession
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugSession [

	^ outcome at: #debugSession ifAbsent: [ self debuggerSession ]
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugSession: aDebugSession [

	outcome at: #debugSession put: aDebugSession
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugger [

	^ debugger
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugger: aDebugger [

	debugger := aDebugger
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> debuggerSession [

	debugger ifNil: [ ^ nil ].
	^ debugger session
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> handleDeferredDebuggerError: anError [

	outcome
		at: #status put: #failed;
		at: #exception put: anError.
	self signal
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> outcome [

	^ outcome
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> outcome: aDictionary [

	outcome := aDictionary
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> prepareExceptionForProceed [

	self debugSession ifNotNil: [ :session |
			session exception ifNotNil: [ :exception |
				exception mcpPrepareForProceed ] ]
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> proceed [

	^ self proceedUsing: [ self proceedCurrentDebugSession ]
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> proceedCurrentDebugSession [

	^ self debugController performOperationNamed: 'resume' context: nil
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> proceedUsing: aBlock [

	| process timedOut |
	process := self workerProcess.
	process ifNil: [ ^ #missingWorker ].
	process isTerminated ifTrue: [ ^ #terminated ].
	self prepareExceptionForProceed.
	MCPDebugAttachedDebuggerSelectionStrategy activate: self during: [
			aBlock value.
			timedOut := self waitForSignal ].
	timedOut ifFalse: [ ^ self currentStatus ].
	process isTerminated ifTrue: [ ^ #terminated ].
	process isSuspended ifTrue: [ ^ #paused ].
	^ #running
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> resultPreviewCharacterLimit: anInteger [

	resultPreviewCharacterLimit := anInteger
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> semaphore [

	^ semaphore
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> semaphore: aSemaphore [

	semaphore := aSemaphore
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> shouldProceedUsingAttachedDebugger [

	^ self shouldProceedUsingAttachedDebuggerFor: self debugSession
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> shouldProceedUsingAttachedDebuggerFor: aDebugSession [

	| visibleSession |
	visibleSession := self debuggerSession.
	visibleSession ifNil: [ ^ false ].
	aDebugSession ifNil: [ ^ false ].
	^ visibleSession == aDebugSession
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> signal [

	semaphore signal
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> terminateWorker [
	"Attached sessions are owned by the human/debugger process, not MCP. Removing the MCP record must not terminate that process."

	^ false
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> timeoutMilliseconds [

	^ timeoutMilliseconds
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> timeoutMilliseconds: anInteger [

	timeoutMilliseconds := anInteger
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> waitForSignal [

	^ semaphore waitTimeoutMilliseconds: timeoutMilliseconds
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> workerProcess [

	^ self debugSession ifNotNil: [ :session |
		  session interruptedProcess ]
]
