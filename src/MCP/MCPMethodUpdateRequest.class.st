"
Parsed method update request. It uses patch semantics: exactly one method update field selects the internal update action for an existing method. newSelector changes are classified by arity: same arity renames or reorders, higher arity adds arguments, and lower arity removes arguments.
"
Class {
	#name : 'MCPMethodUpdateRequest',
	#superclass : 'Object',
	#instVars : [
		'className',
		'classSide',
		'selector',
		'newSelector',
		'protocol',
		'permutation',
		'force',
		'suppliedProperties',
		'refactoringScopeSpec',
		'argumentNames',
		'argumentValueExpressions'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPMethodUpdateRequest class >> fromRequest: request tool: aTool [

	| parsedRequest |
	parsedRequest := self new initializeFromRequest: request.
	parsedRequest hasRenameUpdate
		ifTrue: [ parsedRequest refactoringScopeSpec: (aTool refactoringScopeSpecFromRequest: request) ]
		ifFalse: [
		parsedRequest refactoringScopeSpec: (MCPRefactoringScopeSpec packageNames: #(  ) classNames: #(  ) hierarchyClassNames: #(  )) ].
	^ parsedRequest
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> addedArgumentCount [

	^ self permutation count: [ :each | each <= 0 ]
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> argumentNames [

	^ argumentNames ifNil: [ #(  ) ]
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> argumentRenameMapForBehavior: aBehavior [

	| oldArgumentNames renameMap resolvedPermutation |
	self argumentNames isEmpty ifTrue: [ ^ #(  ) ].
	oldArgumentNames := self oldArgumentNamesForBehavior: aBehavior.
	oldArgumentNames ifEmpty: [ ^ #(  ) ].
	resolvedPermutation := self permutationForBehavior: aBehavior.
	renameMap := OrderedCollection new.
	1 to: resolvedPermutation size do: [ :targetIndex |
			| oldIndex newArgumentName oldArgumentName renameArgument |
			oldIndex := resolvedPermutation at: targetIndex.
			oldIndex > 0 ifTrue: [
					oldArgumentName := oldArgumentNames at: oldIndex.
					newArgumentName := self argumentNames at: targetIndex.
					oldArgumentName = newArgumentName ifFalse: [
							renameArgument := RBArgumentName name: oldArgumentName.
							renameArgument newName: newArgumentName.
							renameMap add: renameArgument ] ] ].
	^ renameMap asArray
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> argumentValueExpressionAt: newArgumentIndex [

	self argumentValueExpressions isEmpty ifTrue: [ ^ 'nil' ].
	^ self argumentValueExpressions at: newArgumentIndex
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> argumentValueExpressions [

	^ argumentValueExpressions ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> className [

	^ className
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> classSide [

	^ classSide = true
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> commandForTool: aTool [

	^ MCPUpdateMethodCommand tool: aTool request: self
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> contextValueForPropertyNamed: propertyName [

	propertyName = 'newSelector' ifTrue: [ ^ self newSelector ].
	propertyName = 'protocol' ifTrue: [ ^ self protocol ].
	propertyName = 'permutation' ifTrue: [ ^ self permutation ].
	propertyName = 'arguments' ifTrue: [ ^ self argumentNames ].
	propertyName = 'argumentValueExpressions' ifTrue: [ ^ self argumentValueExpressions ].
	^ nil
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> defaultPermutationFromSelector: oldSelector toSelector: newSelector [

	| newArgumentCount oldArgumentCount |
	oldArgumentCount := oldSelector numArgs.
	newArgumentCount := newSelector numArgs.
	oldArgumentCount = newArgumentCount ifTrue: [ ^ self identityPermutationForSelector: oldSelector ].
	newArgumentCount = 0 ifTrue: [ ^ #(  ) ].
	oldArgumentCount = 0 ifTrue: [ ^ ((1 to: newArgumentCount) collect: [ :index | index negated ]) asArray ].
	^ self keywordPermutationFromSelector: oldSelector toSelector: newSelector
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> force [

	^ force = true
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasArgumentNames [

	^ self hasSuppliedPropertyNamed: 'arguments'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasArgumentValueExpressions [

	^ self hasSuppliedPropertyNamed: 'argumentValueExpressions'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasPermutation [

	^ self hasSuppliedPropertyNamed: 'permutation'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasProtocolUpdate [

	^ self hasSuppliedPropertyNamed: 'protocol'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasRenameUpdate [

	^ self hasSuppliedPropertyNamed: 'newSelector'
]

{ #category : 'testing' }
MCPMethodUpdateRequest >> hasSuppliedPropertyNamed: aPropertyName [

	^ self suppliedProperties includes: aPropertyName asString
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> identityPermutationForSelector: aSelector [

	^ (1 to: aSelector numArgs) asArray
]

{ #category : 'initialization' }
MCPMethodUpdateRequest >> initializeFromRequest: request [

	suppliedProperties := self updatePropertyNames select: [ :each | request hasArgumentNamed: each ].
	className := request stringArgumentNamed: 'class'.
	classSide := (request stringArgumentNamed: 'side' default: 'instance') = 'class'.
	selector := request stringArgumentNamed: 'selector'.
	newSelector := request stringArgumentNamed: 'newSelector'.
	protocol := request stringArgumentNamed: 'protocol'.
	argumentNames := request stringCollectionArgumentNamed: 'arguments'.
	argumentValueExpressions := request stringCollectionArgumentNamed: 'argumentValueExpressions'.
	permutation := self
		               permutationFromRequest: request
		               selector: selector asSymbol
		               newSelector: (newSelector ifNotNil: [ newSelector asSymbol ]).
	force := request booleanArgumentNamed: 'force' default: false.
	^ self
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> keywordPermutationFromSelector: oldSelector toSelector: newSelector [

	| nextNewArgument oldKeywords usedOldIndexes |
	oldKeywords := oldSelector keywords.
	usedOldIndexes := Set new.
	nextNewArgument := 0.
	^ (newSelector keywords collect: [ :keyword |
			   | oldIndex |
			   oldIndex := self unusedIndexOf: keyword in: oldKeywords excluding: usedOldIndexes.
			   oldIndex = 0
				   ifTrue: [
						   nextNewArgument := nextNewArgument + 1.
						   nextNewArgument negated ]
				   ifFalse: [
						   usedOldIndexes add: oldIndex.
						   oldIndex ] ]) asArray
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> newArgumentSpecsForBehavior: aBehavior [

	| newArgumentIndex resolvedPermutation |
	newArgumentIndex := 0.
	resolvedPermutation := self permutationForBehavior: aBehavior.
	^ (1 to: resolvedPermutation size)
		  select: [ :targetIndex | (resolvedPermutation at: targetIndex) <= 0 ]
		  thenCollect: [ :targetIndex |
				  | argumentName defaultExpression |
				  newArgumentIndex := newArgumentIndex + 1.
				  argumentName := self argumentNames at: targetIndex ifAbsent: [ 'anArgument' , newArgumentIndex asString ].
				  defaultExpression := self argumentValueExpressionAt: newArgumentIndex.
				  RBArgumentName name: argumentName value: defaultExpression ]
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> newSelector [

	^ newSelector
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> newSelectorUpdateAction [

	| newArgumentCount oldArgumentCount |
	self hasRenameUpdate ifFalse: [ ^ nil ].
	oldArgumentCount := self selector asSymbol numArgs.
	newArgumentCount := self newSelector asSymbol numArgs.
	newArgumentCount > oldArgumentCount ifTrue: [ ^ 'addArguments' ].
	newArgumentCount < oldArgumentCount ifTrue: [ ^ 'removeArguments' ].
	^ 'rename'
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> oldArgumentNamesForBehavior: aBehavior [

	^ (aBehavior parseTreeForSelector: self selector asSymbol) ifNil: [ #(  ) ] ifNotNil: [ :parseTree | parseTree argumentNames ]
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> permutation [

	^ permutation ifNil: [ #(  ) ]
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> permutationForBehavior: aBehavior [
	"The index map from the new argument list to the old one. The caller gives argument names, which is what it knows, and the map falls out of them. An explicit permutation is still accepted and wins, because a reorder and a cross-rename cannot be told apart by name alone."

	| newNames oldNames |
	permutation ifNotNil: [ ^ permutation ].
	oldNames := self oldArgumentNamesForBehavior: aBehavior.
	newNames := self argumentNames.
	newNames ifEmpty: [ ^ self permutationWithoutArgumentNamesFrom: oldNames ].
	"Same arity means the names rename in place; a reorder has to say so with permutation."
	newNames size = oldNames size ifTrue: [ ^ (1 to: newNames size) asArray ].
	^ (newNames collect: [ :each | oldNames indexOf: each ]) asArray
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> permutationFromRequest: request selector: oldSelector newSelector: targetSelector [

	| requestedPermutation selectorToUse |
	selectorToUse := targetSelector ifNil: [ oldSelector ].
	requestedPermutation := request
		                        arrayArgumentNamed: 'permutation'
		                        ifAbsent: [ ^ self defaultPermutationFromSelector: oldSelector toSelector: selectorToUse ].
	self validatePermutation: requestedPermutation fromSelector: oldSelector toSelector: selectorToUse.
	^ requestedPermutation
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> permutationWithoutArgumentNamesFrom: oldNames [
	"No names and no permutation. Keeping the old arguments in order and appending the new ones is the only reading of a selector that grew; one that shrank does not say which argument goes, so ask."

	| newArity |
	newArity := self newSelector asSymbol numArgs.
	newArity >= oldNames size ifTrue: [
		^ ((1 to: oldNames size) , ((oldNames size + 1 to: newArity) collect: [ :each | 0 ])) asArray ].
	MCPCommandError
		signalErrorCode: #ArgumentNamesRequired
		message: 'Removing arguments needs arguments, naming the ones the method keeps, or permutation mapping them by index.'
		details: self requestedContext
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> protocol [

	^ protocol
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> refactoringScopeSpec [

	^ refactoringScopeSpec
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> refactoringScopeSpec: aRefactoringScopeSpec [

	refactoringScopeSpec := aRefactoringScopeSpec
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> removedArgumentIndexesForBehavior: aBehavior [

	| keptIndexes |
	keptIndexes := (self permutationForBehavior: aBehavior) asSet.
	^ ((1 to: self selector asSymbol numArgs) reject: [ :index | keptIndexes includes: index ]) asArray
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> removedArgumentNamesInRemovalOrderFor: aBehavior from: oldArgumentNames [

	^ ((self removedArgumentIndexesForBehavior: aBehavior) asArray sort: [ :left :right | left > right ]) collect: [ :index |
		  oldArgumentNames at: index ]
]

{ #category : 'converting' }
MCPMethodUpdateRequest >> requestedContext [

	| context |
	context := Dictionary new.
	context at: #class put: self className.
	self classSide ifTrue: [ context at: #side put: 'class' ].
	context at: #selector put: self selector.
	self suppliedProperties do: [ :propertyName |
		context at: propertyName asSymbol put: (self contextValueForPropertyNamed: propertyName) ].
	^ context
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> requestedMethodUpdateActions [

	| actions newSelectorAction |
	actions := OrderedCollection new.
	newSelectorAction := self newSelectorUpdateAction.
	newSelectorAction ifNotNil: [ actions add: newSelectorAction ].
	self hasProtocolUpdate ifTrue: [ actions add: 'changeProtocol' ].
	^ actions asArray
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> selector [

	^ selector
]

{ #category : 'accessing' }
MCPMethodUpdateRequest >> suppliedProperties [

	^ suppliedProperties ifNil: [ #(  ) ]
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> unusedIndexOf: keyword in: oldKeywords excluding: usedOldIndexes [

	1 to: oldKeywords size do: [ :index |
	((oldKeywords at: index) = keyword and: [ (usedOldIndexes includes: index) not ]) ifTrue: [ ^ index ] ].
	^ 0
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> updatePropertyNames [

	^ #( 'newSelector' 'protocol' 'permutation' 'arguments' 'argumentValueExpressions' )
]

{ #category : 'validating' }
MCPMethodUpdateRequest >> validateAddArgumentsUpdate [

	self argumentNames isEmpty ifTrue: [
			MCPCommandError
				signalErrorCode: #ArgumentNamesRequiredForAddedArguments
				message: 'argumentNames is required when newSelector adds method arguments.'
				details: self requestedContext ].
	self argumentNames size = self newSelector asSymbol numArgs ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentNames
				message: 'argumentNames must contain one name for each target selector argument.'
				details: self requestedContext ].
	(self argumentNames allSatisfy: [ :each | each isNotEmpty ]) ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentNames
				message: 'argumentNames must not contain empty names.'
				details: self requestedContext ].
	(self argumentValueExpressions isNotEmpty and: [ self argumentValueExpressions size ~= self addedArgumentCount ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentValueExpressions
				message: 'argumentValueExpressions must contain one expression for each newly added argument.'
				details: self requestedContext ].
	^ self
]

{ #category : 'validating' }
MCPMethodUpdateRequest >> validateForUpdate [

	| action |
	self hasPermutation ifTrue: [
			self hasRenameUpdate ifFalse: [
					MCPCommandError
						signalErrorCode: #PermutationRequiresMethodSelectorUpdate
						message: 'permutation is only valid when update changes a method selector with newSelector.'
						details: self requestedContext ] ].
	(self hasArgumentNames or: [ self hasArgumentValueExpressions ]) ifTrue: [
			self hasRenameUpdate ifFalse: [
					MCPCommandError
						signalErrorCode: #ArgumentMetadataRequiresMethodSelectorUpdate
						message: 'argumentNames and argumentValueExpressions are only valid with newSelector.'
						details: self requestedContext ] ].
	action := self newSelectorUpdateAction.
	action = 'addArguments' ifTrue: [ self validateAddArgumentsUpdate ].
	^ self
]

{ #category : 'private - request' }
MCPMethodUpdateRequest >> validatePermutation: requestedPermutation fromSelector: oldSelector toSelector: newSelector [

	| newArgumentCount oldArgumentCount positiveIndexes |
	oldArgumentCount := oldSelector numArgs.
	newArgumentCount := newSelector numArgs.
	requestedPermutation size = newArgumentCount ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'permutation must contain one entry for each target selector argument.'
				details: self requestedContext ].
	(requestedPermutation allSatisfy: [ :each | each isInteger ]) ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'permutation entries must be integers.'
				details: self requestedContext ].
	positiveIndexes := requestedPermutation select: [ :each | each > 0 ].
	(positiveIndexes allSatisfy: [ :each | each between: 1 and: oldArgumentCount ]) ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'positive permutation entries must reference existing arguments by 1-based index.'
				details: self requestedContext ].
	positiveIndexes asSet size = positiveIndexes size ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'permutation must not reference the same old argument twice.'
				details: self requestedContext ].
	newArgumentCount >= oldArgumentCount
		ifTrue: [
				positiveIndexes size = oldArgumentCount ifFalse: [
						MCPCommandError
							signalErrorCode: #InvalidMethodArgumentPermutation
							message: 'adding arguments requires every old argument to appear exactly once in permutation.'
							details: self requestedContext ] ]
		ifFalse: [
				positiveIndexes size = newArgumentCount ifFalse: [
						MCPCommandError
							signalErrorCode: #InvalidMethodArgumentPermutation
							message: 'removing arguments requires permutation to contain only kept old argument indexes.'
							details: self requestedContext ].
				(requestedPermutation allSatisfy: [ :each | each > 0 ]) ifFalse: [
						MCPCommandError
							signalErrorCode: #InvalidMethodArgumentPermutation
							message: 'removing arguments does not accept negative permutation entries.'
							details: self requestedContext ] ].
	^ self
]
