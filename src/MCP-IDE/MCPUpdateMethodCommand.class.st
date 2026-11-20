"
Changes one method's selector within a refactoring environment, updating its senders there: a rename, or arguments added or removed, as the arities of the two selectors say.

It plans the change from the keywords of the two selectors, each argument going with its keyword, and from the argument names: which kept arguments are renamed, what the added ones are called, and in what order the removed ones go. Senders pass nil for an added argument.
"
Class {
	#name : 'MCPUpdateMethodCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'behavior',
		'selector',
		'newSelector',
		'permutation',
		'argumentNames',
		'environment'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPUpdateMethodCommand class >> changing: oldSelector of: aBehavior to: newSelector argumentNames: names environment: anEnvironment [

	^ self new
		  initializeChanging: oldSelector
		  of: aBehavior
		  to: newSelector
		  argumentNames: names
		  environment: anEnvironment
]

{ #category : 'planning' }
MCPUpdateMethodCommand class >> permutationFrom: oldSelector to: newSelector [
	"One entry per argument of newSelector: the index of the argument of oldSelector it takes, or a negative number for a new one. Each keyword takes the argument of the same keyword of oldSelector, wherever it moves. A keyword oldSelector lacks takes the first argument no keyword took, or, once none is left, is a new argument, numbered -1, -2 and on."

	| oldKeywords shared taken untaken newArgument |
	newSelector numArgs = 0 ifTrue: [ ^ #(  ) ].
	oldKeywords := oldSelector keywords.
	taken := Set new.
	shared := newSelector keywords collect: [ :keyword |
			          (1 to: oldSelector numArgs)
				          detect: [ :index | (oldKeywords at: index) = keyword and: [ (taken includes: index) not ] ]
				          ifFound: [ :index | taken add: index ]
				          ifNone: [ 0 ] ].
	untaken := ((1 to: oldSelector numArgs) reject: [ :index | taken includes: index ]) asOrderedCollection.
	newArgument := 0.
	^ shared collect: [ :index |
			  index > 0
				  ifTrue: [ index ]
				  ifFalse: [ untaken ifEmpty: [ newArgument := newArgument - 1 ] ifNotEmpty: [ untaken removeFirst ] ] ]
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> addArguments [

	(RBAddParameterRefactoring
		 model: self refactoringModel
		 addParameterToMethod: selector
		 in: behavior
		 newSelector: newSelector
		 permutation: permutation
		 newArgs: self addedArguments) execute
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> addedArguments [
	"The arguments the new selector adds, each named by the call; senders pass nil for them."

	^ (1 to: permutation size)
		  select: [ :targetIndex | (permutation at: targetIndex) <= 0 ]
		  thenCollect: [ :targetIndex | RBArgumentName name: (argumentNames at: targetIndex) value: 'nil' ]
]

{ #category : 'executing' }
MCPUpdateMethodCommand >> execute [
	"Rename the method, or add or remove arguments, as the arities of the two selectors say, updating its senders across the environment, then give its arguments the names the call gave."

	newSelector numArgs > selector numArgs
		ifTrue: [ self addArguments ]
		ifFalse: [
				newSelector numArgs < selector numArgs
					ifTrue: [ self removeArguments ]
					ifFalse: [ self rename ] ].
	self nameArguments
]

{ #category : 'initialization' }
MCPUpdateMethodCommand >> initializeChanging: oldSelector of: aBehavior to: aSelector argumentNames: names environment: anEnvironment [

	selector := oldSelector.
	behavior := aBehavior.
	newSelector := aSelector.
	permutation := self class permutationFrom: oldSelector to: aSelector.
	argumentNames := names.
	environment := anEnvironment
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> nameArguments [
	"Rename the arguments the method kept to the names the call gave, in one pass so that two of them can trade names. The refactoring named the ones it added, and renamed one whose name was taken."

	| rewriter tree |
	argumentNames ifEmpty: [ ^ self ].
	tree := behavior parseTreeForSelector: newSelector.
	rewriter := RBParseTreeRewriter new.
	tree argumentNames withIndexDo: [ :current :index |
			| name |
			name := argumentNames at: index.
			((permutation at: index) > 0 and: [ current ~= name ]) ifTrue: [
					rewriter
						replace: current with: name;
						replaceArgument: current with: name ] ].
	(rewriter executeTree: tree) ifTrue: [ behavior compile: rewriter tree newSource classified: (behavior >> newSelector) protocol ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> newSelectorInKeptOrder [
	"The new selector with its keywords in the order of the arguments they take, which is the order a removal leaves them in."

	| keywords |
	permutation ifEmpty: [ ^ newSelector ].
	keywords := newSelector keywords.
	^ ('' join: (permutation asSortedCollection collect: [ :each | keywords at: (permutation indexOf: each) ])) asSymbol
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> refactoringModel [
	"A refactoring performs every change its model holds, so each one gets a model of its own: sharing one would perform again what the ones before it changed."

	^ RBNamespace onEnvironment: environment
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> refuseSelectorsInUse: someSelectors [
	"Each step renames every implementor of the selector it starts from and rewrites every sender of it, so a selector the change passes through that something in the environment already implements or sends, or the class inherits, would take that along."

	| scope |
	scope := self refactoringModel.
	someSelectors
		detect: [ :each |
			(behavior canUnderstand: each) or: [
				(scope allImplementorsOf: each) isNotEmpty or: [ (scope allReferencesTo: each) isNotEmpty ] ] ]
		ifFound: [ :each |
				MCPCommandError
					signalErrorCode: #IntermediateSelectorInUse
					message:
						('Removing these arguments passes through {1}, which is already in use in scope and would change too: remove one argument per call, reorder the keywords in a call of their own, or narrow scope.'
							 format: { each })
					details: Dictionary new ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> removalSteps [
	"Each argument to remove, last first, with the selector its removal leaves: the one before without that argument's keyword, or for the last one the new selector's keywords in the order of the arguments they take."

	| keywords names removed |
	keywords := selector keywords asOrderedCollection.
	names := (behavior parseTreeForSelector: selector) argumentNames.
	removed := ((1 to: selector numArgs) reject: [ :index | permutation includes: index ]) reversed.
	^ removed withIndexCollect: [ :index :step |
			  keywords removeAt: index.
			  (names at: index) -> (step = removed size
				   ifTrue: [ self newSelectorInKeptOrder ]
				   ifFalse: [ ('' join: keywords) asSymbol ]) ]
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> removeArguments [
	"One refactoring per argument, last first so that each removal leaves the indexes of the ones still to remove as they were. A removal keeps the other arguments in their order, so the last one leaves the new selector's keywords in the order of the arguments they take, and a rename then reorders them."

	| last steps |
	steps := self removalSteps.
	self refuseSelectorsInUse: ((steps collect: [ :each | each value ]) copyWithout: newSelector).
	last := steps inject: selector into: [ :current :step |
			        (RBRemoveParameterRefactoring
				         model: self refactoringModel
				         removeParameter: step key
				         in: behavior
				         selector: current)
				        newSelector: step value;
				        execute.
			        step value ].
	last = newSelector ifFalse: [
			(self class
				 changing: last
				 of: behavior
				 to: newSelector
				 argumentNames: #(  )
				 environment: environment) execute ]
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> rename [

	(ReRenameMethodRefactoring
		 model: self refactoringModel
		 renameMethod: selector
		 in: behavior
		 to: newSelector
		 permutation: permutation) execute
]
