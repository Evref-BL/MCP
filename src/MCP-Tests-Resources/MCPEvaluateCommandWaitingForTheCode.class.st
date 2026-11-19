"
An evaluate command whose time limit counts from when the code it evaluates runs, rather than from the call, and that looks at the code more often than the command does. A test can then stop code with a short limit once it has reached what the test stops it in, however long a loaded machine took to start and compile it.
"
Class {
	#name : 'MCPEvaluateCommandWaitingForTheCode',
	#superclass : 'MCPEvaluateCommand',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private' }
MCPEvaluateCommandWaitingForTheCode >> watch: anEvaluator until: done started: hasStarted [
	"The code runs once its DoIt is on the evaluator's stack. Code that ends before then is not watched. Code that has not reached it within 5 s, as when other processes keep the evaluator from running, is watched from then on, so that it is stopped or said not to have started rather than waited for."

	| deadline |
	deadline := Time millisecondClockValue + 5000.
	[
		Time millisecondClockValue < deadline and: [
			(anEvaluator suspendedContext ifNotNil: [ :top | top findContextSuchThat: [ :each | each method selector == #DoIt ] ]) isNil ] ]
		whileTrue: [ (done waitTimeoutSeconds: 1 / 1000) ifFalse: [ ^ nil ] ].
	^ super watch: anEvaluator until: done started: hasStarted
]

{ #category : 'private' }
MCPEvaluateCommandWaitingForTheCode >> watchMilliseconds [

	^ 10
]
