"
Coordinates MCP control of a debugger that was opened outside MCP. While a resumed attached process is allowed to run, it temporarily redirects matching Oups debugger openings back into the already attached debugger instead of spawning a second debugger.
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
	debugger ifNotNil: [
			[ debugger session: aDebugSession ]
				on: Error
				do: [ :ignored | nil ] ].
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

	debugger ifNil: [ ^ nil ].
	^ [ debugger session ]
		  on: Error
		  do: [ :ignored | nil ]
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugger [

	^ debugger
]

{ #category : 'accessing' }
MCPDebugAttachedContinuation >> debugger: aDebugger [

	debugger := aDebugger
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

	^ self proceedUsing: [ self debugSession resume ]
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
