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
MCPDebugToolContractTest >> candidateRefForDebugger: aDebugger [

	^ 'debugger-candidate-' , aDebugger identityHash asString
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
		  registerDebugSession: (MCPDebugControlTestSession withContext: thisContext)
		  named: 'Synthetic control debug session'
		  status: 'paused'
		  reason: 'halt'
]

{ #category : 'private' }
MCPDebugToolContractTest >> registerSuspendedSessionEvaluating: anExpression named: aName [
	"A session that can be proceeded needs a worker genuinely stopped at its own error, which a
	synthetic session on the running process cannot be. It carries no debugger: driving a real
	StDebugger's action model needs the UI this test does not have."

	| semaphore session worker |
	semaphore := Semaphore new.
	worker := [
	          [ Smalltalk compiler evaluate: anExpression ]
		          on: Exception
		          do: [ :error |
				          session := DebugSession named: aName on: Processor activeProcess startedAt: error signalerContext.
				          session exception: error.
				          semaphore signal.
				          Processor activeProcess suspend ] ] newProcess.
	worker resume.
	semaphore wait.
	^ MCPDebugSessionRegistry default
		  registerDebugSession: session
		  named: aName
		  status: 'paused'
		  reason: 'capturedException'
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

	#( #mcpDebugMethodUpdateGeneratedValue #mcpDebugMethodUpdateTemporaryStub ) do: [ :selector |
		(MCPUpdateDebugMethodTestTarget includesSelector: selector) ifTrue: [ MCPUpdateDebugMethodTestTarget removeSelector: selector ] ].
	Smalltalk globals removeKey: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ nil ]
]

