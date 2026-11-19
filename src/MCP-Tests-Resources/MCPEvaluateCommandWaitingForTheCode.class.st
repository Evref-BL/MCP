"
An evaluate command whose time limit counts from when the code it evaluates runs, rather than from the call, and that looks at the code every 10 ms rather than 100. A test can then stop code with a short limit once it has reached what the test stops it in, however long a loaded machine took to start and compile it.
"
Class {
	#name : 'MCPEvaluateCommandWaitingForTheCode',
	#superclass : 'MCPEvaluateCommand',
	#category : 'MCP-Tests-Resources',
	#package : 'MCP-Tests-Resources'
}

{ #category : 'private' }
MCPEvaluateCommandWaitingForTheCode >> watch: anEvaluator until: done started: hasStarted [
	"The code runs once its DoIt is on the evaluator's stack. Code that ends before then is not watched."

	[ (anEvaluator suspendedContext ifNotNil: [ :top | top findContextSuchThat: [ :each | each method selector == #DoIt ] ]) isNil ]
		whileTrue: [ (done waitTimeoutSeconds: 1 / 1000) ifFalse: [ ^ nil ] ].
	^ super watch: anEvaluator until: done started: hasStarted
]

{ #category : 'private' }
MCPEvaluateCommandWaitingForTheCode >> watchMilliseconds [

	^ 10
]
