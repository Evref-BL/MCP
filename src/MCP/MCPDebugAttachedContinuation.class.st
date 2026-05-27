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

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugSession [

	^ outcome at: #debugSession ifAbsent: [
			  debugger ifNil: [ ^ nil ].
			  [ debugger session ]
				  on: Error
				  do: [ :ignored | nil ] ]
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugSession: aDebugSession [

	outcome at: #debugSession put: aDebugSession.
	^ self
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
	^ [ debugger session ]
		  on: Error
		  do: [ :ignored | nil ]
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> deferAttachedDebuggerAction: aBlock [

	| deferredAction |
	deferredAction := [
		                  [ aBlock value ]
			                  on: Exception
			                  do: [ :error |
					                  outcome
						                  at: #status put: #failed;
						                  at: #exception put: error.
					                  self signal ] ].
	debugger ifNotNil: [ :aDebugger |
			(aDebugger respondsTo: #defer:) ifTrue: [
				^ aDebugger defer: deferredAction ] ].
	^ UIManager default defer: deferredAction
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
MCPDebugAttachedContinuation >> performAttachedDebuggerOperation: selector context: aContext [

	selector = #resume ifTrue: [ ^ debugger proceedDebugSession ].
	selector = #terminate ifTrue: [ ^ debugger close ].
	selector = #restart: ifTrue: [
		^ debugger debuggerActionModel restartContext: aContext ].
	^ debugger debuggerActionModel perform: selector with: aContext
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> performDebugSessionOperation: selector context: aContext on: aDebugSession [

	self shouldProceedUsingAttachedDebugger ifTrue: [
			^ self deferAttachedDebuggerAction: [
				  self
					  performAttachedDebuggerOperation: selector
					  context: aContext ] ].
	^ self
		  performDirectDebugSessionOperation: selector
		  context: aContext
		  on: aDebugSession
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> performDirectDebugSessionOperation: selector context: aContext on: aDebugSession [

	selector numArgs = 0 ifTrue: [ ^ aDebugSession perform: selector ].
	^ aDebugSession perform: selector with: aContext
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> prepareExceptionForProceed [

	| exception session |
	session := self debugSession.
	session ifNil: [ ^ self ].
	exception := [ session exception ]
		             on: Error
		             do: [ :ignored | nil ].
	(exception isKindOf: MessageNotUnderstood) ifTrue: [
		exception mcpPrepareToResend ]
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> proceed [

	^ self proceedUsing: [ self proceedCurrentDebugSession ]
]

{ #category : 'private' }
MCPDebugAttachedContinuation >> proceedCurrentDebugSession [

	^ self
		  performDebugSessionOperation: #resume
		  context: nil
		  on: self debugSession
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

	| currentSession visibleSession |
	(debugger notNil and: [ debugger respondsTo: #proceedDebugSession ])
		ifFalse: [ ^ false ].
	visibleSession := self debuggerSession.
	visibleSession ifNil: [ ^ false ].
	currentSession := self debugSession.
	currentSession ifNil: [ ^ false ].
	^ visibleSession == currentSession
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> signal [

	semaphore signal
]

{ #category : 'controlling' }
MCPDebugAttachedContinuation >> terminateWorker [
	"Attached sessions are owned by the human/debugger process, not MCP. Forgetting the MCP record must not terminate that process."

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

	| session |
	session := self debugSession.
	session ifNil: [ ^ nil ].
	^ [ session interruptedProcess ]
		  on: Error
		  do: [ :ignored | nil ]
]
