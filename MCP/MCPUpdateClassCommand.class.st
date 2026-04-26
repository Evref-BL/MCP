"
Orchestrates operation=update for edit-class. It receives one parsed MCPClassUpdateRequest, builds an MCPClassUpdatePlanInfo for the single internal update action, dispatches to the command that applies the change, and wraps the command result in MCPClassAppliedChangeResult for tool output. Slot edits and slot collection replacement are both parsed from the same update request.
"
Class {
	#name : 'MCPUpdateClassCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'classRequest'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPUpdateClassCommand class >> tool: aTool request: aClassRequest [

	^ self new initializeTool: aTool request: aClassRequest
]

{ #category : 'private - results' }
MCPUpdateClassCommand >> appliedUpdateResultFor: aChangeResult plan: plan [

	^ MCPClassAppliedChangeResult
		  updatePlan: plan
		  changeResult: aChangeResult
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> classRequest [

	^ classRequest
]

{ #category : 'executing' }
MCPUpdateClassCommand >> execute [

	| plan |
	[ plan := self updatePlan ]
		on: MCPCommandError
		do: [ :error |
			^ self tool
				  errorResultForCommandError: error
				  operation: 'update'
				  requestedContext: self validationContext ].
	^ self executePlan: plan
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeAddSlotWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'addSlot'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPAddSlotCommand
				             className: self classRequest className
				             slotName: self classRequest slotName
				             classSide: self classRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: 'Added '
					  ,
					  (self tool slotDescriptionForClassSide:
						   self classRequest classSide) , ' '
					  , self classRequest slotName , ' to class '
					  , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForAddSlotNamed: self classRequest slotName
				  onClassNamed: self classRequest className
				  classSide: self classRequest classSide
				  error: error ]
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeMoveSlotAction: operation withPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: operation
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPMoveSlotCommand
				             className: self classRequest className
				             slotName: self classRequest slotName
				             direction: operation
				             classSide: self classRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  (self successMessageForMoveSlotAction: operation)
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForMoveSlotNamed: self classRequest slotName
				  onClassNamed: self classRequest className
				  classSide: self classRequest classSide
				  operation: operation
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeMoveWithPlan: plan [

	| packageName result |
	packageName := self movePackageName.
	^ self tool
		  executeEditOperation: 'move'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPMoveClassCommand
				             className: self classRequest className
				             packageName: packageName
				             tag: self classRequest tag) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Moved class ' , self classRequest className , ' to package '
					  , packageName , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForMoveClassNamed: self classRequest className
				  packageName: packageName
				  tag: self classRequest tag
				  error: error ]
]

{ #category : 'executing' }
MCPUpdateClassCommand >> executePlan: plan [

	| selector |
	selector := self executeSelectorForAction: plan updateAction.
	selector ifNotNil: [ ^ self perform: selector with: plan ].
	^ self tool
		  errorResultForCommandError: (MCPCommandError new
				   errorCode: #UnknownClassUpdateAction;
				   messageText:
					   'Unknown class update action: ' , plan updateAction;
				   details: plan requestedContext;
				   yourself)
		  operation: 'update'
		  requestedContext: plan requestedContext
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executePullUpSlotWithPlan: plan [

	^ self executeMoveSlotAction: 'pullUpSlot' withPlan: plan
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executePushDownSlotWithPlan: plan [

	^ self executeMoveSlotAction: 'pushDownSlot' withPlan: plan
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeRemoveSlotWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'removeSlot'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPRemoveSlotCommand
				             className: self classRequest className
				             slotName: self classRequest slotName
				             classSide: self classRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: 'Removed '
					  ,
					  (self tool slotDescriptionForClassSide:
						   self classRequest classSide) , ' '
					  , self classRequest slotName , ' from class '
					  , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForRemoveSlotNamed: self classRequest slotName
				  onClassNamed: self classRequest className
				  classSide: self classRequest classSide
				  error: error ]
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeRenameSlotWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'renameSlot'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPRenameSlotCommand
				             className: self classRequest className
				             slotName: self classRequest slotName
				             newSlotName: self classRequest newSlotName
				             classSide: self classRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Renamed slot ' , self classRequest slotName , ' to '
					  , self classRequest newSlotName , ' in class '
					  , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForRenameSlotNamed: self classRequest slotName
				  to: self classRequest newSlotName
				  onClassNamed: self classRequest className
				  classSide: self classRequest classSide
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeRenameWithPlan: plan [

	| refactoringModel result targetClass |
	^ self tool
		  executeEditOperation: 'rename'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  targetClass := Smalltalk globals
				                 at: self classRequest className asSymbol
				                 ifAbsent: [
					                 MCPCommandError signalMissingClassNamed:
						                 self classRequest className ].
			  refactoringModel := self tool
				                      refactoringModelForScopeSpec:
				                      self classRequest refactoringScopeSpec
				                      anchoredAtBehavior: targetClass.
			  result := (MCPRenameClassCommand
				             className: self classRequest className
				             newClassName: self classRequest newClassName
				             model: refactoringModel) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Renamed class ' , self classRequest className , ' to '
					  , self classRequest newClassName , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForRenameClassNamed: self classRequest className
				  to: self classRequest newClassName
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReparentWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'reparent'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPReparentClassCommand
				             className: self classRequest className
				             superclassName: self classRequest superclassName)
				            execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Reparented class ' , self classRequest className
					  , ' to superclass ' , self classRequest superclassName , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForReparentClassNamed: self classRequest className
				  superclassName: self classRequest superclassName
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceClassTraitsWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'replaceClassTraits'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPReplaceClassSideTraitsCommand
				             className: self classRequest className
				             classTraitNames: self classRequest classTraits)
				            execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Replaced class-side traits for class '
					  , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForReplaceClassTraitsOnClassNamed:
				  self classRequest className
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceDefinitionWithPlan: plan [

	| command result |
	command := MCPReplaceClassDefinitionCommand new.
	command
		className: self classRequest className;
		slotNames: self classRequest slotNames;
		classSlotNames: self classRequest classSlotNames;
		replaceSlots: (self classRequest hasSuppliedPropertyNamed: 'slots');
		replaceClassSlots:
			(self classRequest hasSuppliedPropertyNamed: 'classSlots').
	^ self tool
		  executeEditOperation: 'replaceDefinition'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [ result := command execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Replaced slot definition for class '
					  , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForReplaceDefinitionOnClassNamed:
				  self classRequest className
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceLayoutWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'replaceLayout'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPReplaceClassLayoutCommand
				             className: self classRequest className
				             layout: self classRequest layout) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Replaced layout for class ' , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForReplaceLayoutOnClassNamed:
				  self classRequest className
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceSharedPoolsWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'replaceSharedPools'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPReplaceClassSharedPoolsCommand
				             className: self classRequest className
				             sharedPoolNames: self classRequest sharedPools)
				            execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Replaced shared pools for class ' , self classRequest className
				  , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForReplaceSharedPoolsOnClassNamed:
				  self classRequest className
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceSharedVariablesWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'replaceSharedVariables'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPReplaceClassSharedVariablesCommand
				             className: self classRequest className
				             sharedVariableNames:
				             self classRequest sharedVariables) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Replaced shared variables for class '
					  , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForReplaceSharedVariablesOnClassNamed:
				  self classRequest className
				  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceTraitsWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'replaceTraits'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPReplaceClassTraitsCommand
				             className: self classRequest className
				             traitNames: self classRequest traits) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Replaced traits for class ' , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForReplaceTraitsOnClassNamed:
				  self classRequest className
				  error: error ]
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> executeSelectorForAction: action [

	| selectors |
	selectors := {
		             ('move' -> #executeMoveWithPlan:).
		             ('rename' -> #executeRenameWithPlan:).
		             ('reparent' -> #executeReparentWithPlan:).
		             ('setComment' -> #executeSetCommentWithPlan:).
		             ('replaceTraits' -> #executeReplaceTraitsWithPlan:).
		             ('replaceClassTraits'
		              -> #executeReplaceClassTraitsWithPlan:).
		             ('replaceSharedVariables'
		              -> #executeReplaceSharedVariablesWithPlan:).
		             ('replaceSharedPools'
		              -> #executeReplaceSharedPoolsWithPlan:).
		             ('replaceLayout' -> #executeReplaceLayoutWithPlan:).
		             ('replaceDefinition'
		              -> #executeReplaceDefinitionWithPlan:).
		             ('addSlot' -> #executeAddSlotWithPlan:).
		             ('removeSlot' -> #executeRemoveSlotWithPlan:).
		             ('renameSlot' -> #executeRenameSlotWithPlan:).
		             ('pullUpSlot' -> #executePullUpSlotWithPlan:).
		             ('pushDownSlot' -> #executePushDownSlotWithPlan:) }
		             asDictionary.
	^ selectors at: action ifAbsent: [ nil ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeSetCommentWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'setComment'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPChangeClassCommentCommand
				             className: self classRequest className
				             classComment: self classRequest classComment) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Set comment for class ' , self classRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForSetCommentOnClassNamed:
				  self classRequest className
				  error: error ]
]

{ #category : 'initialization' }
MCPUpdateClassCommand >> initializeTool: aTool request: aClassRequest [

	tool := aTool.
	classRequest := aClassRequest.
	^ self
]

{ #category : 'private - move' }
MCPUpdateClassCommand >> movePackageName [

	^ self tool
		  packageNameForMoveClassNamed: self classRequest className
		  requestedPackageName: self classRequest packageName
]

{ #category : 'private - move' }
MCPUpdateClassCommand >> moveRequestedContext [

	^ {
		  (#className -> self classRequest className).
		  (#packageName -> self movePackageName).
		  (#tag -> (self classRequest tag
			    ifNil: [ '' ]
			    ifNotNil: [ self classRequest tag ])) } asDictionary
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> requestedContextForAction: action [

	| context |
	action = 'move' ifTrue: [ ^ self moveRequestedContext ].
	action = 'rename' ifTrue: [
		context := self classRequest requestedContext.
		self tool
			addRefactoringScopeContextFromSpec:
			self classRequest refactoringScopeSpec
			toRequestedContext: context.
		^ context ].
	action = 'renameSlot' ifTrue: [
		^ self classRequest renameSlotRequestedContext ].
	(#( 'addSlot' 'removeSlot' 'pullUpSlot' 'pushDownSlot' ) includes:
		 action) ifTrue: [ ^ self classRequest slotRequestedContext ].
	^ self classRequest requestedContext
]

{ #category : 'private - signaling' }
MCPUpdateClassCommand >> signalAmbiguousUpdateActions: actions [

	^ MCPCommandError
		  signalErrorCode: #AmbiguousClassUpdateRequest
		  message:
		  'update accepts one class edit action per request. Split multiple edits into separate requests.'
		  details: (self validationContext
				   at: #updateActions put: actions;
				   yourself)
]

{ #category : 'private - signaling' }
MCPUpdateClassCommand >> signalNoUpdateRequested [

	^ MCPCommandError
		  signalErrorCode: #NoClassUpdateRequested
		  message:
		  'operation=update requires one update field such as newClassName, superclassName, packageName, tag, classComment, slots, classSlots, traits, classTraits, sharedVariables, sharedPools, layout, or slotAction.'
		  details: self validationContext
]

{ #category : 'private - slots' }
MCPUpdateClassCommand >> successMessageForMoveSlotAction: operation [

	| slotDescription |
	slotDescription := self tool slotDescriptionForClassSide:
		                   self classRequest classSide.
	operation = 'pullUpSlot' ifTrue: [
		^ 'Pulled up ' , slotDescription , ' ' , self classRequest slotName
		  , ' to class ' , self classRequest className , '.' ].
	^ 'Pushed down ' , slotDescription , ' ' , self classRequest slotName
	  , ' from class ' , self classRequest className , '.'
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> updateAction [

	| actions slotOperation |
	actions := OrderedCollection withAll:
		           self classRequest requestedClassUpdateActions.
	self classRequest validateSlotUpdate.
	slotOperation := self classRequest slotOperation.
	slotOperation ifNotNil: [ actions add: slotOperation ].
	actions ifEmpty: [ self signalNoUpdateRequested ].
	actions size > 1 ifTrue: [
		self signalAmbiguousUpdateActions: actions asArray ].
	^ actions first
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> updatePlan [

	| action |
	action := self updateAction.
	^ MCPClassUpdatePlanInfo
		  updateAction: action
		  requestedContext: (self requestedContextForAction: action)
]

{ #category : 'private' }
MCPUpdateClassCommand >> validationContext [

	^ self classRequest validationContext
]
