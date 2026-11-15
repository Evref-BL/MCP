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

	^ self
		  executeSelectorChange: 'addArguments'
		  plan: plan
		  summary: 'Added arguments to {1} as {2}.'
		  refactor: [ :behavior :model |
				  self
					  executeRefactoring: (self tool
							   addParameterRefactoringForSelector: self request selector asSymbol
							   inBehavior: behavior
							   to: self request newSelector asSymbol
							   permutation: (self request permutationForBehavior: behavior)
							   newArgs: (self request newArgumentSpecsForBehavior: behavior)
							   model: model)
					  renamingArgumentsIn: behavior ]
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
				  behavior := self updateTargetBehavior.
				  oldCompiledMethod := behavior
					                       compiledMethodAt: selectorSymbol
					                       ifAbsent: [ MCPCommandError signalMissingMethod: self request selector in: behavior ].
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
					  successResultText: (self
							   protocolChangeSummaryFor: (self tool methodReferenceForBehavior: behavior selector: selectorSymbol)
							   from: oldProtocol
							   to: (self protocolNameForMethod: newCompiledMethod))
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
MCPUpdateMethodCommand >> executeRefactoring: aRefactoring renamingArgumentsIn: aBehavior [

	| renameMap |
	renameMap := self request argumentRenameMapForBehavior: aBehavior.
	renameMap ifNotEmpty: [ aRefactoring renameMap: renameMap ].
	aRefactoring execute
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeRemoveArgumentsWithPlan: plan [

	^ self
		  executeSelectorChange: 'removeArguments'
		  plan: plan
		  summary: 'Removed arguments from {1} as {2}.'
		  refactor: [ :behavior :model | self removeArgumentsFrom: behavior model: model ]
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeRenameWithPlan: plan [

	^ self
		  executeSelectorChange: 'rename'
		  plan: plan
		  summary: 'Renamed {1} to {2}.'
		  refactor: [ :behavior :model |
				  self
					  executeRefactoring: (self tool
							   renameRefactoringForSelector: self request selector asSymbol
							   inBehavior: behavior
							   to: self request newSelector asSymbol
							   permutation: (self request permutationForBehavior: behavior)
							   model: model)
					  renamingArgumentsIn: behavior ]
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeSelectorChange: action plan: plan summary: summaryFormat refactor: refactorBlock [
	"A rename, or arguments added or removed: the method is looked up, refactorBlock runs the refactoring on it with the scope's model, and the answer names the method before and after, as summaryFormat says."

	| behavior changeResult newSelectorSymbol oldMethodReference oldSelectorSymbol |
	oldSelectorSymbol := self request selector asSymbol.
	newSelectorSymbol := self request newSelector asSymbol.
	^ self tool
		  executeMutationAction: action
		  force: self request force
		  requestedContext: plan requestedContext
		  work: [
				  behavior := self updateTargetBehavior.
				  behavior
					  compiledMethodAt: oldSelectorSymbol
					  ifAbsent: [ MCPCommandError signalMissingMethod: self request selector in: behavior ].
				  oldMethodReference := self tool methodReferenceForBehavior: behavior selector: oldSelectorSymbol.
				  refactorBlock
					  value: behavior
					  value: (self tool refactoringModelForScopeSpec: self request refactoringScopeSpec anchoredAtBehavior: behavior).
				  changeResult := (MCPMethodUpdateChangeResult
					                   updateAction: action
					                   method: (self tool reformattedMethodForBehavior: behavior selector: newSelectorSymbol))
					                  oldSelector: self request selector;
					                  newSelector: self request newSelector;
					                  yourself ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (summaryFormat format: {
								   oldMethodReference.
								   (self tool methodReferenceForBehavior: behavior selector: newSelectorSymbol) })
					  data: (self appliedUpdateResultFor: changeResult plan: plan) asDictionary
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  action = 'rename'
					  ifTrue: [
							  self tool
								  failureMessageForRenameClassNamed: self request className
								  classSide: self request classSide
								  selector: self request selector
								  newSelector: self request newSelector
								  error: error ]
					  ifFalse: [
							  self tool
								  failureMessageForArgumentUpdateAction: action
								  classNamed: self request className
								  classSide: self request classSide
								  selector: self request selector
								  newSelector: self request newSelector
								  error: error ] ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> planForAction: action [

	^ MCPMethodUpdatePlanInfo updateAction: action requestedContext: (self requestedContextForAction: action)
]

{ #category : 'private - methods' }
MCPUpdateMethodCommand >> protocolChangeSummaryFor: methodReference from: oldProtocolName to: newProtocolName [
	"Moved EvalLedger>>audit from as yet unclassified to accounting., in the words method_compile uses when a replace moves a method; EvalLedger>>audit is already in accounting. when it was there before."

	^ String streamContents: [ :stream |
			  oldProtocolName = newProtocolName
				  ifTrue: [
						  stream
							  nextPutAll: methodReference;
							  nextPutAll: ' is already in ';
							  nextPutAll: (self protocolTextFor: newProtocolName) ]
				  ifFalse: [
						  stream
							  nextPutAll: 'Moved ';
							  nextPutAll: methodReference;
							  nextPutAll: ' from ';
							  nextPutAll: (self protocolTextFor: oldProtocolName);
							  nextPutAll: ' to ';
							  nextPutAll: (self protocolTextFor: newProtocolName) ].
			  stream nextPut: $. ]
]

{ #category : 'private - methods' }
MCPUpdateMethodCommand >> protocolNameForMethod: aCompiledMethod [

	^ aCompiledMethod protocolName ifNil: [ '' ] ifNotNil: [ :aProtocol | aProtocol asString ]
]

{ #category : 'private - methods' }
MCPUpdateMethodCommand >> protocolTextFor: aProtocolName [
	"A method filed under no protocol has an empty name, which a sentence calls no protocol."

	^ aProtocolName isEmptyOrNil
		  ifTrue: [ 'no protocol' ]
		  ifFalse: [ aProtocolName ]
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> removeArgumentsFrom: aBehavior model: aModel [
	"One refactoring per argument, in the request's removal order; the last one gives the requested selector."

	| currentSelector removedArgumentNames |
	currentSelector := self request selector asSymbol.
	removedArgumentNames := self request
		                        removedArgumentNamesInRemovalOrderFor: aBehavior
		                        from: (aBehavior parseTreeForSelector: currentSelector) argumentNames.
	removedArgumentNames doWithIndex: [ :argumentName :index |
			| nextSelector refactoring |
			nextSelector := index = removedArgumentNames size
				                ifTrue: [ self request newSelector asSymbol ]
				                ifFalse: [
				                self selectorAfterRemovingArgumentNamed: argumentName fromBehavior: aBehavior selector: currentSelector ].
			refactoring := self tool
				               removeParameterRefactoringForArgumentNamed: argumentName
				               inBehavior: aBehavior
				               selector: currentSelector
				               model: aModel.
			refactoring newSelector: nextSelector.
			refactoring execute.
			currentSelector := nextSelector ]
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

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> updateTargetBehavior [
	"The behaviour every update action works on. A method the class got from a trait is the trait's to rename, recategorize or re-argument, so the four actions stop here rather than each learning what a trait is."

	| behavior |
	behavior := self tool behaviorNamed: self request className classSide: self request classSide.
	self tool signalTraitOriginBeforeUpdating: self request selector in: behavior.
	^ behavior
]
