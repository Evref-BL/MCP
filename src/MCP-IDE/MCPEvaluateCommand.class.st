"
Evaluates Smalltalk code for the evaluate tool, in a process of its own one priority below the caller, and watches it: it stops the code at its time limit, or sooner when its stack or the image's memory runs away, and leaves alone what the code forked.

What happens in the code's process is read there, while it is there to read: the value's preview, within a limit of characters, since printing a value runs its own code; and a failure's description, before its stack unwinds. The code may also never start, end its own process, or be stopped, which this process sees, reading where a stopped evaluation was before it unwinds.

It answers an evaluation, holding how it ended and what it read: itself, or, when the code's process returned, the copy of itself that process noted what it read in. What a call answers for each ending is the tool's to say.
"
Class {
	#name : 'MCPEvaluateCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'transcript',
		'code',
		'timeLimit',
		'previewLimit',
		'ending',
		'answer',
		'preview',
		'answerSize',
		'warnings',
		'failure',
		'failureDetails',
		'transcriptText',
		'transcriptTruncated',
		'stopReason',
		'stoppedFrames',
		'stillUnwinding',
		'holders'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPEvaluateCommand class >> code: aString timeLimit: seconds previewLimit: anInteger [
	"Evaluate aString, stopping it after seconds, and preview its value in at most anInteger characters, as many as are kept of what it writes to the Transcript."

	^ self new initializeCode: aString timeLimit: seconds previewLimit: anInteger
]

{ #category : 'accessing' }
MCPEvaluateCommand class >> processName [
	"What the process an evaluation runs in is called, and how the one that stops it begins: the tool's name, which a person listing processes recognises."

	^ 'evaluate'
]

{ #category : 'stopping' }
MCPEvaluateCommand class >> terminate: anEvaluator waiting: seconds [
	"Terminate anEvaluator in a helper at its priority, so that its ensure blocks run there, and answer whether it was still unwinding after seconds. What the stopped code grew is garbage only once it has unwound, which may be after the answer, and a full collection of a large heap takes seconds, so the helper collects it once the code has unwound and the answer has gone out. Were the call's deferred actions never run, its worker ended first or its caller never running them, waiting for them would keep the helper and the garbage forever, so the helper waits for the answer only as long as the answer waits for the unwinding. The class forks the helper so that it holds nothing of the evaluation, whose frames hold what the stopped code grew."

	| answered stillUnwinding stopped |
	stopped := Semaphore new.
	answered := Semaphore new.
	[
		[ anEvaluator terminate ] ensure: [ stopped signal ].
		answered waitTimeoutSeconds: seconds.
		Smalltalk garbageCollect ] forkAt: anEvaluator priority named: self processName , ' stop'.
	stillUnwinding := stopped waitTimeoutSeconds: seconds.
	MCPPostResponseActions defer: [ answered signal ].
	^ stillUnwinding
]

{ #category : 'accessing' }
MCPEvaluateCommand >> answer [
	"The code's value."

	^ answer
]

{ #category : 'accessing' }
MCPEvaluateCommand >> answerSize [
	"How many elements a collection holds whose preview was cut, or nil."

	^ answerSize
]

{ #category : 'testing' }
MCPEvaluateCommand >> answeredTheTranscript [
	"Code that ends on the Transcript, as a cascade of show: does, answers the recorder that stood in for it while the code ran."

	^ answer == transcript
]

{ #category : 'private' }
MCPEvaluateCommand >> callBoundary [
	"How a call resumes a notification and describes a failure, which MCPTool keeps for every tool. The code runs in a process of its own, so they are re-established there with a tool of no kind in particular: a failure is described while its stack is still there to read, which is only in that process, before it unwinds."

	^ MCPTool new
]

{ #category : 'accessing' }
MCPEvaluateCommand >> code [

	^ code
]

{ #category : 'private' }
MCPEvaluateCommand >> describeFailure: anException [
	"Read in the process that raised anException, while its stack is still there, and within the time limit, since describing a frame prints what it holds."

	failure := anException.
	failureDetails := self callBoundary errorDetailsFor: anException
]

{ #category : 'private' }
MCPEvaluateCommand >> endedItsOwnProcess [
	"The code terminated the process it ran in, so there is no value, only what it wrote to the Transcript before."

	self noteTranscript.
	ending := #endedItsOwnProcess
]

{ #category : 'accessing' }
MCPEvaluateCommand >> ending [
	"How the evaluation ended: #value, #syntaxFailure, #runtimeFailure, #failure when what failed was not the code's own, #endedItsOwnProcess, #notStarted or #stopped."

	^ ending
]

{ #category : 'executing' }
MCPEvaluateCommand >> evaluate [
	"The code is compiled much as a Playground page compiles it, so a name it assigns without declaring is a variable of this evaluation, and what it writes to the Transcript comes back with its value."

	| compiler notice result warningDescriptions |
	compiler := SmalltalkImage current compiler.
	compiler requestor: (MCPPlaygroundRequestor forCode: code).
	notice := nil.
	warningDescriptions := OrderedCollection new.
	compiler failBlock: [ :aNotice |
			notice := aNotice.
			nil ].
	result := [ transcript recordDuring: [ compiler evaluate: code ] ]
		          on: Exception
		          do: [ :error |
				          (error isKindOf: Notification) ifTrue: [ self resumeNotification: error collectingWarningInto: warningDescriptions ].
				          error mcpSyntaxNotice ifNotNil: [ :syntaxNotice | ^ self syntaxFailureFor: syntaxNotice ].
				          ^ self runtimeFailureFor: error ].
	notice ifNotNil: [ ^ self syntaxFailureFor: notice ].
	self resultDataFor: result.
	warnings := warningDescriptions asArray.
	ending := #value
]

{ #category : 'private' }
MCPEvaluateCommand >> evaluateWithinCallBoundary [
	"The boundary MCPTool>>executeRequest:do:onError: keeps around a call, in the process the code runs in, so that no exception goes unhandled there, opens a debugger and leaves the call waiting for its limit."

	[ self callBoundary resumingNotificationsDuring: [ self evaluate ] ]
		on: Exception
		do: [ :error | self failureFor: error ]
]

{ #category : 'executing' }
MCPEvaluateCommand >> execute [
	"The code runs in a process one priority below this one, which can therefore always take the processor back, however the code computes, and stop it at its time limit, or sooner when it runs away. A limit kept at the same priority cannot preempt a computing loop. That process notes what it reads in a copy of myself, which becomes the answer once the process has returned from it, before it signals done, since this process wakes above it. Until then the code may still end its own process or be stopped, and what a stopped evaluation's ensure blocks then do, fail or answer, is not part of the answer. Answer the evaluation, holding how it ended."

	| done evaluation evaluator outcome started actions stop |
	done := Semaphore new.
	started := false.
	actions := MCPPostResponseActions value.
	transcript := MCPTranscriptRecorder limit: previewLimit.
	evaluation := self copy.
	evaluator := [
		             started := true.
		             [
			             MCPPostResponseActions value: actions during: [ evaluation evaluateWithinCallBoundary ].
			             outcome := evaluation ] ensure: [ done signal ] ] newProcess.
	evaluator
		priority: Processor activePriority - 1;
		name: self class processName.
	self start: evaluator.
	stop := self watch: evaluator until: done started: [ started ].
	stop ifNil: [ ^ outcome ifNil: [ self endedItsOwnProcess ] ].
	started ifFalse: [ ^ self terminateUnstarted: evaluator ].
	[ outcome isNil and: [ self isSaving: evaluator ] ] whileTrue: [ done waitTimeoutSeconds: 1 ].
	outcome ifNotNil: [ ^ outcome ].
	evaluator isTerminated ifTrue: [ ^ self endedItsOwnProcess ].
	^ self stop: evaluator because: stop
]

{ #category : 'accessing' }
MCPEvaluateCommand >> failure [
	"The exception the evaluation failed with, or the notice its compilation did."

	^ failure
]

{ #category : 'accessing' }
MCPEvaluateCommand >> failureDetails [
	"The failure as a call describes one, read while its stack was still there."

	^ failureDetails
]

{ #category : 'private' }
MCPEvaluateCommand >> failureFor: anError [
	"A failure that is not the code's own, in getting it ready to compile or in previewing its value."

	self describeFailure: anError.
	ending := #failure
]

{ #category : 'testing' }
MCPEvaluateCommand >> hasTruncatedPreview [

	^ preview size >= previewLimit
]

{ #category : 'accessing' }
MCPEvaluateCommand >> holders [
	"The processes that kept the processor from an evaluation that never started."

	^ holders
]

{ #category : 'initialization' }
MCPEvaluateCommand >> initializeCode: aString timeLimit: seconds previewLimit: anInteger [

	code := aString.
	timeLimit := seconds.
	previewLimit := anInteger.
	warnings := #(  ).
	transcriptTruncated := false.
	stillUnwinding := false
]

{ #category : 'private' }
MCPEvaluateCommand >> isSaving: aProcess [
	"A save restarts the MCP listener in the process that asked for it, after the snapshot. Stopped in between, the image would be left without its listener, so a save runs to its end, however long."

	| top |
	top := aProcess suspendedContext ifNil: [ ^ false ].
	^ (top stackOfSize: self savingFrameLimit) anySatisfy: [ :each | each method == (SessionManager >> #snapshot:andQuit:) ]
]

{ #category : 'testing' }
MCPEvaluateCommand >> isStillUnwinding [
	"Whether a stopped evaluation's ensure blocks were still running when it answered."

	^ stillUnwinding
]

{ #category : 'testing' }
MCPEvaluateCommand >> isTranscriptTruncated [

	^ transcriptTruncated
]

{ #category : 'accessing' }
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
MCPEvaluateCommand >> noteTranscript [
	"What the code has written to the Transcript by now, read where its answer is decided: what its ensure blocks write while it unwinds is not part of it."

	transcript ifNil: [ ^ self ].
	transcriptText := transcript contents.
	transcriptTruncated := transcript isTruncated
]

{ #category : 'private' }
MCPEvaluateCommand >> noteWhereStopped: anEvaluator [
	"Where the code is, read before it unwinds, cut at the outermost DoIt as a failure's frames are, and what it wrote by then. The frames are kept, not described: describing one may print what it holds, which would run the stopped code's own printOn:, which may be what never ends, or wait on a lock the stopped process holds. They are kept as copies, because terminating the process rewrites its frames on some Pharo versions: on 11, the top one becomes Process>>endProcess."

	| boundary |
	boundary := self callBoundary.
	stoppedFrames := anEvaluator suspendedContext
		                 ifNil: [ #(  ) ]
		                 ifNotNil: [ :top |
		                 (boundary framesUpToCallerIn: (top stackOfSize: boundary errorStackTraceLimit + 1)) collect: [ :each |
			                 each copy ] ].
	self noteTranscript
]

{ #category : 'accessing' }
MCPEvaluateCommand >> preview [
	"The value's print string, cut at the preview limit."

	^ preview
]

{ #category : 'private' }
MCPEvaluateCommand >> resultDataFor: anAnswer [
	"Note the value, previewed here, within the time limit, since printing it runs its own code. What a cut preview left out is noted too. The full length is deliberately not computed: printStringLimitedTo: stops early, and forcing the whole print string is exactly the cost this preview exists to avoid. Code that ends on the Transcript answers the recorder that stood in for it, which needs no preview."

	answer := anAnswer.
	anAnswer == transcript ifTrue: [ ^ self noteTranscript ].
	preview := anAnswer printStringLimitedTo: previewLimit.
	self noteTranscript.
	self hasTruncatedPreview ifFalse: [ ^ self ].
	(anAnswer isCollection and: [ anAnswer isString not ]) ifTrue: [ answerSize := anAnswer size ]
]

{ #category : 'private' }
MCPEvaluateCommand >> resumeNotification: aNotification collectingWarningInto: warningDescriptions [
	"A warning is the one notification the caller has to see: the value still arrives, and the warning is what says it is not what it looks like. Pharo's own description names the class first, which is the word that gets read, and the same text is kept once, since a loop over a deprecated method raises one sentence as often as it runs."

	(aNotification isKindOf: Warning) ifTrue: [ warningDescriptions addIfNotPresent: aNotification description ].
	^ aNotification mcpResume
]

{ #category : 'private' }
MCPEvaluateCommand >> runtimeFailureFor: anError [
	"Described before the code's ensure blocks run and write more to the Transcript."

	self describeFailure: anError.
	anError mcpAddToolErrorDetailsTo: failureDetails.
	self noteTranscript.
	ending := #runtimeFailure
]

{ #category : 'private' }
MCPEvaluateCommand >> savingFrameLimit [
	"How deep in the evaluator's stack a save is looked for: deeper than the snapshot and the startup actions that follow it."

	^ 50
]

{ #category : 'accessing' }
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
MCPEvaluateCommand >> stop: anEvaluator because: aReason [
	"Where the code is, and what it wrote, are read before it unwinds. A computing evaluator is taken off the run queue here: the helper that terminates it runs at its priority, and would otherwise wait behind it for a turn it may never get. One waiting on a semaphore is left waiting, since terminating it from there is what releases a critical section. The helper terminates it so that its ensure blocks run at its own priority and this process waits for them only so long."

	anEvaluator suspendingList == (Processor waitingProcessesAt: anEvaluator priority) ifTrue: [ anEvaluator suspend ].
	self noteWhereStopped: anEvaluator.
	stillUnwinding := self class terminate: anEvaluator waiting: self unwindingSeconds.
	stillUnwinding ifTrue: [ transcript ifNotNil: [ :recorder | recorder finish ] ].
	stopReason := aReason.
	ending := #stopped
]

{ #category : 'accessing' }
MCPEvaluateCommand >> stopReason [
	"Why a stopped evaluation was stopped: #timeLimit, #stackDepth or #memoryGrowth."

	^ stopReason
]

{ #category : 'accessing' }
MCPEvaluateCommand >> stoppedFrames [
	"Where a stopped evaluation was, top first, cut at its outermost DoIt, one frame more than a failure shows when the stack goes deeper."

	^ stoppedFrames
]

{ #category : 'private' }
MCPEvaluateCommand >> syntaxFailureFor: aNotice [

	self describeFailure: aNotice.
	ending := #syntaxFailure
]

{ #category : 'private' }
MCPEvaluateCommand >> terminateUnstarted: anEvaluator [
	"Other processes kept the processor the whole time, so the evaluator ran nothing and has nothing to unwind: this process terminates it itself. Its priority is read first, since terminating it raises it to this one."

	| priority |
	priority := anEvaluator priority.
	anEvaluator terminate.
	holders := (Processor waitingProcessesAt: priority) asArray.
	ending := #notStarted
]

{ #category : 'accessing' }
MCPEvaluateCommand >> timeLimit [
	"How long, in seconds, the code may run before it is stopped."

	^ timeLimit
]

{ #category : 'accessing' }
MCPEvaluateCommand >> transcriptText [
	"What the code wrote to the Transcript by the time its answer was decided, or nil when it never ran far enough to write."

	^ transcriptText
]

{ #category : 'private' }
MCPEvaluateCommand >> unwindingSeconds [
	"How long a stopped evaluation's ensure blocks may run before the answer goes without waiting for them."

	^ 5
]

{ #category : 'accessing' }
MCPEvaluateCommand >> warnings [
	"What was raised while the code ran, reported beside the value rather than instead of it."

	^ warnings
]

{ #category : 'private' }
MCPEvaluateCommand >> watch: anEvaluator until: done started: hasStarted [
	"Answer nil once the code has ended, or else why it is to be stopped: #stackDepth, #memoryGrowth or #timeLimit. At every look this process, running above the code, takes the processor back from it and reads what makes runaway code dangerous before its time limit passes: an endless recursion grows its stack by millions of frames a second and the image by GBs, enough to make a machine swap within the limit and the stop itself slow. Before the code has started, what grows the image is not the code."

	| deadline memory |
	deadline := Time microsecondClockValue + (timeLimit * 1000000).
	memory := self memoryInUse.
	[
		(done waitTimeoutSeconds: self watchMilliseconds / 1000) ifFalse: [ ^ nil ].
		(self stackOf: anEvaluator isDeeperThan: self stackDepthLimit) ifTrue: [ ^ #stackDepth ].
		(hasStarted value and: [ self memoryInUse - memory > self memoryGrowthLimit ]) ifTrue: [ ^ #memoryGrowth ].
		Time microsecondClockValue < deadline ] whileTrue.
	^ #timeLimit
]

{ #category : 'private' }
MCPEvaluateCommand >> watchMilliseconds [
	"How often the code's stack and the image's memory are looked at while it runs. An endless recursion grows its stack by millions of frames a second, so this is what decides how far past the bound it gets."

	^ 100
]
