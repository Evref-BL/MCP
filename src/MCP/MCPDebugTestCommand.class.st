"
Runs one SUnit test case in a bounded worker process and captures failures or errors as DebugSession records.

This gives agents debugger control over a failing test without evaluating arbitrary Smalltalk source.
"
Class {
	#name : 'MCPDebugTestCommand',
	#superclass : 'MCPDebugCaptureCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - data' }
MCPDebugTestCommand >> capabilities [

	^ {
		  (#isolatedWorkerProcess -> true).
		  (#testExecution -> true).
		  (#runtimeExceptionCapture -> true).
		  (#syntaxErrorsCreateSessions -> false).
		  (#timeoutTermination -> true).
		  (#postCaptureState -> true).
		  (#mutating -> true) } asDictionary
]

{ #category : 'private - data' }
MCPDebugTestCommand >> captureWarnings [

	^ #( 'debug-test runs one SUnit test in a forked worker process and may mutate image state.'
	     'Captured failures or errors leave the worker process suspended until debug-control resumes or terminates the session.' )
]

{ #category : 'private - results' }
MCPDebugTestCommand >> capturedReasonFor: aDebugSession [

	^ (aDebugSession exception isKindOf: TestFailure)
		  ifTrue: [ 'testFailure' ]
		  ifFalse: [ 'testError' ]
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
		  okSummary: 'Debug test passed without a failure or error.'
		  data: data
		  warnings: warnings
]

{ #category : 'executing' }
MCPDebugTestCommand >> execute [

	self testCase.
	^ super execute
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
		  (#testMethodName -> request testMethodName) } asDictionary
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
		  | answer handled outcome |
		  outcome := aContinuation outcome.
		  handled := false.
		  answer := [
			            self testCase runCase.
			            true ]
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
