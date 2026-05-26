Class {
	#name : 'MCPDebugToolContractTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPDebugToolContractTest >> installDebugEditTemporaryStub [

	| source |
	source := String streamContents: [ :stream |
			          stream
				          nextPutAll: 'mcpDebugEditTemporaryStub';
				          cr;
				          cr;
				          tab;
				          nextPutAll: '^ self notYetImplemented' ].
	MCPDebugEditTestTarget compile: source classified: 'tests'
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
MCPDebugToolContractTest >> removeDebugEditTestMethods [

	#( #mcpDebugEditGeneratedValue #mcpDebugEditTemporaryStub ) do: [
			:selector |
			(MCPDebugEditTestTarget includesSelector: selector) ifTrue: [
				MCPDebugEditTestTarget removeSelector: selector ] ].
	Smalltalk globals
		removeKey: #MCPDebugEditProceedCounter
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
	MCPDebugSessionRegistry resetDefault.
	(Smalltalk globals includesKey: #MCPDebugBreakpointRegistry) ifTrue: [
		MCPDebugBreakpointRegistry resetDefault ].
	self removeDebugEditTestMethods
]

{ #category : 'private' }
MCPDebugToolContractTest >> stateDataForRecord: record [

	| result |
	result := self
		          callToolNamed: 'debug-state'
		          withArguments:
		          { (#sessionId -> record sessionId) } asDictionary.
	^ self dataFrom: result
]

{ #category : 'private' }
MCPDebugToolContractTest >> syntheticDebugSession [

	^ DebugSession
		  named: 'MCP synthetic debug session'
		  on: Processor activeProcess
		  startedAt: thisContext
]

{ #category : 'running' }
MCPDebugToolContractTest >> tearDown [

	(Smalltalk globals includesKey: #MCPDebugBreakpointRegistry) ifTrue: [
		MCPDebugBreakpointRegistry resetDefault ].
	self terminateCapturedSessions.
	self removeDebugEditTestMethods.
	MCPDebugSessionRegistry resetDefault.
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
			(record reason = 'capturedException' and: [
				 record debugSession notNil ]) ifTrue: [
					[ record debugSession terminate ]
						on: Error
						do: [ :ignored | nil ] ] ]
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugBreakpointsCanDisableAndEnableBreakpoint [

	| breakpointId data |
	data := self dataFrom:
		        (self callToolNamed: 'debug-breakpoints' withArguments: {
				         (#operation -> 'set').
				         (#className -> 'MCPDebugToolContractTest').
				         (#selector -> 'syntheticDebugSession') } asDictionary).
	breakpointId := data at: #breakpointId.

	data := self dataFrom:
		        (self callToolNamed: 'debug-breakpoints' withArguments: {
				         (#operation -> 'disable').
				         (#breakpointId -> breakpointId) } asDictionary).
	self deny: (data at: #enabled).

	data := self dataFrom:
		        (self callToolNamed: 'debug-breakpoints' withArguments: {
				         (#operation -> 'enable').
				         (#breakpointId -> breakpointId) } asDictionary).
	self assert: (data at: #enabled)
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugBreakpointsSetsListsAndRemovesMethodBreakpoint [

	| breakpointId data listData removeData result |
	result := self callToolNamed: 'debug-breakpoints' withArguments: {
			          (#operation -> 'set').
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
			             callToolNamed: 'debug-breakpoints'
			             withArguments: { (#operation -> 'list') } asDictionary).
	self assert: (listData at: #totalCount) equals: 1.
	self
		assert: ((listData at: #breakpoints) first at: #breakpointId)
		equals: breakpointId.

	removeData := self dataFrom:
		              (self
			               callToolNamed: 'debug-breakpoints'
			               withArguments: {
					               (#operation -> 'remove').
					               (#breakpointId -> breakpointId) } asDictionary).
	self assert: (removeData at: #removed).
	listData := self dataFrom: (self
			             callToolNamed: 'debug-breakpoints'
			             withArguments: { (#operation -> 'list') } asDictionary).
	self assert: (listData at: #totalCount) equals: 0
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugBreakpointsSupportsSourceIntervalTarget [

	| data source start stop |
	source := (MCPDebugToolContractTest >> #syntheticDebugSession)
		          sourceCode.
	start := source findString: 'thisContext'.
	stop := start + 'thisContext' size - 1.
	data := self dataFrom:
		        (self callToolNamed: 'debug-breakpoints' withArguments: {
				         (#operation -> 'set').
				         (#className -> 'MCPDebugToolContractTest').
				         (#selector -> 'syntheticDebugSession').
				         (#targetKind -> 'sourceInterval').
				         (#sourceStart -> start).
				         (#sourceStop -> stop) } asDictionary).
	self assert: (data at: #targetKind) equals: 'sourceInterval'.
	self assert: (data at: #sourceStart) equals: start.
	self assert: (data at: #sourceStop) equals: stop.
	self assert: (data at: #nodeClassName) equals: 'OCVariableNode'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureCapturesRuntimeExceptionAsDebugSession [

	| data exception result session sessionId state |
	result := self callToolNamed: 'debug-capture' withArguments: {
			          (#expression -> 'self error: ''debug-capture boom''').
			          (#name -> 'Captured runtime error').
			          (#timeoutMilliseconds -> 1000) } asDictionary.
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
		((exception at: #message) includesSubstring: 'debug-capture boom').
	self deny: (state at: #callStack) isEmpty.
	self deny: (state at: #selectedFrame) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureReportsSyntaxFailureWithoutSession [

	| error result |
	result := self callToolNamed: 'debug-capture' withArguments: {
			          (#expression -> '1 +').
			          (#timeoutMilliseconds -> 1000) } asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugCaptureSyntaxError'.
	self assert: (error at: #expression) equals: '1 +'.
	self assert: MCPDebugSessionRegistry default size equals: 0
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugCaptureReturnsCompletedResultWithoutSession [

	| data result |
	result := self callToolNamed: 'debug-capture' withArguments: {
			          (#expression -> '21 + 21').
			          (#timeoutMilliseconds -> 1000) } asDictionary.
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
	result := self callToolNamed: 'debug-capture' withArguments: {
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
	result := self callToolNamed: 'debug-control' withArguments: {
			          (#sessionId -> record sessionId).
			          (#operation -> 'stepOver').
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
	result := self callToolNamed: 'debug-control' withArguments: {
			          (#sessionId -> record sessionId).
			          (#frameRef -> (record sessionId , '/old-state/frame-0')).
			          (#operation -> 'stepInto') } asDictionary.
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
	result := self callToolNamed: 'debug-control' withArguments: {
			          (#sessionId -> record sessionId).
			          (#operation -> 'resume') } asDictionary.
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
	result := self callToolNamed: 'debug-control' withArguments: {
			          (#sessionId -> record sessionId).
			          (#stateId -> record stateId).
			          (#frameRef -> frameRef).
			          (#operation -> 'stepOver') } asDictionary.
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
MCPDebugToolContractTest >> testDebugEditCanIgnoreCritiquesAndProceed [

	| action arguments captureData editData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugEditProceedCounter put: ((Smalltalk at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPDebugEditTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug-capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured critique-ignored edit').
					                (#timeoutMilliseconds -> 1000) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugEditGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ self mcpDebugEditStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments
		at: #methodSource put: methodSource;
		at: #ignoreCritiques put: true.
	result := self callToolNamed: 'debug-edit' withArguments: arguments.
	editData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (editData at: #editKind) equals: 'missingMethod'.
	self assert: (editData at: #proceeded).
	self deny: (editData at: #blockedByCritiques).
	self deny: (editData at: #critiques) isEmpty.
	self assert: (editData at: #proceedOutcome) equals: 'paused'.
	self deny: (editData at: #state) isNil.
	self
		assert: ((editData at: #repairActions) first at: #selector)
		equals: 'mcpDebugEditStillMissing'.
	self
		assert:
		(Smalltalk globals at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEditCanProceedAfterPriorCritiqueBlockWithIgnoreCritiques [

	| action arguments blockedData captureData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugEditProceedCounter put: ((Smalltalk at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPDebugEditTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug-capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured two-step critique edit').
					                (#timeoutMilliseconds -> 1000) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugEditGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ self mcpDebugEditStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments at: #methodSource put: methodSource.
	blockedData := self dataFrom:
		               (self
			                callToolNamed: 'debug-edit'
			                withArguments: arguments).
	self assert: (blockedData at: #blockedByCritiques).
	arguments := {
		             (#sessionId -> (blockedData at: #sessionId)).
		             (#stateId -> (blockedData at: #stateId)).
		             (#frameRef -> (blockedData at: #frameRef)).
		             (#methodSource -> methodSource).
		             (#ignoreCritiques -> true) } asDictionary.
	result := self callToolNamed: 'debug-edit' withArguments: arguments.
	blockedData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (blockedData at: #proceeded).
	self deny: (blockedData at: #blockedByCritiques).
	self assert: (blockedData at: #proceedOutcome) equals: 'paused'.
	self
		assert: ((blockedData at: #repairActions) first at: #selector)
		equals: 'mcpDebugEditStillMissing'.
	self
		assert:
		(Smalltalk globals at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEditCreatesMissingMethodFromRepairAction [

	| action arguments captureData editData methodSource result state |
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug-capture'
			                withArguments: {
					                (#expression
					                 ->
					                 'MCPDebugEditTestTarget new triggerMissingMethod').
					                (#name -> 'Captured missing method edit').
					                (#timeoutMilliseconds -> 1000) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugEditGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ 42' ].
	arguments := (action at: #arguments) copy.
	arguments at: #methodSource put: methodSource.
	result := self callToolNamed: 'debug-edit' withArguments: arguments.
	editData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (editData at: #editKind) equals: 'missingMethod'.
	self assert: (editData at: #previousStateId) equals: 'state-0'.
	self assert: (editData at: #stateId) equals: 'state-2'.
	self assert: (editData at: #proceeded).
	self deny: (editData at: #blockedByCritiques).
	self assert: (editData at: #proceedOutcome) equals: 'completed'.
	self assert: (editData at: #resultPrintString) equals: '42'.
	self
		assert: ((editData at: #method) at: #selector)
		equals: 'mcpDebugEditGeneratedValue'.
	self
		assert: ((editData at: #method) at: #className)
		equals: 'MCPDebugEditTestTarget'.
	self
		assert:
		(MCPDebugEditTestTarget new perform: #mcpDebugEditGeneratedValue)
		equals: 42.
	self assert: (editData at: #state) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEditProceedsAfterCleanMissingMethodRepair [

	| action arguments captureData editData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugEditProceedCounter put: ((Smalltalk at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPDebugEditTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug-capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured missing method proceed').
					                (#timeoutMilliseconds -> 1000) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugEditGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ 42' ].
	arguments := (action at: #arguments) copy.
	arguments at: #methodSource put: methodSource.
	result := self callToolNamed: 'debug-edit' withArguments: arguments.
	editData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (editData at: #editKind) equals: 'missingMethod'.
	self assert: (editData at: #proceeded).
	self deny: (editData at: #blockedByCritiques).
	self assert: (editData at: #proceedOutcome) equals: 'completed'.
	self assert: (editData at: #resultClassName) equals: 'SmallInteger'.
	self assert: (editData at: #resultPrintString) equals: '42'.
	self
		assert:
		(Smalltalk globals at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEditRecompilesNotYetImplementedFrame [

	| action arguments captureData editData methodSource result state |
	self installDebugEditTemporaryStub.
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug-capture'
			                withArguments: {
					                (#expression
					                 ->
					                 'MCPDebugEditTestTarget new mcpDebugEditTemporaryStub').
					                (#name -> 'Captured not yet implemented edit').
					                (#timeoutMilliseconds -> 1000) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	self assert: (action at: #kind) equals: 'notYetImplemented'.
	self assert: (action at: #requiresMethodSource).
	self assert: ((action at: #defaultMethodSource) includesSubstring:
			 'notYetImplemented').
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugEditTemporaryStub';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ 43' ].
	arguments := (action at: #arguments) copy.
	arguments at: #methodSource put: methodSource.
	result := self callToolNamed: 'debug-edit' withArguments: arguments.
	editData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (editData at: #editKind) equals: 'notYetImplemented'.
	self assert: (editData at: #proceeded).
	self deny: (editData at: #blockedByCritiques).
	self assert: (editData at: #proceedOutcome) equals: 'completed'.
	self assert: (editData at: #resultPrintString) equals: '43'.
	self
		assert:
		(MCPDebugEditTestTarget new perform: #mcpDebugEditTemporaryStub)
		equals: 43.
	self
		assert: ((editData at: #method) at: #selector)
		equals: 'mcpDebugEditTemporaryStub'.
	self assert: (editData at: #state) isNil
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEditStopsBeforeProceedingWhenCritiquesAreReported [

	| action arguments captureData editData expression methodSource result state |
	expression := String streamContents: [ :stream |
			              stream
				              nextPutAll:
					              'Smalltalk at: #MCPDebugEditProceedCounter put: ((Smalltalk at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ]) + 1).';
				              cr;
				              nextPutAll:
					              'MCPDebugEditTestTarget new triggerMissingMethod' ].
	captureData := self dataFrom:
		               (self
			                callToolNamed: 'debug-capture'
			                withArguments: {
					                (#expression -> expression).
					                (#name -> 'Captured critique-blocked edit').
					                (#timeoutMilliseconds -> 1000) } asDictionary).
	state := captureData at: #state.
	action := (state at: #repairActions) first.
	methodSource := String streamContents: [ :stream |
			                stream
				                nextPutAll: 'mcpDebugEditGeneratedValue';
				                cr;
				                cr;
				                tab;
				                nextPutAll: '^ self mcpDebugEditStillMissing' ].
	arguments := (action at: #arguments) copy.
	arguments at: #methodSource put: methodSource.
	result := self callToolNamed: 'debug-edit' withArguments: arguments.
	editData := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (editData at: #editKind) equals: 'missingMethod'.
	self deny: (editData at: #proceeded).
	self assert: (editData at: #blockedByCritiques).
	self
		assert: (editData at: #proceedOutcome)
		equals: 'blockedByCritiques'.
	self deny: (editData at: #critiques) isEmpty.
	self
		assert:
		(Smalltalk globals at: #MCPDebugEditProceedCounter ifAbsent: [ 0 ])
		equals: 1
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateEvaluatesExpressionInSelectedFrame [

	| record stateData frameRef result data |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self callToolNamed: 'debug-evaluate' withArguments: {
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
	result := self callToolNamed: 'debug-evaluate' withArguments: {
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
	result := self callToolNamed: 'debug-evaluate' withArguments: {
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
	result := self callToolNamed: 'debug-evaluate' withArguments: {
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
	result := self callToolNamed: 'debug-evaluate' withArguments: {
			          (#sessionId -> record sessionId).
			          (#frameRef -> frameRef).
			          (#expression -> 'self error: ''debug-evaluate boom''') }
			          asDictionary.
	error := self errorFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'error'.
	self assert: (error at: #errorCode) equals: 'DebugEvaluationFailed'.
	self
		assert: (error at: #expression)
		equals: 'self error: ''debug-evaluate boom'''
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugEvaluateReportsSyntaxFailure [

	| record stateData frameRef result error |
	record := self registerSyntheticSession.
	stateData := self stateDataForRecord: record.
	frameRef := (stateData at: #selectedFrame) at: #frameRef.
	result := self callToolNamed: 'debug-evaluate' withArguments: {
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
MCPDebugToolContractTest >> testDebugSessionsDescribeRegisteredSession [

	| record result data session |
	record := self registerSyntheticSession.
	result := self callToolNamed: 'debug-sessions' withArguments: {
			          (#operation -> 'describe').
			          (#sessionId -> record sessionId) } asDictionary.
	data := self dataFrom: result.
	session := data at: #session.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (session at: #sessionId) equals: record sessionId.
	self assert: (session at: #status) equals: 'paused'
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsForgetTerminatesCapturedSessionWorker [

	| data process record result sessionId |
	data := self dataFrom:
		        (self callToolNamed: 'debug-capture' withArguments: {
				         (#expression -> 'self error: ''forget cleanup boom''').
				         (#timeoutMilliseconds -> 1000) } asDictionary).
	sessionId := data at: #sessionId.
	record := MCPDebugSessionRegistry default
		          sessionRecordAt: sessionId
		          ifAbsent: [
		          self fail: 'Captured session was not registered.' ].
	process := record debugSession process.
	self deny: process isTerminated.

	result := self callToolNamed: 'debug-sessions' withArguments: {
			          (#operation -> 'forget').
			          (#sessionId -> sessionId) } asDictionary.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #forgotten).
	self assert: (data at: #terminated).
	self assert: process isTerminated.
	self assert: MCPDebugSessionRegistry default size equals: 0
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsListsEmptyRegistry [

	| result data |
	result := self
		          callToolNamed: 'debug-sessions'
		          withArguments: Dictionary new.
	data := self dataFrom: result.
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #sessions) isEmpty
]

{ #category : 'tests' }
MCPDebugToolContractTest >> testDebugSessionsRequestRejectsUnsupportedOperationWithStructuredError [

	| error request |
	request := MCPToolRequest new
		           tool: MCPToolDebugSessions new;
		           arguments: { (#operation -> 'wat') } asDictionary;
		           yourself.
	error := [
		         MCPDebugSessionsRequest
			         fromRequest: request
			         tool: request tool.
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
	result := self callToolNamed: 'debug-capture' withArguments: {
			          (#expression
			           -> 'MCPDebugEditTestTarget new triggerMissingMethod').
			          (#name -> 'Captured missing method').
			          (#timeoutMilliseconds -> 1000) } asDictionary.
	data := self dataFrom: result.
	state := data at: #state.
	action := (state at: #repairActions) first.
	arguments := action at: #arguments.
	self assert: (action at: #kind) equals: 'missingMethod'.
	self assert: (action at: #toolName) equals: 'debug-edit'.
	self
		assert: (action at: #selector)
		equals: 'mcpDebugEditGeneratedValue'.
	self
		assert: (action at: #targetClassName)
		equals: 'MCPDebugEditTestTarget'.
	self deny: (action at: #requiresMethodSource).
	self assert: ((action at: #defaultMethodSource) includesSubstring:
			 'mcpDebugEditGeneratedValue').
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
	result := self callToolNamed: 'debug-state' withArguments: {
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
	result := self callToolNamed: 'debug-state' withArguments: {
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
	result := self callToolNamed: 'debug-state' withArguments: {
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
	result := self callToolNamed: 'debug-state' withArguments: {
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
		          callToolNamed: 'debug-state'
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
MCPDebugToolContractTest >> testDebugVariablesExpandsNestedChildReference [

	| record data selfVariable result child childResult |
	record := self registerSyntheticSession.
	data := self stateDataForRecord: record.
	selfVariable := self selfVariableFromStateData: data.
	result := self
		          callToolNamed: 'debug-variables'
		          withArguments:
		          { (#variableRef -> (selfVariable at: #variableRef)) }
			          asDictionary.
	child := self
		         variableNamed: 'testSelector'
		         inVariables: ((self dataFrom: result) at: #variables).
	childResult := self
		               callToolNamed: 'debug-variables'
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
		          callToolNamed: 'debug-variables'
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
		          callToolNamed: 'debug-variables'
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
	result := self callToolNamed: 'debug-variables' withArguments: {
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
		          callToolNamed: 'debug-variables'
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