{ #category : 'private' }
MCPDebugToolContractTest >> scopeNamed: scopeName inStateData: data [

	^ (data at: #scopes) detect: [ :each | (each at: #kind) = scopeName ]
]

{ #category : 'private' }
MCPDebugToolContractTest >> selfVariableFromStateData: data [

	| receiverScope |
	receiverScope := self scopeNamed: 'receiver' inStateData: data.
	^ self variableNamed: 'self' inVariables: (receiverScope at: #variables)
]

{ #category : 'running' }
MCPDebugToolContractTest >> setUp [

	super setUp.
	MCPDebugAttachedDebuggerSelectionStrategy reset.
	MCPDebugSessionRegistry resetDefault.
	self removeDebugMethodUpdateTestMethods
]

{ #category : 'private' }
MCPDebugToolContractTest >> stateDataForRecord: record [

	| result |
	result := self callToolNamed: 'debug_session' withArguments: { (#session -> record sessionId) } asDictionary.
	^ self dataFrom: result
]

{ #category : 'private' }
MCPDebugToolContractTest >> syntheticDebugSession [

	^ DebugSession named: 'MCP synthetic debug session' on: Processor activeProcess startedAt: thisContext
]

{ #category : 'private' }
MCPDebugToolContractTest >> syntheticDebuggerNamed: aString [

	| exception session |
	exception := (OupsNullException fromSignallerContext: thisContext)
		             messageText: aString;
		             yourself.
	session := (DebugSession named: aString on: Processor activeProcess startedAt: thisContext)
		           exception: exception;
		           yourself.
	^ StDebugger on: session
]

{ #category : 'running' }
MCPDebugToolContractTest >> tearDown [

	self terminateCapturedSessions.
	self removeDebugMethodUpdateTestMethods.
	MCPDebugSessionRegistry resetDefault.
	MCPDebugAttachedDebuggerSelectionStrategy reset.
	super tearDown
]

{ #category : 'private' }
MCPDebugToolContractTest >> terminateCapturedSessions [

	(Smalltalk globals includesKey: #MCPDebugSessionRegistry) ifFalse: [ ^ self ].
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
		                   ifAbsent: [ self fail: 'Missing attached debugger controller.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [ self fail: 'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed: 'Attached controller debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	continuation := continuationClass debugger: debugger timeoutMilliseconds: 25 resultPreviewCharacterLimit: 1000.
	controller := continuation debugControllerForSession: session.
	self assert: controller class equals: controllerClass.
	self assert: controller debugSession equals: session
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedContinuationBuildsSessionControllerForUnownedSession [

	| continuation continuationClass controller controllerClass debugger replacementSession session |
	controllerClass := Smalltalk globals at: #MCPDebugSessionController ifAbsent: [ self fail: 'Missing session controller.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [ self fail: 'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed: 'Attached controller visible debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	replacementSession := (self syntheticDebuggerNamed: 'Attached controller replacement session') session.
	continuation := continuationClass debugger: debugger timeoutMilliseconds: 25 resultPreviewCharacterLimit: 1000.
	controller := continuation debugControllerForSession: replacementSession.
	self assert: controller class equals: controllerClass.
	self assert: controller debugSession equals: replacementSession
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedContinuationDefersRestartThroughDebuggerActionModel [

	| context continuation continuationClass controller debugger session |
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [ self fail: 'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed: 'Deferred attached restart debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	continuation := continuationClass debugger: debugger timeoutMilliseconds: 25 resultPreviewCharacterLimit: 1000.
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
		                     ifAbsent: [ self fail: 'Missing attached debugger continuation.' ].
	session := (self syntheticDebuggerNamed: 'Deferred attached proceed debugger') session.
	debugger := MCPDebugDeferredDebuggerStub new session: session.
	continuation := continuationClass debugger: debugger timeoutMilliseconds: 25 resultPreviewCharacterLimit: 1000.
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
		                     ifAbsent: [ self fail: 'Missing attached debugger continuation.' ].
	debugger := self syntheticDebuggerNamed: 'Attached continuation visible debugger'.
	continuation := continuationClass debugger: debugger timeoutMilliseconds: 25 resultPreviewCharacterLimit: 1000.
	self assert: continuation shouldProceedUsingAttachedDebugger.
	replacementSession := (self syntheticDebuggerNamed: 'Attached continuation replacement session') session.
	continuation debugSession: replacementSession.
	self deny: continuation shouldProceedUsingAttachedDebugger
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedDebuggerSelectionStrategyCapturesSoleContinuationWhenProcessChanges [

	| continuation continuationClass debugger debuggerCount exception newProcess newSession strategyClass |
	strategyClass := Smalltalk globals
		                 at: #MCPDebugAttachedDebuggerSelectionStrategy
		                 ifAbsent: [ self fail: 'Missing attached debugger selection strategy.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [ self fail: 'Missing attached debugger continuation.' ].
	strategyClass reset.
	debugger := self syntheticDebuggerNamed: 'Attached original process debugger'.
	continuation := continuationClass debugger: debugger timeoutMilliseconds: 25 resultPreviewCharacterLimit: 1000.
	newProcess := [ nil ] newProcess.
	exception := (OupsNullException fromSignallerContext: thisContext)
		             messageText: 'Attached different process session';
		             yourself.
	newSession := (DebugSession named: 'Attached different process session' on: newProcess startedAt: thisContext)
		              exception: exception;
		              yourself.
	debuggerCount := StDebugger allInstances size.
	strategyClass activate: continuation during: [ (strategyClass with: { StDebugger } asArray) openDebuggerForSession: newSession ].
	self assert: continuation capturedDebugSession equals: newSession.
	self assert: continuation currentStatus equals: #captured.
	self assert: StDebugger allInstances size equals: debuggerCount
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testAttachedDebuggerSelectionStrategyReusesAttachedDebugger [

	| activeCount continuation continuationClass debugger debuggerCount newSession originalSession previousStrategy strategyClass |
	strategyClass := Smalltalk globals
		                 at: #MCPDebugAttachedDebuggerSelectionStrategy
		                 ifAbsent: [ self fail: 'Missing attached debugger selection strategy.' ].
	continuationClass := Smalltalk globals
		                     at: #MCPDebugAttachedContinuation
		                     ifAbsent: [ self fail: 'Missing attached debugger continuation.' ].
	strategyClass reset.
	previousStrategy := OupsDebuggerSelectionStrategy debuggerSelectionStrategy.
	activeCount := strategyClass activeContinuations size.
	debugger := self syntheticDebuggerNamed: 'Attached strategy debugger'.
	originalSession := debugger session.
	continuation := continuationClass debugger: debugger timeoutMilliseconds: 25 resultPreviewCharacterLimit: 1000.
	newSession := (self syntheticDebuggerNamed: 'Attached replacement session') session.
	debuggerCount := StDebugger allInstances size.
	strategyClass activate: continuation during: [ (strategyClass with: { StDebugger } asArray) openDebuggerForSession: newSession ].
	self assert: debugger session equals: originalSession.
	self assert: continuation debugSession equals: newSession.
	self assert: continuation capturedDebugSession equals: newSession.
	self assert: continuation currentStatus equals: #captured.
	self assert: StDebugger allInstances size equals: debuggerCount.
	self assert: OupsDebuggerSelectionStrategy debuggerSelectionStrategy equals: previousStrategy.
	self assert: strategyClass activeContinuations size equals: activeCount
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCandidateAttachRegistersCandidateFromSearch [

	| data debugger ref result searchData |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed: 'Attachable human debugger'.
	ref := self candidateRefForDebugger: debugger.
	searchData := self dataFrom: (self callToolNamed: 'debug_session' withArguments: Dictionary new).
	self assert: ((searchData at: #candidates) anySatisfy: [ :each | (each at: #candidateRef) = ref ]).

	result := self callToolNamed: 'debug_session' withArguments: { (#session -> ref) } asDictionary.
	data := self dataFrom: result.

	self deny: (self resultIndicatesError: result).
	self
		assert: (MCPDebugSessionRegistry default
				 sessionRecordAt: (data at: #sessionId)
				 ifAbsent: [ self fail: 'Attached session was not registered.' ]) debugSession
		equals: debugger session.
	"Naming the session it was given attaches nothing further and answers the same state."
	self
		assert: ((self dataFrom: (self callToolNamed: 'debug_session' withArguments: { (#session -> (data at: #sessionId)) } asDictionary))
				 at: #sessionId)
		equals: (data at: #sessionId)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCandidateSearchReturnsUnattachedDebuggerCandidates [

	| candidates data newer newerRef older olderRef refs result |
	Smalltalk garbageCollect.
	older := self syntheticDebuggerNamed: 'Older human debugger'.
	newer := self syntheticDebuggerNamed: 'Newer human debugger'.
	olderRef := self candidateRefForDebugger: older.
	newerRef := self candidateRefForDebugger: newer.

	result := self callToolNamed: 'debug_session' withArguments: Dictionary new.
	data := self dataFrom: result.
	candidates := data at: #candidates.
	refs := candidates collect: [ :each | each at: #candidateRef ].

	self deny: (self resultIndicatesError: result).
	self assert: (refs includes: olderRef).
	self assert: (refs includes: newerRef).
	self
		assert: ((candidates detect: [ :each | (each at: #candidateRef) = newerRef ]) at: #sessionName)
		equals: 'Newer human debugger'.
	self assert: ((candidates detect: [ :each | (each at: #candidateRef) = newerRef ]) includesKey: #topFrame)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCandidateSearchSkipsAlreadyRegisteredDebuggers [

	| candidates data debugger ref refs result |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed: 'Already attached human debugger'.
	ref := self candidateRefForDebugger: debugger.
	MCPDebugSessionRegistry default
		registerDebugSession: debugger session
		named: 'Already attached human debugger'
		status: 'paused'
		reason: 'attachedDebugger'.

	result := self callToolNamed: 'debug_session' withArguments: Dictionary new.
	data := self dataFrom: result.
	candidates := data at: #candidates.
	refs := candidates collect: [ :each | each at: #candidateRef ].

	self deny: (self resultIndicatesError: result).
	self deny: (refs includes: ref)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateEvaluatesExpressionInSelectedFrame [

	| record stateData frameRef result data |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self callToolNamed: 'image_evaluate' withArguments: {
			          (#frame -> frameRef).
			          (#code -> 'self class name') } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #frameRef) equals: frameRef.
	self assert: (data at: #resultClassName) equals: 'ByteSymbol'.
	self assert: (data at: #resultPrintString) equals: '#MCPDebugToolContractTest'.
	self deny: (data at: #hasResultVariableRef)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateReadsTemporaryInSelectedFrame [

	| frameRef marker record result stateData data |
	marker := 41.
	record := MCPDebugSessionRegistry default
		          registerDebugSession:
		          (DebugSession named: 'MCP active temporary debug session' on: Processor activeProcess startedAt: thisContext)
		          named: 'Synthetic active temporary debug session'
		          status: 'paused'
		          reason: 'halt'.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self callToolNamed: 'image_evaluate' withArguments: {
			          (#frame -> frameRef).
			          (#code -> 'marker + 1') } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #resultClassName) equals: 'SmallInteger'.
	self assert: (data at: #resultPrintString) equals: '42'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateReportsRuntimeFailure [

	| record stateData frameRef result error |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self callToolNamed: 'image_evaluate' withArguments: {
			          (#frame -> frameRef).
			          (#code -> 'self error: ''frame evaluate boom''') } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'DebugEvaluationFailed'.
	self assert: (error at: #expression) equals: 'self error: ''frame evaluate boom'''
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateReportsSyntaxFailure [

	| record stateData frameRef result error |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self callToolNamed: 'image_evaluate' withArguments: {
			          (#frame -> frameRef).
			          (#code -> '1 +') } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'DebugEvaluationSyntaxError'.
	self assert: (error at: #expression) equals: '1 +'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateCanIgnoreCritiquesAndProceed [

	| action arguments record updateData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugMethodUpdateProceedCounter put: ((Smalltalk at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll: 'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' ].
	record := self registerSuspendedSessionEvaluating: expression named: 'Captured critique-ignored update'.
	state := self stateDataForRecord: record.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ self mcpDebugMethodUpdateStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments
		at: #source put: methodSource;
		at: #force put: true.
	result := self callToolNamed: 'method_compile' withArguments: arguments.
	updateData := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self deny: (updateData at: #critiques) isEmpty.
	self assert: (updateData at: #proceedOutcome) equals: 'running'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateCreatesMissingMethodFromRepairAction [

	| action arguments record generatedValue updateData expectedSource methodSource result state |
	record := self registerSuspendedSessionEvaluating: 'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' named: 'Captured missing method update'.
	state := self stateDataForRecord: record.
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
	result := self callToolNamed: 'method_compile' withArguments: arguments.
	updateData := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self assert: (updateData at: #previousStateId) equals: 'state-0'.
	self assert: (updateData at: #stateId) equals: 'state-2'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self assert: (updateData at: #proceedOutcome) equals: 'running'.
	self assert: ((updateData at: #method) at: #selector) equals: 'mcpDebugMethodUpdateGeneratedValue'.
	self assert: ((updateData at: #method) at: #className) equals: 'MCPUpdateDebugMethodTestTarget'.
	self assert: ((updateData at: #method) at: #source) equals: expectedSource.
	generatedValue := MCPUpdateDebugMethodTestTarget new mcpDebugMethodUpdateGeneratedValue.
	self assert: generatedValue equals: 42.
	self assert: (updateData at: #state) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateProceedsAfterCleanMissingMethodRepair [

	| action arguments record updateData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugMethodUpdateProceedCounter put: ((Smalltalk at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll: 'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' ].
	record := self registerSuspendedSessionEvaluating: expression named: 'Captured missing method proceed'.
	state := self stateDataForRecord: record.
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
	result := self callToolNamed: 'method_compile' withArguments: arguments.
	updateData := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self assert: (updateData at: #proceedOutcome) equals: 'running'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateRecompilesNotYetImplementedFrame [

	| action arguments record generatedValue updateData expectedSource methodSource result state |
	self installDebugMethodUpdateTemporaryStub.
	record := self registerSuspendedSessionEvaluating: 'MCPUpdateDebugMethodTestTarget new mcpDebugMethodUpdateTemporaryStub' named: 'Captured not yet implemented update'.
	state := self stateDataForRecord: record.
	action := (state at: #repairActions) first.
	self assert: (action at: #kind) equals: 'notYetImplemented'.
	self assert: (action at: #requiresMethodSource).
	self assert: ((action at: #defaultMethodSource) includesSubstring: 'notYetImplemented').
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
	result := self callToolNamed: 'method_compile' withArguments: arguments.
	updateData := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (updateData at: #updateKind) equals: 'notYetImplemented'.
	self assert: (updateData at: #proceeded).
	self deny: (updateData at: #blockedByCritiques).
	self assert: (updateData at: #proceedOutcome) equals: 'running'.
	generatedValue := MCPUpdateDebugMethodTestTarget new mcpDebugMethodUpdateTemporaryStub.
	self assert: generatedValue equals: 43.
	self assert: ((updateData at: #method) at: #selector) equals: 'mcpDebugMethodUpdateTemporaryStub'.
	self assert: ((updateData at: #method) at: #source) equals: expectedSource.
	self assert: (updateData at: #state) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testFrameRepairRequestNormalizesMethodSourceLineFeeds [

	| parsedRequest source tool |
	source := 'mcpDebugNormalizedSource' , String lf , '^ ''line one' , String lf , 'line two'''.
	tool := MCPToolCompileMethod new.
	parsedRequest := self parsedRequestForTool: tool arguments: {
			                 (#frame -> 'debug-session-1/state-0/frame-0').
			                 (#source -> source) } asDictionary.
	self deny: (parsedRequest methodSource includes: Character lf).
	self assert: (parsedRequest methodSource includes: Character cr)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugMethodUpdateStopsBeforeProceedingWhenCritiquesAreReported [

	| action arguments record updateData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugMethodUpdateProceedCounter put: ((Smalltalk at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll: 'MCPUpdateDebugMethodTestTarget new triggerMissingMethod' ].
	record := self registerSuspendedSessionEvaluating: expression named: 'Captured critique-blocked update'.
	state := self stateDataForRecord: record.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugMethodUpdateGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ self mcpDebugMethodUpdateStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments at: #source put: methodSource.
	result := self callToolNamed: 'method_compile' withArguments: arguments.
	updateData := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (updateData at: #updateKind) equals: 'missingMethod'.
	self deny: (updateData at: #proceeded).
	self assert: (updateData at: #blockedByCritiques).
	self assert: (updateData at: #proceedOutcome) equals: 'blockedByCritiques'.
	self deny: (updateData at: #critiques) isEmpty.
	self assert: (Smalltalk globals at: #MCPDebugMethodUpdateProceedCounter ifAbsent: [ 0 ]) equals: 1
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

	| data debugger record ref |
	Smalltalk garbageCollect.
	debugger := self syntheticDebuggerNamed: 'Attachable continuation debugger'.
	ref := self candidateRefForDebugger: debugger.
	data := self dataFrom: (self callToolNamed: 'debug_session' withArguments: { (#session -> ref) } asDictionary).
	record := MCPDebugSessionRegistry default
		          sessionRecordAt: (data at: #sessionId)
		          ifAbsent: [ self fail: 'Attached session was not registered.' ].
	self assert: record continuation notNil.
	self assert: record continuation class name equals: #MCPDebugAttachedContinuation.
	self assert: record continuation debugger equals: debugger.
	self assert: record continuation timeoutMilliseconds equals: 2000
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsAttachRejectsUnknownCandidateRef [

	| error result |
	result := self
		          callToolNamed: 'debug_session'
		          withArguments: { (#session -> 'debugger-candidate-missing') } asDictionary.
	error := self errorFrom: result.
	self assert: (self resultIndicatesError: result).
	self assert: (error at: #errorCode) equals: 'DebugSessionCandidateNotFound'.
	self assert: (error at: #candidateRef) equals: 'debugger-candidate-missing'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsListsEmptyRegistry [

	| result data |
	result := self callToolNamed: 'debug_session' withArguments: Dictionary new.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #sessions) isEmpty
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateOffersMissingMethodRepairAction [

	| action arguments record state |
	record := self
		          registerSuspendedSessionEvaluating: 'MCPUpdateDebugMethodTestTarget new triggerMissingMethod'
		          named: 'Captured missing method'.
	state := self stateDataForRecord: record.
	action := (state at: #repairActions) first.
	arguments := action at: #arguments.
	self assert: (action at: #kind) equals: 'missingMethod'.
	self assert: (action at: #toolName) equals: 'method_compile'.
	self assert: (action at: #selector) equals: 'mcpDebugMethodUpdateGeneratedValue'.
	self assert: (action at: #targetClassName) equals: 'MCPUpdateDebugMethodTestTarget'.
	self deny: (action at: #requiresMethodSource).
	self assert: ((action at: #defaultMethodSource) includesSubstring: 'mcpDebugMethodUpdateGeneratedValue').
	self assert: ((arguments at: #frame) beginsWith: record sessionId).
	self deny: (arguments includesKey: #sessionId).
	self deny: (arguments includesKey: #targetClassName).
	self deny: (arguments includesKey: #classSide)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugStateReturnsCompositeSnapshotForRegisteredSession [

	| record result data |
	record := self registerSyntheticSession.
	result := self callToolNamed: 'debug_session' withArguments: { (#session -> record sessionId) } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #sessionId) equals: record sessionId.
	self assert: (data at: #stateId) equals: record stateId.
	self deny: (data at: #callStack) isEmpty.
	self deny: (data at: #scopes) isEmpty.
	self assert: ((data at: #selectedFrame) at: #frameRef) equals: record sessionId , '/' , record stateId , '/frame-0'
]

{ #category : 'private' }
MCPDebugToolContractTest >> variableNamed: variableName inVariables: variables [

	^ variables detect: [ :each | (each at: #name) = variableName ]
]
