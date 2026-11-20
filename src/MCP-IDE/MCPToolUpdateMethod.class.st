"
Tool that changes one method's protocol, its selector, or both in one call.

The changes apply in order, protocol first, stopping at the first that fails. A selector change is MCPUpdateMethodCommand's.
"
Class {
	#name : 'MCPToolUpdateMethod',
	#superclass : 'MCPToolMethodMutation',
	#traits : 'TMCPSequencedUpdate',
	#classTraits : 'TMCPSequencedUpdate classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateMethod class >> toolName [

	^ 'method_update'
]

{ #category : 'metadata' }
MCPToolUpdateMethod >> additionalKeywords [
	"The name no longer carries protocol or selector, which are the words that led to the two tools this replaces."

	^ super additionalKeywords , #( 'protocol' 'selector' 'rename' 'recategorize' 'signature' 'argument' 'extension' )
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> applyUpdate: action of: request [

	^ action = 'changeProtocol'
		  ifTrue: [ self changeProtocolOf: request ]
		  ifFalse: [ self changeSelector: action of: request ]
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
							  failureMessage: ('Unable to change protocol for {1} to {2}' format: {
										   (self methodReferenceForClassName: className selector: selector isClassSide: classSide).
										   (request stringArgumentNamed: 'protocol') })
							  error: error ] ]
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> changeSelector: action of: request [
	"A rename, or arguments added or removed: the method is looked up, its selector changed across the scope's model, senders included, and the answer names the method before and after. The refactoring keeps the method's text but for its selector line, and the method is then reformatted unless format is false. The senders are left as the refactoring writes them."

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
					   argumentNames: (request stringCollectionArgumentNamed: 'arguments')
					   environment:
					   (self refactoringEnvironmentForScopeSpec: (self refactoringScopeSpecFromRequest: request) anchoredAtBehavior: behavior))
					  execute.
				  (request booleanArgumentNamed: 'format') ifTrue: [ self reformattedMethodForBehavior: behavior selector: newSelector ] ]
		  successResult: [ :warningMessages |
				  self
					  successResultText: ((self selectorChangeSummaryFormatFor: action) format: {
								   oldMethodReference.
								   (self methodReferenceForBehavior: behavior selector: newSelector) })
					  data: Dictionary new
					  warnings: warningMessages ]
		  failureSummary: [ :error | self failureMessageForSelectorChange: action of: request error: error ]
]

