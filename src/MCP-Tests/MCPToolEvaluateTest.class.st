"
Tests evaluate: what it answers for code that runs, fails or never starts, what a failure says about the message or variable at fault, and how it stops code at its time limit and what it leaves behind.
"
Class {
	#name : 'MCPToolEvaluateTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolEvaluateTest >> evaluate: aString within: seconds [
	"The answer of an evaluation with a time limit, as a call gets it: once it has answered, what it deferred runs, as the server runs it after the response. Through test_run a test runs inside a call of its own, which would otherwise hold what the evaluation deferred until the whole run has answered."

	| actions result |
	actions := OrderedCollection new.
	result := MCPPostResponseActions value: actions during: [
			          self callToolNamed: 'evaluate' withArguments: {
					          (#code -> aString).
					          (#timeoutSeconds -> seconds) } asDictionary ].
	actions do: [ :each | each value ].
	^ result
]

{ #category : 'private' }
MCPToolEvaluateTest >> evaluateBriefly: aString [
	"The answer to an evaluation of aString with the tests' short limit, once what it deferred has run, as the server runs it after the response."

	| actions result |
	actions := OrderedCollection new.
	result := self evaluateBriefly: aString deferringInto: actions.
	actions do: [ :each | each value ].
	^ result
]

{ #category : 'private' }
MCPToolEvaluateTest >> evaluateBriefly: aString deferringInto: actions [
	"The answer to an evaluation of aString with the tests' short limit, counted from when its code runs, leaving in actions what the call deferred until after its response."

	| tool |
	tool := MCPToolEvaluate new.
	^ MCPPostResponseActions value: actions during: [
			  tool answerFor:
				  (MCPEvaluateCommandWaitingForTheCode
					   code: aString
					   timeLimit: self stopLimitSeconds
					   previewLimit: tool resultPreviewCharacterLimit) execute ]
]

{ #category : 'private' }
MCPToolEvaluateTest >> fullGarbageCollections [
	"How many full collections the VM has made since it started."

	^ Smalltalk vm parameterAt: 7
]

{ #category : 'private' }
MCPToolEvaluateTest >> liveProcessesNamed: aString [

	^ Process allInstances select: [ :each | each name = aString and: [ each isTerminated not ] ]
]

{ #category : 'private' }
MCPToolEvaluateTest >> notStartedTextHeldBy: processes [
	"The text of an evaluation that never started within 1 s, while these processes held the priority evaluations run at."

	| tool |
	tool := MCPToolEvaluate new.
	^ tool contentTextForStructuredContent: (Dictionary new
			   at: #summary put: (tool notStartedMessageFor: 1);
			   at: #error put: (tool notStartedDetailsFor: processes within: 1);
			   yourself)
]

{ #category : 'private' }
MCPToolEvaluateTest >> processesNamed: aString [
	"Terminated or not, as long as something still holds them."

	^ Process allInstances select: [ :each | each name = aString ]
]

{ #category : 'private' }
MCPToolEvaluateTest >> stopLimitSeconds [
	"The time limit of an evaluation a test lets stop, counted from when its code runs: the command takes a fraction of a second, which the tool's schema does not, so these tests wait a tenth of what a whole second would cost."

	^ 0.1
]

{ #category : 'private' }
MCPToolEvaluateTest >> stoppedEarlyResultOf: aString bounds: aBlock [
	"The answer to an evaluation of aString with a limit of 30 s, by a command whose bounds aBlock sets. What the call deferred runs once it has answered, as the server runs it after the response."

	| actions command result tool |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommandStoppingEarly code: aString timeLimit: 30 previewLimit: tool resultPreviewCharacterLimit.
	aBlock value: command.
	actions := OrderedCollection new.
	result := MCPPostResponseActions value: actions during: [ tool answerFor: command execute ].
	actions do: #value.
	^ result
]

{ #category : 'private' }
MCPToolEvaluateTest >> stoppedTextOf: aResult [
	"The text of an evaluation's answer that must be a stop at the tests' limit, which its error code says too."

	| text |
	self assert: aResult isError.
	self assert: ((aResult structuredContent at: #error) at: #errorCode) equals: 'EvaluationTimedOut'.
	text := aResult content first text.
	self assert: (text lines first: 2) equals: {
			('Evaluation stopped after ' , self stopLimitSeconds printString , ' s, its time limit.').
			'What it changed before then stays changed.' }.
	^ text
]

{ #category : 'private' }
MCPToolEvaluateTest >> stoppedTextUnwindingBrieflyOf: aString deferringInto: actions [
	"The text of an evaluation of aString that must be stopped at the tests' limit, by a command that waits less than the command's bound for the stopped code to unwind, leaving in actions what the call deferred until after its response. A test whose stopped code unwinds slowly waits that shorter bound in full."

	| command tool |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommandUnwindingBriefly
		           code: aString
		           timeLimit: self stopLimitSeconds
		           previewLimit: tool resultPreviewCharacterLimit.
	^ self stoppedTextOf: (MCPPostResponseActions value: actions during: [ tool answerFor: command execute ])
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateAnsweringTheSilentTranscriptNamesIt [

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'Transcript') } asDictionary.
	self assert: ((result at: #content) first at: #text) equals: 'Transcript'.
	self deny: ((self dataFrom: result) includesKey: #transcript)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateAnswersBeforeASlowUnwindEnds [
	"An ensure block may take as long as it likes. The answer waits for it only so long, says it was still running, and puts the Transcript back itself."

	| actions milliseconds text transcript |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	transcript := self class environment at: #Transcript.
	actions := OrderedCollection new.
	[
		milliseconds := Time millisecondsToRun: [
				                text := self
					                        stoppedTextUnwindingBrieflyOf:
					                        '[ [ true ] whileTrue ] ensure: [ MCPEvaluateTestProbe holdUntilReleased ]'
					                        deferringInto: actions ].
		self assert: (self class environment at: #Transcript) identicalTo: transcript ] ensure: [
			actions do: #value.
			MCPEvaluateTestProbe release.
			MCPEvaluateTestProbe holder ifNotNil: [ :holder | self waitUntilEnded: holder ] ].
	self assert: (text lines at: 3) equals: 'Its ensure blocks were still running when this answer was sent.'.
	self assert: milliseconds < 15000
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateAnswersThePrintStringAsItsWholeText [
	"The envelope around a one-line answer cost more than the answer."

	| data result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> '3 + 4') } asDictionary.
	data := self dataFrom: result.
	self assert: (self textFrom: result) equals: '7'.
	self assert: (data at: #resultClassName) equals: 'SmallInteger'.
	self assert: (data at: #resultPrintString) equals: '7'.
	self assertEmpty: (self warningsFrom: result)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateAnswersTranscriptContentsWithWhatItWrote [

	| result |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Transcript show: ''written''. Transcript contents') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((self dataFrom: result) at: #resultPrintString) equals: '''written'''
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateAnswersWhenAFailingCodesEnsureBlockEndsItsProcess [
	"A failure is answered once the code's process has unwound, so an ensure block that ends that process leaves no value and no failure to answer."

	| result |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> '[ 1/0 ] ensure: [ Processor activeProcess terminate ]') } asDictionary.
	self assert: (self resultIndicatesError: result).
	self
		assert: (self textFrom: result)
		equals: 'Evaluation ended the process running it, so it has no value to answer.'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateAnswersWhenTheCodeEndsItsOwnProcess [
	"The process that ends is the one the code runs in, not the one that answers."

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'Processor activeProcess terminate') } asDictionary.
	self assert: (self resultIndicatesError: result).
	self assert: (self textFrom: result) equals: 'Evaluation ended the process running it, so it has no value to answer.'.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'EvaluationEndedItsProcess'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateAnswersWhileAForkHoldsItsPriority [
	"A fork computing at the evaluator's priority may keep the process that terminates the evaluator from ever running, so the answer waits for the termination only so long. The test then waits for its own stopping process, which ends only once the evaluator has."

	self timeLimit: 30 seconds.
	self underEitherPreemptionRuleDo: [ :yields |
			| actions before milliseconds |
			before := self liveProcessesNamed: 'evaluate stop'.
			actions := OrderedCollection new.
			[
				milliseconds := Time millisecondsToRun: [
						                self
							                stoppedTextUnwindingBrieflyOf:
							                '[ [ true ] whileTrue ] forkAt: Processor activePriority named: ''mcp-evaluate-hog-probe''. [ true ] whileTrue'
							                deferringInto: actions ] ] ensure: [
					actions do: #value.
					(self liveProcessesNamed: 'mcp-evaluate-hog-probe') do: [ :each | each terminate ] ].
			((self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before) do: [ :each | self waitUntilEnded: each ].
			self assert: milliseconds < 15000 ]
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateCancelsALoadOverUnsavedChanges [
	"Monticello asks a person before it loads over the image's unsaved changes, and a call has none: Pharo 14 opened its dialog in a headless image, and the call waited out its time limit. The load is cancelled, which the warning answers nil for, and the warning says so rather than what loading would lose."

	| data result |
	result := self callToolNamed: 'evaluate' withArguments: {
			          (#code -> 'MCMergeOrLoadWarning signalFor: { (MCPackage named: ''MCP-Tests-RunResources'') workingCopy }').
			          (#timeoutSeconds -> 10) } asDictionary.
	self deny: (result includesKey: #isError).
	data := self dataFrom: result.
	self assert: (data at: #resultPrintString) equals: 'nil'.
	self
		assert: (self warningsFrom: result) asArray
		equals:
		{ 'MCMergeOrLoadWarning: Cancelled a load that would lose the image''s unsaved changes to MCP-Tests-RunResources. To load over them, handle MCMergeOrLoadWarning with load.' }
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateCatchesHaltAsRuntimeFailure [

	| result text |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Halt signal: ''mcp halt test''') } asDictionary.
	text := self textFrom: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during execution').
	self assert: (text includesSubstring: 'Halt').
	self assert: (text includesSubstring: 'mcp halt test')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateCodesAnAssignmentToAnArgumentAsMethodCompileDoes [
	"A compile notice carries the code method_compile gives the same notice, so a failure is counted alike whichever tool met it. Before Pharo 13 the notice an evaluation gets holds no tree to find the read-only variable in, and Pharo 10 only warns of the assignment."

	| result |
	(self class environment includesKey: #OCNotice) ifFalse: [
		^ self skip: 'Before Pharo 13, an evaluation''s notice holds no tree to find a read-only variable in.' ].
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> '[ :each | each := 1 ] value: 2') } asDictionary.
	self assert: (result at: #isError).
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'CompileReadOnlyAssignment'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateDeclaresAnUndeclaredNameAsAPlaygroundDoes [

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'total := 3 + 4. total * 2') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((self dataFrom: result) at: #resultPrintString) equals: '14'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateEndingOnTheTranscriptAnswersWhatItWrote [
	"A cascade of show: answers the recorder that stood in for the Transcript. What it wrote is the answer; the recorder is nobody's business, and a value line reading Transcript would say nothing more."

	| contentText data result truncatedText |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Transcript show: ''Balance: 120''; cr; show: ''Largest Deposit: 100''') } asDictionary.
	contentText := (result at: #content) first at: #text.
	data := self dataFrom: result.
	self assert: contentText equals: (String lf join: #( 'Transcript:' 'Balance: 120' 'Largest Deposit: 100' )).
	self deny: (contentText includesSubstring: 'MCPTranscriptRecorder').
	self assert: (data at: #resultPrintString) equals: 'Transcript'.
	self assert: (data at: #resultClassName) equals: (self class environment at: #Transcript) class name asString.
	self assert: (data at: #answeredTranscript).
	truncatedText := MCPToolEvaluate new resultTextFor: (Dictionary new
			                  at: #resultPrintString put: 'Transcript';
			                  at: #answeredTranscript put: true;
			                  at: #transcript put: 'Balance';
			                  at: #transcriptTruncated put: true;
			                  yourself).
	self assert: truncatedText equals: (String lf join: #( 'Transcript:' 'Balance' '[transcript truncated]' ))
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateFailureTextNamesSuggestionsAndFrames [

	| lines text |
	text := self textFrom: (self
			         callToolNamed: 'evaluate'
			         withArguments: { (#code -> 'OrderedCollection new adAll: #( 1 2 3 )') } asDictionary).
	lines := text lines.
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'Did you mean: addAll:' ]).
	self assert: (lines reject: [ :each | each beginsWith: '   ' ]) last equals: 'UndefinedObject>>DoIt'.
	self deny: (text includesSubstring: '"errorClass"')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateForgetsItsVariablesAfterTheCall [

	| result |
	self callToolNamed: 'evaluate' withArguments: { (#code -> 'leftover := 5') } asDictionary.
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'leftover') } asDictionary.
	self compilerReadsUndeclaredNamesAsNil ifTrue: [ ^ self assert: ((self dataFrom: result) at: #resultPrintString) equals: 'nil' ].
	self assert: (result at: #isError).
	self assert: ((self errorFrom: result) at: #sourceLine) equals: 'leftover'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateIsMarkedAsAdvancedEscapeHatch [

	| description |
	self assert: (MCPToolEvaluate new asJRPCJSON at: #name) equals: 'evaluate'.
	description := MCPToolEvaluate new description.
	self assert: (description includesSubstring: 'escape hatch').
	self assert: (description includesSubstring: 'arbitrary Smalltalk code')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateLeavesACapitalizedNameUndeclared [

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'MCPNoSuchGlobalForThisTest new') } asDictionary.
	self assert: (result at: #isError).
	self compilerReadsUndeclaredNamesAsNil ifTrue: [ ^ self ].
	self assert: ((self errorFrom: result) at: #sourceLine) equals: 'MCPNoSuchGlobalForThisTest new'.
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'CompileUndeclaredVariable'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateLeavesANameNeverAssignedUndeclared [
	"A Playground would read it as nil. A name only read is far more often a typo or a missing selector, and the compile error points at it."

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'neverAssigned isNil') } asDictionary.
	self compilerReadsUndeclaredNamesAsNil ifTrue: [ ^ self deny: (result at: #isError ifAbsent: [ false ]) ].
	self assert: (result at: #isError).
	self assert: ((self errorFrom: result) at: #sourceLine) equals: 'neverAssigned isNil'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateLeavesTheProcessesItForkedRunning [
	"Forking is how longer work runs, so a stop leaves alone what the code forked."

	self timeLimit: 30 seconds.
	[
		self stoppedTextOf: (self evaluateBriefly:
				 '[ (Delay forSeconds: 30) wait ] forkAt: Processor userBackgroundPriority named: ''mcp-evaluate-fork-probe''. [ true ] whileTrue').
		self denyEmpty: (self liveProcessesNamed: 'mcp-evaluate-fork-probe') ] ensure: [
		(self liveProcessesNamed: 'mcp-evaluate-fork-probe') do: [ :each | each terminate ] ]
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateLetsASaveFinish [
	"Stopped between the snapshot and the restart of the listener that follows it, a save would leave the image without its listener. Neither process is resumed, so nothing is saved."

	| command other saving |
	command := MCPEvaluateCommand code: 'Smalltalk saveSession' timeLimit: 1 previewLimit: 100.
	saving := Process
		          forContext: (Context
				           sender: nil
				           receiver: SessionManager default
				           method: SessionManager >> #snapshot:andQuit:
				           arguments: #( true false ))
		          priority: Processor userBackgroundPriority.
	other := Process
		         forContext: (Context
				          sender: nil
				          receiver: SessionManager default
				          method: SessionManager >> #currentSession
				          arguments: #(  ))
		         priority: Processor userBackgroundPriority.
	self assert: (command isSaving: saving).
	self deny: (command isSaving: other)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateLetsNotificationsUseTheirDefaultAction [

	| data result |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'MCPToolDefaultActionNotification signal') } asDictionary.
	data := self dataFrom: result.
	self deny: (result includesKey: #isError).
	self assert: (data at: #resultClassName) equals: 'ByteSymbol'.
	self assert: (data at: #resultPrintString) equals: '#mcpDefaultAction'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateLooksAtTheMemoryOnlyOnceTheCodeHasStarted [
	"Before the code has started, whatever grows the image is not the code, so only the time limit stops it. A bound below any growth stands for one the image passed. Code that has ended is never stopped."

	| command tool unstarted |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommandStoppingEarly code: '3 + 4' timeLimit: self unstartedLimitSeconds previewLimit: 100.
	command memoryGrowthLimit: -1024 * 1024 * 1024.
	unstarted := [ 3 + 4 ] newProcess.
	self
		assert: (tool stopSummaryFor: (command watch: unstarted until: Semaphore new started: [ false ]) of: command)
		equals: 'Evaluation stopped after ' , self unstartedLimitSeconds printString , ' s, its time limit.'.
	self assert: ((tool stopSummaryFor: (command watch: unstarted until: Semaphore new started: [ true ]) of: command) beginsWith:
			 'Evaluation stopped: the image''s memory grew by more than ').
	self assert: (command
			 watch: unstarted
			 until: (Semaphore new
					  signal;
					  yourself)
			 started: [ true ]) isNil
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateNamesAFailureSignalledWithoutAText [
	"An error signalled without a text is named by its description, so the answer still says what failed after its colon."

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'Error new signal') } asDictionary.
	self assert: (self textFrom: result) lines first equals: 'Evaluation failed during execution (Error): Error'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateNamesAFrameOnOneLineByItsClassAndMethod [
	"Every Pharo names a frame so; before 14, Pharo printed a block's frame with the block's source, over as many lines as it has."

	| tool |
	tool := MCPToolEvaluate new.
	self assert: (tool frameNameFor: thisContext) equals: 'MCPToolEvaluateTest>>testEvaluateNamesAFrameOnOneLineByItsClassAndMethod'.
	self
		assert: [ tool frameNameFor: thisContext ] value
		equals: '[ ] in MCPToolEvaluateTest>>testEvaluateNamesAFrameOnOneLineByItsClassAndMethod'.
	self
		assert: (tool frameNameFor: (Context
					  sender: nil
					  receiver: 3
					  method: Object >> #printString
					  arguments: #(  )))
		equals: 'SmallInteger(Object)>>printString'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateNamesAnUndeclaredVariable [
	"Pharo 13's notice says only Undeclared variable, and Pharo 14's names it in the DoIt the code was compiled as, so MCP names it itself."

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'MCPNoSuchGlobalForThisTest new') } asDictionary.
	self assert: (result at: #isError).
	self compilerReadsUndeclaredNamesAsNil ifTrue: [ ^ self ].
	self assert: ((self summaryFrom: result) endsWith: '): Undeclared variable: MCPNoSuchGlobalForThisTest Line 1')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateNotStartedTextTellsAnEvaluationFromAFork [
	"A process named after the tool is an earlier evaluation, which ends at its own limit; any other at the priority evaluations run at was forked by one, and has no limit."

	| evaluation fork lines summary |
	evaluation := [ 1 ] newProcess
		              name: 'evaluate';
		              yourself.
	fork := [ 2 ] newProcess
		        name: 'mcp-fork-probe';
		        yourself.
	summary := 'Evaluation did not start within 1 s, its time limit; none of it ran.'.
	lines := (self notStartedTextHeldBy: {
			          evaluation.
			          fork }) lines.
	self assert: (lines first: 2) equals: {
			summary.
			'Holding the priority evaluations run at:' }.
	self assert: ((lines at: 3) beginsWith: 'an earlier evaluation, in ').
	self assert: ((lines at: 4) beginsWith: 'a process an evaluation forked, named mcp-fork-probe, in ').
	self assert: (lines allButFirst: 4) equals: #( 'An earlier evaluation stops at its own time limit; call again after it.'
		   'A fork has no time limit; while it computes, evaluations may not start.'
		   'If it never ends, only an image restart ends it, losing what was not saved.'
		   'Fork long work at Processor userBackgroundPriority, below evaluations.' ).
	lines := (self notStartedTextHeldBy: { evaluation }) lines.
	self assert: lines size equals: 4.
	self assert: (lines at: 3) equals: 'an earlier evaluation, in ' , (MCPToolEvaluate new frameNameFor: evaluation suspendedContext).
	self assert: lines last equals: 'An earlier evaluation stops at its own time limit; call again after it.'.
	self assert: (self notStartedTextHeldBy: #(  )) lines equals: {
			summary.
			'No other process holds the priority evaluations run at,'.
			'so code at a higher priority, such as another call, kept the processor.' }
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateOmitsTruncationFieldsForSmallResults [

	| data |
	data := self dataFrom:
		        (self callToolNamed: 'evaluate' withArguments: { (#code -> '#( 1 2 3 )') } asDictionary).
	self deny: (data includesKey: #truncated).
	self deny: (data includesKey: #resultSize)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluatePrintsAValueWhosePrintingSignalsANotificationTheBoundaryRefuses [
	"Printing the value runs the caller's code too, so a notification the boundary refuses to resume gets its default action there, as it does in the code itself."

	| data result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'MCPToolNotifyingPrintTarget new') } asDictionary.
	data := self dataFrom: result.
	self deny: (result includesKey: #isError).
	self assert: (data at: #resultPrintString) equals: 'printed after #mcpDefaultAction'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluatePutsTheTranscriptBackAfterAFailure [

	| previous result |
	previous := self class environment at: #Transcript.
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Transcript show: ''before''. Error signal: ''boom''') } asDictionary.
	self assert: (result at: #isError).
	self assert: (self class environment at: #Transcript) identicalTo: previous.
	self assert: ((self errorFrom: result) at: #transcript) equals: 'before'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateQueuesPostResponseActionsOfTheCall [
	"The code runs in a process of its own, and what it defers must still wait for the response of the call that ran it."

	| actions result |
	actions := OrderedCollection new.
	result := MCPPostResponseActions value: actions during: [
			          self
				          callToolNamed: 'evaluate'
				          withArguments: { (#code -> 'MCPPostResponseActions value add: [ 1 ]. #queued') } asDictionary ].
	self assert: (self textFrom: result) equals: '#queued'.
	self assert: actions size equals: 1
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateReportsADeprecationBesideTheValue [
	"A deprecation says the answer is not what the caller thinks, and the answer arrives all the same, so it has to arrive with it. The same deprecation raised twice is reported once."

	| className contentText result warnings |
	className := 'MCPEvaluateDeprecationFixture'.
	self
		createClassNamed: className
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	[
		self
			ensureMethodSource: 'answer

	self deprecated: ''Use #betterAnswer instead.''.
	^ 42'
			protocol: 'tests'
			on: (self classNamed: className).
		result := self
			          callToolNamed: 'evaluate'
			          withArguments:
			          { (#code -> '| fixture | fixture := MCPEvaluateDeprecationFixture new. fixture answer + fixture answer') }
				          asDictionary.
		warnings := self warningsFrom: result.
		contentText := (result at: #content) first at: #text.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: ((self dataFrom: result) at: #resultPrintString) equals: '84'.
		self assert: warnings size equals: 1.
		self assert: (warnings first beginsWith: 'Deprecation: ').
		self assert: (warnings first includesSubstring: className , '>>#answer').
		self assert: (warnings first includesSubstring: 'Use #betterAnswer instead.').
		self assert: (contentText includesSubstring: warnings first).
		self assert: (contentText beginsWith: '84') ] ensure: [ self removeClassNamed: className ]
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateReportsAPlainWarningBesideTheValue [
	"Warning>>defaultAction treats an unhandled warning as an error, so a call over code that only warned used to fail before its value arrived."

	| contentText result warnings |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'Warning signal: ''take care''. 42') } asDictionary.
	warnings := self warningsFrom: result.
	contentText := (result at: #content) first at: #text.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((self dataFrom: result) at: #resultPrintString) equals: '42'.
	self assert: warnings asArray equals: #( 'Warning: take care' ).
	self assert: (contentText beginsWith: '42')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateReportsTheFailingSourceLine [
	"A character offset makes a caller count through its own source to find the mistake."

	| error result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> '| s |
s := WriteStream on: String new.
s << cr.
s contents') } asDictionary.
	self compilerReadsUndeclaredNamesAsNil ifTrue: [ ^ self assert: (result at: #isError) ].
	error := self errorFrom: result.
	self assert: (error at: #line) equals: 3.
	self assert: (error at: #sourceLine) equals: 's << cr.'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateReportsTruncationAndCollectionSize [
	"A cut preview used to end in a marker and nothing else, so the caller could not tell whether two or two hundred kilobytes were missing."

	| data |
	data := self dataFrom:
		        (self
			         callToolNamed: 'evaluate'
			         withArguments: { (#code -> '(1 to: 40000) asOrderedCollection') } asDictionary).
	self assert: (data at: #truncated).
	self assert: (data at: #resultSize) equals: 40000.
	self
		assert: (data at: #resultPrintString) size
		equals: ((1 to: 40000) asOrderedCollection printStringLimitedTo: MCPToolEvaluate new resultPreviewCharacterLimit) size
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateRequiresCodeInSchema [

	self assert: (MCPToolEvaluate new inputSchema required includes: 'code')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateResumesNotificationsSignaledByADefaultAction [
	"A default action may signal a notification of its own, and a handler is suspended while its block runs: Deprecation>>defaultAction logs, logging signals DeprecationPerformedNotification, and that second notification used to escape and fail the call."

	| data result |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'MCPToolNestedNotification signal') } asDictionary.
	data := self dataFrom: result.
	self deny: (result includesKey: #isError).
	self assert: (data at: #resultPrintString) equals: '''nested-mcpDefaultAction'''
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateReturnsCompilationFailureInformation [

	| error result text |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> '1 +') } asDictionary.
	text := self textFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during compilation').
	self assert: (text includesSubstring: self expectedSyntaxErrorNoticeClassName).
	self assert: (text includesSubstring: 'Line 1').
	self assert: (error at: #errorClass) equals: self expectedSyntaxErrorNoticeClassName.
	self assert: (error at: #errorCode) equals: 'CompileSyntaxError'.
	self assert: ((error at: #message) includesSubstring: 'expected')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateReturnsRuntimeFailureInformation [

	| error result stackTrace text |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'Error signal: ''boom''') } asDictionary.
	text := self textFrom: result.
	error := self errorFrom: result.
	stackTrace := error at: #stackTrace.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during execution').
	self assert: (text includesSubstring: 'boom').
	self assert: ((text lines reject: [ :each | each beginsWith: '   ' ]) last includesSubstring: 'UndefinedObject>>DoIt').
	self assert: (error at: #errorClass) equals: 'Error'.
	self assert: (error at: #errorCode) equals: 'EvaluationRuntimeError'.
	self assert: ((error at: #message) includesSubstring: 'boom').
	self assert: (error includesKey: #signalerContext).
	self assert: stackTrace class equals: Array.
	self deny: stackTrace isEmpty.
	self assert: (stackTrace first beginsWith: (error at: #signalerContext))
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateReturnsWhatItWroteToTheTranscript [

	| contentText result |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Transcript show: ''one''; cr; show: 2. 42') } asDictionary.
	contentText := (result at: #content) first at: #text.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((self dataFrom: result) at: #resultPrintString) equals: '42'.
	self assert: ((self dataFrom: result) at: #transcript) equals: (String streamContents: [ :stream |
				 stream
					 nextPutAll: 'one';
					 nextPut: Character lf;
					 nextPutAll: '2' ]).
	self assert: (contentText beginsWith: '42').
	self assert: (contentText includesSubstring: 'Transcript:')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateRunsJustBelowTheCallingProcess [
	"Only a process above the code can take the processor back from code that computes, so the code runs one priority below the call."

	self
		assert: (self textFrom:
				 (self callToolNamed: 'evaluate' withArguments: { (#code -> 'Processor activePriority') } asDictionary))
		equals: (Processor activePriority - 1) printString
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateSaysWhenPrintingTheValueFailed [
	"The code ran and answered a value; what failed is printing it, in its class's own printOn:. The answer says so rather than reading as a failure of the code."

	| error fixture result |
	fixture := self
		           createClassNamed: 'UnprintableFixture'
		           superclassName: 'Object'
		           slots: #(  )
		           classSlots: #(  ).
	result := [
		          self
			          ensureMethodSource: 'printOn: aStream
	aStream nextPutAll: ''half''.
	1 / 0'
			          protocol: 'printing'
			          on: fixture.
		          self callToolNamed: 'evaluate' withArguments: { (#code -> 'UnprintableFixture new') } asDictionary ] ensure: [
		          self removeClassNamed: 'UnprintableFixture' ].
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: ((self summaryFrom: result) beginsWith: 'Evaluation ran, but printing its value failed (ZeroDivide): ').
	self assert: (error at: #errorClass) equals: 'ZeroDivide'.
	self assert: (error at: #errorCode) equals: 'EvaluationPrintFailed'.
	self assert: ((error at: #stackTrace) anySatisfy: [ :each | each beginsWith: 'UnprintableFixture>>printOn:' ])
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStackAndMemoryStopsSayWhy [
	"Each early stop names what the code passed and how far, and the stack's names what runs that deep."

	| command tool |
	tool := MCPToolEvaluate new.
	command := MCPEvaluateCommand code: '3 + 4' timeLimit: 30 previewLimit: 100.
	self
		assert: (tool stackStoppedMessageFor: command stackDepthLimit)
		equals: 'Evaluation stopped: its stack passed 1000000 frames, which an endless recursion does.'.
	self
		assert: (tool memoryStoppedMessageFor: command memoryGrowthLimit)
		equals: 'Evaluation stopped: the image''s memory grew by more than 4 GB while it ran.'.
	self
		assert: (tool memoryStoppedMessageFor: 16 * 1024 * 1024)
		equals: 'Evaluation stopped: the image''s memory grew by more than 16 MB while it ran.'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStackTraceStopsAtTheEvaluatedCode [
	"Below the outermost doIt every frame is compiler and dispatch scaffolding, identical on every failure."

	| error stackTrace |
	error := self errorFrom:
		         (self callToolNamed: 'evaluate' withArguments: { (#code -> '#( 1 2 3 ) do: [ :each | each frobnicate ]') } asDictionary).
	stackTrace := error at: #stackTrace.
	self assert: stackTrace last equals: 'UndefinedObject>>DoIt'.
	self deny: (stackTrace anySatisfy: [ :each | each includesSubstring: 'MCP' ]).
	self deny: (stackTrace anySatisfy: [ :each | each includesSubstring: 'OpalCompiler' ])
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopCollapsesARecursion [
	"A recursion fills every frame kept with one name. The fixture's name must not begin with MCP, whose frames are cut as the server's own, and it waits rather than computes, so the test grows no memory."

	| fixture result |
	self timeLimit: 30 seconds.
	fixture := self
		           createClassNamed: 'StopRecursionFixture'
		           superclassName: 'Object'
		           slots: #(  )
		           classSlots: #(  ).
	result := [
		          self
			          ensureMethodSource: 'descend: n
	n = 0 ifTrue: [ ^ (Delay forSeconds: 60) wait ].
	^ self descend: n - 1'
			          protocol: 'fixture'
			          on: fixture.
		          self evaluateBriefly: 'StopRecursionFixture new descend: 100' ] ensure: [
		          self removeClassNamed: 'StopRecursionFixture' ].
	self assert: ((self stoppedTextOf: result) lines anySatisfy: [ :each |
			 (each beginsWith: 'StopRecursionFixture>>descend:, at least ') and: [ each endsWith: ' times in a row' ] ])
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopCollectsGarbageAfterTheAnswer [
	"What a stopped evaluation grew is garbage once it ends. A full collection of a large heap takes seconds, so the process that stopped it collects only once the answer has gone out, which the call's post-response action tells it, and until then it waits."

	| actions before helpers |
	self timeLimit: 30 seconds.
	before := self liveProcessesNamed: 'evaluate stop'.
	actions := OrderedCollection new.
	self evaluateBriefly: '[ true ] whileTrue' deferringInto: actions.
	helpers := (self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before.
	[
		self assert: actions size equals: 1.
		self assert: helpers size equals: 1.
		(Delay forMilliseconds: 20) wait.
		self deny: helpers first isTerminated ] ensure: [ actions do: #value ].
	self waitUntilEnded: helpers first.
	self assert: helpers first isTerminated
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopCollectsGarbageOnceTheCodeHasUnwound [
	"The answer may go out while the stopped code still unwinds, and what it grew stays reachable until it has, so the collection waits for the unwinding as well as for the answer."

	| actions before helpers collections |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	before := self liveProcessesNamed: 'evaluate stop'.
	actions := OrderedCollection new.
	[
		self
			stoppedTextUnwindingBrieflyOf: '[ [ true ] whileTrue ] ensure: [ MCPEvaluateTestProbe holdUntilReleased ]'
			deferringInto: actions.
		collections := self fullGarbageCollections.
		actions do: #value.
		self assert: self fullGarbageCollections equals: collections.
		helpers := (self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before.
		self assert: helpers size equals: 1 ] ensure: [
			MCPEvaluateTestProbe release.
			MCPEvaluateTestProbe holder ifNotNil: [ :holder | self waitUntilEnded: holder ] ].
	self waitUntilEnded: helpers first.
	self assert: helpers first isTerminated.
	self assert: self fullGarbageCollections > collections
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopCollectsGarbageWhenTheAnswerNeverGoesOut [
	"A client that gave up leaves the answer unwritten, and what the call deferred unrun. The process that stopped the code waits for the answer only as long as the answer waits for the unwinding, then collects anyway, rather than keep itself and the garbage forever."

	| actions before collections helpers |
	self timeLimit: 30 seconds.
	before := self liveProcessesNamed: 'evaluate stop'.
	collections := self fullGarbageCollections.
	actions := OrderedCollection new.
	self stoppedTextUnwindingBrieflyOf: '[ true ] whileTrue' deferringInto: actions.
	helpers := (self liveProcessesNamed: 'evaluate stop') copyWithoutAll: before.
	self assert: helpers size equals: 1.
	self waitUntilEnded: helpers first.
	self assert: helpers first isTerminated.
	self assert: self fullGarbageCollections > collections
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStoppedAnswersItsTranscript [
	"What the code wrote before it was stopped may be all that says how far it got. It comes last, after the recipe, as in every other answer, and the Transcript is put back."

	| previous result |
	self timeLimit: 30 seconds.
	previous := self class environment at: #Transcript.
	result := self evaluateBriefly: 'Transcript show: ''started''. [ true ] whileTrue'.
	self assert: (self class environment at: #Transcript) identicalTo: previous.
	self
		assert: ((self stoppedTextOf: result) lines last: 3)
		equals: #( 'A fork has no time limit, and at this priority it holds up no evaluation.'
			   'Transcript:' 'started' ).
	self assert: ((result structuredContent at: #error) at: #transcript) equals: 'started'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStoppedAnswersTheTranscriptAsItWasAtTheStop [
	"Once the call has stopped the code, what its unwinding writes or raises does not reach the answer."

	| result |
	self timeLimit: 30 seconds.
	result := self evaluateBriefly:
		          '[ Transcript show: ''before''. (Delay forSeconds: 10) wait ] ensure: [ Transcript show: ''cleanup''. 1/0 ]'.
	self stoppedTextOf: result.
	self assert: ((result structuredContent at: #error) at: #transcript) equals: 'before'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStoppedFramesCollapseARecursion [
	"A run of equal frame names is one line with its count, and the run that reaches the last frame kept, when the stack goes deeper, counts at least that many."

	| lines tool |
	tool := MCPToolEvaluate new.
	lines := tool collapsedFrameLines: (Array new: 20 withAll: 'StopRecursionFixture>>descend:') deeper: true.
	self assert: lines equals: #( 'StopRecursionFixture>>descend:, at least 20 times in a row' ).
	self assert: (tool collapsedFrameLines: #( 'a' 'b' 'b' 'c' 'b' ) deeper: false) equals: #( 'a' 'b, 2 times in a row'
	   'c' 'b' ).
	self assert: (tool collapsedFrameLines: #( 'a' 'b' ) deeper: true) equals: #( 'a' 'b' )
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStoppedTextNamesTheLimitAndTheWayToRunLongerWork [
	"The answer names the limit the code reached, where it was, and the one way it recommends to run longer work. It does not offer to raise the limit: through a client that waits less, a raised limit loses the answer while the code goes on."

	| text tool |
	tool := MCPToolEvaluate new.
	text := tool contentTextForStructuredContent: (Dictionary new
			         at: #summary put: (tool stoppedMessageFor: 30);
			         at: #error put: (Dictionary new
					          at: #stoppedIn put: (tool collapsedFrameLines: (Array new: 20 withAll: 'ZooKeeper>>animals') deeper: true);
					          at: #hint put: tool longerWorkHintLines;
					          at: #timeoutSeconds put: 30;
					          yourself);
			         yourself).
	self assert: text equals: (String lf join: 'Evaluation stopped after 30 s, its time limit.
What it changed before then stays changed.
Stopped in:
ZooKeeper>>animals, at least 20 times in a row
Run longer work in a forked process that writes its result to a file:
[ | file result |
	file := FileLocator imageDirectory / ''result.txt''.
	file ensureDelete.
	result := [ "the work" ] on: Error do: [ :error | error description ].
	file writeStreamDo: [ :out | out print: result ] ]
		forkAt: Processor userBackgroundPriority
		named: ''result''
The file appears when the work ends; read it in a later call.
A fork has no time limit, and at this priority it holds up no evaluation.' lines).
	self deny: (text includesSubstring: 'timeoutSeconds')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsAComputingLoopUnderEitherPreemptionRule [
	"A loop that computes never yields, so only a process above it can take the processor back, whichever way the virtual machine requeues the process it preempts. The process that terminates the loop runs at the loop's priority, so the loop is taken off the run queue first, and has unwound under either rule by the time the answer goes."

	self timeLimit: 30 seconds.
	self underEitherPreemptionRuleDo: [ :yields |
			| actions before evaluators lines milliseconds result rule |
			rule := 'With processPreemptionYields ' , yields printString.
			before := self processesNamed: 'evaluate'.
			actions := OrderedCollection new.
			[
				milliseconds := Time millisecondsToRun: [ result := self evaluateBriefly: '[ true ] whileTrue' deferringInto: actions ].
				evaluators := (self processesNamed: 'evaluate') copyWithoutAll: before ] ensure: [ actions do: #value ].
			lines := (self stoppedTextOf: result) lines.
			self deny: (lines includes: 'Its ensure blocks were still running when this answer was sent.') description: rule.
			self assert: (lines includes: 'Stopped in:').
			self assert: (lines includes: 'UndefinedObject>>DoIt').
			self assert: evaluators size equals: 1.
			self waitUntilEnded: evaluators first.
			self assert: evaluators first isTerminated description: rule.
			self assert: milliseconds < 10000 ]
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsAFailureWhoseEnsureBlockOutlastsTheLimit [
	"A failure is answered only once its ensure blocks have run, so one that waits past the limit is stopped there, like any other code."

	| result |
	self timeLimit: 30 seconds.
	result := self evaluateBriefly: '[ 1/0 ] ensure: [ (Delay forMilliseconds: 500) wait ]'.
	self assert: ((self stoppedTextOf: result) includesSubstring: 'Stopped in:')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsARecursionPastItsStackBound [
	"An endless recursion grows the image by GBs within its time limit, so the stack is looked at while the code runs, and the code is stopped once it passes a bound, long before the limit. The fixture waits at the bottom of a recursion just past a low bound, so the test grows no memory."

	| fixture lines milliseconds result |
	self timeLimit: 30 seconds.
	fixture := self
		           createClassNamed: 'StopRecursionFixture'
		           superclassName: 'Object'
		           slots: #(  )
		           classSlots: #(  ).
	[
		self
			ensureMethodSource: 'descend: n
	n = 0 ifTrue: [ ^ (Delay forSeconds: 60) wait ].
	^ self descend: n - 1'
			protocol: 'fixture'
			on: fixture.
		milliseconds := Time millisecondsToRun: [
			                result := self
				                          stoppedEarlyResultOf: 'StopRecursionFixture new descend: 2000'
				                          bounds: [ :command | command stackDepthLimit: 1000 ] ] ] ensure: [
		self removeClassNamed: 'StopRecursionFixture' ].
	self assert: result isError.
	lines := (self textOfEvaluateResult: result) lines.
	self assert: (lines first: 2) equals: #( 'Evaluation stopped: its stack passed 1000 frames, which an endless recursion does.'
		   'What it changed before then stays changed.' ).
	self assert: (lines anySatisfy: [ :each | each beginsWith: 'StopRecursionFixture>>descend:, at least ' ]).
	self assert: ((result structuredContent at: #error) at: #errorCode) equals: 'EvaluationStackTooDeep'.
	self assert: milliseconds < 10000
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsAWaitAndRunsItsEnsureBlocks [
	"A stop unwinds the code as any termination does: its ensure blocks run, and the Transcript it was recording is put back."

	| result transcript |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	transcript := self class environment at: #Transcript.
	result := self evaluateBriefly: '[ (Delay forSeconds: 60) wait ] ensure: [ MCPEvaluateTestProbe noteEnsureRan ]'.
	self deny: ((self stoppedTextOf: result) includesSubstring: 'still running').
	self assert: MCPEvaluateTestProbe ensureRan.
	self assert: (self class environment at: #Transcript) identicalTo: transcript
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsAWaitInACriticalSectionWithoutSignallingIt [
	"Terminated while it waits to enter a critical section, a process leaves without signalling the semaphore, which it never acquired, but only when terminated from where it waits: suspended first, it would signal on its way out and let a second process in. So a stop leaves a waiting evaluator waiting."

	| holder mutex |
	self timeLimit: 30 seconds.
	MCPEvaluateTestProbe reset.
	mutex := MCPEvaluateTestProbe mutex.
	holder := [ mutex critical: [ MCPEvaluateTestProbe holdUntilReleased ] ]
		          forkAt: Processor activePriority + 1
		          named: 'mcp-evaluate-mutex-holder-probe'.
	[
		self deny:
			((self stoppedTextOf: (self evaluateBriefly: 'MCPEvaluateTestProbe mutex critical: [ #entered ]')) includesSubstring:
				 'still running').
		self deny: mutex isSignaled description: 'The stopped evaluation signalled a semaphore it never acquired.' ] ensure: [
			MCPEvaluateTestProbe release.
			self waitUntilEnded: holder ].
	self assert: holder isTerminated.
	self assert: mutex isSignaled.
	mutex wait.
	self deny: mutex isSignaled description: 'The semaphore admits a second process.'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsAnEndlessRecursionWithinASecondOrTwo [
	"An eval run's recursion grew the image by more than a GB a second until its time limit, and stopping a stack that deep took longer than the limit. Its stack passes the bound within a fraction of a second, so it is stopped long before the limit, having grown the image by a few hundred MB."

	| fixture milliseconds result |
	self timeLimit: 30 seconds.
	fixture := self
		           createClassNamed: 'StopRecursionFixture'
		           superclassName: 'Object'
		           slots: #(  )
		           classSlots: #(  ).
	[
		self
			ensureMethodSource: 'members
	^ self members sorted'
			protocol: 'fixture'
			on: fixture.
		milliseconds := Time millisecondsToRun: [ result := self evaluate: 'StopRecursionFixture new members' within: 30 ] ] ensure: [
		self removeClassNamed: 'StopRecursionFixture' ].
	self assert: (self resultIndicatesError: result).
	self
		assert: (self textFrom: result) lines first
		equals: 'Evaluation stopped: its stack passed 1000000 frames, which an endless recursion does.'.
	self assert: milliseconds < 10000
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsCodeThatCatchesEveryException [
	"A limit that signals is caught by the first handler that takes every exception, and the code carries on. Terminating a process signals nothing."

	| milliseconds result |
	self timeLimit: 30 seconds.
	milliseconds := Time millisecondsToRun: [
		                result := self evaluateBriefly: '[ [ true ] whileTrue ] on: Exception do: [ :e | [ true ] whileTrue ]' ].
	self deny: ((self stoppedTextOf: result) includesSubstring: 'still running').
	self assert: milliseconds < 10000
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateStopsCodeThatKeepsMoreMemoryThanItsBound [
	"Code that keeps what it allocates without recursing passes no stack bound, so the image's memory backs the stack up. The bound is set low and the code keeps 24 MB, then waits, so the test allocates no GBs. A collection beforehand keeps garbage freed meanwhile from hiding the growth."

	| lines milliseconds result |
	self timeLimit: 30 seconds.
	Smalltalk garbageCollect.
	milliseconds := Time millisecondsToRun: [
			                result := self
				                          stoppedEarlyResultOf:
				                          '| kept | kept := (1 to: 3) collect: [ :each | ByteArray new: 8 * 1024 * 1024 ]. (Delay forSeconds: 60) wait. kept size'
				                          bounds: [ :command | command memoryGrowthLimit: 16 * 1024 * 1024 ] ].
	self assert: result isError.
	lines := (self textOfEvaluateResult: result) lines.
	self assert: (lines first: 2) equals: #( 'Evaluation stopped: the image''s memory grew by more than 16 MB while it ran.'
		   'What it changed before then stays changed.' ).
	self assert: (lines includes: 'Stopped in:').
	self assert: ((result structuredContent at: #error) at: #errorCode) equals: 'EvaluationMemoryGrowthTooLarge'.
	self assert: milliseconds < 10000
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateSurvivesADeprecationInAnImageThatRaisesThem [
	"Deprecation>>defaultAction raises when the image is set to raise deprecations, which is the same line a plain warning reaches."

	| previous result |
	previous := Deprecation raiseWarning.
	result := [
		          Deprecation raiseWarning: true.
		          self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> 'Object new deprecated: ''probe explanation.''. 7') } asDictionary ] ensure: [
		          Deprecation raiseWarning: previous ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((self dataFrom: result) at: #resultPrintString) equals: '7'.
	self assert: ((self warningsFrom: result) anySatisfy: [ :each | each includesSubstring: 'probe explanation.' ])
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateTakesTheStepTheWorldGivesTheTranscript [
	"The world goes on stepping while an evaluation runs. Where it steps the Transcript, the recorder standing in for it takes the step, or the world loop fails and a headless image quits."

	| result |
	self worldStepsTheTranscript ifFalse: [ ^ self skip: 'The world no longer steps the Transcript.' ].
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'Transcript show: ''stepped''; stepGlobal. Transcript contents') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((self dataFrom: result) at: #resultPrintString) equals: '''stepped'''
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateThatNeverStartedSaysSo [
	"Whether an evaluation behind a computing process ever gets a turn depends on how the virtual machine schedules processes of one priority, so the double leaves it unstarted, as if it never did."

	| command error holder result |
	self timeLimit: 30 seconds.
	holder := [ [ true ] whileTrue ] forkAt: Processor activePriority - 1 named: 'mcp-evaluate-holder-probe'.
	[
		command := MCPEvaluateCommandNeverStarting code: '3 + 4' timeLimit: self unstartedLimitSeconds previewLimit: 100.
		result := MCPToolEvaluate new answerFor: command execute ] ensure: [ holder terminate ].
	error := result structuredContent at: #error.
	self assert: result isError.
	self
		assert: (result structuredContent at: #summary)
		equals: 'Evaluation did not start within ' , self unstartedLimitSeconds printString , ' s, its time limit; none of it ran.'.
	self assert: ((error at: #heldBy) anySatisfy: [ :each |
			 each beginsWith: 'a process an evaluation forked, named mcp-evaluate-holder-probe, in ' ]).
	self assert: (error at: #timeoutSeconds) equals: self unstartedLimitSeconds.
	self assert: (error at: #errorCode) equals: 'EvaluationNotStarted'.
	self assert: command evaluator isTerminated
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateTimeoutSecondsIsAnIntegerFromOneToSixHundred [
	"A limit of 0 would stop the code before it ran, and one above ten minutes would let an evaluation nobody waits for any more cost more. The description says what a limit longer than the client waits costs."

	| property tool |
	tool := MCPToolEvaluate new.
	property := self inputPropertyNamed: 'timeoutSeconds' inTool: tool.
	self assert: property type equals: 'integer'.
	self assert: (property extraProperties at: #default) equals: 30.
	self assert: (property extraProperties at: #minimum) equals: 1.
	self assert: (property extraProperties at: #maximum) equals: 600.
	self assert: (property description includesSubstring: 'loses the answer').
	self assert: tool inputSchema required equals: #( 'code' ).
	self
		assertResult: (self callToolNamed: 'evaluate' withArguments: {
					 (#code -> '1').
					 (#timeoutSeconds -> 0) } asDictionary)
		refusesArgumentsSaying: 'timeoutSeconds must be at least 1, not 0.'.
	self
		assert: ((tool requestFromToolCallArguments: {
					  (#code -> '1').
					  (#timeoutSeconds -> 3600) } asDictionary) integerArgumentOrDefaultNamed: 'timeoutSeconds')
		equals: 600
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testEvaluateToolPointsAtTheToolCatalog [
	"evaluate is where an agent lands when it believes no dedicated tool exists, so its description has to name the way out."

	| tool |
	tool := self toolRegistry toolNamed: 'evaluate' ifAbsent: [ self fail: 'Missing evaluate tool' ].
	self assert: (tool description includesSubstring: 'tool_search')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageNotUnderstoodByAClassSaysItsInstancesUnderstandIt [
	"A constructor compiled on the instance side, then sent to the class, was answered with the class side's selectors that resembled it. Its send of new, which no instance understands, says it was meant for the class side, and compiling it there is offered. Any other instance-side method is sent to an instance: add: sent to OrderedCollection when new was forgotten, sumTo: whose source is in the .changes file as the caller's is, and port:, a library's setter, whose source is there too. Every class understands at:, so at:ifAbsent: also reads as at: then ifAbsent:, a guess that the instances understanding it outweighs. A new instance of the class of Smalltalk globals is empty, so the one everyone means is named."

	| error |
	error := self errorFrom: (self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> 'MCPNotUnderstoodNoteTestTarget withLabel: ''a''') } asDictionary).
	self
		assert: (error at: #note)
		equals:
		'Instances of MCPNotUnderstoodNoteTestTarget understand withLabel:, but MCPNotUnderstoodNoteTestTarget itself does not: withLabel: is an instance-side method. It sends new to self, which instances of MCPNotUnderstoodNoteTestTarget do not understand: compile it with method_compile and side class to send it to MCPNotUnderstoodNoteTestTarget.'.
	self deny: (error includesKey: #suggestedSelectors).
	error := self errorFrom:
		         (self callToolNamed: 'evaluate' withArguments: { (#code -> 'MCPDebugWatchTestTarget sumTo: 3') } asDictionary).
	self
		assert: (error at: #note)
		equals:
		'Instances of MCPDebugWatchTestTarget understand sumTo:, but MCPDebugWatchTestTarget itself does not: sumTo: is an instance-side method. Send it to an instance.'.
	error := self errorFrom:
		         (self callToolNamed: 'evaluate' withArguments: { (#code -> 'JRPCHTTPServer port: 4000') } asDictionary).
	self
		assert: (error at: #note)
		equals:
		'Instances of JRPCHTTPServer understand port:, but JRPCHTTPServer itself does not: port: is an instance-side method. Send it to an instance.'.
	error := self errorFrom:
		         (self callToolNamed: 'evaluate' withArguments: { (#code -> 'OrderedCollection add: 1') } asDictionary).
	self
		assert: (error at: #note)
		equals:
		'Instances of OrderedCollection understand add:, but OrderedCollection itself does not: add: is an instance-side method. Send it to an instance.'.
	error := self errorFrom:
		         (self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> 'OrderedCollection at: 1 ifAbsent: [ 0 ]') } asDictionary).
	self assert:
		((error at: #note) beginsWith: 'Instances of OrderedCollection understand at:ifAbsent:, but OrderedCollection itself does not').
	self deny: ((error at: #note) includesSubstring: 'method_compile').
	error := self errorFrom: (self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> 'Smalltalk globals class at: #Object ifAbsent: [ nil ]') } asDictionary).
	self assert: ((error at: #note) endsWith: ' is an instance-side method. Send it to an instance, such as Smalltalk globals.')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageNotUnderstoodByAnInstanceSaysItsClassUnderstandsIt [
	"A class-side method is sent to the class, whether it is one of Pharo's own, such as withAll:, or one compiled since the image shipped: nothing in it tells that it was meant for the instances. Every class understands name, which Class implements, so an instance that does not lacks an accessor rather than was sent a class-side message: only a method a class side of its own hierarchy defines says so."

	| error |
	error := self errorFrom:
		         (self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> 'MCPDebugWatchTestTarget new doubleOf: 3') } asDictionary).
	self
		assert: (error at: #note)
		equals:
		'MCPDebugWatchTestTarget itself understands doubleOf:, but its instances do not: doubleOf: is a class-side method. Send it to MCPDebugWatchTestTarget.'.
	error := self errorFrom:
		         (self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> 'OrderedCollection new withAll: #( 1 )') } asDictionary).
	self
		assert: (error at: #note)
		equals:
		'OrderedCollection itself understands withAll:, but its instances do not: withAll: is a class-side method. Send it to OrderedCollection.'.
	error := self errorFrom: (self callToolNamed: 'evaluate' withArguments: { (#code -> 'Object new name') } asDictionary).
	self deny: (error includesKey: #note)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageNotUnderstoodPassedOnToSuperIsSentByTheFrameThatSentIt [
	"An override of doesNotUnderstand: that passes the message on to super, as nil's own does in Pharo 10 and 11, runs one doesNotUnderstand: inside the one the virtual machine sent. The note reads the frame that sent the message, the sender of the outermost, not the override, which only passed it on: in those versions it named UndefinedObject>>doesNotUnderstand: as the code that sent a message to nil."

	| sender |
	sender := [
		          MCPNotUnderstoodNotePassingOnTarget new mcpProbeNobodyUnderstands.
		          nil ]
		          on: Error
		          do: [ :error | error return: (MCPNotUnderstoodNote senderOf: error) ].
	self assert: sender compiledCode method equals: thisContext method
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageNotUnderstoodSaysTwoKeywordMessagesRunTogether [
	"sorted:collect:, which nothing implements, was meant as sorted: then collect:. The selectors it resembles, sorted: among them, read as blaming the receiver, so the compile critique's sentence comes first. It is a guess, which a mistyped selector such as at:ifAbsentPut:put: matches too, so the selectors stay after it."

	| error result |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments:
		          { (#code -> '#( 3 1 2 ) asOrderedCollection sorted: [ :a :b | a < b ] collect: [ :each | each ]') } asDictionary.
	error := self errorFrom: result.
	self
		assert: (error at: #note)
		equals:
		'sorted:collect: is one message. To send collect: to what sorted: answers, put the sorted: send in parentheses: (... sorted: ...) collect: ...'.
	self assert: ((error at: #suggestedSelectors) includes: 'sorted:').
	self assert: (self textFrom: result) lines second equals: (error at: #note).
	self assert: ((self textFrom: result) lines third beginsWith: 'Did you mean: ').
	error := self errorFrom: (self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> 'Dictionary new at: 1 ifAbsentPut: [ 0 ] put: 3') } asDictionary).
	self assert: ((error at: #suggestedSelectors) includes: 'at:ifAbsentPut:')
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageNotUnderstoodSuggestsNearMissSelectors [
	"Thirty-five failures in a day of real use were guesses at an API; the receiver knows which selectors the guess resembles."

	| error |
	error := self errorFrom: (self
			         callToolNamed: 'evaluate'
			         withArguments: { (#code -> 'OrderedCollection new adAll: #( 1 2 3 )') } asDictionary).
	self assert: (error at: #suggestedSelectors) first equals: 'addAll:'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageNotUnderstoodSuggestsNothingForAnUnrelatedSelector [
	"Pharo's corrector answers its closest candidates whatever their distance; suggesting those would be worse than saying nothing."

	| error |
	error := self errorFrom: (self
			         callToolNamed: 'evaluate'
			         withArguments: { (#code -> 'OrderedCollection new frobnicate') } asDictionary).
	self deny: (error includesKey: #suggestedSelectors)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageNotUnderstoodWithNoSelectorAnswersTheFailure [
	"Before Pharo 14, perform: nil raises a message not understood whose selector is nil, which has no keywords to read: the answer is that failure, not an error raised while reading it."

	| result |
	result := self callToolNamed: 'evaluate' withArguments: { (#code -> 'MessageNotUnderstood new
	message: (Message selector: nil arguments: #(  ));
	receiver: 3;
	signal') } asDictionary.
	self assert: ((self textFrom: result) beginsWith: 'Evaluation failed during execution (MessageNotUnderstood)').
	self deny: ((self errorFrom: result) includesKey: #note)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageSentToNilByAnInlinedSendNamesTheSendTheCodeWrote [
	"to:do: is compiled inline, as a <= the code never wrote, which fails in Pharo's own methods when the limit is nil. The note names to:do:, the send the code wrote, and since the <= does not say which of to:do:'s operands was nil, it does not either."

	| error |
	error := self errorFrom: (self callToolNamed: 'evaluate' withArguments: { (#code -> '| limit |
1 to: limit do: [ :each | each ]') } asDictionary).
	self assert: (error at: #note) equals: 'The code sent to:do:, which met the nil.'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageSentToNilByPharoNamesTheVariableTheCodePassed [
	"Comparing with nil, or adding it, fails in the kernel, which sends nil a message of its own from a method running on nil. The variable the code left nil is width, or each in a block, not that method's self."

	| error |
	error := self errorFrom: (self callToolNamed: 'evaluate' withArguments: { (#code -> '| width |
3 > width') } asDictionary).
	self assert: (error at: #note) equals: 'The code sent > with the argument width, which is nil.'.
	self deny: (error includesKey: #suggestedSelectors).
	error := self errorFrom: (self
			          callToolNamed: 'evaluate'
			          withArguments: { (#code -> '#( 1 nil 3 ) inject: 0 into: [ :sum :each | sum + each ]') } asDictionary).
	self assert: (error at: #note) equals: 'The code sent + with the argument each, which is nil.'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageSentToNilInsidePharoSaysTheCodePassedNone [
	"Sorting a collection that holds nil fails in Pharo's own methods, on an element the code never named: the send the code made says so, rather than pointing at its receiver. Adding a number to a point whose coordinate is nil passes through Number>>adaptToPoint:andSend:, which the code never sent, and the send named is still the code's own."

	| error |
	error := self errorFrom:
		         (self callToolNamed: 'evaluate' withArguments: { (#code -> '#( 3 nil 1 ) asSortedCollection') } asDictionary).
	self
		assert: (error at: #note)
		equals: 'The code sent asSortedCollection, whose receiver and arguments are not nil: the nil was met inside it.'.
	error := self errorFrom: (self callToolNamed: 'evaluate' withArguments: { (#code -> '| point |
point := 3 @ nil.
point + 1') } asDictionary).
	self assert: (error at: #note) equals: 'The code sent +, whose receiver and arguments are not nil: the nil was met inside it.'
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageSentToNilNamesTheMethodThatSentIt [
	"nil's own selectors, such as addModelItemsToWindowMenu: for add:, are nobody's guess. Which method sent the message says where the nil came from."

	| error result |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> 'MCPToolRunTestsRaiser new addToNil') } asDictionary.
	error := self errorFrom: result.
	self assert: (error at: #note) equals: 'MCPToolRunTestsRaiser>>addToNil sent + to nil.'.
	self deny: (error includesKey: #suggestedSelectors).
	self assert: (self textFrom: result) lines second equals: (error at: #note)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testMessageSentToNilNamesTheVariableThatHeldIt [
	"The variable that held nil is what was never set."

	| error |
	error := self errorFrom: (self callToolNamed: 'evaluate' withArguments: { (#code -> '| names |
names add: 3') } asDictionary).
	self assert: (error at: #note) equals: 'The code sent add: to names, which is nil.'.
	self deny: (error includesKey: #suggestedSelectors)
]

{ #category : 'tests' }
MCPToolEvaluateTest >> testToolsOwnRegistryMetadata [

	| tool |
	tool := MCPToolEvaluate new.
	self assert: tool groupName equals: 'runtime'.
	self assert: tool defaultExposure equals: 'static'.
	self assert: tool annotations readOnlyHint equals: nil.
	self assert: (tool keywords includes: 'smalltalk')
]

{ #category : 'private' }
MCPToolEvaluateTest >> textOfEvaluateResult: aResult [
	"The text a call gets for an evaluation that failed."

	^ aResult content first text
]

{ #category : 'private' }
MCPToolEvaluateTest >> underEitherPreemptionRuleDo: aBlock [
	"Whether a preempted process goes to the back of its run queue is a setting of the virtual machine, which an image keeps from whoever built it. It reaches the image file only on a save, which no test makes."

	| original |
	original := Smalltalk vm processPreemptionYields.
	[
		#( true false ) do: [ :yields |
				Smalltalk vm processPreemptionYields: yields.
				aBlock value: yields ] ] ensure: [ Smalltalk vm processPreemptionYields: original ]
]

{ #category : 'private' }
MCPToolEvaluateTest >> unstartedLimitSeconds [
	"The time limit of an evaluation whose code a test never runs: nothing has to be reached first, so it is shorter than the tests' limit for code they let stop."

	^ 0.02
]

{ #category : 'private' }
MCPToolEvaluateTest >> waitUntilEnded: aProcess [
	"Up to 5 s, for what a stopped evaluation left unwinding."

	| deadline |
	deadline := Time millisecondClockValue + 5000.
	[ aProcess isTerminated or: [ Time millisecondClockValue > deadline ] ] whileFalse: [ (Delay forMilliseconds: 5) wait ]
]
