"
Continuation object for debug_capture worker processes.

It coordinates the suspended worker, captured exception state, timeout wait, resume/proceed behavior, result preview limits, and worker cleanup for MCP-owned captured sessions.
"
Class {
	#name : 'MCPDebugCaptureContinuation',
	#superclass : 'Object',
	#instVars : [
		'outcome',
		'semaphore',
		'workerProcess',
		'timeoutMilliseconds',
		'resultPreviewCharacterLimit'
	],
	#category : 'MCP-Debugging',
	#package : 'MCP',
	#tag : 'Debugging'
}

{ #category : 'instance creation' }
MCPDebugCaptureContinuation class >> outcome: anOutcome semaphore: aSemaphore timeoutMilliseconds: timeoutInteger resultPreviewCharacterLimit: limitInteger [

	^ self new
		  outcome: anOutcome;
		  semaphore: aSemaphore;
		  timeoutMilliseconds: timeoutInteger;
		  resultPreviewCharacterLimit: limitInteger;
		  yourself
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> capturedDebugSession [

	^ outcome at: #debugSession ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> capturedException [

	^ outcome at: #exception ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> completedAnswer [

	^ outcome at: #answer ifAbsent: [ nil ]
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> currentStatus [

	^ outcome at: #status ifAbsent: [ #missing ]
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> outcome [

	^ outcome
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> outcome: aDictionary [

	outcome := aDictionary.
	^ self
]

{ #category : 'private' }
MCPDebugCaptureContinuation >> prepareExceptionForProceed [

	| exception |
	exception := self capturedException.
	(exception isKindOf: MessageNotUnderstood) ifTrue: [
		exception mcpPrepareToResend ]
]

{ #category : 'controlling' }
MCPDebugCaptureContinuation >> proceed [

	workerProcess ifNil: [ ^ #missingWorker ].
	workerProcess isTerminated ifTrue: [ ^ #terminated ].
	self prepareExceptionForProceed.
	workerProcess resume.
	^ (semaphore waitTimeoutMilliseconds: timeoutMilliseconds)
		  ifTrue: [ #timedOut ]
		  ifFalse: [ self currentStatus ]
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> resultPreviewCharacterLimit: anInteger [

	resultPreviewCharacterLimit := anInteger.
	^ self
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> semaphore [

	^ semaphore
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> semaphore: aSemaphore [

	semaphore := aSemaphore.
	^ self
]

{ #category : 'controlling' }
MCPDebugCaptureContinuation >> signal [

	semaphore signal
]

{ #category : 'controlling' }
MCPDebugCaptureContinuation >> terminateWorker [

	workerProcess ifNil: [ ^ false ].
	^ [
		  workerProcess terminate.
		  true ]
		  on: Error
		  do: [ :ignored | false ]
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> timeoutMilliseconds [

	^ timeoutMilliseconds
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> timeoutMilliseconds: anInteger [

	timeoutMilliseconds := anInteger.
	^ self
]

{ #category : 'controlling' }
MCPDebugCaptureContinuation >> waitForSignal [

	^ semaphore waitTimeoutMilliseconds: timeoutMilliseconds
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> workerProcess [

	^ workerProcess
]

{ #category : 'accessing' }
MCPDebugCaptureContinuation >> workerProcess: aProcess [

	workerProcess := aProcess.
	^ self
]
