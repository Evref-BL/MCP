"
Command for applying one high-level edit-method update patch. It selects an internal method update action, executes it, and returns structured method update DTOs.
"
Class {
	#name : 'MCPUpdateMethodCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPUpdateMethodCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - results' }
MCPUpdateMethodCommand >> appliedUpdateResultFor: aChangeResult plan: plan [

	^ MCPMethodAppliedChangeResult
		  updatePlan: plan
		  changeResult: aChangeResult
]

{ #category : 'executing' }
MCPUpdateMethodCommand >> execute [

	| plan |
	[ plan := self updatePlan ]
		on: MCPCommandError
		do: [ :error |
			^ self tool
				  errorResultForCommandError: error
				  operation: 'update'
				  requestedContext: self request requestedContext ].
	^ self executePlan: plan
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeChangeProtocolWithPlan: plan [

	| behavior changeResult newCompiledMethod oldCompiledMethod oldProtocol selectorSymbol |
	selectorSymbol := self request selector asSymbol.
	^ self tool
		  executeEditOperation: 'changeProtocol'
		  force: self request force
		  requestedContext: plan requestedContext
		  work: [
			  behavior := self tool
				              behaviorNamed: self request className
				              classSide: self request classSide.
			  oldCompiledMethod := behavior
				                       compiledMethodAt: selectorSymbol
				                       ifAbsent: [
					                       MCPCommandError
						                       signalMissingMethodInClassName:
						                       self request className
						                       classSide: self request classSide
						                       selector: self request selector ].
			  oldProtocol := self protocolNameForMethod: oldCompiledMethod.
			  (RBMethodProtocolTransformation
				   protocol: self request protocol
				   inMethod: selectorSymbol
				   inClass: (self tool
						    classReferenceNameFor: self request className
						    classSide: self request classSide)) execute.
			  newCompiledMethod := behavior compiledMethodAt: selectorSymbol.
			  changeResult := (MCPMethodUpdateChangeResult
				                   operation: 'changeProtocol'
				                   method: newCompiledMethod)
				                  oldProtocol: oldProtocol;
				                  newProtocol: self request protocol;
				                  yourself ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: 'Changed protocol for ' , (self tool
						   methodReferenceForBehavior: behavior
						   selector: selectorSymbol) , '.'
				  data:
				  (self appliedUpdateResultFor: changeResult plan: plan)
					  asDictionary
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self tool
				  failureMessageForChangeProtocolClassNamed:
				  self request className
				  classSide: self request classSide
				  selector: self request selector
				  protocol: self request protocol
				  error: error ]
]

{ #category : 'executing' }
MCPUpdateMethodCommand >> executePlan: plan [

	| selector |
	selector := self executeSelectorForAction: plan operation.
	selector ifNotNil: [ ^ self perform: selector with: plan ].
	^ self tool
		  errorResultForCommandError: (MCPCommandError new
				   errorCode: #UnknownMethodUpdateAction;
				   messageText: 'Unknown method update action: ' , plan operation;
				   details: plan requestedContext;
				   yourself)
		  operation: 'update'
		  requestedContext: plan requestedContext
]

{ #category : 'executing - method' }
MCPUpdateMethodCommand >> executeRenameWithPlan: plan [

	| behavior changeResult newCompiledMethod newSelectorSymbol oldMethodReference oldSelectorSymbol refactoring refactoringModel |
	oldSelectorSymbol := self request selector asSymbol.
	newSelectorSymbol := self request newSelector asSymbol.
	^ self tool
		  executeEditOperation: 'rename'
		  force: self request force
		  requestedContext: plan requestedContext
		  work: [
			  behavior := self tool
				              behaviorNamed: self request className
				              classSide: self request classSide.
			  behavior compiledMethodAt: oldSelectorSymbol ifAbsent: [
				  MCPCommandError
					  signalMissingMethodInClassName: self request className
					  classSide: self request classSide
					  selector: self request selector ].
			  refactoringModel := self tool
				                      refactoringModelForScopeSpec:
				                      self request refactoringScopeSpec
				                      anchoredAtBehavior: behavior.
			  oldMethodReference := self tool
				                        methodReferenceForBehavior: behavior
				                        selector: oldSelectorSymbol.
			  refactoring := self tool
				                 renameRefactoringForSelector: oldSelectorSymbol
				                 inBehavior: behavior
				                 to: newSelectorSymbol
				                 permutation: self request permutation
				                 model: refactoringModel.
			  refactoring execute.
			  newCompiledMethod := self tool
				                       reformattedMethodForBehavior: behavior
				                       selector: newSelectorSymbol.
			  changeResult := (MCPMethodUpdateChangeResult
				                   operation: 'rename'
				                   method: newCompiledMethod)
				                  oldSelector: self request selector;
				                  newSelector: self request newSelector;
				                  yourself ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Renamed ' , oldMethodReference , ' to ' , (self tool
						   methodReferenceForBehavior: behavior
						   selector: newSelectorSymbol) , '.'
				  data:
				  (self appliedUpdateResultFor: changeResult plan: plan)
					  asDictionary
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
MCPUpdateMethodCommand >> executeSelectorForAction: action [

	| selectors |
	selectors := {
		             ('rename' -> #executeRenameWithPlan:).
		             ('changeProtocol' -> #executeChangeProtocolWithPlan:) }
		             asDictionary.
	^ selectors at: action ifAbsent: [ nil ]
]

{ #category : 'initialization' }
MCPUpdateMethodCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - methods' }
MCPUpdateMethodCommand >> protocolNameForMethod: aCompiledMethod [

	^ aCompiledMethod protocol
		  ifNil: [ '' ]
		  ifNotNil: [ :aProtocol | aProtocol name asString ]
]

{ #category : 'accessing' }
MCPUpdateMethodCommand >> request [

	^ request
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> requestedContextForAction: action [

	| context |
	context := self request requestedContext copy.
	action = 'rename' ifTrue: [
		self tool
			addRefactoringScopeContextFromSpec:
			self request refactoringScopeSpec
			toRequestedContext: context ].
	^ context
]

{ #category : 'private - signaling' }
MCPUpdateMethodCommand >> signalAmbiguousUpdateActions: actions [

	^ MCPCommandError
		  signalErrorCode: #AmbiguousMethodUpdateRequest
		  message:
		  'update accepts one method edit action per request. Split multiple edits into separate requests.'
		  details: (self request requestedContext
				   at: #updateActions put: actions;
				   yourself)
]

{ #category : 'private - signaling' }
MCPUpdateMethodCommand >> signalNoUpdateRequested [

	^ MCPCommandError
		  signalErrorCode: #NoMethodUpdateRequested
		  message:
		  'operation=update requires one method update field such as newSelector or protocol.'
		  details: self request requestedContext
]

{ #category : 'accessing' }
MCPUpdateMethodCommand >> tool [

	^ tool
]

{ #category : 'accessing' }
MCPUpdateMethodCommand >> updateAction [

	| actions |
	self request validateForUpdate.
	actions := self request requestedMethodUpdateActions.
	actions ifEmpty: [ self signalNoUpdateRequested ].
	actions size > 1 ifTrue: [
		self signalAmbiguousUpdateActions: actions ].
	^ actions first
]

{ #category : 'accessing' }
MCPUpdateMethodCommand >> updatePlan [

	| action |
	action := self updateAction.
	^ MCPMethodUpdatePlanInfo
		  operation: action
		  requestedContext: (self requestedContextForAction: action)
]
