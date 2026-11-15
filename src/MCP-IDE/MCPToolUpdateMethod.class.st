"
Tool that changes one method's protocol, its selector, or both in one call.

The changes apply in order, protocol first, stopping at the first that fails. A selector change is MCPUpdateMethodCommand's.
"
Class {
	#name : 'MCPToolUpdateMethod',
	#superclass : 'MCPToolMethodMutation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateMethod class >> toolName [

	^ 'method_update'
]

{ #category : 'private - specs' }
MCPToolUpdateMethod >> additionalKeywords [
	"The name no longer carries protocol or selector, which are the words that led to the two tools this replaces."

	^ super additionalKeywords , #( 'protocol' 'selector' 'rename' 'recategorize' 'signature' 'argument' 'extension' )
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> applyUpdates: actions of: request [
	"Apply the actions in order, stopping at the first that fails. They all land on one method and the later ones build on the earlier, so carrying on would apply half a change nobody asked for."

	| applied |
	applied := OrderedCollection new.
	actions doWithIndex: [ :action :index |
			| result |
			result := action = 'changeProtocol'
				          ifTrue: [ self changeProtocolOf: request ]
				          ifFalse: [ self changeSelector: action of: request ].
			result isError ifTrue: [
					^ self
						  resultForFailure: result
						  of: action
						  applied: (applied collect: [ :each | each key ] as: Array)
						  skipped: (actions allButFirst: index) ].
			applied add: action -> result ].
	^ self resultForUpdates: applied of: request
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> changeProtocolOf: request [

	| behavior newCompiledMethod oldProtocol selector |
	selector := request stringArgumentNamed: 'selector'.
	^ self
		  executeMutationAction: 'changeProtocol'
		  force: false
		  requestedContext: (self requestedContextFor: request action: 'changeProtocol')
		  work: [
				  behavior := self updateTargetBehaviorFor: request.
				  oldProtocol := self protocolNameForMethod:
					                 (behavior
						                  compiledMethodAt: selector asSymbol
						                  ifAbsent: [ MCPCommandError signalMissingMethod: selector in: behavior ]).
				  self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
						  (RBMethodProtocolTransformation
							   protocol: (request stringArgumentNamed: 'protocol')
							   inMethod: selector asSymbol
							   inClass: (self classReferenceNameFor: className classSide: classSide)) execute ].
				  newCompiledMethod := behavior compiledMethodAt: selector asSymbol ]
		  successResult: [ :warningMessages |
				  self
					  successResultText: (self
							   protocolChangeSummaryFor: (self methodReferenceForBehavior: behavior selector: selector asSymbol)
							   from: oldProtocol
							   to: (self protocolNameForMethod: newCompiledMethod))
					  data: Dictionary new
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
						  self
							  failureMessageForChangeProtocolClassNamed: className
							  classSide: classSide
							  selector: selector
							  protocol: (request stringArgumentNamed: 'protocol')
							  error: error ] ]
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> changeSelector: action of: request [
	"A rename, or arguments added or removed: the method is looked up, its selector changed across the scope's model, senders included, and the answer names the method before and after."

	| behavior newSelector oldMethodReference selector |
	selector := (request stringArgumentNamed: 'selector') asSymbol.
	newSelector := (request stringArgumentNamed: 'newSelector') asSymbol.
	^ self
		  executeMutationAction: action
		  force: (request booleanArgumentNamed: 'force')
		  requestedContext: (self requestedContextFor: request action: action)
		  work: [
				  behavior := self updateTargetBehaviorFor: request.
				  behavior
					  compiledMethodAt: selector
					  ifAbsent: [ MCPCommandError signalMissingMethod: (request stringArgumentNamed: 'selector') in: behavior ].
				  oldMethodReference := self methodReferenceForBehavior: behavior selector: selector.
				  (MCPUpdateMethodCommand
					   changing: selector
					   of: behavior
					   to: newSelector
					   permutation: (self permutationFor: request)
					   argumentNames: (request stringCollectionArgumentNamed: 'arguments')
					   argumentValueExpressions: (request stringCollectionArgumentNamed: 'argumentValueExpressions')
					   model: (self refactoringModelForScopeSpec: (self refactoringScopeSpecFromRequest: request) anchoredAtBehavior: behavior))
					  execute.
				  self reformattedMethodForBehavior: behavior selector: newSelector ]
		  successResult: [ :warningMessages |
				  self
					  successResultText: ((self selectorChangeSummaryFormatFor: action) format: {
								   oldMethodReference.
								   (self methodReferenceForBehavior: behavior selector: newSelector) })
					  data: Dictionary new
					  warnings: warningMessages ]
		  failureSummary: [ :error | self failureMessageForSelectorChange: action of: request error: error ]
]

{ #category : 'executing' }
MCPToolUpdateMethod >> checkArguments: request [
	"A side that says the other one than the class name, a permutation that does not fit the selectors, and a scope naming a package that does not exist are refused."

	self classNameAndSideOf: request do: [ :className :classSide :sideGiven |  ].
	(request arrayArgumentNamed: 'permutation' ifAbsent: [ nil ]) ifNotNil: [ :permutation |
		self validatePermutation: permutation of: request ].
	(request hasArgumentNamed: 'newSelector') ifTrue: [ self refactoringScopeSpecFromRequest: request ]
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> contextValueNamed: anArgumentName in: request permutation: aPermutation [

	anArgumentName = 'permutation' ifTrue: [ ^ aPermutation ].
	(#( 'arguments' 'argumentValueExpressions' ) includes: anArgumentName) ifTrue: [
		^ request stringCollectionArgumentNamed: anArgumentName ].
	^ request stringArgumentNamed: anArgumentName
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> failureMessageForSelectorChange: action of: request error: anError [

	^ self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			  action = 'rename'
				  ifTrue: [
						  self
							  failureMessageForRenameClassNamed: className
							  classSide: classSide
							  selector: (request stringArgumentNamed: 'selector')
							  newSelector: (request stringArgumentNamed: 'newSelector')
							  error: anError ]
				  ifFalse: [
						  self
							  failureMessageForArgumentUpdateAction: action
							  classNamed: className
							  classSide: classSide
							  selector: (request stringArgumentNamed: 'selector')
							  newSelector: (request stringArgumentNamed: 'newSelector')
							  error: anError ] ]
]

{ #category : 'private - results' }
MCPToolUpdateMethod >> keysStatedInSummary [
	"Several updates each say what they did in the summary, a line each."

	^ #( updates )
]

{ #category : 'private - specs' }
MCPToolUpdateMethod >> methodToolSpec [

	^ {
		  (#title -> 'Update Method').
		  (#description
		   ->
		   'Change one method: its protocol, its selector, or both in one call. A selector change is classified by arity, so the same argument renames, adds or removes arguments, and senders are updated.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (MCPStructureProperties new
				    name: 'class';
				    type: 'string';
				    description: 'The class defining the method.';
				    yourself).
			   (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on.').
			   self forceSchemaProperty.
			   (MCPStructureProperties new
				    name: 'selector';
				    type: 'string';
				    description: 'The method selector to update.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'protocol';
				    type: 'string';
				    description:
					    'Refile the method under this protocol. For an extension method, name an extension protocol such as *Package-Name.';
				    yourself).
			   (MCPStructureProperties new
				    name: 'newSelector';
				    type: 'string';
				    description: 'Rename the method to this selector, updating its senders.';
				    yourself).
			   ((MCPStructureProperties new
				     name: 'arguments';
				     type: 'array';
				     description:
					     'Names of the arguments the new selector takes, in order. Names matching the current ones are kept, new names are added arguments, and current ones left out are removed.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Argument name.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'argumentValueExpressions';
				     type: 'array';
				     description: 'Expressions senders pass for each added argument, in order.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Smalltalk expression.';
						     yourself);
				    yourself).
			   ((MCPStructureProperties new
				     name: 'permutation';
				     type: 'array';
				     description:
					     'Only to reorder arguments, which names cannot express: one entry per new argument, holding the index of the current argument it takes, or 0 for an added one. Inferred from arguments when omitted.')
				    items: (MCPStructureProperties new
						     type: 'integer';
						     description: 'Current argument index, or 0.';
						     yourself);
				    yourself).
			   self methodSearchScopeSchemaProperty }).
		  (#requiredProperties -> #( 'class' 'selector' )).
		  (#atLeastOneProperties -> #( 'protocol' 'newSelector' )) } asDictionary
]

{ #category : 'executing' }
MCPToolUpdateMethod >> mutateWith: request [
	"Check what the arguments ask for together, then apply each change they ask for."

	| actions |
	self validateUpdate: request.
	actions := self updateActionsFor: request.
	actions ifEmpty: [
			MCPCommandError
				signalErrorCode: #NoMethodUpdateRequested
				message: 'Method update requires one method update field such as newSelector or protocol.'
				details: (self requestedContextFor: request) ].
	^ self applyUpdates: actions of: request
]

{ #category : 'private - arguments' }
MCPToolUpdateMethod >> permutationFor: request [
	"The permutation the call gave, or the one its selectors imply."

	| selector |
	selector := (request stringArgumentNamed: 'selector') asSymbol.
	^ request
		  arrayArgumentNamed: 'permutation'
		  ifAbsent: [ MCPUpdateMethodCommand defaultPermutationFrom: selector to: (self targetSelectorFor: request) ]
]

{ #category : 'private - results' }
MCPToolUpdateMethod >> protocolChangeSummaryFor: methodReference from: oldProtocolName to: newProtocolName [
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

{ #category : 'private - results' }
MCPToolUpdateMethod >> protocolNameForMethod: aCompiledMethod [

	^ aCompiledMethod protocolName ifNil: [ '' ] ifNotNil: [ :aProtocol | aProtocol asString ]
]

{ #category : 'private - results' }
MCPToolUpdateMethod >> protocolTextFor: aProtocolName [
	"A method filed under no protocol has an empty name, which a sentence calls no protocol."

	^ aProtocolName isEmptyOrNil
		  ifTrue: [ 'no protocol' ]
		  ifFalse: [ aProtocolName ]
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> requestedContextFor: request [

	^ self requestedContextFor: request permutation: (self permutationFor: request)
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> requestedContextFor: request action: action [
	"A selector change also names the refactoring scope it updates senders in."

	| context |
	context := self requestedContextFor: request.
	(#( 'rename' 'addArguments' 'removeArguments' ) includes: action) ifTrue: [
		self addRefactoringScopeContextFromSpec: (self refactoringScopeSpecFromRequest: request) toRequestedContext: context ].
	^ context
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> requestedContextFor: request permutation: aPermutation [
	"The call as read: the class without its side, the class side when it is the one meant, the selector, and each update argument the call supplied, with aPermutation for the permutation."

	| context |
	context := Dictionary new.
	self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			context at: #class put: className.
			classSide ifTrue: [ context at: #side put: 'class' ] ].
	context at: #selector put: (request stringArgumentNamed: 'selector').
	self updateArgumentNames do: [ :each |
			(request hasArgumentNamed: each) ifTrue: [
				context at: each asSymbol put: (self contextValueNamed: each in: request permutation: aPermutation) ] ].
	^ context
]

{ #category : 'private - results' }
MCPToolUpdateMethod >> resultForFailure: errorResult of: action applied: appliedActions skipped: skippedActions [
	"A single change fails as it always did. When it was one of several, say which had already landed and which were never attempted, because the method is left part-way."

	| details summary |
	(appliedActions isEmpty and: [ skippedActions isEmpty ]) ifTrue: [ ^ errorResult ].
	details := (errorResult structuredContent at: #error ifAbsent: [ Dictionary new ]) copy.
	details
		at: #failedUpdate put: action;
		at: #appliedUpdates put: appliedActions asArray;
		at: #skippedUpdates put: skippedActions asArray.
	summary := String streamContents: [ :stream |
			           stream << (errorResult structuredContent at: #summary ifAbsent: [ '' ]).
			           stream << ' Update ' << action << ' failed'.
			           appliedActions ifNotEmpty: [
					           stream << ', after applying '.
					           appliedActions do: [ :each | stream << each ] separatedBy: [ stream << ', ' ] ].
			           skippedActions ifNotEmpty: [
					           stream << '; not attempted: '.
					           skippedActions do: [ :each | stream << each ] separatedBy: [ stream << ', ' ] ].
			           stream << '.' ].
	^ self errorResultText: summary details: details
]

{ #category : 'private - results' }
MCPToolUpdateMethod >> resultForUpdates: applied of: request [
	"One action answers exactly what it answers alone. Several say how many were applied, then what each one answered alone, a line each in the order applied; their data stays under updates."

	| updates warnings |
	applied size = 1 ifTrue: [ ^ applied first value ].
	warnings := OrderedCollection new.
	updates := applied collect: [ :each |
			           warnings addAll: (self warningsOfResult: each value).
			           (each value structuredContent at: #data ifAbsent: [ Dictionary new ]) copy
				           at: #action put: each key;
				           yourself ].
	^ self
		  successResultText: (String streamContents: [ :stream |
					   stream
						   nextPutAll: 'Applied ';
						   print: applied size;
						   nextPutAll: ' updates to method ';
						   nextPutAll: (self classNameAndSideOf: request do: [ :className :classSide :sideGiven | className ]);
						   nextPutAll: '>>';
						   nextPutAll: (request stringArgumentNamed: 'selector');
						   nextPut: $:.
					   applied do: [ :each |
							   stream
								   nextPut: Character lf;
								   nextPutAll: (each value structuredContent at: #summary ifAbsent: [ '' ]) ] ])
		  data: { (#updates -> updates asArray) } asDictionary
		  warnings: warnings asArray
]

{ #category : 'private - results' }
MCPToolUpdateMethod >> selectorChangeSummaryFormatFor: action [

	action = 'rename' ifTrue: [ ^ 'Renamed {1} to {2}.' ].
	action = 'addArguments' ifTrue: [ ^ 'Added arguments to {1} as {2}.' ].
	^ 'Removed arguments from {1} as {2}.'
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> selectorUpdateActionFor: request [
	"What a new selector does, by its arity against the current one's: rename or reorder, add arguments, or remove them. Nil when the call gives none."

	| newArgumentCount oldArgumentCount |
	(request hasArgumentNamed: 'newSelector') ifFalse: [ ^ nil ].
	oldArgumentCount := (request stringArgumentNamed: 'selector') asSymbol numArgs.
	newArgumentCount := (request stringArgumentNamed: 'newSelector') asSymbol numArgs.
	newArgumentCount > oldArgumentCount ifTrue: [ ^ 'addArguments' ].
	newArgumentCount < oldArgumentCount ifTrue: [ ^ 'removeArguments' ].
	^ 'rename'
]

{ #category : 'private - arguments' }
MCPToolUpdateMethod >> targetSelectorFor: request [
	"The selector the method ends up with: the new one when the call gives one, else its own."

	^ (request stringArgumentNamed: 'newSelector')
		  ifNil: [ (request stringArgumentNamed: 'selector') asSymbol ]
		  ifNotNil: [ :newSelector | newSelector asSymbol ]
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> updateActionsFor: request [
	"Every change the call asks for, in the order they must be applied. Changing the protocol finds the method by the selector the caller wrote, so a selector change comes after it."

	| actions |
	actions := OrderedCollection new.
	(request hasArgumentNamed: 'protocol') ifTrue: [ actions add: 'changeProtocol' ].
	(self selectorUpdateActionFor: request) ifNotNil: [ :action | actions add: action ].
	^ actions asArray
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> updateArgumentNames [
	"The arguments that say what to change, in the order the requested context names them."

	^ #( 'newSelector' 'protocol' 'permutation' 'arguments' 'argumentValueExpressions' )
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> updateTargetBehaviorFor: request [
	"The behaviour every update action works on. A method the class got from a trait is the trait's to rename, recategorize or re-argument, so the actions stop here rather than each learning what a trait is."

	| behavior |
	behavior := self
		            classNameAndSideOf: request
		            do: [ :className :classSide :sideGiven | self behaviorNamed: className classSide: classSide ].
	self signalTraitOriginBeforeUpdating: (request stringArgumentNamed: 'selector') in: behavior.
	^ behavior
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> validateAddedArguments: request [

	| argumentNames argumentValueExpressions |
	argumentNames := request stringCollectionArgumentNamed: 'arguments'.
	argumentValueExpressions := request stringCollectionArgumentNamed: 'argumentValueExpressions'.
	argumentNames isEmpty ifTrue: [
			MCPCommandError
				signalErrorCode: #ArgumentNamesRequiredForAddedArguments
				message: 'argumentNames is required when newSelector adds method arguments.'
				details: (self requestedContextFor: request) ].
	argumentNames size = (request stringArgumentNamed: 'newSelector') asSymbol numArgs ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentNames
				message: 'argumentNames must contain one name for each target selector argument.'
				details: (self requestedContextFor: request) ].
	(argumentNames allSatisfy: [ :each | each isNotEmpty ]) ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentNames
				message: 'argumentNames must not contain empty names.'
				details: (self requestedContextFor: request) ].
	(argumentValueExpressions isNotEmpty and: [
		 argumentValueExpressions size ~= ((self permutationFor: request) count: [ :each | each <= 0 ]) ]) ifTrue: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentValueExpressions
				message: 'argumentValueExpressions must contain one expression for each newly added argument.'
				details: (self requestedContextFor: request) ]
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> validatePermutation: requestedPermutation of: request [
	"While it is checked, the permutation reads as empty in the error details."

	| details newArgumentCount oldArgumentCount positiveIndexes |
	details := self requestedContextFor: request permutation: #(  ).
	oldArgumentCount := (request stringArgumentNamed: 'selector') asSymbol numArgs.
	newArgumentCount := (self targetSelectorFor: request) numArgs.
	requestedPermutation size = newArgumentCount ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'permutation must contain one entry for each target selector argument.'
				details: details ].
	(requestedPermutation allSatisfy: [ :each | each isInteger ]) ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'permutation entries must be integers.'
				details: details ].
	positiveIndexes := requestedPermutation select: [ :each | each > 0 ].
	(positiveIndexes allSatisfy: [ :each | each between: 1 and: oldArgumentCount ]) ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'positive permutation entries must reference existing arguments by 1-based index.'
				details: details ].
	positiveIndexes asSet size = positiveIndexes size ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentPermutation
				message: 'permutation must not reference the same old argument twice.'
				details: details ].
	newArgumentCount >= oldArgumentCount
		ifTrue: [
				positiveIndexes size = oldArgumentCount ifFalse: [
						MCPCommandError
							signalErrorCode: #InvalidMethodArgumentPermutation
							message: 'adding arguments requires every old argument to appear exactly once in permutation.'
							details: details ] ]
		ifFalse: [
				positiveIndexes size = newArgumentCount ifFalse: [
						MCPCommandError
							signalErrorCode: #InvalidMethodArgumentPermutation
							message: 'removing arguments requires permutation to contain only kept old argument indexes.'
							details: details ].
				(requestedPermutation allSatisfy: [ :each | each > 0 ]) ifFalse: [
						MCPCommandError
							signalErrorCode: #InvalidMethodArgumentPermutation
							message: 'removing arguments does not accept negative permutation entries.'
							details: details ] ]
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> validateUpdate: request [
	"What the arguments say together: permutation and the argument lists only come with a new selector, and one that adds arguments names them."

	(request hasArgumentNamed: 'permutation') ifTrue: [
			(request hasArgumentNamed: 'newSelector') ifFalse: [
					MCPCommandError
						signalErrorCode: #PermutationRequiresMethodSelectorUpdate
						message: 'permutation is only valid when update changes a method selector with newSelector.'
						details: (self requestedContextFor: request) ] ].
	((request hasArgumentNamed: 'arguments') or: [ request hasArgumentNamed: 'argumentValueExpressions' ]) ifTrue: [
			(request hasArgumentNamed: 'newSelector') ifFalse: [
					MCPCommandError
						signalErrorCode: #ArgumentMetadataRequiresMethodSelectorUpdate
						message: 'argumentNames and argumentValueExpressions are only valid with newSelector.'
						details: (self requestedContextFor: request) ] ].
	(self selectorUpdateActionFor: request) = 'addArguments' ifTrue: [ self validateAddedArguments: request ]
]
