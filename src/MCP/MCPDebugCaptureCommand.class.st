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

	^ #( 'debug-capture evaluates arbitrary Smalltalk in a forked worker process and may mutate image state.'
	     'Captured exceptions leave the worker process suspended until debug-control resumes or terminates the session.' )
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> capturedResultFor: aDebugSession [

	| data record state warnings |
	record := registry
		          registerDebugSession: aDebugSession
		          named: request name
		          status: 'paused'
		          reason: 'capturedException'.
	state := (MCPDebugStateInfo fromRecord: record request: request)
		         asDictionary.
	warnings := self captureWarnings.
	data := {
		        (#captured -> true).
		        (#timedOut -> false).
		        (#sessionId -> record sessionId).
		        (#stateId -> record stateId).
		        (#session
		         -> (MCPDebugSessionInfo fromRecord: record) asDictionary).
		        (#state -> state).
		        (#resultClassName -> nil).
		        (#resultPrintString -> nil).
		        (#timeoutMilliseconds -> request timeoutMilliseconds).
		        (#warnings -> warnings).
		        (#capabilities -> self capabilities) } asDictionary.
	^ MCPDebugToolResult
		  okSummary: 'Debug capture registered ' , record sessionId , '.'
		  data: data
		  warnings: warnings
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
		        (#warnings -> warnings).
		        (#capabilities -> self capabilities) } asDictionary.
	^ MCPDebugToolResult
		  okSummary: 'Debug capture completed without an exception.'
		  data: data
		  warnings: warnings
]

{ #category : 'executing' }
MCPDebugCaptureCommand >> execute [

	| outcome timedOut worker semaphore |
	outcome := Dictionary new.
	semaphore := Semaphore new.
	worker := self workerProcessForOutcome: outcome semaphore: semaphore.
	worker resume.
	timedOut := semaphore waitTimeoutMilliseconds:
		            request timeoutMilliseconds.
	timedOut ifTrue: [ ^ self timeoutResultForWorker: worker ].
	^ self resultForOutcome: outcome
]

{ #category : 'private - printing' }
MCPDebugCaptureCommand >> limitedPrintStringOf: anObject [

	anObject ifNil: [ ^ 'nil' ].
	^ [
	  anObject printStringLimitedTo: request resultPreviewCharacterLimit ]
		  on: Error
		  do: [ :error | anObject class name asString ]
]

{ #category : 'private - worker' }
MCPDebugCaptureCommand >> recordCapturedException: anException inOutcome: outcome [

	| debugSession |
	debugSession := DebugSession
		                named: request name
		                on: Processor activeProcess
		                startedAt: anException signalerContext.
	debugSession exception: anException.
	outcome
		at: #status put: #captured;
		at: #debugSession put: debugSession;
		at: #exception put: anException
]

{ #category : 'private - worker' }
MCPDebugCaptureCommand >> recordCompletedAnswer: answer inOutcome: outcome [

	outcome
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
MCPDebugCaptureCommand >> resultForOutcome: outcome [

	| status |
	status := outcome at: #status ifAbsent: [ #missing ].
	status = #completed ifTrue: [
		^ self completedResultFor: (outcome at: #answer) ].
	status = #captured ifTrue: [
		^ self capturedResultFor: (outcome at: #debugSession) ].
	status = #syntaxError ifTrue: [
		^ self syntaxFailureFor: (outcome at: #notice) ].
	^ MCPDebugToolResult
		  errorSummary: 'Debug capture failed without a worker outcome.'
		  details: {
				  (#errorCode -> 'DebugCaptureNoOutcome').
				  (#expression -> request expression) } asDictionary
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> syntaxFailureFor: aNotice [

	| details |
	details := tool errorDetailsFor: aNotice.
	details
		at: #errorCode put: 'DebugCaptureSyntaxError';
		at: #description
		put: 'Compilation failed before capture execution.';
		at: #expression put: request expression.
	(aNotice respondsTo: #position) ifTrue: [
		details at: #position put: aNotice position ].
	^ MCPDebugToolResult
		  errorSummary: (tool syntaxFailureMessageFor: aNotice)
		  details: details
]

{ #category : 'private - results' }
MCPDebugCaptureCommand >> timeoutResultForWorker: workerProcess [

	| details |
	[ workerProcess terminate ]
		on: Error
		do: [ :ignored | nil ].
	details := {
		           (#errorCode -> 'DebugCaptureTimedOut').
		           (#expression -> request expression).
		           (#timeoutMilliseconds -> request timeoutMilliseconds).
		           (#workerTerminated -> true) } asDictionary.
	^ MCPDebugToolResult
		  errorSummary: 'Debug capture timed out after '
			  , request timeoutMilliseconds asString , ' ms.'
		  details: details
]

{ #category : 'private - worker' }
MCPDebugCaptureCommand >> workerProcessForOutcome: outcome semaphore: semaphore [

	^ [
		  | answer compiler handled notice |
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
						            ifNotNil: [ :syntaxNotice |
							            self
								            recordSyntaxFailure: syntaxNotice
								            inOutcome: outcome ]
						            ifNil: [
								            self
									            recordCapturedException: error
									            inOutcome: outcome.
								            semaphore signal.
								            Processor activeProcess suspend ].
					            nil ].
		  handled ifFalse: [
				  notice
					  ifNotNil: [
					  self recordSyntaxFailure: notice inOutcome: outcome ]
					  ifNil: [ self recordCompletedAnswer: answer inOutcome: outcome ] ].
		  semaphore signal ] newProcess
]
