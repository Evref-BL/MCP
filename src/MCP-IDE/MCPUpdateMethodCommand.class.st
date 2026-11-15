"
Changes one method's selector across a refactoring model, updating its senders: a rename, or arguments added or removed, as the arities of the two selectors say.

It plans the change from the permutation, which maps each argument of the new selector to the old one it takes or to none, and from the argument names: which kept arguments are renamed, what the added ones are called and what senders pass for them, and in what order the removed ones go.
"
Class {
	#name : 'MCPUpdateMethodCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'behavior',
		'model',
		'selector',
		'newSelector',
		'permutation',
		'argumentNames',
		'argumentValueExpressions'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPUpdateMethodCommand class >> changing: oldSelector of: aBehavior to: newSelector permutation: anArray argumentNames: names argumentValueExpressions: expressions model: aModel [

	^ self new
		  initializeChanging: oldSelector
		  of: aBehavior
		  to: newSelector
		  permutation: anArray
		  argumentNames: names
		  argumentValueExpressions: expressions
		  model: aModel
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand class >> defaultPermutationFrom: oldSelector to: newSelector [
	"The permutation a selector change implies when the caller gives none: one entry per argument of newSelector, holding the index of the argument of oldSelector it takes, or a negative number for a new one."

	| newArgumentCount oldArgumentCount |
	oldArgumentCount := oldSelector numArgs.
	newArgumentCount := newSelector numArgs.
	oldArgumentCount = newArgumentCount ifTrue: [ ^ (1 to: oldArgumentCount) asArray ].
	newArgumentCount = 0 ifTrue: [ ^ #(  ) ].
	oldArgumentCount = 0 ifTrue: [ ^ (1 to: newArgumentCount) collect: [ :index | index negated ] as: Array ].
	^ self keywordPermutationFrom: oldSelector to: newSelector
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand class >> keywordPermutationFrom: oldSelector to: newSelector [
	"Each keyword of newSelector takes the argument of the same keyword of oldSelector, and a keyword oldSelector lacks is a new argument, numbered -1, -2 and on."

	| nextNewArgument oldKeywords usedOldIndexes |
	oldKeywords := oldSelector keywords.
	usedOldIndexes := Set new.
	nextNewArgument := 0.
	^ newSelector keywords
		  collect: [ :keyword |
				  | oldIndex |
				  oldIndex := self unusedIndexOf: keyword in: oldKeywords excluding: usedOldIndexes.
				  oldIndex = 0
					  ifTrue: [
							  nextNewArgument := nextNewArgument + 1.
							  nextNewArgument negated ]
					  ifFalse: [
							  usedOldIndexes add: oldIndex.
							  oldIndex ] ]
		  as: Array
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand class >> unusedIndexOf: keyword in: oldKeywords excluding: usedOldIndexes [

	1 to: oldKeywords size do: [ :index |
	((oldKeywords at: index) = keyword and: [ (usedOldIndexes includes: index) not ]) ifTrue: [ ^ index ] ].
	^ 0
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> addArguments [

	self executeRenamingArguments: (RBAddParameterRefactoring
			 model: model
			 addParameterToMethod: selector
			 in: behavior
			 newSelector: newSelector
			 permutation: permutation
			 newArgs: self addedArguments)
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> addedArguments [
	"The arguments the new selector adds, each named by the call or anArgument1 and on, with what senders pass for it."

	| newArgumentIndex |
	newArgumentIndex := 0.
	^ (1 to: permutation size) select: [ :targetIndex | (permutation at: targetIndex) <= 0 ] thenCollect: [ :targetIndex |
			  | argumentName defaultExpression |
			  newArgumentIndex := newArgumentIndex + 1.
			  argumentName := argumentNames at: targetIndex ifAbsent: [ 'anArgument' , newArgumentIndex asString ].
			  defaultExpression := self argumentValueExpressionAt: newArgumentIndex.
			  RBArgumentName name: argumentName value: defaultExpression ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> argumentRenameMap [
	"Each argument the method keeps under another name, as the refactorings take it."

	| oldArgumentNames renameMap |
	argumentNames isEmpty ifTrue: [ ^ #(  ) ].
	oldArgumentNames := self oldArgumentNames.
	oldArgumentNames ifEmpty: [ ^ #(  ) ].
	renameMap := OrderedCollection new.
	1 to: permutation size do: [ :targetIndex |
			| oldIndex newArgumentName oldArgumentName renameArgument |
			oldIndex := permutation at: targetIndex.
			oldIndex > 0 ifTrue: [
					oldArgumentName := oldArgumentNames at: oldIndex.
					newArgumentName := argumentNames at: targetIndex.
					oldArgumentName = newArgumentName ifFalse: [
							renameArgument := RBArgumentName name: oldArgumentName.
							renameArgument newName: newArgumentName.
							renameMap add: renameArgument ] ] ].
	^ renameMap asArray
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> argumentValueExpressionAt: newArgumentIndex [
	"What senders pass for the added argument at newArgumentIndex; nil when the call gave no expressions."

	argumentValueExpressions isEmpty ifTrue: [ ^ 'nil' ].
	^ argumentValueExpressions at: newArgumentIndex
]

{ #category : 'executing' }
MCPUpdateMethodCommand >> execute [
	"Rename the method, or add or remove arguments, as the arities of the two selectors say, updating its senders across the model."

	newSelector numArgs > selector numArgs ifTrue: [ ^ self addArguments ].
	newSelector numArgs < selector numArgs ifTrue: [ ^ self removeArguments ].
	^ self rename
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> executeRenamingArguments: aRefactoring [

	| renameMap |
	renameMap := self argumentRenameMap.
	renameMap ifNotEmpty: [ aRefactoring renameMap: renameMap ].
	aRefactoring execute
]

{ #category : 'initialization' }
MCPUpdateMethodCommand >> initializeChanging: oldSelector of: aBehavior to: aSelector permutation: anArray argumentNames: names argumentValueExpressions: expressions model: aModel [

	selector := oldSelector.
	behavior := aBehavior.
	newSelector := aSelector.
	permutation := anArray.
	argumentNames := names.
	argumentValueExpressions := expressions.
	model := aModel
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> oldArgumentNames [

	^ (behavior parseTreeForSelector: selector) ifNil: [ #(  ) ] ifNotNil: [ :parseTree | parseTree argumentNames ]
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> removeArguments [
	"One refactoring per argument, in removal order; the last one gives the requested selector."

	| currentSelector removedArgumentNames |
	currentSelector := selector.
	removedArgumentNames := self removedArgumentNamesInRemovalOrderFrom:
		                        (behavior parseTreeForSelector: currentSelector) argumentNames.
	removedArgumentNames doWithIndex: [ :argumentName :index |
			| nextSelector refactoring |
			nextSelector := index = removedArgumentNames size
				                ifTrue: [ newSelector ]
				                ifFalse: [ self selectorAfterRemovingArgumentNamed: argumentName selector: currentSelector ].
			refactoring := RBRemoveParameterRefactoring
				               model: model
				               removeParameter: argumentName
				               in: behavior
				               selector: currentSelector.
			refactoring newSelector: nextSelector.
			refactoring execute.
			currentSelector := nextSelector ]
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> removedArgumentIndexes [
	"The indexes of the arguments of the old selector the permutation does not keep."

	| keptIndexes |
	keptIndexes := permutation asSet.
	^ ((1 to: selector numArgs) reject: [ :index | keptIndexes includes: index ]) asArray
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> removedArgumentNamesInRemovalOrderFrom: oldArgumentNames [
	"Last first, so that each removal leaves the indexes of the ones still to remove as they were."

	^ (self removedArgumentIndexes asArray sort: [ :left :right | left > right ]) collect: [ :index | oldArgumentNames at: index ]
]

{ #category : 'private - refactoring' }
MCPUpdateMethodCommand >> rename [

	self executeRenamingArguments: (ReRenameMethodRefactoring
			 model: model
			 renameMethod: selector
			 in: behavior
			 to: newSelector
			 permutation: permutation)
]

{ #category : 'private - planning' }
MCPUpdateMethodCommand >> selectorAfterRemovingArgumentNamed: argumentName selector: selectorSymbol [

	| argumentIndex keywords parseTree |
	parseTree := behavior parseTreeForSelector: selectorSymbol.
	parseTree ifNil: [ Error signal: 'Cannot parse sources' ].
	argumentIndex := parseTree argumentNames indexOf: argumentName ifAbsent: [ Error signal: 'Argument does not exist' ].
	keywords := selectorSymbol keywords asOrderedCollection.
	keywords size = 1 ifTrue: [ ^ (keywords first copyWithout: $:) asSymbol ].
	keywords removeAt: argumentIndex.
	^ (String streamContents: [ :stream | keywords do: [ :each | stream nextPutAll: each ] ]) asSymbol
]
