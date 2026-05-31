"
Creates or hot-recompiles a method from the current debugger frame.

It supports debugger-driven development by deriving repair targets, compiling with critique feedback, and proceeding the paused computation when the edit is accepted.
"
Class {
	#name : 'MCPDebugEditCommand',
	#superclass : 'MCPDebugCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - actions' }
MCPDebugEditCommand >> analyzerForRecord: aRecord [

	^ MCPDebugRepairAnalyzer fromRecord: aRecord request: request
]

{ #category : 'private - data' }
MCPDebugEditCommand >> capabilities [

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
MCPDebugEditCommand >> classNameForBehavior: aBehavior [

	aBehavior ifNil: [ ^ nil ].
	^ aBehavior isMeta
		  ifTrue: [ aBehavior instanceSide name asString ]
		  ifFalse: [ aBehavior name asString ]
]

{ #category : 'private - methods' }
MCPDebugEditCommand >> classSideForBehavior: aBehavior [

	^ aBehavior notNil and: [ aBehavior isMeta ]
]

{ #category : 'private - compiling' }
MCPDebugEditCommand >> compileForRecord: aRecord context: aContext editKind: editKind [

	(#( 'missingMethod' 'subclassResponsibility' ) includes: editKind)
		ifTrue: [
				^ self
					  compileImplementationForRecord: aRecord
					  context: aContext
					  editKind: editKind ].
	(#( 'recompile' 'shouldBeImplemented' 'notYetImplemented' )
		 includes: editKind) ifTrue: [
		^ self recompileContext: aContext record: aRecord editKind: editKind ].
	^ self signalUnsupportedEditForRecord: aRecord editKind: editKind
]

{ #category : 'private - compiling' }
MCPDebugEditCommand >> compileImplementationForRecord: aRecord context: aContext editKind: editKind [

	| analyzer behavior details message source |
	analyzer := self analyzerForRecord: aRecord.
	message := analyzer
		           messageForException: analyzer exception
		           context: aContext.
	message ifNil: [
		^ self signalUnsupportedEditForRecord: aRecord editKind: editKind ].
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
				  editKind: editKind ].
	details := {
		           (#source -> source).
		           (#behavior -> behavior).
		           (#expectedSelector -> message selector).
		           (#context -> aContext).
		           (#message -> message).
		           (#record -> aRecord).
		           (#editKind -> editKind) } asDictionary.
	^ self compileSourceUsing: details
]

{ #category : 'private - compiling' }
MCPDebugEditCommand >> compileSourceUsing: details [

	| actualSelector behavior context expectedSelector message method record selectorDetails |
	record := details at: #record.
	behavior := details at: #behavior.
	behavior ifNil: [
			^ self
				  signalUnsupportedEditForRecord: record
				  editKind: (details at: #editKind) ].
	expectedSelector := details at: #expectedSelector.
	actualSelector := behavior compile: (details at: #source).
	actualSelector = expectedSelector ifFalse: [
			selectorDetails := {
				                   (#sessionId -> record sessionId).
				                   (#stateId -> record stateId).
				                   (#editKind -> (details at: #editKind)).
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
MCPDebugEditCommand >> compiledMethodForContext: aContext [

	^ aContext method methodClass lookupSelector: aContext selector
]

{ #category : 'private - data' }
MCPDebugEditCommand >> critiqueDataForMethod: aCompiledMethod [

	^ MCPToolCreateMethod new critiqueDataForMethod: aCompiledMethod

]

{ #category : 'private - actions' }
MCPDebugEditCommand >> editContextForRecord: aRecord selectedContext: selectedContext editKind: editKind [

	| analyzer context exception |
	analyzer := self analyzerForRecord: aRecord.
	exception := analyzer exception.
	(#( 'missingMethod' 'subclassResponsibility' ) includes: editKind)
		ifTrue: [
				context := analyzer targetContextForException: exception.
				context ifNotNil: [ ^ context ] ].
	(#( 'shouldBeImplemented' 'notYetImplemented' ) includes: editKind)
		ifTrue: [
				context := analyzer selectorContextForException: exception.
				context ifNotNil: [ ^ context ] ].
	^ selectedContext
]

{ #category : 'private - actions' }
MCPDebugEditCommand >> editKindForRecord: aRecord [

	| exception |
	exception := (self analyzerForRecord: aRecord) exception.
	exception ifNil: [ ^ 'recompile' ].
	(exception isKindOf: MessageNotUnderstood) ifTrue: [
		^ 'missingMethod' ].
	(exception isKindOf: SubclassResponsibility) ifTrue: [
		^ 'subclassResponsibility' ].
	(exception isKindOf: ShouldBeImplemented) ifTrue: [
		^ 'shouldBeImplemented' ].
	(exception isKindOf: NotYetImplemented) ifTrue: [
		^ 'notYetImplemented' ].
	^ 'recompile'
]

{ #category : 'executing' }
MCPDebugEditCommand >> execute [

	| compiledMethod context critiques data editKind frameIndex frameRef previousStateId proceedData record resultDetails selectedContext |
	record := self sessionRecordWithMatchingState.
	previousStateId := record stateId.
	frameIndex := self selectedFrameIndex.
	selectedContext := self
		                   selectedContextForRecord: record
		                   frameIndex: frameIndex.
	editKind := self editKindForRecord: record.
	context := self
		           editContextForRecord: record
		           selectedContext: selectedContext
		           editKind: editKind.
	frameIndex := self
		              frameIndexForContext: context
		              record: record
		              fallback: frameIndex.
	compiledMethod := self
		                  compileForRecord: record
		                  context: context
		                  editKind: editKind.
	record advanceStateForStatus: 'paused' reason: 'debugEdit'.
	frameRef := self frameRefForRecord: record frameIndex: frameIndex.
	critiques := self critiqueDataForMethod: compiledMethod.
	proceedData := (critiques notEmpty and: [
		                request ignoreCritiques not ])
		               ifTrue: [ self proceedDataBlockedByCritiques ]
		               ifFalse: [ self proceedAfterEditForRecord: record ].
	(proceedData at: #blockedByCritiques) ifTrue: [
		record reason: 'debugEditCritiques' ].
	resultDetails := {
		                 (#method -> compiledMethod).
		                 (#record -> record).
		                 (#previousStateId -> previousStateId).
		                 (#frameRef -> frameRef).
		                 (#editKind -> editKind) } asDictionary.
	data := self
		        resultDataUsing: resultDetails
		        critiques: critiques
		        proceedData: proceedData.
	^ MCPDebugToolResult
		  okSummary:
		  'Debug edit ' , editKind , ' applied to ' , record sessionId , '.'
		  data: data
		  warnings: (data at: #warnings)
]

{ #category : 'private - compiling' }
MCPDebugEditCommand >> formattedMethodForBehavior: aBehavior selector: aSelector [

	| compiledMethod |
	compiledMethod := aBehavior >> aSelector.
	compiledMethod reformat.
	^ aBehavior >> aSelector
]

{ #category : 'private - frames' }
MCPDebugEditCommand >> frameIndexForContext: aContext record: aRecord fallback: fallbackIndex [

	| rawContexts |
	rawContexts := (MCPDebugStateInfo
		                fromRecord: aRecord
		                request: request) rawContexts.
	^ (rawContexts indexOf: aContext ifAbsent: [ fallbackIndex + 1 ]) - 1
]

{ #category : 'private - frames' }
MCPDebugEditCommand >> frameRefForRecord: aRecord frameIndex: frameIndex [

	^ aRecord sessionId , '/' , aRecord stateId , '/frame-'
	  , frameIndex asString
]

{ #category : 'private - printing' }
MCPDebugEditCommand >> limitedPrintStringOf: anObject limit: characterLimit [

	anObject ifNil: [ ^ 'nil' ].
	^ [ anObject printStringLimitedTo: characterLimit ]
		  on: Error
		  do: [ :error | anObject class name asString ]
]

{ #category : 'private - data' }
MCPDebugEditCommand >> methodDataFor: aCompiledMethod [

	^ (MCPCompiledMethodInfo fromMethod: aCompiledMethod)
		  asDictionaryIncludingSource: true
]

{ #category : 'private - source' }
MCPDebugEditCommand >> methodSourceOrNil [

	request methodSource ifNil: [ ^ nil ].
	request methodSource trimBoth isEmpty ifTrue: [ ^ nil ].
	^ request methodSource
]

{ #category : 'private - proceeding' }
MCPDebugEditCommand >> prepareInterruptedProcessForContext: aContext record: aRecord [

	| process session |
	session := aRecord debugSession.
	(session isKindOf: DebugSession) ifFalse: [ ^ self ].
	process := session interruptedProcess.
	process isTerminated ifTrue: [ ^ self ].
	process suspendedContext: aContext
]

{ #category : 'private - proceeding' }
MCPDebugEditCommand >> proceedAfterEditForRecord: aRecord [

	aRecord continuation ifNotNil: [ :continuation |
		^ self proceedContinuation: continuation forRecord: aRecord ].
	^ self proceedDebugSessionForRecord: aRecord
]

{ #category : 'private - proceeding' }
MCPDebugEditCommand >> proceedContinuation: aContinuation forRecord: aRecord [

	| answer status |
	status := aContinuation proceed.
	status = #completed ifTrue: [
			answer := aContinuation completedAnswer.
			aRecord
				debugSession: nil;
				continuation: nil;
				advanceStateForStatus: 'completed' reason: 'debugEditProceed'.
			^ self
				  proceedDataForCompletedAnswer: answer
				  limit: aContinuation resultPreviewCharacterLimit ].
	status = #captured ifTrue: [
			aRecord
				debugSession: aContinuation capturedDebugSession;
				advanceStateForStatus: 'paused' reason: 'capturedException'.
			^ self proceedDataForOutcome: 'paused' timedOut: false ].
	status = #paused ifTrue: [
			aRecord advanceStateForStatus: 'paused' reason: 'debugEditProceed'.
			^ self proceedDataForOutcome: 'paused' timedOut: false ].
	status = #running ifTrue: [
			aRecord advanceStateForStatus: 'running' reason: 'debugEditProceed'.
			^ self proceedDataForOutcome: 'running' timedOut: false ].
	status = #timedOut ifTrue: [
			aContinuation terminateWorker.
			aRecord
				continuation: nil;
				advanceStateForStatus: 'timedOut'
				reason: 'debugEditProceedTimeout'.
			^ self proceedDataForOutcome: 'timedOut' timedOut: true ].
	status = #terminated ifTrue: [
			aRecord
				continuation: nil;
				advanceStateForStatus: 'terminated' reason: 'debugEditProceed'.
			^ self proceedDataForOutcome: 'terminated' timedOut: false ].
	^ self proceedDataForOutcome: status asString timedOut: false
]

{ #category : 'private - proceeding' }
MCPDebugEditCommand >> proceedDataBlockedByCritiques [

	^ {
		  (#proceeded -> false).
		  (#blockedByCritiques -> true).
		  (#proceedOutcome -> 'blockedByCritiques').
		  (#resultClassName -> nil).
		  (#resultPrintString -> nil).
		  (#timedOut -> false) } asDictionary
]

{ #category : 'private - proceeding' }
MCPDebugEditCommand >> proceedDataForCompletedAnswer: answer [

	^ self
		  proceedDataForCompletedAnswer: answer
		  limit: request resultPreviewCharacterLimit
]

{ #category : 'private - proceeding' }
MCPDebugEditCommand >> proceedDataForCompletedAnswer: answer limit: characterLimit [

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
MCPDebugEditCommand >> proceedDataForOutcome: outcomeString timedOut: timedOutBoolean [

	^ {
		  (#proceeded -> true).
		  (#blockedByCritiques -> false).
		  (#proceedOutcome -> outcomeString).
		  (#resultClassName -> nil).
		  (#resultPrintString -> nil).
		  (#timedOut -> timedOutBoolean) } asDictionary
]

{ #category : 'private - proceeding' }
MCPDebugEditCommand >> proceedDebugSessionForRecord: aRecord [

	aRecord debugSession ifNil: [
		^ self proceedDataForOutcome: 'unavailable' timedOut: false ].
	[
		aRecord debugSession resume.
		aRecord advanceStateForStatus: 'running' reason: 'debugEditProceed' ]
		on: Exception
		do: [ :error |
				aRecord
					advanceStateForStatus: 'paused'
					reason: 'debugEditProceedError'.
				^ self proceedDataForOutcome: 'failed' timedOut: false ].
	^ self proceedDataForOutcome: 'running' timedOut: false
]

{ #category : 'private - compiling' }
MCPDebugEditCommand >> recompileContext: aContext record: aRecord editKind: editKind [

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
				  editKind: editKind ].
	succeeded := aRecord debugSession
		             recompileMethodTo: source
		             inContext: aContext
		             notifying: nil.
	succeeded ifFalse: [
			^ self
				  signalRecompileFailedForRecord: aRecord
				  frameIndex: frameIndex
				  editKind: editKind ].
	method := self compiledMethodForContext: aContext.
	method ifNil: [
			^ self
				  signalRecompileFailedForRecord: aRecord
				  frameIndex: frameIndex
				  editKind: editKind ].
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
MCPDebugEditCommand >> resultDataUsing: details critiques: critiques proceedData: proceedData [

	| methodData record repairActions state warnings |
	record := details at: #record.
	state := self stateDataForRecord: record.
	repairActions := state
		                 ifNil: [ #(  ) ]
		                 ifNotNil: [
		                 state at: #repairActions ifAbsent: [ #(  ) ] ].
	warnings := tool editWarnings.
	methodData := self methodDataFor: (details at: #method).
	^ {
		  (#sessionId -> record sessionId).
		  (#previousStateId -> (details at: #previousStateId)).
		  (#stateId -> record stateId).
		  (#frameRef -> (details at: #frameRef)).
		  (#editKind -> (details at: #editKind)).
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
MCPDebugEditCommand >> selectedContextForRecord: aRecord frameIndex: frameIndex [

	| contexts stateInfo |
	stateInfo := MCPDebugStateInfo fromRecord: aRecord request: request.
	contexts := stateInfo rawContexts.
	^ contexts
		  at: frameIndex + 1
		  ifAbsent: [
		  self signalMissingFrameIndex: frameIndex record: aRecord ]
]

{ #category : 'private - frames' }
MCPDebugEditCommand >> selectedFrameIndex [

	| frameToken index suffix tokens |
	request frameRef ifNil: [ ^ 0 ].
	tokens := request frameRef findTokens: '/'.
	tokens size >= 3 ifFalse: [ ^ self signalInvalidFrameReference ].
	frameToken := tokens third.
	(frameToken beginsWith: 'frame-') ifFalse: [
		^ self signalInvalidFrameReference ].
	suffix := frameToken allButFirst: 6.
	index := [ suffix asInteger ]
		         on: Error
		         do: [ :error | ^ self signalInvalidFrameReference ].
	index < 0 ifTrue: [ ^ self signalInvalidFrameReference ].
	^ index
]

{ #category : 'private - errors' }
MCPDebugEditCommand >> signalInvalidFrameReference [

	^ MCPCommandError
		  signalErrorCode: #DebugFrameReferenceInvalid
		  message:
		  'Invalid debug frame reference: ' , request frameRef asString
		  , '.'
		  details: { (#frameRef -> request frameRef) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugEditCommand >> signalMissingFrameIndex: frameIndex record: aRecord [

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
MCPDebugEditCommand >> signalRecompileFailedForRecord: aRecord frameIndex: frameIndex editKind: editKind [

	^ MCPCommandError
		  signalErrorCode: #DebugEditRecompileFailed
		  message:
		  'debug_method_update could not recompile the selected debug frame.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#frameRef
				   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)).
				  (#editKind -> editKind) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugEditCommand >> signalRequiredMethodSourceForRecord: aRecord frameIndex: frameIndex editKind: editKind [

	^ MCPCommandError
		  signalErrorCode: #DebugEditMethodSourceRequired
		  message:
		  'debug_method_update requires methodSource for ' , editKind , '.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#frameRef
				   -> (self frameRefForRecord: aRecord frameIndex: frameIndex)).
				  (#editKind -> editKind) } asDictionary
]

{ #category : 'private - errors' }
MCPDebugEditCommand >> signalSelectorMismatchWithDetails: details [

	^ MCPCommandError
		  signalErrorCode: #DebugEditSelectorMismatch
		  message:
			  'debug_method_update compiled ' , (details at: #actualSelector)
			  , ' but the debug state expects '
			  , (details at: #expectedSelector) , '.'
		  details: details
]

{ #category : 'private - errors' }
MCPDebugEditCommand >> signalUnsupportedEditForRecord: aRecord editKind: editKind [

	^ MCPCommandError
		  signalErrorCode: #DebugEditUnsupported
		  message:
		  'debug_method_update cannot repair the current debug state.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#editKind -> editKind) } asDictionary
]

{ #category : 'private - data' }
MCPDebugEditCommand >> stateDataForRecord: aRecord [

	(aRecord status = 'paused' and: [ aRecord debugSession notNil ])
		ifFalse: [ ^ nil ].
	^ (MCPDebugStateInfo fromRecord: aRecord request: request)
		  asDictionary
]
