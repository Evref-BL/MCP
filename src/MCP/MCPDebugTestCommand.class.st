"
Runs one SUnit test under debugger control in a bounded worker process.

The command installs a temporary breakpoint on the requested test phase, runs the test through SUnit's debug path, and registers the stopped execution as an MCP DebugSession.
"
Class {
	#name : 'MCPDebugTestCommand',
	#superclass : 'MCPDebugCaptureCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - resolving' }
MCPDebugTestCommand >> breakpointMethod [

	^ self testClass lookupSelector: self breakpointSelector
]

{ #category : 'private - resolving' }
MCPDebugTestCommand >> breakpointSelector [

	request stopAt = 'test' ifTrue: [ ^ self testSelector ].
	request stopAt = 'setUp' ifTrue: [ ^ #setUp ].
	request stopAt = 'tearDown' ifTrue: [ ^ #tearDown ].
	^ self signalUnsupportedStopPoint
]

{ #category : 'private - data' }
MCPDebugTestCommand >> capabilities [

	^ {
		  (#isolatedWorkerProcess -> true).
		  (#testExecution -> true).
		  (#testPhaseBreakpoints -> true).
		  (#runtimeExceptionCapture -> true).
		  (#syntaxErrorsCreateSessions -> false).
		  (#timeoutTermination -> true).
		  (#postCaptureState -> true).
		  (#mutating -> true) } asDictionary
]

{ #category : 'private - data' }
MCPDebugTestCommand >> captureWarnings [

	^ #( 'debug-test runs one SUnit test in a forked worker process and may mutate image state.'
	     'Captured debug stops, failures, or errors leave the worker process suspended until debug-control resumes or terminates the session.' )
]

{ #category : 'private - results' }
MCPDebugTestCommand >> capturedReasonFor: aDebugSession [

	| exception |
	exception := aDebugSession exception.
	(exception isKindOf: Break) ifTrue: [ ^ 'debugStop' ].
	(exception isKindOf: TestFailure) ifTrue: [ ^ 'testFailure' ].
	^ 'testError'
]

{ #category : 'private - results' }
MCPDebugTestCommand >> capturedResultFor: aDebugSession continuation: aContinuation [

	| data record state warnings |
	record := registry
		          registerDebugSession: aDebugSession
		          named: request name
		          status: 'paused'
		          reason: (self capturedReasonFor: aDebugSession).
	record continuation: aContinuation.
	state := (MCPDebugStateInfo fromRecord: record request: request)
		         asDictionary.
	warnings := self captureWarnings.
	data := self testData.
	data
		at: #captured put: true;
		at: #timedOut put: false;
		at: #passed put: false;
		at: #sessionId put: record sessionId;
		at: #stateId put: record stateId;
		at: #session
		put: (MCPDebugSessionInfo fromRecord: record) asDictionary;
		at: #state put: state;
		at: #timeoutMilliseconds put: request timeoutMilliseconds;
		at: #warnings put: warnings;
		at: #capabilities put: self capabilities.
	^ MCPDebugToolResult
		  okSummary: 'Debug test registered ' , record sessionId , '.'
		  data: data
		  warnings: warnings
]

{ #category : 'private - results' }
MCPDebugTestCommand >> completedResultFor: ignored [

	| data warnings |
	warnings := self captureWarnings.
	data := self testData.
	data
		at: #captured put: false;
		at: #timedOut put: false;
		at: #passed put: true;
		at: #sessionId put: nil;
		at: #stateId put: nil;
		at: #session put: nil;
		at: #state put: nil;
		at: #timeoutMilliseconds put: request timeoutMilliseconds;
		at: #warnings put: warnings;
		at: #capabilities put: self capabilities.
	^ MCPDebugToolResult
		  okSummary: 'Debug test completed without stopping or failing.'
		  data: data
		  warnings: warnings
]

{ #category : 'private - worker' }
MCPDebugTestCommand >> debugStartContextFor: anException [

	(anException isKindOf: Break) ifTrue: [
		^ anException signalerContext sender ].
	^ anException signalerContext
]

{ #category : 'executing' }
MCPDebugTestCommand >> execute [

	self testCase.
	self breakpointMethod.
	^ super execute
]

{ #category : 'private - debugging' }
MCPDebugTestCommand >> installStopBreakpoint [

	^ DebugPointManager
		  installNew: BreakDebugPoint
		  on: self breakpointMethod ast
]

{ #category : 'private - worker' }
MCPDebugTestCommand >> recordCapturedException: anException inOutcome: outcome [

	| debugSession |
	debugSession := DebugSession
		                named: request name
		                on: Processor activeProcess
		                startedAt: (self debugStartContextFor: anException).
	debugSession exception: anException.
	outcome
		removeKey: #answer ifAbsent: [ nil ];
		at: #status put: #captured;
		at: #debugSession put: debugSession;
		at: #exception put: anException
]

{ #category : 'private - debugging' }
MCPDebugTestCommand >> removeBreakpoint: aDebugPoint [

	aDebugPoint ifNil: [ ^ self ].
	[ aDebugPoint remove ]
		on: Error
		do: [ :ignored | nil ]
]

{ #category : 'private - errors' }
MCPDebugTestCommand >> signalClassIsNotTestCase: aClass [

	^ MCPCommandError
		  signalErrorCode: #DebugTestClassIsNotTestCase
		  message: request className , ' is not a TestCase subclass.'
		  details: {
				  (#className -> request className).
				  (#actualClassName -> aClass name asString).
				  (#expectedSuperclassName -> 'TestCase') } asDictionary
]

{ #category : 'private - errors' }
MCPDebugTestCommand >> signalUnsupportedStopPoint [

	^ MCPCommandError
		  signalErrorCode: #DebugTestStopPointUnsupported
		  message:
		  'Unsupported debug test stopAt: ' , request stopAt asString , '.'
		  details: {
				  (#stopAt -> request stopAt).
				  (#supportedStopPoints -> MCPDebugTestRequest supportedStopPoints) }
				  asDictionary
]

{ #category : 'private - resolving' }
MCPDebugTestCommand >> testCase [

	| class selector |
	class := self testClass.
	selector := self testSelector.
	(class canUnderstand: selector) ifFalse: [
			MCPCommandError
				signalMissingMethodInClassName: request className
				classSide: false
				selector: selector ].
	^ class selector: selector
]

{ #category : 'private - resolving' }
MCPDebugTestCommand >> testClass [

	| class |
	class := Smalltalk globals
		         at: request className asSymbol
		         ifAbsent: [
		         MCPCommandError signalMissingClassNamed: request className ].
	(class = TestCase or: [ class inheritsFrom: TestCase ]) ifFalse: [
		self signalClassIsNotTestCase: class ].
	^ class
]

{ #category : 'private - results' }
MCPDebugTestCommand >> testData [

	^ {
		  (#className -> request className).
		  (#testMethodName -> request testMethodName).
		  (#stopAt -> request stopAt) } asDictionary
]

{ #category : 'private - resolving' }
MCPDebugTestCommand >> testSelector [

	^ request testMethodName asSymbol
]

{ #category : 'private - results' }
MCPDebugTestCommand >> timeoutResultForContinuation: aContinuation [

	| details |
	aContinuation terminateWorker.
	details := self testData.
	details
		at: #errorCode put: 'DebugTestTimedOut';
		at: #timeoutMilliseconds put: request timeoutMilliseconds;
		at: #workerTerminated put: true.
	^ MCPDebugToolResult
		  errorSummary:
			  'Debug test timed out after '
			  , request timeoutMilliseconds asString , ' ms.'
		  details: details
]

{ #category : 'private - worker' }
MCPDebugTestCommand >> workerProcessForContinuation: aContinuation [

	^ [
		  | answer breakpoint handled outcome |
		  outcome := aContinuation outcome.
		  handled := false.
		  breakpoint := self installStopBreakpoint.
		  answer := [
			            [
				            self testClass debug: self testSelector.
				            true ] ensure: [ self removeBreakpoint: breakpoint ] ]
			            on: Exception
			            do: [ :error |
					            handled := true.
					            self
						            recordCapturedException: error
						            inOutcome: outcome.
					            aContinuation signal.
					            Processor activeProcess suspend.
					            false ].
		  handled
			  ifFalse: [ self recordCompletedAnswer: answer inOutcome: outcome ]
			  ifTrue: [
					  (outcome at: #status ifAbsent: [ nil ]) = #captured ifTrue: [
						  self recordCompletedAnswer: answer inOutcome: outcome ] ].
		  aContinuation signal ] newProcess
]
