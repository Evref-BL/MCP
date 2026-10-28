"
Command for applying one method update patch. It selects an internal method update action, executes it, and returns structured method update DTOs.
"
Class {
	#name : 'MCPUpdateMethodCommand',
	#superclass : 'MCPToolRequestCommand',
	#traits : 'TMCPSequencedUpdate',
	#classTraits : 'TMCPSequencedUpdate classTrait',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> actionApplicationOrder [
	"Changing the protocol resolves the method by the selector the caller wrote, so a selector change comes after it."

	^ #( 'changeProtocol' 'rename' 'addArguments' 'removeArguments' )
]

{ #category : 'private - results' }
MCPUpdateMethodCommand >> appliedUpdateResultFor: aChangeResult plan: plan [

	^ MCPMethodAppliedChangeResult updatePlan: plan changeResult: aChangeResult
]

{ #category : 'executing' }
MCPUpdateMethodCommand >> execute [

	| actions |
	[ actions := self updateActions ]
		on: MCPCommandError
		do: [ :error | ^ self tool errorResultForCommandError: error action: 'update' requestedContext: self request requestedContext ].
	^ self executeActions: actions
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeAddArgumentsWithPlan: plan [

	| behavior changeResult newCompiledMethod newSelectorSymbol oldMethodReference oldSelectorSymbol refactoring refactoringModel renameMap |
	oldSelectorSymbol := self request selector asSymbol.
	newSelectorSymbol := self request newSelector asSymbol.
	^ self tool
		  executeMutationAction: 'addArguments'
		  force: self request force
		  requestedContext: plan requestedContext
		  work: [
				  behavior := self tool behaviorNamed: self request className classSide: self request classSide.
				  behavior compiledMethodAt: oldSelectorSymbol ifAbsent: [
						  MCPCommandError
							  signalMissingMethodInClassName: self request className
							  classSide: self request classSide
							  selector: self request selector ].
				  refactoringModel := self tool refactoringModelForScopeSpec: self request refactoringScopeSpec anchoredAtBehavior: behavior.
				  oldMethodReference := self tool methodReferenceForBehavior: behavior selector: oldSelectorSymbol.
				  refactoring := self tool
					                 addParameterRefactoringForSelector: oldSelectorSymbol
					                 inBehavior: behavior
					                 to: newSelectorSymbol
					                 permutation: (self request permutationForBehavior: behavior)
					                 newArgs: (self request newArgumentSpecsForBehavior: behavior)
					                 model: refactoringModel.
				  renameMap := self request argumentRenameMapForBehavior: behavior.
				  renameMap ifNotEmpty: [ refactoring renameMap: renameMap ].
				  refactoring execute.
				  newCompiledMethod := self tool reformattedMethodForBehavior: behavior selector: newSelectorSymbol.
				  changeResult := (MCPMethodUpdateChangeResult updateAction: 'addArguments' method: newCompiledMethod)
					                  oldSelector: self request selector;
					                  newSelector: self request newSelector;
					                  yourself ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
								   stream << 'Added arguments to ' << oldMethodReference << ' as '
								   << (self tool methodReferenceForBehavior: behavior selector: newSelectorSymbol) << '.' ])
					  data: (self appliedUpdateResultFor: changeResult plan: plan) asDictionary
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForArgumentUpdateAction: 'addArguments'
					  classNamed: self request className
					  classSide: self request classSide
					  selector: self request selector
					  newSelector: self request newSelector
					  error: error ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> executeBlockForAction: action [

	^ {
		  ('rename' -> [ :plan | self executeRenameWithPlan: plan ]).
		  ('addArguments' -> [ :plan | self executeAddArgumentsWithPlan: plan ]).
		  ('removeArguments' -> [ :plan | self executeRemoveArgumentsWithPlan: plan ]).
		  ('changeProtocol' -> [ :plan | self executeChangeProtocolWithPlan: plan ]) } asDictionary at: action ifAbsent: [ nil ]
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeChangeProtocolWithPlan: plan [

	| behavior changeResult newCompiledMethod oldCompiledMethod oldProtocol selectorSymbol |
	selectorSymbol := self request selector asSymbol.
	^ self tool
		  executeMutationAction: 'changeProtocol'
		  force: false
		  requestedContext: plan requestedContext
		  work: [
				  behavior := self tool behaviorNamed: self request className classSide: self request classSide.
				  oldCompiledMethod := behavior compiledMethodAt: selectorSymbol ifAbsent: [
						                       MCPCommandError
							                       signalMissingMethodInClassName: self request className
							                       classSide: self request classSide
							                       selector: self request selector ].
				  oldProtocol := self protocolNameForMethod: oldCompiledMethod.
				  (RBMethodProtocolTransformation
					   protocol: self request protocol
					   inMethod: selectorSymbol
					   inClass: (self tool classReferenceNameFor: self request className classSide: self request classSide)) execute.
				  newCompiledMethod := behavior compiledMethodAt: selectorSymbol.
				  changeResult := (MCPMethodUpdateChangeResult updateAction: 'changeProtocol' method: newCompiledMethod)
					                  oldProtocol: oldProtocol;
					                  newProtocol: self request protocol;
					                  yourself ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
							   stream << 'Changed protocol for ' << (self tool methodReferenceForBehavior: behavior selector: selectorSymbol) << '.' ])
					  data: (self appliedUpdateResultFor: changeResult plan: plan) asDictionary
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForChangeProtocolClassNamed: self request className
					  classSide: self request classSide
					  selector: self request selector
					  protocol: self request protocol
					  error: error ]
]

{ #category : 'executing' }
MCPUpdateMethodCommand >> executePlan: plan [

	| actionBlock |
	actionBlock := self executeBlockForAction: plan updateAction.
	actionBlock ifNotNil: [ ^ actionBlock value: plan ].
	^ self tool
		  errorResultForCommandError: (MCPCommandError new
				   errorCode: #UnknownMethodUpdateAction;
				   messageText: 'Unknown method update action: ' , plan updateAction;
				   details: plan requestedContext;
				   yourself)
		  action: 'update'
		  requestedContext: plan requestedContext
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeRemoveArgumentsWithPlan: plan [

	| behavior changeResult currentSelector newCompiledMethod newSelectorSymbol oldArgumentNames oldMethodReference oldSelectorSymbol refactoring refactoringModel removedArgumentNames |
	oldSelectorSymbol := self request selector asSymbol.
	newSelectorSymbol := self request newSelector asSymbol.
	^ self tool
		  executeMutationAction: 'removeArguments'
		  force: self request force
		  requestedContext: plan requestedContext
		  work: [
				  behavior := self tool behaviorNamed: self request className classSide: self request classSide.
				  behavior compiledMethodAt: oldSelectorSymbol ifAbsent: [
						  MCPCommandError
							  signalMissingMethodInClassName: self request className
							  classSide: self request classSide
							  selector: self request selector ].
				  oldArgumentNames := (behavior parseTreeForSelector: oldSelectorSymbol) argumentNames.
				  removedArgumentNames := self request removedArgumentNamesInRemovalOrderFor: behavior from: oldArgumentNames.
				  refactoringModel := self tool refactoringModelForScopeSpec: self request refactoringScopeSpec anchoredAtBehavior: behavior.
				  oldMethodReference := self tool methodReferenceForBehavior: behavior selector: oldSelectorSymbol.
				  currentSelector := oldSelectorSymbol.
				  removedArgumentNames doWithIndex: [ :argumentName :index |
						  | nextSelector |
						  nextSelector := index = removedArgumentNames size
							                  ifTrue: [ newSelectorSymbol ]
							                  ifFalse: [
							                  self selectorAfterRemovingArgumentNamed: argumentName fromBehavior: behavior selector: currentSelector ].
						  refactoring := self tool
							                 removeParameterRefactoringForArgumentNamed: argumentName
							                 inBehavior: behavior
							                 selector: currentSelector
							                 model: refactoringModel.
						  refactoring newSelector: nextSelector.
						  refactoring execute.
						  currentSelector := nextSelector ].
				  newCompiledMethod := self tool reformattedMethodForBehavior: behavior selector: newSelectorSymbol.
				  changeResult := (MCPMethodUpdateChangeResult updateAction: 'removeArguments' method: newCompiledMethod)
					                  oldSelector: self request selector;
					                  newSelector: self request newSelector;
					                  yourself ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
								   stream << 'Removed arguments from ' << oldMethodReference << ' as '
								   << (self tool methodReferenceForBehavior: behavior selector: newSelectorSymbol) << '.' ])
					  data: (self appliedUpdateResultFor: changeResult plan: plan) asDictionary
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForArgumentUpdateAction: 'removeArguments'
					  classNamed: self request className
					  classSide: self request classSide
					  selector: self request selector
					  newSelector: self request newSelector
					  error: error ]
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeRenameWithPlan: plan [

	| behavior changeResult newCompiledMethod newSelectorSymbol oldMethodReference oldSelectorSymbol refactoring refactoringModel renameMap |
	oldSelectorSymbol := self request selector asSymbol.
	newSelectorSymbol := self request newSelector asSymbol.
	^ self tool
		  executeMutationAction: 'rename'
		  force: self request force
		  requestedContext: plan requestedContext
		  work: [
				  behavior := self tool behaviorNamed: self request className classSide: self request classSide.
				  behavior compiledMethodAt: oldSelectorSymbol ifAbsent: [
						  MCPCommandError
							  signalMissingMethodInClassName: self request className
							  classSide: self request classSide
							  selector: self request selector ].
				  refactoringModel := self tool refactoringModelForScopeSpec: self request refactoringScopeSpec anchoredAtBehavior: behavior.
				  oldMethodReference := self tool methodReferenceForBehavior: behavior selector: oldSelectorSymbol.
				  refactoring := self tool
					                 renameRefactoringForSelector: oldSelectorSymbol
					                 inBehavior: behavior
					                 to: newSelectorSymbol
					                 permutation: (self request permutationForBehavior: behavior)
					                 model: refactoringModel.
				  renameMap := self request argumentRenameMapForBehavior: behavior.
				  renameMap ifNotEmpty: [ refactoring renameMap: renameMap ].
				  refactoring execute.
				  newCompiledMethod := self tool reformattedMethodForBehavior: behavior selector: newSelectorSymbol.
				  changeResult := (MCPMethodUpdateChangeResult updateAction: 'rename' method: newCompiledMethod)
					                  oldSelector: self request selector;
					                  newSelector: self request newSelector;
					                  yourself ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (String streamContents: [ :stream |
								   stream << 'Renamed ' << oldMethodReference << ' to '
								   << (self tool methodReferenceForBehavior: behavior selector: newSelectorSymbol) << '.' ])
					  data: (self appliedUpdateResultFor: changeResult plan: plan) asDictionary
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self tool
					  failureMessageForRenameClassNamed: self request className
					  classSide: self request classSide
					  selector: self request selector
					  newSelector: self request newSelector
					  error: error ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> planForAction: action [

	^ MCPMethodUpdatePlanInfo updateAction: action requestedContext: (self requestedContextForAction: action)
]

{ #category : 'private - methods' }
MCPUpdateMethodCommand >> protocolNameForMethod: aCompiledMethod [

	^ aCompiledMethod protocol ifNil: [ '' ] ifNotNil: [ :aProtocol | aProtocol name asString ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> requestedContextForAction: action [

	| context |
	context := self request requestedContext copy.
	(#( 'rename' 'addArguments' 'removeArguments' ) includes: action) ifTrue: [
		self tool addRefactoringScopeContextFromSpec: self request refactoringScopeSpec toRequestedContext: context ].
	^ context
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> selectorAfterRemovingArgumentNamed: argumentName fromBehavior: aBehavior selector: selectorSymbol [

	| argumentIndex keywords parseTree |
	parseTree := aBehavior parseTreeForSelector: selectorSymbol.
	parseTree ifNil: [ Error signal: 'Cannot parse sources' ].
	argumentIndex := parseTree argumentNames indexOf: argumentName ifAbsent: [ Error signal: 'Argument does not exist' ].
	keywords := selectorSymbol keywords asOrderedCollection.
	keywords size = 1 ifTrue: [ ^ (keywords first copyWithout: $:) asSymbol ].
	keywords removeAt: argumentIndex.
	^ (String streamContents: [ :stream | keywords do: [ :each | stream nextPutAll: each ] ]) asSymbol
]

{ #category : 'private - signaling' }
MCPUpdateMethodCommand >> signalNoUpdateRequested [

	^ MCPCommandError
		  signalErrorCode: #NoMethodUpdateRequested
		  message: 'Method update requires one method update field such as newSelector or protocol.'
		  details: self request requestedContext
]

{ #category : 'accessing' }
MCPUpdateMethodCommand >> updateAction [
	"The first change the request asks for. Execution goes through updateActions."

	^ self updateActions first updateAction
]

{ #category : 'accessing' }
MCPUpdateMethodCommand >> updateActions [
	"Every change the request asks for, as plans, in the order they must be applied."

	| plans |
	self request validateForUpdate.
	plans := self request requestedMethodUpdateActions collect: [ :action | self planForAction: action ].
	plans ifEmpty: [ self signalNoUpdateRequested ].
	^ self actionsInApplicationOrder: plans
]

{ #category : 'accessing' }
MCPUpdateMethodCommand >> updatePlan [

	^ self updateActions first
]

{ #category : 'private - results' }
MCPUpdateMethodCommand >> updateSubjectDescription [

	^ String streamContents: [ :stream | stream << 'method ' << self request className << '>>' << self request selector ]
]
