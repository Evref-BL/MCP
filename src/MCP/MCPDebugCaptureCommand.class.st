"
Evaluates Smalltalk in a bounded worker process and captures runtime exceptions as DebugSession records.

This is the MCP-owned entry point for opening a debuggable session from arbitrary code without invoking the normal UI debugger.
"
Class {
	#name : 'MCPDebugCaptureCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - data' }
MCPDebugCaptureCommand >> capabilities [

	^ {
		  (#isolatedWorkerProcess -> true).
		  (#runtimeExceptionCapture -> true).
		  (#syntaxErrorsCreateSessions -> false).
		  (#timeoutTermination -> true).
		  (#postCaptureState -> true).
		  (#mutating -> true) } asDictionary
]

{ #category : 'private - data' }
MCPDebugCaptureCommand >> captureWarnings [

	^ #( 'debug_capture evaluates arbitrary Smalltalk in a forked worker process and may mutate image state.'
	     'Captured exceptions leave the worker process suspended until debug_session_resume or debug_session_terminate controls the session.' )
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> capturedResultFor: aDebugSession continuation: aContinuation [

	| data record state warnings |
	record := registry
		          registerDebugSession: aDebugSession
		          named: request name
		          status: 'paused'
		          reason: 'capturedException'.
	record continuation: aContinuation.
	state := (MCPDebugStateInfo fromRecord: record request: request) asDictionary.
	warnings := self captureWarnings.
	data := {
		        (#captured -> true).
		        (#timedOut -> false).
		        (#sessionId -> record sessionId).
		        (#stateId -> record stateId).
		        (#session -> (MCPDebugSessionInfo fromRecord: record) asDictionary).
		        (#state -> state).
		        (#resultClassName -> nil).
		        (#resultPrintString -> nil).
		        (#timeoutMilliseconds -> request timeoutMilliseconds).
		        (#capabilities -> self capabilities) } asDictionary.
	warnings ifNotEmpty: [ data at: #warnings put: warnings ].
	^ MCPDebugToolResult okSummary: 'Debug capture registered ' , record sessionId , '.' data: data warnings: warnings
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> completedResultFor: answer [

	| data warnings |
	warnings := self captureWarnings.
	data := {
		        (#captured -> false).
		        (#timedOut -> false).
		        (#sessionId -> nil).
		        (#stateId -> nil).
		        (#session -> nil).
		        (#state -> nil).
		        (#resultClassName -> answer class name asString).
		        (#resultPrintString -> (self limitedPrintStringOf: answer)).
		        (#timeoutMilliseconds -> request timeoutMilliseconds).
		        (#capabilities -> self capabilities) } asDictionary.
	warnings ifNotEmpty: [ data at: #warnings put: warnings ].
	^ MCPDebugToolResult okSummary: 'Debug capture completed without an exception.' data: data warnings: warnings
]

{ #category : 'executing' }
MCPDebugCaptureCommand >> execute [

	| continuation timedOut worker |
	continuation := MCPDebugCaptureContinuation
		                outcome: Dictionary new
		                semaphore: Semaphore new
		                timeoutMilliseconds: request timeoutMilliseconds
		                resultPreviewCharacterLimit: request resultPreviewCharacterLimit.
	worker := self workerProcessForContinuation: continuation.
	continuation workerProcess: worker.
	worker resume.
	timedOut := continuation waitForSignal.
	timedOut ifTrue: [ ^ self timeoutResultForContinuation: continuation ].
	^ self resultForContinuation: continuation
]

{ #category : 'private - printing' }
MCPDebugCaptureCommand >> limitedPrintStringOf: anObject [

	^ self limitedPrintStringOf: anObject limit: request resultPreviewCharacterLimit
]

{ #category : 'private - worker' }
MCPDebugCaptureCommand >> recordCapturedException: anException inOutcome: outcome [

	| debugSession |
	debugSession := DebugSession named: request name on: Processor activeProcess startedAt: anException signalerContext.
	debugSession exception: anException.
	outcome
		removeKey: #answer ifAbsent: [ nil ];
		at: #status put: #captured;
		at: #debugSession put: debugSession;
		at: #exception put: anException
]

{ #category : 'private - worker' }
MCPDebugCaptureCommand >> recordCompletedAnswer: answer inOutcome: outcome [

	outcome
		removeKey: #debugSession ifAbsent: [ nil ];
		removeKey: #exception ifAbsent: [ nil ];
		at: #status put: #completed;
		at: #answer put: answer
]

{ #category : 'private - worker' }
MCPDebugCaptureCommand >> recordSyntaxFailure: aNotice inOutcome: outcome [

	outcome
		at: #status put: #syntaxError;
		at: #notice put: aNotice
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> resultForContinuation: aContinuation [

	| status |
	status := aContinuation currentStatus.
	status = #completed ifTrue: [ ^ self completedResultFor: aContinuation completedAnswer ].
	status = #captured ifTrue: [ ^ self capturedResultFor: aContinuation capturedDebugSession continuation: aContinuation ].
	status = #syntaxError ifTrue: [ ^ self syntaxFailureFor: (aContinuation outcome at: #notice) ].
	^ MCPDebugToolResult errorSummary: 'Debug capture failed without a worker outcome.' details: {
			  (#errorCode -> 'DebugCaptureNoOutcome').
			  (#expression -> request expression) } asDictionary
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> syntaxFailureFor: aNotice [

	| details |
	details := tool errorDetailsFor: aNotice.
	details
		at: #errorCode put: 'DebugCaptureSyntaxError';
		at: #description put: 'Compilation failed before capture execution.';
		at: #expression put: request expression.
	^ MCPDebugToolResult errorSummary: (tool syntaxFailureMessageFor: aNotice) details: details
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> timeoutResultForContinuation: aContinuation [

	| details |
	aContinuation terminateWorker.
	details := {
		           (#errorCode -> 'DebugCaptureTimedOut').
		           (#expression -> request expression).
		           (#timeoutMilliseconds -> request timeoutMilliseconds).
		           (#workerTerminated -> true) } asDictionary.
	^ MCPDebugToolResult
		  errorSummary: 'Debug capture timed out after ' , request timeoutMilliseconds asString , ' ms.'
		  details: details
]

{ #category : 'private - worker' }
MCPDebugCaptureCommand >> workerProcessForContinuation: aContinuation [

	^ [
		  | answer compiler handled notice outcome |
		  outcome := aContinuation outcome.
		  compiler := SmalltalkImage current compiler.
		  compiler compilationContext isScripting: true.
		  notice := nil.
		  compiler failBlock: [ :aNotice |
				  notice := aNotice.
				  nil ].
		  handled := false.
		  answer := [ compiler evaluate: request expression ]
			            on: Exception
			            do: [ :error |
					            handled := true.
					            (PharoCompatibility syntaxNoticeFromException: error)
						            ifNotNil: [ :syntaxNotice | self recordSyntaxFailure: syntaxNotice inOutcome: outcome ]
						            ifNil: [
								            self recordCapturedException: error inOutcome: outcome.
								            aContinuation signal.
								            Processor activeProcess suspend ].
					            nil ].
		  handled
			  ifFalse: [
					  notice
						  ifNotNil: [ self recordSyntaxFailure: notice inOutcome: outcome ]
						  ifNil: [ self recordCompletedAnswer: answer inOutcome: outcome ] ]
			  ifTrue: [
			  (outcome at: #status ifAbsent: [ nil ]) = #captured ifTrue: [ self recordCompletedAnswer: answer inOutcome: outcome ] ].
		  aContinuation signal ] newProcess
]
