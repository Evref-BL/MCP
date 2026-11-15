"
Command that evaluates Smalltalk code for the evaluate tool and returns a result data dictionary.
"
Class {
	#name : 'MCPEvaluateCommand',
	#superclass : 'MCPToolRequestCommand',
	#instVars : [
		'resultPreviewCharacterLimit',
		'transcript'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPEvaluateCommand class >> tool: aTool request: aRequest resultPreviewCharacterLimit: anInteger [

	^ self new initializeTool: aTool request: aRequest resultPreviewCharacterLimit: anInteger
]

{ #category : 'private' }
MCPEvaluateCommand >> addTranscriptTo: aDictionary [

	transcript contents ifEmpty: [ ^ self ].
	aDictionary at: #transcript put: transcript contents.
	transcript isTruncated ifTrue: [ aDictionary at: #transcriptTruncated put: true ]
]

{ #category : 'private' }
MCPEvaluateCommand >> endedItsOwnProcessResult [
	"The code terminated the process it ran in, so there is no value, only what it wrote to the Transcript before."

	| details |
	details := Dictionary new.
	transcript ifNotNil: [ self addTranscriptTo: details ].
	^ MCPEvaluateResult errorSummary: tool endedItsOwnProcessMessage details: details
]

{ #category : 'executing' }
MCPEvaluateCommand >> evaluate [
	"The code is compiled much as a Playground page compiles it, so a name it assigns without declaring is a variable of this evaluation, and what it writes to the Transcript comes back with its value."

	| answer compiler notice warningDescriptions |
	compiler := SmalltalkImage current compiler.
	compiler requestor: (MCPPlaygroundRequestor forCode: request code).
	notice := nil.
	warningDescriptions := OrderedCollection new.
	compiler failBlock: [ :aNotice |
			notice := aNotice.
			nil ].
	transcript := MCPTranscriptRecorder limit: resultPreviewCharacterLimit.
	answer := [ transcript recordDuring: [ compiler evaluate: request code ] ]
		          on: Exception
		          do: [ :error |
				          (error isKindOf: Notification) ifTrue: [ self resumeNotification: error collectingWarningInto: warningDescriptions ].
				          error mcpSyntaxNotice ifNotNil: [ :syntaxNotice | ^ self syntaxFailureFor: syntaxNotice ].
				          ^ self runtimeFailureFor: error ].
	notice ifNotNil: [ ^ self syntaxFailureFor: notice ].
	^ MCPEvaluateResult okData: (self resultDataFor: answer) warnings: warningDescriptions asArray
]

{ #category : 'private' }
MCPEvaluateCommand >> evaluateWithinCallBoundary [
	"The boundary MCPTool>>executeParsedRequestFrom:do:onError: keeps around a call, in the process the code runs in, so that no exception goes unhandled there, opens a debugger and leaves the call waiting for its limit."

	^ [
		  [ self evaluate ]
			  on: Notification
			  do: [ :notification |
					  (tool shouldResumeNotification: notification)
						  ifTrue: [ tool resumeNotification: notification ]
						  ifFalse: [ notification pass ] ] ]
		  on: Exception
		  do: [ :error |
		  MCPEvaluateResult errorSummary: (error messageText ifNil: [ error asString ]) details: (tool errorDetailsFor: error) ]
]

{ #category : 'executing' }
MCPEvaluateCommand >> execute [
	"The code runs in a process one priority below this one, which can therefore always take the processor back, however the code computes, and stop it at its time limit, or sooner when it runs away. A limit kept at the same priority cannot preempt a computing loop."

	| done evaluator outcome started actions stop |
	done := Semaphore new.
	started := false.
	actions := MCPPostResponseActions value.
	evaluator := [
		             started := true.
		             [ outcome := MCPPostResponseActions value: actions during: [ self evaluateWithinCallBoundary ] ] ensure: [
			             done signal ] ] newProcess.
	evaluator
		priority: Processor activePriority - 1;
		name: tool name.
	self start: evaluator.
	stop := self watch: evaluator until: done started: [ started ].
	stop ifNil: [ ^ outcome ifNil: [ self endedItsOwnProcessResult ] ].
	started ifFalse: [ ^ self notStartedResultFor: evaluator ].
	[ outcome isNil and: [ self isSaving: evaluator ] ] whileTrue: [ done waitTimeoutSeconds: 1 ].
	outcome ifNotNil: [ ^ outcome ].
	evaluator isTerminated ifTrue: [ ^ self endedItsOwnProcessResult ].
	^ self stop: evaluator saying: stop
]

{ #category : 'initialization' }
MCPEvaluateCommand >> initializeTool: aTool request: aRequest resultPreviewCharacterLimit: anInteger [

	tool := aTool.
	request := aRequest.
	resultPreviewCharacterLimit := anInteger.
	^ self
]

{ #category : 'private' }
MCPEvaluateCommand >> isSaving: aProcess [
	"A save restarts the MCP listener in the process that asked for it, after the snapshot. Stopped in between, the image would be left without its listener, so a save runs to its end, however long."

	| top |
	top := aProcess suspendedContext ifNil: [ ^ false ].
	^ (top stackOfSize: self savingFrameLimit) anySatisfy: [ :each | each method == (SessionManager >> #snapshot:andQuit:) ]
]

{ #category : 'private' }
MCPEvaluateCommand >> memoryGrowthLimit [
	"Generous, since it backs the stack bound up rather than stands for a precise one: code that keeps this much more within one evaluation is either running away, filling a collection in a loop that never ends, or doing heavy work, a model load, that belongs in a fork, which has no limit. Much more, and a machine of 16 GB starts to swap."

	^ 4 * 1024 * 1024 * 1024
]

{ #category : 'private' }
MCPEvaluateCommand >> memoryInUse [
	"The bytes the image's objects take in old space, where whatever code keeps ends up. Every Pharo from 10 to 15 reads them the same way."

	^ Smalltalk vm oldSpace - Smalltalk vm freeOldSpaceSize
]

{ #category : 'private' }
MCPEvaluateCommand >> notStartedDetailsFor: processes [

	^ Dictionary new
		  at: #heldBy put: (tool heldByLinesFor: processes);
		  at: #hint put: (tool heldByHintLinesFor: processes);
		  at: #timeoutSeconds put: request timeoutSeconds;
		  yourself
]

{ #category : 'private' }
MCPEvaluateCommand >> notStartedResultFor: anEvaluator [
	"Other processes kept the processor the whole time, so the evaluator ran nothing and has nothing to unwind: this process terminates it itself. Its priority is read first, since terminating it raises it to this one."

	| priority |
	priority := anEvaluator priority.
	anEvaluator terminate.
	^ MCPEvaluateResult
		  errorSummary: (tool notStartedMessageFor: request timeoutSeconds)
		  details: (self notStartedDetailsFor: (Processor waitingProcessesAt: priority) asArray)
]

{ #category : 'private' }
MCPEvaluateCommand >> resultDataFor: anAnswer [
	"Report what a truncated preview left out. The full length is deliberately not computed: printStringLimitedTo: stops early, and forcing the whole print string is exactly the cost this preview exists to avoid."

	| data printString |
	printString := anAnswer printStringLimitedTo: resultPreviewCharacterLimit.
	data := Dictionary new.
	data at: #resultClassName put: anAnswer class name asString.
	data at: #resultPrintString put: printString.
	self addTranscriptTo: data.
	printString size < resultPreviewCharacterLimit ifTrue: [ ^ data ].
	data at: #truncated put: true.
	(anAnswer isCollection and: [ anAnswer isString not ]) ifTrue: [ data at: #resultSize put: anAnswer size ].
	^ data
]

{ #category : 'accessing' }
MCPEvaluateCommand >> resultPreviewCharacterLimit [

	^ resultPreviewCharacterLimit
]

{ #category : 'private' }
MCPEvaluateCommand >> resumeNotification: aNotification collectingWarningInto: warningDescriptions [
	"A warning is the one notification the caller has to see: the value still arrives, and the warning is what says it is not what it looks like. Pharo's own description names the class first, which is the word that gets read, and the same text is kept once, since a loop over a deprecated method raises one sentence as often as it runs."

	(aNotification isKindOf: Warning) ifTrue: [ warningDescriptions addIfNotPresent: aNotification description ].
	^ self tool resumeNotification: aNotification
]

{ #category : 'private' }
MCPEvaluateCommand >> runtimeFailureFor: anError [

	| details |
	details := tool errorDetailsFor: anError.
	anError mcpAddToolErrorDetailsTo: details.
	self addTranscriptTo: details.
	^ MCPEvaluateResult errorSummary: (tool runtimeFailureMessageFor: anError) details: details
]

{ #category : 'private' }
MCPEvaluateCommand >> savingFrameLimit [
	"How deep in the evaluator's stack a save is looked for: deeper than the snapshot and the startup actions that follow it."

	^ 50
]

{ #category : 'private' }
MCPEvaluateCommand >> sourceIndexFor: aPosition [
	"A notice can point one character past the end of the source, where the expression simply stopped, so the position is clamped rather than rejected."

	| source |
	aPosition ifNil: [ ^ nil ].
	source := request code.
	source ifEmpty: [ ^ nil ].
	^ (aPosition max: 1) min: source size
]

{ #category : 'private' }
MCPEvaluateCommand >> stackDepthLimit [
	"Far deeper than ordinary code goes, and passed within a fraction of a second by an endless recursion. Compiling and running tests stay within a few hundred frames. Printing a structure that contains itself goes deepest, since printString bounds the characters printed rather than the depth: tens of thousands of frames, more where each level prints little."

	^ 1000000
]

{ #category : 'private' }
MCPEvaluateCommand >> stackOf: aProcess isDeeperThan: aNumber [
	"Its frames are counted only up to the bound, so that a stack millions of frames deep costs no more to look at than one at the bound."

	| frame depth |
	frame := aProcess suspendedContext.
	depth := 0.
	[ frame isNil ] whileFalse: [
			(depth := depth + 1) > aNumber ifTrue: [ ^ true ].
			frame := frame sender ].
	^ false
]

{ #category : 'private' }
MCPEvaluateCommand >> start: aProcess [
	"A method of its own, so that a test double can leave the evaluator unstarted."

	aProcess resume
]

{ #category : 'private' }
MCPEvaluateCommand >> stop: anEvaluator saying: aSummary [
	"Where the code is, and what it wrote, are read before it unwinds. A computing evaluator is taken off the run queue here: the helper below runs at its priority, and would otherwise wait behind it for a turn it may never get. One waiting on a semaphore is left waiting, since terminating it from there is what releases a critical section. The helper terminates it, so that its ensure blocks run at its own priority and this process waits for them only so long. What the stopped code grew is garbage only once it has unwound, which may be after the answer, and a full collection of a large heap takes seconds, so the helper collects it once the code has unwound and the answer has gone out."

	| details stopped answered |
	anEvaluator suspendingList == (Processor waitingProcessesAt: anEvaluator priority) ifTrue: [ anEvaluator suspend ].
	details := self stoppedDetailsFor: anEvaluator.
	stopped := Semaphore new.
	answered := Semaphore new.
	[
		[ anEvaluator terminate ] ensure: [ stopped signal ].
		answered wait.
		Smalltalk garbageCollect ] forkAt: anEvaluator priority named: tool name , ' stop'.
	(stopped waitTimeoutSeconds: self unwindingSeconds) ifTrue: [
			details at: #stillUnwinding put: true.
			transcript ifNotNil: [ :recorder | recorder finish ] ].
	MCPPostResponseActions defer: [ answered signal ].
	^ MCPEvaluateResult errorSummary: aSummary details: details
]

{ #category : 'private' }
MCPEvaluateCommand >> stoppedDetailsFor: anEvaluator [
	"Where the code is, read before it unwinds, cut at the outermost DoIt as a failure's frames are. Each frame is printed by its class and method only: printing a value would run the stopped code's own printOn:, which may be what never ends, or wait on a lock the stopped process holds."

	| details frames limit |
	limit := tool errorStackTraceLimit.
	frames := anEvaluator suspendedContext
		          ifNil: [ #(  ) ]
		          ifNotNil: [ :top | tool framesUpToCallerIn: (top stackOfSize: limit + 1) ].
	details := Dictionary new.
	details at: #stoppedIn put: (tool
			 collapsedFrameLines: ((frames first: (frames size min: limit)) collect: [ :each | each printString ] as: Array)
			 deeper: frames size > limit).
	details at: #hint put: tool longerWorkHintLines.
	details at: #timeoutSeconds put: request timeoutSeconds.
	transcript ifNotNil: [ self addTranscriptTo: details ].
	^ details
]

{ #category : 'private' }
MCPEvaluateCommand >> syntaxFailureFor: aNotice [

	| details index line |
	details := tool errorDetailsFor: aNotice.
	details at: #description put: 'Compilation failed before evaluation.'.
	index := self sourceIndexFor: aNotice position.
	line := index ifNotNil: [ request code lineNumberCorrespondingToIndex: index ].
	line ifNotNil: [
			details at: #line put: line.
			details at: #sourceLine put: (request code lineCorrespondingToIndex: index) ].
	^ MCPEvaluateResult errorSummary: (tool syntaxFailureMessageFor: aNotice line: line) details: details
]

{ #category : 'private' }
MCPEvaluateCommand >> unwindingSeconds [
	"How long a stopped evaluation's ensure blocks may run before the answer goes without waiting for them."

	^ 5
]

{ #category : 'private' }
MCPEvaluateCommand >> watch: anEvaluator until: done started: hasStarted [
	"Answer nil once the code has ended, or else why it is to be stopped, as the summary of its answer. At every look this process, running above the code, takes the processor back from it and reads what makes runaway code dangerous before its time limit passes: an endless recursion grows its stack by millions of frames a second and the image by GBs, enough to make a machine swap within the limit and the stop itself slow. Before the code has started, what grows the image is not the code."

	| deadline memory |
	deadline := Time microsecondClockValue + (request timeoutSeconds * 1000000).
	memory := self memoryInUse.
	[
		(done waitTimeoutSeconds: self watchMilliseconds / 1000) ifFalse: [ ^ nil ].
		(self stackOf: anEvaluator isDeeperThan: self stackDepthLimit) ifTrue: [ ^ tool stackStoppedMessageFor: self stackDepthLimit ].
		(hasStarted value and: [ self memoryInUse - memory > self memoryGrowthLimit ]) ifTrue: [
			^ tool memoryStoppedMessageFor: self memoryGrowthLimit ].
		Time microsecondClockValue < deadline ] whileTrue.
	^ tool stoppedMessageFor: request timeoutSeconds
]

{ #category : 'private' }
MCPEvaluateCommand >> watchMilliseconds [
	"How often the code's stack and the image's memory are looked at while it runs. An endless recursion grows its stack by millions of frames a second, so this is what decides how far past the bound it gets."

	^ 100
]
