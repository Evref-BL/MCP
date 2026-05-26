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
	method := behavior lookupSelector: actualSelector.
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
	^ method
]

{ #category : 'private - methods' }
MCPDebugEditCommand >> compiledMethodForContext: aContext [

	| behavior selector |
	behavior := self valueOrNil: [ aContext method methodClass ].
	selector := self valueOrNil: [ aContext selector ].
	(behavior isNil or: [ selector isNil ]) ifTrue: [ ^ nil ].
	^ behavior lookupSelector: selector
]

{ #category : 'private - data' }
MCPDebugEditCommand >> critiqueDataForMethod: aCompiledMethod [

	^ MCPToolEditMethod new critiqueDataForMethod: aCompiledMethod
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

	| compiledMethod context data editKind frameIndex previousStateId record resultDetails selectedContext |
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
	resultDetails := {
		                 (#method -> compiledMethod).
		                 (#record -> record).
		                 (#previousStateId -> previousStateId).
		                 (#frameIndex -> frameIndex).
		                 (#editKind -> editKind) } asDictionary.
	data := self resultDataUsing: resultDetails.
	^ MCPDebugToolResult
		  okSummary:
		  'Debug edit ' , editKind , ' applied to ' , record sessionId , '.'
		  data: data
		  warnings: (data at: #warnings)
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
	^ method
]

{ #category : 'private - data' }
MCPDebugEditCommand >> resultDataUsing: details [

	| critiques methodData record state warnings |
	record := details at: #record.
	state := (MCPDebugStateInfo fromRecord: record request: request)
		         asDictionary.
	warnings := tool editWarnings.
	methodData := self methodDataFor: (details at: #method).
	critiques := self critiqueDataForMethod: (details at: #method).
	^ {
		  (#sessionId -> record sessionId).
		  (#previousStateId -> (details at: #previousStateId)).
		  (#stateId -> record stateId).
		  (#frameRef
		   ->
		   (self
			    frameRefForRecord: record
			    frameIndex: (details at: #frameIndex))).
		  (#editKind -> (details at: #editKind)).
		  (#method -> methodData).
		  (#critiques -> critiques).
		  (#state -> state).
		  (#repairActions -> (state at: #repairActions ifAbsent: [ #(  ) ])).
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
		  'debug-edit could not recompile the selected debug frame.'
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
		  message: 'debug-edit requires methodSource for ' , editKind , '.'
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
		  message: 'debug-edit compiled ' , (details at: #actualSelector)
			  , ' but the debug state expects '
			  , (details at: #expectedSelector) , '.'
		  details: details
]

{ #category : 'private - errors' }
MCPDebugEditCommand >> signalUnsupportedEditForRecord: aRecord editKind: editKind [

	^ MCPCommandError
		  signalErrorCode: #DebugEditUnsupported
		  message: 'debug-edit cannot repair the current debug state.'
		  details: {
				  (#sessionId -> aRecord sessionId).
				  (#stateId -> aRecord stateId).
				  (#editKind -> editKind) } asDictionary
]

{ #category : 'private' }
MCPDebugEditCommand >> valueOrNil: aBlock [

	^ [ aBlock value ]
		  on: Error
		  do: [ :error | nil ]
]