{ #category : 'private - execution' }
MCPToolUpdateMethod >> checkArguments: request [
	"A side that says the other one than the class name, and a scope naming a package that does not exist, are refused."

	self classNameAndSideOf: request do: [ :className :classSide :sideGiven |  ].
	(request hasArgumentNamed: 'newSelector') ifTrue: [ self refactoringScopeSpecFromRequest: request ]
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> failureMessageForSelectorChange: action of: request error: anError [

	| template |
	template := action = 'rename'
		            ifTrue: [ 'Unable to rename method {1} to {2}' ]
		            ifFalse: [
				            action = 'addArguments'
					            ifTrue: [ 'Unable to add arguments to method {1} as {2}' ]
					            ifFalse: [ 'Unable to remove arguments from method {1} as {2}' ] ].
	^ self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			  self
				  failureMessage: (template format: {
							   (self methodReferenceForClassName: className selector: (request stringArgumentNamed: 'selector') isClassSide: classSide).
							   (request stringArgumentNamed: 'newSelector') })
				  error: anError ]
]

{ #category : 'private - results' }
MCPToolUpdateMethod >> keysStatedInSummary [
	"Several updates each say what they did in the summary, a line each."

	^ #( updates )
]

{ #category : 'private - execution' }
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

{ #category : 'private - results' }
MCPToolUpdateMethod >> protocolChangeSummaryFor: methodReference from: oldProtocolName to: newProtocolName [
	"Moved ZooKeeper>>feed from as yet unclassified to feeding., in the words method_compile uses when a replace moves a method; ZooKeeper>>feed is already in feeding. when it was there before."

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
	"The call as read: the class without its side, the class side when it is the one meant, the selector, and each update argument the call supplied."

	| context |
	context := Dictionary new.
	self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			context at: #class put: className.
			classSide ifTrue: [ context at: #side put: 'class' ] ].
	context at: #selector put: (request stringArgumentNamed: 'selector').
	self updateArgumentNames do: [ :each |
			(request hasArgumentNamed: each) ifTrue: [
					context at: each asSymbol put: (each = 'arguments'
							 ifTrue: [ request stringCollectionArgumentNamed: each ]
							 ifFalse: [ request stringArgumentNamed: each ]) ] ].
	^ context
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

{ #category : 'private - specs' }
MCPToolUpdateMethod >> sendersScopeSchemaProperty [
	"Where a selector change renames and rewrites. The refactoring reads packages, classes and hierarchies only, so the scope offers no other entry."

	^ (self searchScopeSchemaPropertyWith:
			   (self searchScopeSchemaProperties select: [ :each | #( 'classes' 'packages' 'hierarchyOf' ) includes: each name ]))
		  description:
			  'Where a selector change renames the method''s implementors and rewrites its senders; entries add up. Omitted, every implementor and sender of the selector in the image.';
		  yourself
]

{ #category : 'private - specs' }
MCPToolUpdateMethod >> toolSpec [

	^ {
		  (#title -> 'Update Method').
		  (#description
		   ->
		   'Change one method: its protocol, its selector, or both in one call. A selector change is classified by arity, so the same argument renames, adds or removes arguments, and senders are updated.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'class' type: 'string' description: 'The class defining the method.').
			   (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on.').
			   self forceSchemaProperty.
			   (self formatSchemaPropertyDescribedAs:
				    'Reformat the method with its package''s formatter after a selector change. False keeps its source as written but for its selector line. Senders are left as Pharo''s refactoring writes them either way: a rename that keeps the keywords in their order changes only the send; reordering, adding or removing arguments reformats each sender.').
			   (self schemaPropertyNamed: 'selector' type: 'string' description: 'The method selector to update.').
			   (self
				    schemaPropertyNamed: 'protocol'
				    type: 'string'
				    description:
				    'Refile the method under this protocol. For an extension method, name an extension protocol such as *Package-Name.').
			   (self
				    schemaPropertyNamed: 'newSelector'
				    type: 'string'
				    description:
				    'Rename the method to this selector, updating its senders. Its arity says whether arguments are added or removed. Each argument goes with its keyword, so the same keywords in another order reorder the arguments; a new keyword takes the first argument no kept keyword holds, or adds one, which senders pass as nil.').
			   ((self
				     schemaPropertyNamed: 'arguments'
				     type: 'array'
				     description:
					     'Names of the new selector''s arguments, in order: required when it adds arguments, and renaming the kept ones otherwise.')
				    items: (MCPStructureProperties new
						     type: 'string';
						     description: 'Argument name.';
						     yourself);
				    yourself).
			   self sendersScopeSchemaProperty }).
		  (#requiredProperties -> #( 'class' 'selector' )).
		  (#atLeastOneProperties -> #( 'protocol' 'newSelector' )) } asDictionary
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> updateActionOf: action [

	^ action
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

	^ #( 'newSelector' 'protocol' 'arguments' )
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> updateSubjectDescriptionFor: request [
	"What the summary of several updates calls the method: method ZooKeeper>>feed, its class named without its side."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'method ';
				  nextPutAll: (self classNameAndSideOf: request do: [ :className :classSide :sideGiven | className ]);
				  nextPutAll: '>>';
				  nextPutAll: (request stringArgumentNamed: 'selector') ]
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> updateTargetBehaviorFor: request [
	"The behaviour every update action works on. A method the class got from a trait is the trait's to rename, recategorize or re-argument, so the actions stop here rather than each learning what a trait is."

	| behavior |
	behavior := self behaviorNamedIn: request.
	self signalTraitOriginBeforeUpdating: (request stringArgumentNamed: 'selector') in: behavior.
	^ behavior
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> validateArgumentNames: request [
	"A new selector that adds arguments names each of its arguments. Names given for any other one rename the arguments it keeps, so they are one per argument too. Each must be a name an argument can take, and none twice, since the arguments are renamed only once the selector has changed."

	| argumentNames |
	argumentNames := request stringCollectionArgumentNamed: 'arguments'.
	argumentNames isEmpty ifTrue: [
			(self selectorUpdateActionFor: request) = 'addArguments' ifFalse: [ ^ self ].
			MCPCommandError
				signalErrorCode: #ArgumentNamesRequiredForAddedArguments
				message: 'arguments is required when newSelector adds method arguments.'
				details: (self requestedContextFor: request) ].
	argumentNames size = (request stringArgumentNamed: 'newSelector') asSymbol numArgs ifFalse: [
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentNames
				message: 'arguments must contain one name for each target selector argument.'
				details: (self requestedContextFor: request) ].
	argumentNames
		detect: [ :each |
				(RBScanner isVariable: each) not or: [
						(#( 'self' 'super' 'thisContext' 'thisProcess' 'nil' 'true' 'false' ) includes: each) or: [
							(argumentNames occurrencesOf: each) > 1 ] ] ]
		ifFound: [ :each |
				MCPCommandError
					signalErrorCode: #InvalidMethodArgumentNames
					message: ('arguments must be distinct argument names, which {1} is not.' format: { each printString })
					details: (self requestedContextFor: request) ]
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> validateUpdate: request [
	"What the arguments say together: argument names only come with a new selector, which names them as validateArgumentNames: says."

	(request hasArgumentNamed: 'newSelector') ifTrue: [ ^ self validateArgumentNames: request ].
	(request hasArgumentNamed: 'arguments') ifTrue: [
			MCPCommandError
				signalErrorCode: #ArgumentMetadataRequiresMethodSelectorUpdate
				message: 'arguments is only valid with newSelector.'
				details: (self requestedContextFor: request) ]
]
