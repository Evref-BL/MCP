"
Tests debugger tool contracts, schemas, and registry behavior.
"
Class {
	#name : 'MCPDebugToolContractTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPDebugToolContractTest >> assertDebugTestStopAt: stopAt selects: selector [

	| data exception method result selectedFrame session state |
	result := self callToolNamed: 'debug_test_run' withArguments: {
			          (#className -> 'MCPDebugTestToolTarget').
			          (#testMethodName -> 'debugTestPassingCase').
			          (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds).
			          (#stopAt -> stopAt) } asDictionary.
	data := self dataFrom: result.
	session := data at: #session.
	state := data at: #state.
	selectedFrame := state at: #selectedFrame.
	method := selectedFrame at: #method.
	exception := state at: #exception.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #captured).
	self deny: (data at: #timedOut).
	self deny: (data at: #passed).
	self assert: (data at: #className) equals: 'MCPDebugTestToolTarget'.
	self
		assert: (data at: #testMethodName)
		equals: 'debugTestPassingCase'.
	self assert: (data at: #stopAt) equals: stopAt.
	self assert: ((data at: #capabilities) at: #testExecution).
	self assert: ((data at: #capabilities) at: #testPhaseBreakpoints).
	self assert: (session at: #status) equals: 'paused'.
	self assert: (session at: #reason) equals: 'debugStop'.
	self assert: (state at: #sessionId) equals: (session at: #sessionId).
	self assert: (state at: #reason) equals: 'debugStop'.
	self assert: (exception at: #className) equals: 'Break'.
	self assert: (method at: #className) equals: 'MCPDebugTestToolTarget'.
	self assert: (method at: #selector) equals: selector asString
]

{ #category : 'private' }
MCPDebugToolContractTest >> candidateRefForDebugger: aDebugger [

	^ 'debugger-candidate-' , aDebugger identityHash asString
]

{ #category : 'private' }
MCPDebugToolContractTest >> debugSuccessTimeoutMilliseconds [

	^ MCPDebugCaptureRequest defaultTimeoutMilliseconds
]

{ #category : 'private' }
MCPDebugToolContractTest >> installDebugMethodUpdateTemporaryStub [

	| source |
	source := String streamContents: [ :stream |
			          stream
				          nextPutAll: 'mcpDebugMethodUpdateTemporaryStub';
				          cr;
				          cr;
				          tab;
				          nextPutAll: '^ self notYetImplemented' ].
	MCPUpdateDebugMethodTestTarget compile: source classified: 'tests'
]

{ #category : 'private' }
MCPDebugToolContractTest >> registerControlSession [

	^ MCPDebugSessionRegistry default
		  registerDebugSession:
		  (MCPDebugControlTestSession withContext: thisContext)
		  named: 'Synthetic control debug session'
		  status: 'paused'
		  reason: 'halt'
]

{ #category : 'private' }
MCPDebugToolContractTest >> registerSyntheticSession [

	^ MCPDebugSessionRegistry default
		  registerDebugSession: self syntheticDebugSession
		  named: 'Synthetic failing test'
		  status: 'paused'
		  reason: 'halt'
]

{ #category : 'private' }
MCPDebugToolContractTest >> removeDebugMethodUpdateTestMethods [

	#( #mcpDebugMethodUpdateGeneratedValue
	   #mcpDebugMethodUpdateTemporaryStub ) do: [ :selector |
			(MCPUpdateDebugMethodTestTarget includesSelector: selector)
				ifTrue: [ MCPUpdateDebugMethodTestTarget removeSelector: selector ] ].
	Smalltalk globals
		removeKey: #MCPDebugMethodUpdateProceedCounter
		ifAbsent: [ nil ]
]

{ #category : 'private' }
MCPDebugToolContractTest >> scopeNamed: scopeName inStateData: data [

	^ (data at: #scopes) detect: [ :each | (each at: #kind) = scopeName ]
]

{ #category : 'private' }
MCPDebugToolContractTest >> selfVariableFromStateData: data [

	| receiverScope |
	receiverScope := self scopeNamed: 'receiver' inStateData: data.
	^ self
		  variableNamed: 'self'
		  inVariables: (receiverScope at: #variables)
]

{ #category : 'running' }
MCPDebugToolContractTest >> setUp [

	super setUp.
	MCPDebugAttachedDebuggerSelectionStrategy reset.
	MCPDebugSessionRegistry resetDefault.
	(Smalltalk globals includesKey: #MCPDebugBreakpointRegistry) ifTrue: [
		MCPDebugBreakpointRegistry resetDefault ].
	self removeDebugMethodUpdateTestMethods
]

{ #category : 'private' }
MCPDebugToolContractTest >> stateDataForRecord: record [

	| result |
	result := self callToolNamed: 'debug_state_get' withArguments: {
			          (#sessionId -> record sessionId).
			          (#includeReceiver -> true) } asDictionary.
	^ self dataFrom: result
]

{ #category : 'private' }
MCPDebugToolContractTest >> syntheticDebugSession [

	^ DebugSession
		  named: 'MCP synthetic debug session'
		  on: Processor activeProcess
		  startedAt: thisContext
]

{ #category : 'private' }
MCPDebugToolContractTest >> syntheticDebuggerNamed: aString [

	| exception session |
	exception := (OupsNullException fromSignallerContext: thisContext)
		             messageText: aString;
		             yourself.
	session := (DebugSession
		            named: aString
		            on: Processor activeProcess
		            startedAt: thisContext)
		           exception: exception;
		           yourself.
	^ StDebugger on: session
]

{ #category : 'running' }
MCPDebugToolContractTest >> tearDown [

	(Smalltalk globals includesKey: #MCPDebugBreakpointRegistry) ifTrue: [
		MCPDebugBreakpointRegistry resetDefault ].
	self terminateCapturedSessions.
	self removeDebugMethodUpdateTestMethods.
	MCPDebugSessionRegistry resetDefault.
	MCPDebugAttachedDebuggerSelectionStrategy reset.
	super tearDown
]

{ #category : 'private' }
MCPDebugToolContractTest >> terminateCapturedSessions [

	(Smalltalk globals includesKey: #MCPDebugSessionRegistry) ifFalse: [
		^ self ].
	MCPDebugSessionRegistry default sessionRecords do: [ :record |
			record continuation ifNotNil: [ :continuation |
					[ continuation terminateWorker ]
						on: Error
						do: [ :ignored | nil ] ].
			record reason = 'capturedException' ifTrue: [
					record debugSession ifNotNil: [ :session |
							[ session terminate ]
								on: Error
								do: [ :ignored | nil ] ] ] ]
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedContinuationBuildsAttachedDebuggerController [

	| continuation continuationClass controller controllerClass debugger session |
	controllerClass := Smalltalk globals
		                   at: #MCPDebugAttachedDebuggerController
		                   ifAbsent: [
		                   self fail:
			                   'Missing attached debugger controller.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [
		                     self fail:
			                     'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed:
		            'Attached controller debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	continuation := continuationClass
		                debugger: debugger
		                timeoutMilliseconds: 25
		                resultPreviewCharacterLimit: 1000.
	controller := continuation debugControllerForSession: session.
	self assert: controller class equals: controllerClass.
	self assert: controller debugSession equals: session
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedContinuationBuildsSessionControllerForUnownedSession [

	| continuation continuationClass controller controllerClass debugger replacementSession session |
	controllerClass := Smalltalk globals
		                   at: #MCPDebugSessionController
		                   ifAbsent: [
		                   self fail: 'Missing session controller.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [
		                     self fail:
			                     'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed:
		            'Attached controller visible debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	replacementSession := (self syntheticDebuggerNamed:
		                       'Attached controller replacement session')
		                      session.
	continuation := continuationClass
		                debugger: debugger
		                timeoutMilliseconds: 25
		                resultPreviewCharacterLimit: 1000.
	controller := continuation debugControllerForSession:
		              replacementSession.
	self assert: controller class equals: controllerClass.
	self assert: controller debugSession equals: replacementSession
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedContinuationDefersRestartThroughDebuggerActionModel [

	| context continuation continuationClass controller debugger session |
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [
		                     self fail:
			                     'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed:
		            'Deferred attached restart debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	continuation := continuationClass
		                debugger: debugger
		                timeoutMilliseconds: 25
		                resultPreviewCharacterLimit: 1000.
	context := thisContext.
	controller := continuation debugControllerForSession: session.
	controller performOperationNamed: 'restart' context: context.
	self assert: debugger hasDeferredAction.
	self assert: debugger operation equals: nil.
	debugger runDeferredAction.
	self assert: debugger operation equals: #restartContext:.
	self assert: debugger context equals: context
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedContinuationDefersVisibleDebuggerProceed [

	| continuation continuationClass debugger session |
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [
		                     self fail:
			                     'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed:
		            'Deferred attached proceed debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	continuation := continuationClass
		                debugger: debugger
		                timeoutMilliseconds: 25
		                resultPreviewCharacterLimit: 1000.
	self assert: continuation shouldProceedUsingAttachedDebugger.
	continuation proceedCurrentDebugSession.
	self assert: debugger hasDeferredAction.
	self deny: debugger proceeded.
	debugger runDeferredAction.
	self assert: debugger proceeded.
	self assert: debugger operation equals: #proceedDebugSession
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedContinuationUsesVisibleDebuggerOnlyForOwnedSession [

	| continuation continuationClass debugger replacementSession |
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [
		                     self fail:
			                     'Missing attached debugger continuation.' ].
	debugger := self syntheticDebuggerNamed:
		            'Attached continuation visible debugger'.
	continuation := continuationClass
		                debugger: debugger
		                timeoutMilliseconds: 25
		                resultPreviewCharacterLimit: 1000.
	self assert: continuation shouldProceedUsingAttachedDebugger.
	replacementSession := (self syntheticDebuggerNamed:
		                       'Attached continuation replacement session')
		                      session.
	continuation debugSession: replacementSession.
	self deny: continuation shouldProceedUsingAttachedDebugger
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedDebuggerSelectionStrategyCapturesSoleContinuationWhenProcessChanges [

	| continuation continuationClass debugger debuggerCount exception newProcess newSession strategyClass |
	strategyClass := Smalltalk globals
		                 at: #MCPDebugAttachedDebuggerSelectionStrategy
		                 ifAbsent: [
		                 self fail:
			                 'Missing attached debugger selection strategy.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [
		                     self fail:
			                     'Missing attached debugger continuation.' ].
	strategyClass reset.
	debugger := self syntheticDebuggerNamed:
		            'Attached original process debugger'.
	continuation := continuationClass
		                debugger: debugger
		                timeoutMilliseconds: 25
		                resultPreviewCharacterLimit: 1000.
	newProcess := [ nil ] newProcess.
	exception := (OupsNullException fromSignallerContext: thisContext)
		             messageText: 'Attached different process session';
		             yourself.
	newSession := (DebugSession
		               named: 'Attached different process session'
		               on: newProcess
		               startedAt: thisContext)
		              exception: exception;
		              yourself.
	debuggerCount := StDebugger allInstances size.
	strategyClass activate: continuation during: [
			(strategyClass with: { StDebugger } asArray)
				openDebuggerForSession: newSession ].
	self assert: continuation capturedDebugSession equals: newSession.
	self assert: continuation currentStatus equals: #captured.
	self assert: StDebugger allInstances size equals: debuggerCount
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedDebuggerSelectionStrategyReusesAttachedDebugger [

	| activeCount continuation continuationClass debugger debuggerCount newSession originalSession previousStrategy strategyClass |
	strategyClass := Smalltalk globals
		                 at: #MCPDebugAttachedDebuggerSelectionStrategy
		                 ifAbsent: [
		                 self fail:
			                 'Missing attached debugger selection strategy.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [
		                     self fail:
			                     'Missing attached debugger continuation.' ].
	strategyClass reset.
	previousStrategy := OupsDebuggerSelectionStrategy
		                    debuggerSelectionStrategy.
	activeCount := strategyClass activeContinuations size.
	debugger := self syntheticDebuggerNamed: 'Attached strategy debugger'.
	originalSession := debugger session.
	continuation := continuationClass
		                debugger: debugger
		                timeoutMilliseconds: 25
		                resultPreviewCharacterLimit: 1000.
	newSession := (self syntheticDebuggerNamed:
		               'Attached replacement session') session.
	debuggerCount := StDebugger allInstances size.
	strategyClass activate: continuation during: [
			(strategyClass with: { StDebugger } asArray)
				openDebuggerForSession: newSession ].
	self assert: debugger session equals: originalSession.
	self assert: continuation debugSession equals: newSession.
	self assert: continuation capturedDebugSession equals: newSession.
	self assert: continuation currentStatus equals: #captured.
	self assert: StDebugger allInstances size equals: debuggerCount.
	self
		assert: OupsDebuggerSelectionStrategy debuggerSelectionStrategy
		equals: previousStrategy.
	self
		assert: strategyClass activeContinuations size
		equals: activeCount
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugBreakpointsCanDisableAndEnableBreakpoint [

	| breakpointId data |
	data := self dataFrom:
		        (self
			         callToolNamed: 'debug_breakpoint_set'
			         withArguments: {
					         (#className -> 'MCPDebugToolContractTest').
					         (#selector -> 'syntheticDebugSession') } asDictionary).
	breakpointId := data at: #breakpointId.

	data := self dataFrom: (self
			         callToolNamed: 'debug_breakpoint_disable'
			         withArguments:
			         { (#breakpointId -> breakpointId) } asDictionary).
	self deny: (data at: #enabled).

	data := self dataFrom: (self
			         callToolNamed: 'debug_breakpoint_enable'
			         withArguments:
			         { (#breakpointId -> breakpointId) } asDictionary).
	self assert: (data at: #enabled)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugBreakpointsSetsListsAndRemovesMethodBreakpoint [

	| breakpointId data listData removeData result |
	result := self
		          callToolNamed: 'debug_breakpoint_set'
		          withArguments: {
				          (#className -> 'MCPDebugToolContractTest').
				          (#selector -> 'syntheticDebugSession').
				          (#targetKind -> 'method') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #targetKind) equals: 'method'.
	self assert: (data at: #className) equals: 'MCPDebugToolContractTest'.
	self assert: (data at: #selector) equals: 'syntheticDebugSession'.
	self assert: (data at: #enabled).
	breakpointId := data at: #breakpointId.

	listData := self dataFrom: (self
			             callToolNamed: 'debug_breakpoint_list'
			             withArguments: Dictionary new).
	self assert: (listData at: #totalCount) equals: 1.
	self
		assert: ((listData at: #breakpoints) first at: #breakpointId)
		equals: breakpointId.

	removeData := self dataFrom: (self
			               callToolNamed: 'debug_breakpoint_remove'
			               withArguments:
			               { (#breakpointId -> breakpointId) } asDictionary).
	self assert: (removeData at: #removed).
	listData := self dataFrom: (self
			             callToolNamed: 'debug_breakpoint_list'
			             withArguments: Dictionary new).
	self assert: (listData at: #totalCount) equals: 0
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugBreakpointsSupportsSourceIntervalTarget [

	| data nodeClassName source start stop |
	source := (MCPDebugToolContractTest >> #syntheticDebugSession)
		          sourceCode.
	start := source findString: 'thisContext'.
	stop := start + 'thisContext' size - 1.
	data := self dataFrom:
		        (self
			         callToolNamed: 'debug_breakpoint_set'
			         withArguments: {
					         (#className -> 'MCPDebugToolContractTest').
					         (#selector -> 'syntheticDebugSession').
					         (#targetKind -> 'sourceInterval').
					         (#sourceStart -> start).
					         (#sourceStop -> stop) } asDictionary).
	nodeClassName := data at: #nodeClassName.
	self assert: (data at: #targetKind) equals: 'sourceInterval'.
	self assert: (data at: #sourceStart) equals: start.
	self assert: (data at: #sourceStop) equals: stop.
	self assert: (nodeClassName includesSubstring: 'VariableNode')
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCandidateAttachRegistersCandidateFromSearch [

	| data debugger ref result searchData session state |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed: 'Attachable human debugger'.
	ref := self candidateRefForDebugger: debugger.
	searchData := self dataFrom: (self
			               callToolNamed: 'debug_candidate_search'
			               withArguments: Dictionary new).
	self assert: ((searchData at: #candidates) anySatisfy: [ :each |
			 (each at: #candidateRef) = ref ]).

	result := self
		          callToolNamed: 'debug_candidate_attach'
		          withArguments: { (#candidateRef -> ref) } asDictionary.
	data := self dataFrom: result.
	session := data at: #session.
	state := data at: #state.

	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #attached).
	self deny: (data at: #alreadyAttached).
	self assert: (data at: #candidateRef) equals: ref.
	self assert: (session at: #reason) equals: 'attachedDebugger'.
	self assert: (state at: #sessionId) equals: (session at: #sessionId).
	self
		assert: (MCPDebugSessionRegistry default
				 sessionRecordAt: (session at: #sessionId)
				 ifAbsent: [ self fail: 'Attached session was not registered.' ])
				debugSession
		equals: debugger session
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCandidateSearchReturnsUnattachedDebuggerCandidates [

	| candidates data newer newerRef older olderRef refs result |
	Smalltalk garbageCollect.
	older := self syntheticDebuggerNamed: 'Older human debugger'.
	newer := self syntheticDebuggerNamed: 'Newer human debugger'.
	olderRef := self candidateRefForDebugger: older.
	newerRef := self candidateRefForDebugger: newer.

	result := self
		          callToolNamed: 'debug_candidate_search'
		          withArguments: Dictionary new.
	data := self dataFrom: result.
	candidates := data at: #candidates.
	refs := candidates collect: [ :each | each at: #candidateRef ].

	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (refs includes: olderRef).
	self assert: (refs includes: newerRef).
	self
		assert:
			((candidates detect: [ :each | (each at: #candidateRef) = newerRef ])
				 at: #sessionName)
		equals: 'Newer human debugger'.
	self assert:
		((candidates detect: [ :each | (each at: #candidateRef) = newerRef ])
			 includesKey: #topFrame)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCandidateSearchSkipsAlreadyRegisteredDebuggers [

	| candidates data debugger ref refs result |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed:
		            'Already attached human debugger'.
	ref := self candidateRefForDebugger: debugger.
	MCPDebugSessionRegistry default
		registerDebugSession: debugger session
		named: 'Already attached human debugger'
		status: 'paused'
		reason: 'attachedDebugger'.

	result := self
		          callToolNamed: 'debug_candidate_search'
		          withArguments: Dictionary new.
	data := self dataFrom: result.
	candidates := data at: #candidates.
	refs := candidates collect: [ :each | each at: #candidateRef ].

	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self deny: (refs includes: ref)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCandidateSearchSkipsAttachedDebuggerAfterRecordedSessionChanges [

	| candidates data debugger record ref replacementDebugger replacementRef refs result |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed: 'Attached evolving debugger'.
	replacementDebugger := self syntheticDebuggerNamed:
		                       'Captured replacement debugger'.
	ref := self candidateRefForDebugger: debugger.
	replacementRef := self candidateRefForDebugger: replacementDebugger.
	record := MCPDebugSessionRegistry default
		          registerDebugSession: debugger session
		          named: 'Attached evolving debugger'
		          status: 'paused'
		          reason: 'attachedDebugger'.
	record
		debugger: debugger;
		debugSession: replacementDebugger session.

	result := self
		          callToolNamed: 'debug_candidate_search'
		          withArguments: Dictionary new.
	data := self dataFrom: result.
	candidates := data at: #candidates.
	refs := candidates collect: [ :each | each at: #candidateRef ].

	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self deny: (refs includes: ref).
	self deny: (refs includes: replacementRef)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureCapturesRuntimeExceptionAsDebugSession [

	| data exception result session sessionId state |
	result := self callToolNamed: 'debug_capture' withArguments: {
			          (#expression -> 'self error: ''debug_capture boom''').
			          (#name -> 'Captured runtime error').
			          (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary.
	data := self dataFrom: result.
	session := data at: #session.
	state := data at: #state.
	exception := state at: #exception.
	sessionId := session at: #sessionId.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #captured).
	self deny: (data at: #timedOut).
	self assert: (data at: #sessionId) equals: sessionId.
	self assert: (session at: #status) equals: 'paused'.
	self assert: (session at: #reason) equals: 'capturedException'.
	self assert: ((session at: #capabilities) at: #capture).
	self assert: (state at: #sessionId) equals: sessionId.
	self assert: (state at: #stateId) equals: 'state-0'.
	self assert: (exception at: #className) equals: 'Error'.
	self assert:
		((exception at: #message) includesSubstring: 'debug_capture boom').
	self deny: (state at: #callStack) isEmpty.
	self deny: (state at: #selectedFrame) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureReportsSyntaxFailureWithoutSession [

	| error result |
	result := self callToolNamed: 'debug_capture' withArguments: {
			          (#expression -> '1 +').
			          (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugCaptureSyntaxError'.
	self assert: (error at: #expression) equals: '1 +'.
	self assert: MCPDebugSessionRegistry default size equals: 0
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureResumeProceedsCapturedHalt [

	| captureData captureResult resumeData resumeResult sessionId |
	captureResult := self callToolNamed: 'debug_capture' withArguments: {
			                 (#expression -> 'Halt signal. 42').
			                 (#name -> 'Captured halt resume').
			                 (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary.
	captureData := self dataFrom: captureResult.
	sessionId := captureData at: #sessionId.
	resumeResult := self
		                callToolNamed: 'debug_session_resume'
		                withArguments: { (#sessionId -> sessionId) } asDictionary.
	resumeData := self dataFrom: resumeResult.
	self
		assert: ((self structuredContentFrom: resumeResult) at: #status)
		equals: 'ok'.
	self assert: (resumeData at: #status) equals: 'completed'.
	self assert: (resumeData at: #reason) equals: 'resume'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureReturnsCompletedResultWithoutSession [

	| data result |
	result := self callToolNamed: 'debug_capture' withArguments: {
			          (#expression -> '21 + 21').
			          (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self deny: (data at: #captured).
	self deny: (data at: #timedOut).
	self assert: (data at: #resultClassName) equals: 'SmallInteger'.
	self assert: (data at: #resultPrintString) equals: '42'.
	self assert: MCPDebugSessionRegistry default size equals: 0
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureTimesOutWithoutSession [

	| error result |
	result := self callToolNamed: 'debug_capture' withArguments: {
			          (#expression -> '(Delay forMilliseconds: 200) wait. 42').
			          (#timeoutMilliseconds -> 1) } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugCaptureTimedOut'.
	self assert: (error at: #workerTerminated).
	self assert: MCPDebugSessionRegistry default size equals: 0
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugControlRejectsForeignFrameRef [

	| error foreignRecord record result |
	record := self registerControlSession.
	foreignRecord := self registerSyntheticSession.
	result := self
		          callToolNamed: 'debug_session_step_over'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef
				           ->
				           (foreignRecord sessionId , '/' , foreignRecord stateId
				            , '/frame-0')) } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self
		assert: (error at: #errorCode)
		equals: 'DebugFrameReferenceInvalid'.
	self assert: (error at: #sessionId) equals: record sessionId.
	self
		assert: (error at: #referenceSessionId)
		equals: foreignRecord sessionId
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugControlRejectsStaleFrameRef [

	| error record result |
	record := self registerControlSession.
	result := self
		          callToolNamed: 'debug_session_step_into'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef -> (record sessionId , '/old-state/frame-0')) }
				          asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugStateStale'.
	self assert: (error at: #requestedStateId) equals: 'old-state'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugControlResumeAdvancesStateWithoutSnapshot [

	| record result resultData session |
	record := self registerControlSession.
	session := record debugSession.
	result := self
		          callToolNamed: 'debug_session_resume'
		          withArguments:
		          { (#sessionId -> record sessionId) } asDictionary.
	resultData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: session operationNames asArray equals: #( 'resume' ).
	self assert: (resultData at: #previousStateId) equals: 'state-0'.
	self assert: (resultData at: #stateId) equals: 'state-1'.
	self assert: (resultData at: #status) equals: 'running'.
	self deny: (resultData at: #state) notNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugControlStepOverAdvancesStateAndReturnsSnapshot [

	| data frameRef record result resultData session |
	record := self registerControlSession.
	session := record debugSession.
	data := self stateDataForRecord: record.
	frameRef := (data at: #selectedFrame) at: #frameRef.
	result := self
		          callToolNamed: 'debug_session_step_over'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#stateId -> record stateId).
				          (#frameRef -> frameRef).
				          (#returnState -> true) } asDictionary.
	resultData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: session operationNames asArray equals: #( 'stepOver' ).
	self assert: (resultData at: #previousStateId) equals: 'state-0'.
	self assert: (resultData at: #stateId) equals: 'state-1'.
	self assert: record stateId equals: 'state-1'.
	self assert: (resultData at: #status) equals: 'paused'.
	self assert: ((resultData at: #state) at: #stateId) equals: 'state-1'.
	self
		assert: (((resultData at: #state) at: #selectedFrame) at: #frameRef)
		equals: record sessionId , '/state-1/frame-0'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugControlStepOverAdvancesStateWithoutSnapshotByDefault [

	| record result resultData session |
	record := self registerControlSession.
	session := record debugSession.
	result := self
		          callToolNamed: 'debug_session_step_over'
		          withArguments:
		          { (#sessionId -> record sessionId) } asDictionary.
	resultData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: session operationNames asArray equals: #( 'stepOver' ).
	self assert: (resultData at: #previousStateId) equals: 'state-0'.
	self assert: (resultData at: #stateId) equals: 'state-1'.
	self assert: (resultData at: #status) equals: 'paused'.
	self deny: (resultData at: #state) notNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateEvaluatesExpressionInSelectedFrame [

	| record stateData frameRef result data |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self
		          callToolNamed: 'debug_expression_evaluate'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef -> frameRef).
				          (#expression -> 'self class name') } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #frameRef) equals: frameRef.
	self assert: (data at: #resultClassName) equals: 'ByteSymbol'.
	self
		assert: (data at: #resultPrintString)
		equals: '#MCPDebugToolContractTest'.
	self deny: (data at: #hasResultVariableRef)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateReadsTemporaryInSelectedFrame [

	| frameRef marker record result stateData data |
	marker := 41.
	record := MCPDebugSessionRegistry default
		          registerDebugSession: (DebugSession
				           named: 'MCP active temporary debug session'
				           on: Processor activeProcess
				           startedAt: thisContext)
		          named: 'Synthetic active temporary debug session'
		          status: 'paused'
		          reason: 'halt'.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self
		          callToolNamed: 'debug_expression_evaluate'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef -> frameRef).
				          (#expression -> 'marker + 1') } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #resultClassName) equals: 'SmallInteger'.
	self assert: (data at: #resultPrintString) equals: '42'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateRejectsForeignFrameRef [

	| error foreignRecord record result |
	record := self registerSyntheticSession.
	foreignRecord := self registerSyntheticSession.
	result := self
		          callToolNamed: 'debug_expression_evaluate'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef
				           ->
				           (foreignRecord sessionId , '/' , foreignRecord stateId
				            , '/frame-0')).
				          (#expression -> '1') } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self
		assert: (error at: #errorCode)
		equals: 'DebugFrameReferenceInvalid'.
	self assert: (error at: #sessionId) equals: record sessionId.
	self
		assert: (error at: #referenceSessionId)
		equals: foreignRecord sessionId
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateRejectsStaleFrameRef [

	| record result error |
	record := self registerSyntheticSession.
	result := self
		          callToolNamed: 'debug_expression_evaluate'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef -> (record sessionId , '/old-state/frame-0')).
				          (#expression -> '1') } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugStateStale'.
	self assert: (error at: #requestedStateId) equals: 'old-state'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateReportsRuntimeFailure [

	| record stateData frameRef result error |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self
		          callToolNamed: 'debug_expression_evaluate'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef -> frameRef).
				          (#expression
				           -> 'self error: ''debug_expression_evaluate boom''') }
				          asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugEvaluationFailed'.
	self
		assert: (error at: #expression)
		equals: 'self error: ''debug_expression_evaluate boom'''
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateReportsSyntaxFailure [

	| record stateData frameRef result error |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self
		          callToolNamed: 'debug_expression_evaluate'
		          withArguments: {
				          (#sessionId -> record sessionId).
				          (#frameRef -> frameRef).
				          (#expression -> '1 +') } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self
		assert: (error at: #errorCode)
		equals: 'DebugEvaluationSyntaxError'.
	self assert: (error at: #expression) equals: '1 +'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateCanIgnoreCritiquesAndProceed [

	| action arguments captureData updateData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugMethodUpdateProceedCounter put: ((Smalltalk at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug_capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured critique-ignored update').
					                (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll:
					                '^ self mcpDebugMethodUpdateStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments
		at: #source put: methodSource;
		at: #ignoreCritiques put: true.
	result := self
		          callToolNamed: 'debug_method_update'
		          withArguments: arguments.
	updateData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self deny: (updateData at: #critiques) isEmpty.
	self assert: (updateData at: #proceedOutcome) equals: 'paused'.
	self deny: (updateData at: #state) isNil.
	self
		assert: ((updateData at: #repairActions) first at: #selector)
		equals: 'mcpDebugMethodUpdateStillMissing'.
	self
		assert: (Smalltalk globals
				 at: #MCPDebugMethodUpdateProceedCounter
				 ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateCanProceedAfterPriorCritiqueBlockWithIgnoreCritiques [

	| action arguments blockedData captureData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugMethodUpdateProceedCounter put: ((Smalltalk at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug_capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured two-step critique update').
					                (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll:
					                '^ self mcpDebugMethodUpdateStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments at: #source put: methodSource.
	blockedData := self dataFrom:
		               (self
			                callToolNamed: 'debug_method_update'
			                withArguments: arguments).
	self assert: (blockedData at: #blockedByCritiques).
	arguments := {
		             (#sessionId -> (blockedData at: #sessionId)).
		             (#stateId -> (blockedData at: #stateId)).
		             (#frameRef -> (blockedData at: #frameRef)).
		             (#source -> methodSource).
		             (#ignoreCritiques -> true) } asDictionary.
	result := self
		          callToolNamed: 'debug_method_update'
		          withArguments: arguments.
	blockedData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (blockedData at: #proceeded).
	self deny: (blockedData at: #blockedByCritiques).
	self assert: (blockedData at: #proceedOutcome) equals: 'paused'.
	self
		assert: ((blockedData at: #repairActions) first at: #selector)
		equals: 'mcpDebugMethodUpdateStillMissing'.
	self
		assert: (Smalltalk globals
				 at: #MCPDebugMethodUpdateProceedCounter
				 ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateCreatesMissingMethodFromRepairAction [

	| action arguments captureData generatedValue updateData expectedSource methodSource result state |
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug_capture'
			                withArguments: {
					                (#expression
					                 ->
					                 'MCPUpdateDebugMethodTestTarget new triggerMissingMethod').
					                (#name -> 'Captured missing method update').
					                (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                cr;
				                nextPutAll: '^42' ].
	expectedSource := String streamContents: [ :stream |
			                  stream
				                  nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                  cr;
				                  cr;
				                  tab;
				                  nextPutAll: '^ 42' ].
	arguments := (action at: #arguments) copy.
	arguments at: #source put: methodSource.
	result := self
		          callToolNamed: 'debug_method_update'
		          withArguments: arguments.
	updateData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self assert: (updateData at: #previousStateId) equals: 'state-0'.
	self assert: (updateData at: #stateId) equals: 'state-2'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self assert: (updateData at: #proceedOutcome) equals: 'completed'.
	self assert: (updateData at: #resultPrintString) equals: '42'.
	self
		assert: ((updateData at: #method) at: #selector)
		equals: 'mcpDebugMethodUpdateGeneratedValue'.
	self
		assert: ((updateData at: #method) at: #className)
		equals: 'MCPUpdateDebugMethodTestTarget'.
	self
		assert: ((updateData at: #method) at: #source)
		equals: expectedSource.
	generatedValue := MCPUpdateDebugMethodTestTarget new
		                  mcpDebugMethodUpdateGeneratedValue.
	self assert: generatedValue equals: 42.
	self assert: (updateData at: #state) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateProceedsAfterCleanMissingMethodRepair [

	| action arguments captureData updateData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugMethodUpdateProceedCounter put: ((Smalltalk at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug_capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured missing method proceed').
					                (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ 42' ].
	arguments := (action at: #arguments) copy.
	arguments at: #source put: methodSource.
	result := self
		          callToolNamed: 'debug_method_update'
		          withArguments: arguments.
	updateData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self assert: (updateData at: #proceedOutcome) equals: 'completed'.
	self assert: (updateData at: #resultClassName) equals: 'SmallInteger'.
	self assert: (updateData at: #resultPrintString) equals: '42'.
	self
		assert: (Smalltalk globals
				 at: #MCPDebugMethodUpdateProceedCounter
				 ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateRecompilesNotYetImplementedFrame [

	| action arguments captureData generatedValue updateData expectedSource methodSource result state |
	self installDebugMethodUpdateTemporaryStub.
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug_capture'
			                withArguments: {
					                (#expression
					                 ->
					                 'MCPUpdateDebugMethodTestTarget new mcpDebugMethodUpdateTemporaryStub').
					                (#name -> 'Captured not yet implemented update').
					                (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	self assert: (action at: #kind) equals: 'notYetImplemented'.
	self assert: (action at: #requiresMethodSource).
	self assert: ((action at: #defaultMethodSource) includesSubstring:
			 'notYetImplemented').
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateTemporaryStub';
				                cr;
				                nextPutAll: '^43' ].
	expectedSource := String streamContents: [ :stream |
			                  stream
				                  nextPutAll: 'mcpDebugMethodUpdateTemporaryStub';
				                  cr;
				                  cr;
				                  tab;
				                  nextPutAll: '^ 43' ].
	arguments := (action at: #arguments) copy.
	arguments at: #source put: methodSource.
	result := self
		          callToolNamed: 'debug_method_update'
		          withArguments: arguments.
	updateData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (updateData at: #updateKind) equals: 'notYetImplemented'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self assert: (updateData at: #proceedOutcome) equals: 'completed'.
	self assert: (updateData at: #resultPrintString) equals: '43'.
	generatedValue := MCPUpdateDebugMethodTestTarget new
		                  mcpDebugMethodUpdateTemporaryStub.
	self assert: generatedValue equals: 43.
	self
		assert: ((updateData at: #method) at: #selector)
		equals: 'mcpDebugMethodUpdateTemporaryStub'.
	self
		assert: ((updateData at: #method) at: #source)
		equals: expectedSource.
	self assert: (updateData at: #state) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateRequestNormalizesMethodSourceLineFeeds [

	| parsedRequest source tool |
	source := 'mcpDebugNormalizedSource' , String lf , '^ ''line one'
	          , String lf , 'line two'''.
	tool := MCPToolUpdateDebugMethod new.
	parsedRequest := self parsedRequestForTool: tool arguments: {
			                 (#sessionId -> 'debug-session-1').
			                 (#source -> source) } asDictionary.
	self deny: (parsedRequest methodSource includes: Character lf).
	self assert: (parsedRequest methodSource includes: Character cr)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateStopsBeforeProceedingWhenCritiquesAreReported [

	| action arguments captureData updateData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugMethodUpdateProceedCounter put: ((Smalltalk at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug_capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured critique-blocked update').
					                (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll:
					                '^ self mcpDebugMethodUpdateStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments at: #source put: methodSource.
	result := self
		          callToolNamed: 'debug_method_update'
		          withArguments: arguments.
	updateData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self deny: (updateData at: #proceeded).
	self assert: (updateData at: #blockedByCritiques).
	self
		assert: (updateData at: #proceedOutcome)
		equals: 'blockedByCritiques'.
	self deny: (updateData at: #critiques) isEmpty.
	self
		assert: (Smalltalk globals
				 at: #MCPDebugMethodUpdateProceedCounter
				 ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionGetReturnsRegisteredSession [

	| record result data session |
	record := self registerSyntheticSession.
	result := self
		          callToolNamed: 'debug_session_get'
		          withArguments:
		          { (#sessionId -> record sessionId) } asDictionary.
	data := self dataFrom: result.
	session := data at: #session.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (session at: #sessionId) equals: record sessionId.
	self assert: (session at: #status) equals: 'paused'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionRegistryAssignsStateScopedRecord [

	| record info |
	record := self registerSyntheticSession.
	self assert: record sessionId equals: 'debug-session-1'.
	self assert: record stateId equals: 'state-0'.
	info := (MCPDebugSessionInfo fromRecord: record) asDictionary.
	self assert: (info at: #lastStateId) equals: 'state-0'.
	self assert: ((info at: #capabilities) at: #stateInspection)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsAttachInstallsExternalContinuation [

	| data debugger record ref session |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed:
		            'Attachable continuation debugger'.
	ref := self candidateRefForDebugger: debugger.
	data := self dataFrom: (self
			         callToolNamed: 'debug_candidate_attach'
			         withArguments: { (#candidateRef -> ref) } asDictionary).
	session := data at: #session.
	record := MCPDebugSessionRegistry default
		          sessionRecordAt: (session at: #sessionId)
		          ifAbsent: [
		          self fail: 'Attached session was not registered.' ].
	self assert: record continuation notNil.
	self
		assert: record continuation class name
		equals: #MCPDebugAttachedContinuation.
	self assert: record continuation debugger equals: debugger.
	self assert: record continuation timeoutMilliseconds equals: 2000
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsAttachRejectsUnknownCandidateRef [

	| error result |
	result := self
		          callToolNamed: 'debug_candidate_attach'
		          withArguments:
		          { (#candidateRef -> 'debugger-candidate-missing') }
			          asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self
		assert: (error at: #errorCode)
		equals: 'DebugSessionCandidateNotFound'.
	self
		assert: (error at: #candidateRef)
		equals: 'debugger-candidate-missing'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsAttachReusesRecordAfterRecordedSessionChanges [

	| data debugger record ref replacementDebugger result session |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed: 'Attach evolving debugger'.
	replacementDebugger := self syntheticDebuggerNamed:
		                       'Attach replacement debugger'.
	ref := self candidateRefForDebugger: debugger.
	record := MCPDebugSessionRegistry default
		          registerDebugSession: debugger session
		          named: 'Attach evolving debugger'
		          status: 'paused'
		          reason: 'attachedDebugger'.
	record
		debugger: debugger;
		debugSession: replacementDebugger session.

	result := self
		          callToolNamed: 'debug_candidate_attach'
		          withArguments: { (#candidateRef -> ref) } asDictionary.
	data := self dataFrom: result.
	session := data at: #session.

	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #alreadyAttached).
	self assert: (data at: #sessionId) equals: record sessionId.
	self assert: (session at: #sessionId) equals: record sessionId.
	self assert: record debugSession equals: replacementDebugger session
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsListsEmptyRegistry [

	| result data |
	result := self
		          callToolNamed: 'debug_session_list'
		          withArguments: Dictionary new.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #sessions) isEmpty
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsRemoveDoesNotTerminateAttachedDebuggerProcess [

	| attachData debugger ref removeData sessionId |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed:
		            'Remove attached continuation debugger'.
	ref := self candidateRefForDebugger: debugger.
	attachData := self dataFrom: (self
			               callToolNamed: 'debug_candidate_attach'
			               withArguments:
			               { (#candidateRef -> ref) } asDictionary).
	sessionId := attachData at: #sessionId.
	removeData := self dataFrom: (self
			               callToolNamed: 'debug_session_remove'
			               withArguments:
			               { (#sessionId -> sessionId) } asDictionary).
	self assert: (removeData at: #removed).
	self deny: (removeData at: #terminated)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsRemoveTerminatesCapturedSessionWorker [

	| data process record result sessionId |
	data := self dataFrom:
		        (self callToolNamed: 'debug_capture' withArguments: {
				         (#expression -> 'self error: ''remove cleanup boom''').
				         (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary).
	sessionId := data at: #sessionId.
	record := MCPDebugSessionRegistry default
		          sessionRecordAt: sessionId
		          ifAbsent: [
		          self fail: 'Captured session was not registered.' ].
	process := record debugSession process.
	self deny: process isTerminated.

	result := self
		          callToolNamed: 'debug_session_remove'
		          withArguments: { (#sessionId -> sessionId) } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #removed).
	self assert: (data at: #terminated).
	self assert: process isTerminated.
	self assert: MCPDebugSessionRegistry default size equals: 0
]

{ #category : 'tests - debugging sessions' }
MCPDebugToolContractTest >> testDebugSessionsRequestRejectsUnsupportedActionWithStructuredError [

	| error request |
	request := MCPToolRequest new
		           tool: MCPToolListDebugSessions new;
		           arguments: Dictionary new;
		           yourself.
	error := [
		         MCPDebugSessionsRequest
			         fromRequest: request
			         tool: request tool
			         operation: 'wat'.
		         nil ]
		         on: MCPCommandError
		         do: [ :caught | caught ].
	self deny: error isNil.
	self
		assert: error errorCode
		equals: #DebugSessionsOperationUnsupported.
	self assert: (error details at: #operation) equals: 'wat'.
	self assert:
		((error details at: #supportedOperations) includes: 'list')
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateOffersMissingMethodRepairAction [

	| action arguments data result state |
	result := self callToolNamed: 'debug_capture' withArguments: {
			          (#expression
			           ->
			           'MCPUpdateDebugMethodTestTarget new triggerMissingMethod').
			          (#name -> 'Captured missing method').
			          (#timeoutMilliseconds -> self debugSuccessTimeoutMilliseconds) } asDictionary.
	data := self dataFrom: result.
	state := data at: #state.
	action := (state at: #repairActions) first.
	arguments := action at: #arguments.
	self assert: (action at: #kind) equals: 'missingMethod'.
	self assert: (action at: #toolName) equals: 'debug_method_update'.
	self
		assert: (action at: #selector)
		equals: 'mcpDebugMethodUpdateGeneratedValue'.
	self
		assert: (action at: #targetClassName)
		equals: 'MCPUpdateDebugMethodTestTarget'.
	self deny: (action at: #requiresMethodSource).
	self assert: ((action at: #defaultMethodSource) includesSubstring:
			 'mcpDebugMethodUpdateGeneratedValue').
	self assert: (arguments at: #sessionId) equals: (data at: #sessionId).
	self assert: (arguments at: #stateId) equals: (data at: #stateId).
	self deny: (arguments includesKey: #targetClassName).
	self deny: (arguments includesKey: #classSide)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateRejectsForeignFrameRef [

	| error foreignRecord record result |
	record := self registerSyntheticSession.
	foreignRecord := self registerSyntheticSession.
	result := self callToolNamed: 'debug_state_get' withArguments: {
			          (#sessionId -> record sessionId).
			          (#frameRef
			           ->
			           (foreignRecord sessionId , '/' , foreignRecord stateId
			            , '/frame-0')) } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self
		assert: (error at: #errorCode)
		equals: 'DebugFrameReferenceInvalid'.
	self assert: (error at: #sessionId) equals: record sessionId.
	self
		assert: (error at: #referenceSessionId)
		equals: foreignRecord sessionId
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateRejectsMalformedFrameRef [

	| error record result |
	record := self registerSyntheticSession.
	result := self callToolNamed: 'debug_state_get' withArguments: {
			          (#sessionId -> record sessionId).
			          (#frameRef
			           ->
			           (record sessionId , '/' , record stateId , '/not-frame')) }
			          asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self
		assert: (error at: #errorCode)
		equals: 'DebugFrameReferenceInvalid'.
	self assert: ((error at: #frameRef) includesSubstring: 'not-frame')
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateRejectsStaleFrameRef [

	| record result error |
	record := self registerSyntheticSession.
	result := self callToolNamed: 'debug_state_get' withArguments: {
			          (#sessionId -> record sessionId).
			          (#frameRef -> (record sessionId , '/old-state/frame-0')) }
			          asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugStateStale'.
	self assert: (error at: #requestedStateId) equals: 'old-state'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateRejectsStaleStateId [

	| record result error |
	record := self registerSyntheticSession.
	result := self callToolNamed: 'debug_state_get' withArguments: {
			          (#sessionId -> record sessionId).
			          (#stateId -> 'old-state') } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugStateStale'.
	self assert: (error at: #currentStateId) equals: record stateId
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateReturnsCompositeSnapshotForRegisteredSession [

	| record result data |
	record := self registerSyntheticSession.
	result := self
		          callToolNamed: 'debug_state_get'
		          withArguments:
		          { (#sessionId -> record sessionId) } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #sessionId) equals: record sessionId.
	self assert: (data at: #stateId) equals: record stateId.
	self deny: (data at: #callStack) isEmpty.
	self deny: (data at: #scopes) isEmpty.
	self
		assert: ((data at: #selectedFrame) at: #frameRef)
		equals: record sessionId , '/' , record stateId , '/frame-0'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugTestRejectsUnsupportedStopAt [

	self
		should: [
				self callToolNamed: 'debug_test_run' withArguments: {
						(#className -> 'MCPDebugTestToolTarget').
						(#testMethodName -> 'debugTestPassingCase').
						(#stopAt -> 'aroundEach') } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugTestStopsAtSetUp [

	self assertDebugTestStopAt: 'setUp' selects: #setUp
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugTestStopsAtTearDown [

	self assertDebugTestStopAt: 'tearDown' selects: #tearDown
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugTestStopsAtTestMethodByDefault [

	self assertDebugTestStopAt: 'test' selects: #debugTestPassingCase
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugVariablesExpandsNestedChildReference [

	| record data selfVariable result child childResult |
	record := self registerSyntheticSession.
	data := self stateDataForRecord: record.
	selfVariable := self selfVariableFromStateData: data.
	result := self
		          callToolNamed: 'debug_variable_get'
		          withArguments:
		          { (#variableRef -> (selfVariable at: #variableRef)) }
			          asDictionary.
	child := self
		         variableNamed: 'testSelector'
		         inVariables: ((self dataFrom: result) at: #variables).
	childResult := self
		               callToolNamed: 'debug_variable_get'
		               withArguments:
		               { (#variableRef -> (child at: #variableRef)) }
			               asDictionary.
	self
		assert: ((self structuredContentFrom: childResult) at: #status)
		equals: 'ok'.
	self
		assert: ((self dataFrom: childResult) at: #kind)
		equals: 'variable'.
	self
		assert: ((self dataFrom: childResult) at: #printString)
		equals: '#testDebugVariablesExpandsNestedChildReference'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugVariablesExpandsReceiverScope [

	| record data receiverScope result variables |
	record := self registerSyntheticSession.
	data := self stateDataForRecord: record.
	receiverScope := self scopeNamed: 'receiver' inStateData: data.
	result := self
		          callToolNamed: 'debug_variable_get'
		          withArguments:
		          { (#variableRef -> (receiverScope at: #variableRef)) }
			          asDictionary.
	variables := (self dataFrom: result) at: #variables.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: ((self dataFrom: result) at: #kind) equals: 'scope'.
	self assert:
		(self variableNamed: 'self' inVariables: variables) notNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugVariablesExpandsSelfObjectChildren [

	| record data selfVariable result children |
	record := self registerSyntheticSession.
	data := self stateDataForRecord: record.
	selfVariable := self selfVariableFromStateData: data.
	result := self
		          callToolNamed: 'debug_variable_get'
		          withArguments:
		          { (#variableRef -> (selfVariable at: #variableRef)) }
			          asDictionary.
	children := (self dataFrom: result) at: #variables.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: ((self dataFrom: result) at: #kind) equals: 'variable'.
	self assert: ((self dataFrom: result) at: #hasChildren).
	self assert:
		(self variableNamed: 'testSelector' inVariables: children) notNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugVariablesHonorsVariableDepthZero [

	| record data selfVariable result |
	record := self registerSyntheticSession.
	data := self stateDataForRecord: record.
	selfVariable := self selfVariableFromStateData: data.
	result := self callToolNamed: 'debug_variable_get' withArguments: {
			          (#variableRef -> (selfVariable at: #variableRef)).
			          (#variableDepth -> 0) } asDictionary.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: ((self dataFrom: result) at: #hasChildren).
	self assert: ((self dataFrom: result) at: #variables) isEmpty.
	self assert: ((self dataFrom: result) at: #truncated)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugVariablesRejectsStaleVariableRef [

	| record result error |
	record := self registerSyntheticSession.
	result := self
		          callToolNamed: 'debug_variable_get'
		          withArguments: { (#variableRef
			           ->
			           (record sessionId
			            , '/old-state/frame-0/scope-receiver/var-self')) }
				          asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugStateStale'.
	self assert: (error at: #requestedStateId) equals: 'old-state'
]

{ #category : 'private' }
MCPDebugToolContractTest >> variableNamed: variableName inVariables: variables [

	^ variables detect: [ :each | (each at: #name) = variableName ]
]
