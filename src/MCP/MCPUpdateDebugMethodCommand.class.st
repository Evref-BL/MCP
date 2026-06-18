"
Creates or hot-recompiles a method from the current debugger frame.

It supports debugger-driven development by deriving repair targets, compiling with critique feedback, and proceeding the paused computation when the update is accepted.
"
Class {
	#name : 'MCPUpdateDebugMethodCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - actions' }
MCPUpdateDebugMethodCommand >> analyzerForRecord: aRecord [

	^ MCPDebugRepairAnalyzer fromRecord: aRecord request: request
]

{ #category : 'private - data' }
MCPUpdateDebugMethodCommand >> capabilities [

	^ {
		  (#methodCreation -> true).
		  (#methodRecompile -> true).
		  (#stateRefresh -> true).
		  (#methodCritiques -> true).
		  (#critiqueGate -> true).
		  (#autoProceed -> true).
		  (#mutating -> true) } asDictionary
]

{ #category : 'private - methods' }
MCPUpdateDebugMethodCommand >> classNameForBehavior: aBehavior [

	aBehavior ifNil: [ ^ nil ].
	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name asString ]
		  ifFalse: [ aBehavior name asString ]
]

{ #category : 'private - methods' }
MCPUpdateDebugMethodCommand >> classSideForBehavior: aBehavior [

	aBehavior ifNil: [ ^ false ].
	^ aBehavior isMeta
]

{ #category : 'private - compiling' }
MCPUpdateDebugMethodCommand >> compileForRecord: aRecord context: aContext updateKind: updateKind [

	(#( 'missingMethod' 'subclassResponsibility' ) includes: updateKind)
		ifTrue: [
				^ self
					  compileImplementationForRecord: aRecord
					  context: aContext
					  updateKind: updateKind ].
	(#( 'recompile' 'shouldBeImplemented' 'notYetImplemented' )
		 includes: updateKind) ifTrue: [
		^ self recompileContext: aContext record: aRecord updateKind: updateKind ].
	^ self signalUnsupportedUpdateForRecord: aRecord updateKind: updateKind
]

{ #category : 'private - compiling' }
MCPUpdateDebugMethodCommand >> compileImplementationForRecord: aRecord context: aContext updateKind: updateKind [

	| analyzer behavior details message source |
	analyzer := self analyzerForRecord: aRecord.
	message := analyzer
		           messageForException: analyzer exception
		           context: aContext.
	message ifNil: [
		^ self
			  signalUnsupportedUpdateForRecord: aRecord
			  updateKind: updateKind ].
	behavior := analyzer behaviorForContext: aContext.
	source := self methodSourceOrNil ifNil: [
		          analyzer
			          defaultSourceForMessage: message
			          behavior: behavior ].
	source ifNil: [
			^ self
				  signalRequiredMethodSourceForRecord: aRecord
				  frameIndex:
				  (self frameIndexForContext: aContext record: aRecord fallback: 0)
				  updateKind: updateKind ].
	details := {
		           (#source -> source).
		           (#behavior -> behavior).
		           (#expectedSelector -> message selector).
		           (#context -> aContext).
		           (#message -> message).
		           (#record -> aRecord).
		           (#updateKind -> updateKind) } asDictionary.
	^ self compileSourceUsing: details
]

{ #category : 'private - compiling' }
MCPUpdateDebugMethodCommand >> compileSourceUsing: details [

	| actualSelector behavior context expectedSelector message method record selectorDetails source |
	record := details at: #record.
	behavior := details at: #behavior.
	behavior ifNil: [
			^ self
				  signalUnsupportedUpdateForRecord: record
				  updateKind: (details at: #updateKind) ].
	expectedSelector := details at: #expectedSelector.
	source := (details at: #source) withInternalLineEndings.
	actualSelector := behavior compile: source.
	actualSelector = expectedSelector ifFalse: [
			selectorDetails := {
				                   (#sessionId -> record sessionId).
				                   (#stateId -> record stateId).
				                   (#updateKind -> (details at: #updateKind)).
				                   (#expectedSelector -> expectedSelector asString).
				                   (#actualSelector -> actualSelector asString).
				                   (#targetClassName
				                    -> (self classNameForBehavior: behavior)).
				                   (#classSide
				                    -> (self classSideForBehavior: behavior)) }
				                   asDictionary.
			^ self signalSelectorMismatchWithDetails: selectorDetails ].
	method := self
		          formattedMethodForBehavior: behavior
		          selector: actualSelector.
	MethodClassifier classify: method.
	context := details at: #context.
	message := details at: #message.
	context privRefreshWith: method.
	context method numArgs > 0 ifTrue: [
			message arguments withIndexDo: [ :argument :index |
				context tempAt: index put: argument ] ].
	record debugSession
		updateContextTo: context;
		contextChanged.
	self prepareInterruptedProcessForContext: context record: record.
	^ method
]

{ #category : 'private - methods' }
MCPUpdateDebugMethodCommand >> compiledMethodForContext: aContext [

	^ aContext method methodClass lookupSelector: aContext selector
]

{ #category : 'private - data' }
MCPUpdateDebugMethodCommand >> critiqueDataForMethod: aCompiledMethod [

	^ MCPToolCreateMethod new critiqueDataForMethod: aCompiledMethod

]

{ #category : 'executing' }
MCPUpdateDebugMethodCommand >> execute [

	| compiledMethod context critiques data updateKind frameIndex frameRef previousStateId proceedData record resultDetails selectedContext |
	record := self sessionRecordWithMatchingState.
	previousStateId := record stateId.
	frameIndex := self selectedFrameIndex.
	selectedContext := self
		                   selectedContextForRecord: record
		                   frameIndex: frameIndex.
	updateKind := self updateKindForRecord: record.
	context := self
		           updateContextForRecord: record
		           selectedContext: selectedContext
		           updateKind: updateKind.
	frameIndex := self
		              frameIndexForContext: context
		              record: record
		              fallback: frameIndex.
	compiledMethod := self
		                  compileForRecord: record
		                  context: context
		                  updateKind: updateKind.
	record advanceStateForStatus: 'paused' reason: 'debugMethodUpdate'.
	frameRef := self frameRefForRecord: record frameIndex: frameIndex.
	critiques := self critiqueDataForMethod: compiledMethod.
	proceedData := (self shouldBlockProceedForCritiques: critiques)
		               ifTrue: [ self proceedDataBlockedByCritiques ]
		               ifFalse: [
		               self proceedAfterMethodUpdateForRecord: record ].
	(proceedData at: #blockedByCritiques) ifTrue: [
		record reason: 'debugMethodUpdateCritiques' ].
	resultDetails := {
		                 (#method -> compiledMethod).
		                 (#record -> record).
		                 (#previousStateId -> previousStateId).
		                 (#frameRef -> frameRef).
		                 (#updateKind -> updateKind) } asDictionary.
	data := self
		        resultDataUsing: resultDetails
		        critiques: critiques
		        proceedData: proceedData.
	^ MCPDebugToolResult
		  okSummary: 'Debug method update ' , updateKind , ' applied to '
			  , record sessionId , '.'
		  data: data
		  warnings: (data at: #warnings)
]

{ #category : 'private - compiling' }
MCPUpdateDebugMethodCommand >> formattedMethodForBehavior: aBehavior selector: aSelector [

	| compiledMethod |
	compiledMethod := aBehavior >> aSelector.
	compiledMethod reformat.
	^ aBehavior >> aSelector
]

{ #category : 'private - frames' }
MCPUpdateDebugMethodCommand >> frameIndexForContext: aContext record: aRecord fallback: fallbackIndex [

	| rawContexts |
	rawContexts := (MCPDebugStateInfo
		                fromRecord: aRecord
		                request: request) rawContexts.
	^ (rawContexts indexOf: aContext ifAbsent: [ fallbackIndex + 1 ]) - 1
]

{ #category : 'private - frames' }
MCPUpdateDebugMethodCommand >> frameRefForRecord: aRecord frameIndex: frameIndex [

	^ aRecord sessionId , '/' , aRecord stateId , '/frame-'
	  , frameIndex asString
]

{ #category : 'private - data' }
MCPUpdateDebugMethodCommand >> methodDataFor: aCompiledMethod [

	^ (MCPCompiledMethodInfo fromMethod: aCompiledMethod)
		  asDictionaryIncludingSource: true
]

{ #category : 'private - source' }
MCPUpdateDebugMethodCommand >> methodSourceOrNil [

	request methodSource ifNil: [ ^ nil ].
	request methodSource trimBoth isEmpty ifTrue: [ ^ nil ].
	^ request methodSource
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> prepareInterruptedProcessForContext: aContext record: aRecord [

	| process session |
	session := aRecord debugSession.
	session ifNil: [ ^ self ].
	process := session interruptedProcess.
	process isTerminated ifTrue: [ ^ self ].
	process suspendedContext: aContext
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> proceedAfterMethodUpdateForRecord: aRecord [

	aRecord continuation ifNotNil: [ :continuation |
		^ self proceedContinuation: continuation forRecord: aRecord ].
	^ self proceedDebugSessionForRecord: aRecord
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> proceedContinuation: aContinuation forRecord: aRecord [

	| answer status |
	status := aContinuation proceed.
	status = #completed ifTrue: [
			answer := aContinuation completedAnswer.
			aRecord
				debugSession: nil;
				continuation: nil;
				advanceStateForStatus: 'completed' reason: 'debugMethodUpdateProceed'.
			^ self
				  proceedDataForCompletedAnswer: answer
				  limit: aContinuation resultPreviewCharacterLimit ].
	status = #captured ifTrue: [
			aRecord
				debugSession: aContinuation capturedDebugSession;
				advanceStateForStatus: 'paused' reason: 'capturedException'.
			^ self proceedDataForOutcome: 'paused' timedOut: false ].
	status = #paused ifTrue: [
			aRecord advanceStateForStatus: 'paused' reason: 'debugMethodUpdateProceed'.
			^ self proceedDataForOutcome: 'paused' timedOut: false ].
	status = #running ifTrue: [
			aRecord advanceStateForStatus: 'running' reason: 'debugMethodUpdateProceed'.
			^ self proceedDataForOutcome: 'running' timedOut: false ].
	status = #timedOut ifTrue: [
			aContinuation terminateWorker.
			aRecord
				continuation: nil;
				advanceStateForStatus: 'timedOut'
				reason: 'debugMethodUpdateProceedTimeout'.
			^ self proceedDataForOutcome: 'timedOut' timedOut: true ].
	status = #terminated ifTrue: [
			aRecord
				continuation: nil;
				advanceStateForStatus: 'terminated' reason: 'debugMethodUpdateProceed'.
			^ self proceedDataForOutcome: 'terminated' timedOut: false ].
	^ self proceedDataForOutcome: status asString timedOut: false
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> proceedDataBlockedByCritiques [

	^ {
		  (#proceeded -> false).
		  (#blockedByCritiques -> true).
		  (#proceedOutcome -> 'blockedByCritiques').
		  (#resultClassName -> nil).
		  (#resultPrintString -> nil).
		  (#timedOut -> false) } asDictionary
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> proceedDataForCompletedAnswer: answer [

	^ self
		  proceedDataForCompletedAnswer: answer
		  limit: request resultPreviewCharacterLimit
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> proceedDataForCompletedAnswer: answer limit: characterLimit [

	^ {
		  (#proceeded -> true).
		  (#blockedByCritiques -> false).
		  (#proceedOutcome -> 'completed').
		  (#resultClassName -> answer class name asString).
		  (#resultPrintString
		   -> (self limitedPrintStringOf: answer limit: characterLimit)).
		  (#timedOut -> false) } asDictionary
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> proceedDataForOutcome: outcomeString timedOut: timedOutBoolean [

	^ {
		  (#proceeded -> true).
		  (#blockedByCritiques -> false).
		  (#proceedOutcome -> outcomeString).
		  (#resultClassName -> nil).
		  (#resultPrintString -> nil).
		  (#timedOut -> timedOutBoolean) } asDictionary
]

{ #category : 'private - proceeding' }
MCPUpdateDebugMethodCommand >> proceedDebugSessionForRecord: aRecord [

	aRecord debugSession ifNil: [
		^ self proceedDataForOutcome: 'unavailable' timedOut: false ].
	[
		aRecord debugSession resume.
		aRecord advanceStateForStatus: 'running' reason: 'debugMethodUpdateProceed' ]
		on: Exception
		do: [ :error |
				aRecord
					advanceStateForStatus: 'paused'
					reason: 'debugMethodUpdateProceedError'.
				^ self proceedDataForOutcome: 'failed' timedOut: false ].
	^ self proceedDataForOutcome: 'running' timedOut: false
]

{ #category : 'private - compiling' }
MCPUpdateDebugMethodCommand >> recompileContext: aContext record: aRecord updateKind: updateKind [

	| frameIndex method source succeeded |
	frameIndex := self
		              frameIndexForContext: aContext
		              record: aRecord
		              fallback: 0.
	source := self methodSourceOrNil.
	source ifNil: [
			^ self
				  signalRequiredMethodSourceForRecord: aRecord
				  frameIndex: frameIndex
				  updateKind: updateKind ].
	succeeded := PharoCompatibility resumeDeprecationsDuring: [
			             aRecord debugSession
				             recompileMethodTo: source
				             inContext: aContext
				             notifying: nil ].
	succeeded ifFalse: [
			^ self
				  signalRecompileFailedForRecord: aRecord
				  frameIndex: frameIndex
				  updateKind: updateKind ].
	method := self compiledMethodForContext: aContext.
	method ifNil: [
			^ self
				  signalRecompileFailedForRecord: aRecord
				  frameIndex: frameIndex
				  updateKind: updateKind ].
	method := self
		          formattedMethodForBehavior: method methodClass
		          selector: method selector.
	aContext privRefreshWith: method.
	aRecord debugSession
		updateContextTo: aContext;
		contextChanged.
	self prepareInterruptedProcessForContext: aContext record: aRecord.
	^ method
]

{ #category : 'private - data' }
MCPUpdateDebugMethodCommand >> resultDataUsing: details critiques: critiques proceedData: proceedData [

	| methodData record repairActions state warnings |
	record := details at: #record.
	state := self stateDataForRecord: record.
	repairActions := state
		                 ifNil: [ #(  ) ]
		                 ifNotNil: [
		                 state at: #repairActions ifAbsent: [ #(  ) ] ].
	warnings := tool updateWarnings.
	methodData := self methodDataFor: (details at: #method).
	^ {
		  (#sessionId -> record sessionId).
		  (#previousStateId -> (details at: #previousStateId)).
		  (#stateId -> record stateId).
		  (#frameRef -> (details at: #frameRef)).
		  (#updateKind -> (details at: #updateKind)).
		  (#method -> methodData).
		  (#critiques -> critiques).
		  (#proceeded -> (proceedData at: #proceeded)).
		  (#blockedByCritiques -> (proceedData at: #blockedByCritiques)).
		  (#proceedOutcome -> (proceedData at: #proceedOutcome)).
		  (#resultClassName -> (proceedData at: #resultClassName)).
		  (#resultPrintString -> (proceedData at: #resultPrintString)).
		  (#timedOut -> (proceedData at: #timedOut)).
		  (#state -> state).
		  (#repairActions -> repairActions).
		  (#warnings -> warnings).
		  (#capabilities -> self capabilities) } asDictionary
]

{ #category : 'private - frames' }
MCPUpdateDebugMethodCommand >> selectedContextForRecord: aRecord frameIndex: frameIndex [

	| contexts stateInfo |
	stateInfo := MCPDebugStateInfo fromRecord: aRecord request: request.
	contexts := stateInfo rawContexts.
	^ contexts
		  at: frameIndex + 1
		  ifAbsent: [
		  self signalMissingFrameIndex: frameIndex record: aRecord ]
]

{ #category : 'private - critiques' }
MCPUpdateDebugMethodCommand >> shouldBlockProceedForCritiques: critiqueData [

	critiqueData ifEmpty: [ ^ false ].
	^ request ignoreCritiques not
]

{ #category : 'private - errors' }
MCPUpdateDebugMethodCommand >> signalMissingFrameIndex: frameIndex record: aRecord [

	^ MCPCommandError
		  signalErrorCode: #DebugFrameNotFound
		  message:
			  'Debug frame ' , frameIndex asString
			  , ' was not found for session ' , aRecord sessionId , '.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#frameIndex -> frameIndex).
				  (#frameRef
				   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)) }
				  asDictionary
]

{ #category : 'private - errors' }
MCPUpdateDebugMethodCommand >> signalRecompileFailedForRecord: aRecord frameIndex: frameIndex updateKind: updateKind [

	^ MCPCommandError
		  signalErrorCode: #DebugMethodUpdateRecompileFailed
		  message:
		  'debug_method_update could not recompile the selected debug frame.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#frameRef
				   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)).
				  (#updateKind -> updateKind) } asDictionary
]

{ #category : 'private - errors' }
MCPUpdateDebugMethodCommand >> signalRequiredMethodSourceForRecord: aRecord frameIndex: frameIndex updateKind: updateKind [

	^ MCPCommandError
		  signalErrorCode: #DebugMethodUpdateMethodSourceRequired
		  message:
		  'debug_method_update requires source for ' , updateKind , '.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#frameRef
				   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)).
				  (#updateKind -> updateKind) } asDictionary
]

{ #category : 'private - errors' }
MCPUpdateDebugMethodCommand >> signalSelectorMismatchWithDetails: details [

	^ MCPCommandError
		  signalErrorCode: #DebugMethodUpdateSelectorMismatch
		  message:
			  'debug_method_update compiled ' , (details at: #actualSelector)
			  , ' but the debug state expects '
			  , (details at: #expectedSelector) , '.'
		  details: details
]

{ #category : 'private - errors' }
MCPUpdateDebugMethodCommand >> signalUnsupportedUpdateForRecord: aRecord updateKind: updateKind [

	^ MCPCommandError
		  signalErrorCode: #DebugMethodUpdateUnsupported
		  message:
		  'debug_method_update cannot repair the current debug state.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#updateKind -> updateKind) } asDictionary
]

{ #category : 'private - data' }
MCPUpdateDebugMethodCommand >> stateDataForRecord: aRecord [

	aRecord status = 'paused' ifFalse: [ ^ nil ].
	aRecord debugSession ifNil: [ ^ nil ].
	^ (MCPDebugStateInfo fromRecord: aRecord request: request)
		  asDictionary
]

{ #category : 'private - actions' }
MCPUpdateDebugMethodCommand >> updateContextForRecord: aRecord selectedContext: selectedContext updateKind: updateKind [

	| analyzer context exception |
	analyzer := self analyzerForRecord: aRecord.
	exception := analyzer exception.
	(#( 'missingMethod' 'subclassResponsibility' ) includes: updateKind)
		ifTrue: [
				context := analyzer targetContextForException: exception.
				context ifNotNil: [ ^ context ] ].
	(#( 'shouldBeImplemented' 'notYetImplemented' ) includes: updateKind)
		ifTrue: [
				context := analyzer selectorContextForException: exception.
				context ifNotNil: [ ^ context ] ].
	^ selectedContext
]

{ #category : 'private - actions' }
MCPUpdateDebugMethodCommand >> updateKindForRecord: aRecord [

	^ (self analyzerForRecord: aRecord) exception
		  ifNil: [ 'recompile' ]
		  ifNotNil: [ :exception | exception mcpDebugMethodUpdateKind ]
]
