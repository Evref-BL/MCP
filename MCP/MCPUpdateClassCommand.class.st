"
Orchestrates operation=update for edit-class. It receives parsed class and slot requests, builds an MCPClassUpdatePlanInfo for the single internal update action, dispatches to the existing narrow command that applies the change, and wraps the narrow command result in MCPClassAppliedChangeResult for tool output.
"
Class {
	#name : 'MCPUpdateClassCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'classRequest',
		'slotRequest'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPUpdateClassCommand class >> tool: aTool classRequest: aClassRequest slotRequest: aSlotRequest [

	^ self new
		  initializeTool: aTool
		  classRequest: aClassRequest
		  slotRequest: aSlotRequest
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

{ #category : 'private - planning' }
MCPUpdateClassCommand >> commandClassNameForAction: action [

	| commandClassNames |
	commandClassNames := {
		                     ('move' -> MCPMoveClassCommand name).
		                     ('rename' -> MCPRenameClassCommand name).
		                     ('reparent' -> MCPReparentClassCommand name).
		                     ('setComment'
		                      -> MCPChangeClassCommentCommand name).
		                     ('addSlot' -> MCPAddSlotCommand name).
		                     ('removeSlot' -> MCPRemoveSlotCommand name).
		                     ('renameSlot' -> MCPRenameSlotCommand name).
		                     ('pullUpSlot' -> MCPMoveSlotCommand name).
		                     ('pushDownSlot' -> MCPMoveSlotCommand name) }
		                     asDictionary.
	^ commandClassNames at: action ifAbsent: [ '' ]
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
		  force: self slotRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPAddSlotCommand
				             className: self slotRequest className
				             slotName: self slotRequest slotName
				             classSide: self slotRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: 'Added '
					  ,
					  (self tool slotDescriptionForClassSide:
						   self slotRequest classSide) , ' ' , self slotRequest slotName
					  , ' to class ' , self slotRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForAddSlotNamed: self slotRequest slotName
				  onClassNamed: self slotRequest className
				  classSide: self slotRequest classSide
				  error: error ]
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeMoveSlotAction: operation withPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: operation
		  force: self slotRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPMoveSlotCommand
				             className: self slotRequest className
				             slotName: self slotRequest slotName
				             direction: operation
				             classSide: self slotRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  (self successMessageForMoveSlotAction: operation)
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForMoveSlotNamed: self slotRequest slotName
				  onClassNamed: self slotRequest className
				  classSide: self slotRequest classSide
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
	selector := self executeSelectorForAction: plan operation.
	selector ifNotNil: [ ^ self perform: selector with: plan ].
	^ self tool
		  errorResultForCommandError: (MCPCommandError new
				   errorCode: #UnknownClassUpdateAction;
				   messageText: 'Unknown class update action: ' , plan operation;
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
		  force: self slotRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPRemoveSlotCommand
				             className: self slotRequest className
				             slotName: self slotRequest slotName
				             classSide: self slotRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: 'Removed '
					  ,
					  (self tool slotDescriptionForClassSide:
						   self slotRequest classSide) , ' ' , self slotRequest slotName
					  , ' from class ' , self slotRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForRemoveSlotNamed: self slotRequest slotName
				  onClassNamed: self slotRequest className
				  classSide: self slotRequest classSide
				  error: error ]
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeRenameSlotWithPlan: plan [

	| result |
	^ self tool
		  executeEditOperation: 'renameSlot'
		  force: self slotRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPRenameSlotCommand
				             className: self slotRequest className
				             slotName: self slotRequest slotName
				             newSlotName: self slotRequest newSlotName
				             classSide: self slotRequest classSide) execute ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Renamed slot ' , self slotRequest slotName , ' to '
					  , self slotRequest newSlotName , ' in class '
					  , self slotRequest className , '.'
				  data: (self tool dataForAppliedUpdateResult:
						   (self appliedUpdateResultFor: result plan: plan))
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForRenameSlotNamed: self slotRequest slotName
				  to: self slotRequest newSlotName
				  onClassNamed: self slotRequest className
				  classSide: self slotRequest classSide
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

{ #category : 'private - planning' }
MCPUpdateClassCommand >> executeSelectorForAction: action [

	| selectors |
	selectors := {
		             ('move' -> #executeMoveWithPlan:).
		             ('rename' -> #executeRenameWithPlan:).
		             ('reparent' -> #executeReparentWithPlan:).
		             ('setComment' -> #executeSetCommentWithPlan:).
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
MCPUpdateClassCommand >> initializeTool: aTool classRequest: aClassRequest slotRequest: aSlotRequest [

	tool := aTool.
	classRequest := aClassRequest.
	slotRequest := aSlotRequest.
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
		^ self slotRequest renameRequestedContext ].
	(#( 'addSlot' 'removeSlot' 'pullUpSlot' 'pushDownSlot' ) includes:
		 action) ifTrue: [ ^ self slotRequest requestedContext ].
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
		  'operation=update requires one update field such as newClassName, superclassName, packageName, tag, classComment, or slotAction.'
		  details: self validationContext
]

{ #category : 'private - signaling' }
MCPUpdateClassCommand >> signalUnsupportedDefinitionUpdate [

	^ MCPCommandError
		  signalErrorCode: #ClassDefinitionUpdateNotImplemented
		  message:
		  'Class definition replacement updates are not implemented yet.'
		  details: (self validationContext
				   at: #definitionProperties
				   put: self classRequest suppliedDefinitionProperties;
				   yourself)
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> slotRequest [

	^ slotRequest
]

{ #category : 'private - slots' }
MCPUpdateClassCommand >> successMessageForMoveSlotAction: operation [

	| slotDescription |
	slotDescription := self tool slotDescriptionForClassSide:
		                   self slotRequest classSide.
	operation = 'pullUpSlot' ifTrue: [
		^ 'Pulled up ' , slotDescription , ' ' , self slotRequest slotName
		  , ' to class ' , self slotRequest className , '.' ].
	^ 'Pushed down ' , slotDescription , ' ' , self slotRequest slotName
	  , ' from class ' , self slotRequest className , '.'
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
	self slotRequest validateForUpdate.
	slotOperation := self slotRequest slotOperation.
	slotOperation ifNotNil: [ actions add: slotOperation ].
	actions ifEmpty: [ self signalNoUpdateRequested ].
	actions size > 1 ifTrue: [
		self signalAmbiguousUpdateActions: actions asArray ].
	actions first = 'definition' ifTrue: [
		self signalUnsupportedDefinitionUpdate ].
	^ actions first
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> updatePlan [

	| action |
	action := self updateAction.
	^ MCPClassUpdatePlanInfo
		  operation: action
		  commandClassName: (self commandClassNameForAction: action)
		  requestedContext: (self requestedContextForAction: action)
]

{ #category : 'private' }
MCPUpdateClassCommand >> validationContext [

	| context slotContext |
	context := self classRequest requestedContext copy.
	slotContext := self slotRequest requestedContext.
	slotContext keysAndValuesDo: [ :key :value |
		value ifNotNil: [ context at: key ifAbsentPut: [ value ] ] ].
	^ context
]
