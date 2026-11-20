"
Tool that changes one method's protocol, its selector, its formatting, or several in one call.

The changes apply in order, protocol first, stopping at the first that fails. A selector change is MCPUpdateMethodCommand's, and formats the method itself.
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
	"The name says none of what the tool changes: protocol and selector are the words that led to the two tools it replaces, and format the one that leads to formatting a method."

	^ super additionalKeywords , #( 'protocol' 'selector' 'rename' 'recategorize' 'signature' 'argument' 'extension' 'format' )
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> applyUpdate: action of: request [

	action = 'changeProtocol' ifTrue: [ ^ self changeProtocolOf: request ].
	action = 'format' ifTrue: [ ^ self formatOf: request ].
	^ self changeSelector: action of: request
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> changeProtocolOf: request [
	"CompiledMethod>>protocol: files the method under the protocol, and an extension method in the package its protocol names, as a refactoring does, without recompiling it: the history holds one change for the move, and none for a move to the protocol it is in, which changes nothing."

	| behavior oldProtocol protocol selector |
	selector := request stringArgumentNamed: 'selector'.
	protocol := request stringArgumentNamed: 'protocol'.
	^ self
		  executeMutationAction: 'changeProtocol'
		  force: false
		  requestedContext: (self requestedContextFor: request action: 'changeProtocol')
		  work: [
				  | method |
				  behavior := self updateTargetBehaviorFor: request.
				  method := behavior >> selector asSymbol.
				  oldProtocol := self protocolNameForMethod: method.
				  oldProtocol = protocol ifFalse: [ method protocol: protocol ] ]
		  successResult: [ :warningMessages |
				  self
					  successResultText: (self
							   protocolChangeSummaryFor: (self methodReferenceForBehavior: behavior selector: selector asSymbol)
							   from: oldProtocol
							   to: (self protocolNameForMethod: behavior >> selector asSymbol))
					  data: Dictionary new
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
						  self
							  failureMessage: ('Unable to change protocol for {1} to {2}' format: {
										   (self methodReferenceForClassName: className selector: selector isClassSide: classSide).
										   protocol })
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
	"A side that says the other one than the class name, a blank protocol, a new selector that is not one, and a scope naming a package that does not exist are refused."

	self classNameAndSideOf: request do: [ :className :classSide :sideGiven |  ].
	((request hasArgumentNamed: 'protocol') and: [ (request stringArgumentNamed: 'protocol') isNil ]) ifTrue: [
		MCPInvalidToolInput signalBlankArgumentNamed: 'protocol' forTool: self ].
	(request hasArgumentNamed: 'newSelector') ifFalse: [ ^ self ].
	((request stringArgumentNamed: 'newSelector') ifNil: [ '' ]) numArgs < 0 ifTrue: [
			MCPCommandError
				signalErrorCode: #InvalidMethodSelector
				message:
				('newSelector {1} is not a valid selector.' format: { (request argumentNamed: 'newSelector' ifAbsent: [ nil ]) printString })
				details: Dictionary new ].
	self refactoringScopeSpecFromRequest: request
]

{ #category : 'private - errors' }
MCPToolUpdateMethod >> descriptionOfVariable: aVariable [
	"How a refusal names a variable a class sees: the instance variable name of Class, the class variable Shared of Foo, the global Array."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'the ';
				  nextPutAll: (aVariable isInstanceVariable
						   ifTrue: [ 'instance variable ' ]
						   ifFalse: [
								   aVariable isClassVariable
									   ifTrue: [ 'class variable ' ]
									   ifFalse: [ 'global ' ] ]);
				  nextPutAll: aVariable name.
			  aVariable definingClass ifNotNil: [ :class |
					  stream
						  nextPutAll: ' of ';
						  nextPutAll: class name ] ]
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

{ #category : 'private - updating' }
MCPToolUpdateMethod >> formatOf: request [
	"Format the method as it is. The formatter's text replaces the method's only where it differs, so a method already formatted is left as it was, with nothing added to its history."

	| behavior formatted selector |
	selector := (request stringArgumentNamed: 'selector') asSymbol.
	^ self
		  executeMutationAction: 'format'
		  force: false
		  requestedContext: (self requestedContextFor: request)
		  work: [
				  | method |
				  behavior := self updateTargetBehaviorFor: request.
				  method := behavior >> selector.
				  formatted := (self reformattedMethodForBehavior: behavior selector: selector) ~~ method ]
		  successResult: [ :warningMessages |
				  self
					  successResultText: ((formatted
							    ifTrue: [ 'Formatted {1}.' ]
							    ifFalse: [ '{1} is already formatted.' ]) format: { (self methodReferenceForBehavior: behavior selector: selector) })
					  data: Dictionary new
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
						  self
							  failureMessage:
							  ('Unable to format {1}' format:
								   { (self methodReferenceForClassName: className selector: selector isClassSide: classSide) })
							  error: error ] ]
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
				message: 'method_update needs protocol, newSelector or format: true; format: false alone changes nothing.'
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
		   'Change one method: its protocol, its selector, its formatting, or several in one call. A selector change is classified by arity, so the same argument renames, adds or removes arguments, and senders are updated. format: true alone formats the method as it is.').
		  (#action -> 'update').
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'class' type: 'string' description: 'The class defining the method.').
			   (self targetSideSchemaPropertyDescribedAs: 'Which side the method is on.').
			   self forceSchemaProperty.
			   (self formatSchemaPropertyDescribedAs:
				    'Reformat the method with its package''s formatter. True formats it as it is, alone or after a protocol change. A selector change reformats it unless format is false, which keeps its source as written but for its selector line. Senders are left as Pharo''s refactoring writes them either way: a rename that keeps the keywords in their order changes only the send; reordering, adding or removing arguments reformats each sender.').
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
		  (#atLeastOneProperties -> #( 'protocol' 'newSelector' 'format' )) } asDictionary
]

{ #category : 'private - updating' }
MCPToolUpdateMethod >> updateActionOf: action [

	^ action
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> updateActionsFor: request [
	"Every change the call asks for, in the order they must be applied. Changing the protocol finds the method by the selector the caller wrote, so a selector change comes after it. A selector change formats the method unless format is false, so formatting is a change of its own only without one, when format is true."

	| actions |
	actions := OrderedCollection new.
	(request hasArgumentNamed: 'protocol') ifTrue: [ actions add: 'changeProtocol' ].
	(self selectorUpdateActionFor: request)
		ifNil: [
		((request hasArgumentNamed: 'format') and: [ request booleanArgumentNamed: 'format' ]) ifTrue: [ actions add: 'format' ] ]
		ifNotNil: [ :action | actions add: action ].
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
	"The behaviour every update action works on, which defines the method. A method the class got from a trait is the trait's to rename, recategorize, re-argument or format, so the actions stop here rather than each learning what a trait is."

	| behavior selector |
	behavior := self behaviorNamedIn: request.
	selector := request stringArgumentNamed: 'selector'.
	self signalTraitOriginBeforeUpdating: selector in: behavior.
	behavior compiledMethodAt: selector asSymbol ifAbsent: [ MCPCommandError signalMissingMethod: selector in: behavior ].
	^ behavior
]

{ #category : 'private - validating' }
MCPToolUpdateMethod >> validateArgumentNames: request [
	"A new selector that adds arguments names each of its arguments. Names given for any other one rename the arguments it keeps, so they are one per argument too. Each must be a name an argument can take, none twice, since the arguments are renamed only once the selector has changed, and none a variable the method sees that is not already one of its arguments."

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
					details: (self requestedContextFor: request) ].
	self variableShadowedBy: argumentNames in: request ifFound: [ :name :variable |
			MCPCommandError
				signalErrorCode: #InvalidMethodArgumentNames
				message: ('arguments must be distinct argument names, which {1} is not: it would shadow {2}.' format: {
							 name printString.
							 variable })
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

{ #category : 'private - validating' }
MCPToolUpdateMethod >> variableShadowedBy: argumentNames in: request ifFound: aBlock [
	"aBlock gets the first of argumentNames that the method already sees as a variable, and that variable described. An argument of that name would hide the variable and change what the method means: some Pharo versions compile it without a word, others refuse it only once the selector has changed. The variables are the ones the compiler will not let an argument shadow: the method's temporaries and block arguments, and what its class sees, inherited instance and class variables and globals included. A name one of the method's arguments already has hides the same variable before and after, and the call renames the arguments together, so arguments may keep or trade their names. A missing class or method, or one a trait installed, is the update's to report."

	| behavior method tree |
	behavior := self classNameAndSideOf: request do: [ :className :classSide :sideGiven |
			            (MCPImageLookup isClassName: className) ifFalse: [ ^ self ].
			            self behaviorNamed: className classSide: classSide ].
	method := behavior compiledMethodAt: (request stringArgumentNamed: 'selector') asSymbol ifAbsent: [ ^ self ].
	method isFromTrait ifTrue: [ ^ self ].
	tree := method ast.
	(argumentNames copyWithoutAll: tree argumentNames) do: [ :each |
			(tree allTemporaryVariables includes: each) ifTrue: [ ^ aBlock value: each value: ('the temporary {1}' format: { each }) ].
			(tree allArgumentVariables includes: each) ifTrue: [ ^ aBlock value: each value: ('the block argument {1}' format: { each }) ].
			(behavior lookupVar: each asSymbol) ifNotNil: [ :variable |
				variable allowsShadowing ifFalse: [ ^ aBlock value: each value: (self descriptionOfVariable: variable) ] ] ]
]
