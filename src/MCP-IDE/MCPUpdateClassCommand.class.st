"
Orchestrates one parsed class update request.

It builds an MCPClassUpdatePlanInfo for the selected internal update action, dispatches to the command that applies the change, and wraps the command result in MCPClassAppliedChangeResult for tool output. Slot updates and slot collection replacement are both parsed from the same update request.
"
Class {
	#name : 'MCPUpdateClassCommand',
	#superclass : 'MCPCommand',
	#traits : 'TMCPSequencedUpdate',
	#classTraits : 'TMCPSequencedUpdate classTrait',
	#instVars : [
		'tool',
		'classRequest'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPUpdateClassCommand class >> tool: aTool request: aClassRequest [

	^ self new initializeTool: aTool request: aClassRequest
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> actionApplicationOrder [
	"Changes to one class are not independent, so the caller does not choose their order. The superclass goes first because it decides what everything after it validates against; slots are added before anything can refer to them and removed last, after any move that needed them; the name goes last because every other change resolves the class by the name the caller wrote."

	^ #( 'reparent' 'replaceLayout' 'replaceDefinition' 'addSlot' 'renameSlot' 'pullUpSlot' 'pushDownSlot' 'removeSlot' 'replaceTraits'
	     'replaceClassTraits' 'replaceSharedVariables' 'replaceSharedPools' 'setComment' 'move' 'rename' )
]

{ #category : 'private - results' }
MCPUpdateClassCommand >> appliedUpdateResultFor: aChangeResult plan: plan [

	^ MCPClassAppliedChangeResult updatePlan: plan changeResult: aChangeResult
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> classRequest [

	^ classRequest
]

{ #category : 'executing' }
MCPUpdateClassCommand >> execute [

	| actions |
	[ actions := self updateActions ]
		on: MCPCommandError
		do: [ :error | ^ self tool errorResultForCommandError: error action: 'update' requestedContext: self validationContext ].
	^ self executeActions: actions
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeAddSlotWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'addSlot'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
		  result := (MCPAddSlotCommand className: self classRequest className slotName: plan slotName classSide: plan classSide) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
								   stream << 'Added ' << (self tool slotDescriptionForClassSide: plan classSide) << ' ' << plan slotName << ' to class '
								   << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForAddSlotNamed: plan slotName
					  onClassNamed: self classRequest className
					  classSide: plan classSide
					  error: error ]
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> executeBlockForAction: action [

	^ {
		  ('move' -> [ :plan | self executeMoveWithPlan: plan ]).
		  ('rename' -> [ :plan | self executeRenameWithPlan: plan ]).
		  ('reparent' -> [ :plan | self executeReparentWithPlan: plan ]).
		  ('setComment' -> [ :plan | self executeSetCommentWithPlan: plan ]).
		  ('replaceTraits' -> [ :plan | self executeReplaceTraitsWithPlan: plan ]).
		  ('replaceClassTraits' -> [ :plan | self executeReplaceClassTraitsWithPlan: plan ]).
		  ('replaceSharedVariables' -> [ :plan | self executeReplaceSharedVariablesWithPlan: plan ]).
		  ('replaceSharedPools' -> [ :plan | self executeReplaceSharedPoolsWithPlan: plan ]).
		  ('replaceLayout' -> [ :plan | self executeReplaceLayoutWithPlan: plan ]).
		  ('replaceDefinition' -> [ :plan | self executeReplaceDefinitionWithPlan: plan ]).
		  ('addSlot' -> [ :plan | self executeAddSlotWithPlan: plan ]).
		  ('removeSlot' -> [ :plan | self executeRemoveSlotWithPlan: plan ]).
		  ('renameSlot' -> [ :plan | self executeRenameSlotWithPlan: plan ]).
		  ('pullUpSlot' -> [ :plan | self executePullUpSlotWithPlan: plan ]).
		  ('pushDownSlot' -> [ :plan | self executePushDownSlotWithPlan: plan ]) } asDictionary at: action ifAbsent: [ nil ]
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeMoveSlotAction: operation withPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: operation
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
				  result := (MCPMoveSlotCommand
					             className: self classRequest className
					             slotName: plan slotName
					             direction: operation
					             classSide: plan classSide) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (self successMessageForMoveSlotAction: operation plan: plan)
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForMoveSlotNamed: plan slotName
					  onClassNamed: self classRequest className
					  classSide: plan classSide
					  operation: operation
					  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeMoveWithPlan: plan [

	| packageName result |
	packageName := self movePackageName.
	^ self tool
		  executeMutationAction: 'move'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPMoveClassCommand className: self classRequest className packageName: packageName tag: self classRequest tag)
				            execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Moved class ' << self classRequest className << ' to package ' << packageName << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
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

	| actionBlock |
	actionBlock := self executeBlockForAction: plan updateAction.
	actionBlock ifNotNil: [ ^ actionBlock value: plan ].
	^ self tool
		  errorResultForCommandError: (MCPCommandError new
				   errorCode: #UnknownClassUpdateAction;
				   messageText: 'Unknown class update action: ' , plan updateAction;
				   details: plan requestedContext;
				   yourself)
		  action: 'update'
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
		  executeMutationAction: 'removeSlot'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
			  result := (MCPRemoveSlotCommand className: self classRequest className slotName: plan slotName classSide: plan classSide)
				            execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
								   stream << 'Removed ' << (self tool slotDescriptionForClassSide: plan classSide) << ' ' << plan slotName
								   << ' from class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForRemoveSlotNamed: plan slotName
					  onClassNamed: self classRequest className
					  classSide: plan classSide
					  error: error ]
]

{ #category : 'executing - slot' }
MCPUpdateClassCommand >> executeRenameSlotWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'renameSlot'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
				  result := (MCPRenameSlotCommand
					             className: self classRequest className
					             slotName: plan slotName
					             newSlotName: plan newSlotName
					             classSide: plan classSide) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Renamed slot ' << plan slotName << ' to ' << plan newSlotName << ' in class ' << self classRequest className
							   << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForRenameSlotNamed: plan slotName
					  to: plan newSlotName
					  onClassNamed: self classRequest className
					  classSide: plan classSide
					  error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeRenameWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'rename'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
				  MCPImageLookup classNamed: self classRequest className.
				  result := (MCPRenameClassCommand className: self classRequest className newClassName: self classRequest newClassName)
					            execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Renamed class ' << self classRequest className << ' to ' << self classRequest newClassName << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool failureMessageForRenameClassNamed: self classRequest className to: self classRequest newClassName error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReparentWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'reparent'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
				  result := (MCPReparentClassCommand className: self classRequest className superclassName: self classRequest superclassName)
					            execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Reparented class ' << self classRequest className << ' to superclass ' << self classRequest superclassName
							   << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
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
		  executeMutationAction: 'replaceClassTraits'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
				  result := (MCPReplaceClassSideTraitsCommand
					             className: self classRequest className
					             classTraitNames: self classRequest classTraits) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream |
						   stream << 'Replaced class-side traits for class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
		  self tool failureMessageForReplaceClassTraitsOnClassNamed: self classRequest className error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceDefinitionWithPlan: plan [

	| command result instanceDelta classDelta |
	instanceDelta := self classRequest slotDelta.
	classDelta := self classRequest classSlotDelta.
	command := MCPReplaceClassDefinitionCommand new.
	command
		className: self classRequest className;
		slotNames: (self replacementSlotsIn: instanceDelta);
		classSlotNames: (self replacementSlotsIn: classDelta);
		replaceSlots: (instanceDelta isNotNil and: [ instanceDelta hasReplacement ]);
		replaceClassSlots: (classDelta isNotNil and: [ classDelta hasReplacement ]).
	^ self tool
		  executeMutationAction: 'replaceDefinition'
		  force: false
		  requestedContext: plan requestedContext
		  work: [ result := command execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream | stream << 'Replaced slot definition for class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error | self tool failureMessageForReplaceDefinitionOnClassNamed: self classRequest className error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceLayoutWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'replaceLayout'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
		  result := (MCPReplaceClassLayoutCommand className: self classRequest className layout: self classRequest layout) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream | stream << 'Replaced layout for class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error | self tool failureMessageForReplaceLayoutOnClassNamed: self classRequest className error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceSharedPoolsWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'replaceSharedPools'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
				  result := (MCPReplaceClassSharedPoolsCommand
					             className: self classRequest className
					             sharedPoolNames: self classRequest sharedPools) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream | stream << 'Replaced shared pools for class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
		  self tool failureMessageForReplaceSharedPoolsOnClassNamed: self classRequest className error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceSharedVariablesWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'replaceSharedVariables'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
				  result := (MCPReplaceClassSharedVariablesCommand
					             className: self classRequest className
					             sharedVariableNames: self classRequest sharedVariables) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream | stream << 'Replaced shared variables for class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error |
		  self tool failureMessageForReplaceSharedVariablesOnClassNamed: self classRequest className error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeReplaceTraitsWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'replaceTraits'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
		  result := (MCPReplaceClassTraitsCommand className: self classRequest className traitNames: self classRequest traits) execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream | stream << 'Replaced traits for class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error | self tool failureMessageForReplaceTraitsOnClassNamed: self classRequest className error: error ]
]

{ #category : 'executing - class' }
MCPUpdateClassCommand >> executeSetCommentWithPlan: plan [

	| result |
	^ self tool
		  executeMutationAction: 'setComment'
		  force: self classRequest force
		  requestedContext: plan requestedContext
		  work: [
				  result := (MCPChangeClassCommentCommand className: self classRequest className classComment: self classRequest classComment)
					            execute ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream | stream << 'Set comment for class ' << self classRequest className << '.' ])
					  data: (self tool dataForAppliedUpdateResult: (self appliedUpdateResultFor: result plan: plan))
					  warnings: warningMessages ]
		  failureSummary: [ :error | self tool failureMessageForSetCommentOnClassNamed: self classRequest className error: error ]
]

{ #category : 'testing' }
MCPUpdateClassCommand >> hasSlotReplacement [

	^ (self classRequest slotDelta ifNil: [ false ] ifNotNil: [ :delta | delta hasReplacement ]) or: [
		  self classRequest classSlotDelta ifNil: [ false ] ifNotNil: [ :delta | delta hasReplacement ] ]
]

{ #category : 'initialization' }
MCPUpdateClassCommand >> initializeTool: aTool request: aClassRequest [

	tool := aTool.
	classRequest := aClassRequest
]

{ #category : 'private - move' }
MCPUpdateClassCommand >> movePackageName [

	^ self tool packageNameForMoveClassNamed: self classRequest className requestedPackageName: self classRequest packageName
]

{ #category : 'private - move' }
MCPUpdateClassCommand >> moveRequestedContext [

	^ {
		  (#class -> self classRequest className).
		  (#package -> self movePackageName).
		  (#tag -> (self classRequest tag ifNil: [ '' ])) } asDictionary
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> planForAction: action [

	^ MCPClassUpdatePlanInfo updateAction: action requestedContext: (self requestedContextForAction: action)
]

{ #category : 'private - slots' }
MCPUpdateClassCommand >> replacementSlotsIn: aDeltaOrNil [

	aDeltaOrNil ifNil: [ ^ #(  ) ].
	^ aDeltaOrNil replacement ifNil: [ #(  ) ]
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> requestedContextForAction: action [

	action = 'move' ifTrue: [ ^ self moveRequestedContext ].
	^ self classRequest requestedContext
]

{ #category : 'private - signaling' }
MCPUpdateClassCommand >> signalNoUpdateRequested [

	^ MCPCommandError
		  signalErrorCode: #NoClassUpdateRequested
		  message:
		  'Class update requires one update field such as newName, superclassName, packageName, tag, classComment, slots, classSlots, traits, classTraits, sharedVariables, sharedPools, layout, or slotAction.'
		  details: self validationContext
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> slotPlanNamed: action slot: aSlotName newSlot: aNewSlotName side: classSide [

	| context |
	context := Dictionary new
		           at: #class put: self classRequest className;
		           at: #side put: (classSide
				            ifTrue: [ 'class' ]
				            ifFalse: [ 'instance' ]);
		           yourself.
	aSlotName ifNotNil: [ context at: #slot put: aSlotName ].
	aNewSlotName ifNotNil: [ context at: #newSlot put: aNewSlotName ].
	^ (MCPClassUpdatePlanInfo updateAction: action requestedContext: context)
		  slotName: aSlotName;
		  newSlotName: aNewSlotName;
		  classSide: classSide;
		  yourself
]

{ #category : 'private - planning' }
MCPUpdateClassCommand >> slotPlansForSide: classSide [
	"One plan per slot named in the delta, so each failure names the slot it was about. The wholesale replacement is not here: it covers both sides at once, so updateActions plans it once."

	| delta plans |
	delta := self classRequest deltaForSide: classSide.
	delta ifNil: [ ^ #(  ) ].
	delta isEmpty ifTrue: [
			MCPCommandError
				signalErrorCode: #EmptySlotDelta
				message: 'A slots patch must ask for at least one of add, remove, rename, pullUp, pushDown or replace.'
				details: self classRequest requestedContext ].
	plans := OrderedCollection new.
	delta added do: [ :each |
			plans add: (self
					 slotPlanNamed: 'addSlot'
					 slot: each
					 newSlot: nil
					 side: classSide) ].
	delta renamed keysAndValuesDo: [ :from :to |
			plans add: (self
					 slotPlanNamed: 'renameSlot'
					 slot: from
					 newSlot: to
					 side: classSide) ].
	delta pulledUp do: [ :each |
			plans add: (self
					 slotPlanNamed: 'pullUpSlot'
					 slot: each
					 newSlot: nil
					 side: classSide) ].
	delta pushedDown do: [ :each |
			plans add: (self
					 slotPlanNamed: 'pushDownSlot'
					 slot: each
					 newSlot: nil
					 side: classSide) ].
	delta removed do: [ :each |
			plans add: (self
					 slotPlanNamed: 'removeSlot'
					 slot: each
					 newSlot: nil
					 side: classSide) ].
	^ plans
]

{ #category : 'private - slots' }
MCPUpdateClassCommand >> successMessageForMoveSlotAction: operation [

	| slotDescription |
	slotDescription := self tool slotDescriptionForClassSide: self classRequest classSide.
	operation = 'pullUpSlot' ifTrue: [
			^ String streamContents: [ :stream |
					  stream << 'Pulled up ' << slotDescription << ' ' << self classRequest slotName << ' to class '
					  << self classRequest className << '.' ] ].
	^ String streamContents: [ :stream |
			  stream << 'Pushed down ' << slotDescription << ' ' << self classRequest slotName << ' from class '
			  << self classRequest className << '.' ]
]

{ #category : 'private - slots' }
MCPUpdateClassCommand >> successMessageForMoveSlotAction: operation plan: plan [

	| slotDescription |
	slotDescription := self tool slotDescriptionForClassSide: plan classSide.
	operation = 'pullUpSlot' ifTrue: [
			^ String streamContents: [ :stream |
				  stream << 'Pulled up ' << slotDescription << ' ' << plan slotName << ' to class ' << self classRequest className << '.' ] ].
	^ String streamContents: [ :stream |
		  stream << 'Pushed down ' << slotDescription << ' ' << plan slotName << ' from class ' << self classRequest className << '.' ]
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> updateAction [
	"The first change the request asks for. Execution goes through updateActions."

	^ self updateActions first updateAction
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> updateActions [
	"Every operation the request asks for, as plans, in the order they must be applied."

	| plans |
	plans := OrderedCollection new.
	self classRequest requestedClassUpdateActions do: [ :action | plans add: (self planForAction: action) ].
	self hasSlotReplacement ifTrue: [ plans add: (self planForAction: 'replaceDefinition') ].
	plans addAll: (self slotPlansForSide: false).
	plans addAll: (self slotPlansForSide: true).
	plans ifEmpty: [ self signalNoUpdateRequested ].
	^ self actionsInApplicationOrder: plans
]

{ #category : 'accessing' }
MCPUpdateClassCommand >> updatePlan [

	^ self updateActions first
]

{ #category : 'private - results' }
MCPUpdateClassCommand >> updateSubjectDescription [

	^ 'class ' , self classRequest className
]

{ #category : 'private' }
MCPUpdateClassCommand >> validationContext [

	^ self classRequest validationContext
]
