"
Shared implementation for method mutation tools.

It defines per-tool input schemas, translates each concrete method tool request into method creation or update requests, and returns method state plus post-compile critiques when relevant.
"
Class {
	#name : 'MCPToolMethodMutation',
	#superclass : 'MCPToolMutation',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolMethodMutation class >> isAbstract [

	^ self = MCPToolMethodMutation
]

{ #category : 'private - refactoring' }
MCPToolMethodMutation >> addParameterRefactoringForSelector: oldSelectorSymbol inBehavior: aBehavior to: newSelectorSymbol permutation: permutation newArgs: newArguments model: refactoringModel [

	^ RBAddParameterRefactoring
		  model: refactoringModel
		  addParameterToMethod: oldSelectorSymbol
		  in: aBehavior
		  newSelector: newSelectorSymbol
		  permutation: permutation
		  newArgs: newArguments
]

{ #category : 'private' }
MCPToolMethodMutation >> allowedNonErrorCritiqueRuleClasses [

	^ {
		  MCPCollectionThenDoRule.
		  MCPDictionaryAtIfPresentRule.
		  MCPFilteredEmptinessRule.
		  MCPFilterThenCollectRule.
		  MCPMessageNotUnderstoodHandlerRule.
		  MCPNilOnlyConditionalRule.
		  MCPRedundantExplicitSelfReturnRule.
		  MCPRespondsToUsageRule.
		  MCPSelectSizeCountRule.
		  MCPSortedCollectionConversionRule.
		  ReEquivalentSuperclassMethodsRule.
		  ReExcessiveArgumentsRule.
		  ReMissingSuperSendsRule.
		  ReNotOptimizedIfRule.
		  ReNotOptimizedIfNilRule.
		  ReReturnInEnsureRule.
		  ReTempVarOverridesInstVarRule.
		  ReUnaryAccessingMethodWithoutReturnRule }
]

{ #category : 'private' }
MCPToolMethodMutation >> blockingCritiqueDataForMethodNode: aMethodNode [

	| critiques |
	critiques := OrderedCollection new.
	self blockingPreCompileRuleClasses do: [ :ruleClass |
		| rule |
		rule := ruleClass new.
		aMethodNode nodesDo: [ :node |
			rule check: node forCritiquesDo: [ :critique |
				critiques add: critique ] ] ].
	^ critiques collect: [ :each | self critiqueDataFor: each ]
]

{ #category : 'private' }
MCPToolMethodMutation >> blockingPreCompileRuleClasses [

	^ { ReDeadBlockRule }
]

{ #category : 'metadata' }
MCPToolMethodMutation >> buildOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   schemaPropertyNamed: 'changeKind'
					   type: 'string'
					   description:
					   'Whether method_compile created or replaced a method.').
				  self methodCritiquesSchemaProperty }
		  required: #(  )
]

{ #category : 'private' }
MCPToolMethodMutation >> classReferenceNameFor: className classSide: classSide [

	^ classSide
		  ifTrue: [ className , ' class' ]
		  ifFalse: [ className ]
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataFor: aCritique [

	| data interval |
	data := {
		        (#ruleClass -> aCritique rule class name asString).
		        (#title -> aCritique title asString).
		        (#description -> aCritique description asString) }
		        asDictionary.
	interval := self sourceIntervalForCritique: aCritique.
	interval ifNotNil: [
			data
				at: #start put: interval first;
				at: #stop put: interval last ].
	^ data
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataForMethod: aCompiledMethod [

	^ self critiqueDataFromProperties: aCompiledMethod critiques
]

{ #category : 'private' }
MCPToolMethodMutation >> critiqueDataFromProperties: properties [

	| critiques |
	critiques := properties select: [ :each |
		each isCritique and: [ self shouldIncludeCritique: each ] ].
	^ (critiques asArray sort: [ :left :right |
			   left title = right title
				   ifTrue: [ left rule class name < right rule class name ]
				   ifFalse: [ left title < right title ] ]) collect: [ :each |
		  self critiqueDataFor: each ]
]

{ #category : 'metadata' }
MCPToolMethodMutation >> description [

	^ self methodToolSpec at: #description
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForArgumentUpdateAction: updateAction classNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

	| targetName verb |
	targetName := self
		              classReferenceNameFor: className
		              classSide: classSide.
	verb := updateAction = 'addArguments'
		        ifTrue: [ 'add arguments to' ]
		        ifFalse: [ 'remove arguments from' ].
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to ';
				  nextPutAll: verb;
				  nextPutAll: ' method ';
				  nextPutAll: targetName;
				  nextPutAll: '>>';
				  nextPutAll: oldSelector;
				  nextPutAll: ' as ';
				  nextPutAll: newSelector;
				  nextPutAll: ': ';
				  nextPutAll:
					  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForChangeProtocolClassNamed: className classSide: classSide selector: selector protocol: protocol error: anError [

	| targetName |
	targetName := self
		              classReferenceNameFor: className
		              classSide: classSide.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to change protocol for ';
				  nextPutAll: targetName;
				  nextPutAll: '>>';
				  nextPutAll: selector;
				  nextPutAll: ' to ';
				  nextPutAll: protocol;
				  nextPutAll: ': ';
				  nextPutAll:
					  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForCompileClassNamed: className classSide: classSide error: anError [

	| targetName |
	targetName := self
		              classReferenceNameFor: className
		              classSide: classSide.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to compile method on ';
				  nextPutAll: targetName;
				  nextPutAll: ': ';
				  nextPutAll:
					  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> failureMessageForRenameClassNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

	| targetName |
	targetName := self
		              classReferenceNameFor: className
		              classSide: classSide.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'Unable to rename method ';
				  nextPutAll: targetName;
				  nextPutAll: '>>';
				  nextPutAll: oldSelector;
				  nextPutAll: ' to ';
				  nextPutAll: newSelector;
				  nextPutAll: ': ';
				  nextPutAll:
					  (self normalizedCauseMessageForMutationError: anError) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> formatterForMethod: aCompiledMethod [

	| formatter |
	formatter := aCompiledMethod ast class formatter.
	formatter maxLineLength: 130.
	^ formatter
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> inputProperties [

	^ self methodToolSpec at: #inputProperties
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> methodCritiqueSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'One included Renraku critique reported for the method.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'ruleClass'
					   type: 'string'
					   description:
						   'The Renraku rule class that reported the critique.').
				  (self
					   schemaPropertyNamed: 'title'
					   type: 'string'
					   description:
						   'The short critique title, including any rule-specific hint.').
				  (self
					   schemaPropertyNamed: 'description'
					   type: 'string'
					   description:
						   'The critique rationale explaining why the rule flagged the method.').
				  (self
					   integerSchemaPropertyNamed: 'start'
					   description:
						   'The first character position of the critique interval in the method source when available.').
				  (self
					   integerSchemaPropertyNamed: 'stop'
					   description:
						   'The last character position of the critique interval in the method source when available.') };
		  required: #( 'ruleClass' 'title' 'description' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> methodCritiquesSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'critiques'
		   type: 'array'
		   description:
			   'Renraku critiques included in compile output: all error-severity critiques plus selected non-error rules.')
		  items: self methodCritiqueSchema;
		  yourself
]

{ #category : 'private - specs' }
MCPToolMethodMutation >> methodToolSpec [

	self subclassResponsibility
]

{ #category : 'private - actions' }
MCPToolMethodMutation >> mutationAction [

	^ self methodToolSpec at: #action
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> mutationActionForErrorFromParsedRequest: mutationRequest rawRequest: rawRequest [

	^ self mutationAction
]

{ #category : 'private - execution' }
MCPToolMethodMutation >> parsedRequestFromToolRequest: request [

	| requestClass |
	requestClass := self mutationAction = 'compile'
		                ifTrue: [ MCPMethodCompileRequest ]
		                ifFalse: [ MCPMethodUpdateRequest ].
	^ requestClass fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolMethodMutation >> reformattedMethodForBehavior: aBehavior selector: aSelector [

	| compiledMethod formattedSource |
	compiledMethod := aBehavior >> aSelector.
	formattedSource := (self formatterForMethod: compiledMethod) format: compiledMethod ast.
	aBehavior compile: formattedSource classified: compiledMethod protocol.
	^ aBehavior >> aSelector
]

{ #category : 'private - refactoring' }
MCPToolMethodMutation >> removeParameterRefactoringForArgumentNamed: argumentName inBehavior: aBehavior selector: selectorSymbol model: refactoringModel [

	^ RBRemoveParameterRefactoring
		  model: refactoringModel
		  removeParameter: argumentName
		  in: aBehavior
		  selector: selectorSymbol
]

{ #category : 'private - refactoring' }
MCPToolMethodMutation >> renameRefactoringForSelector: oldSelectorSymbol inBehavior: aBehavior to: newSelectorSymbol permutation: permutation model: refactoringModel [

	^ ReRenameMethodRefactoring
		  model: refactoringModel
		  renameMethod: oldSelectorSymbol
		  in: aBehavior
		  to: newSelectorSymbol
		  permutation: permutation
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> requiredInputProperties [

	^ self methodToolSpec
		  at: #requiredProperties
		  ifAbsent: [ #( 'className' ) ]
]

{ #category : 'private' }
MCPToolMethodMutation >> shouldIncludeCritique: aCritique [

	^ self shouldIncludeCritiqueRule: aCritique rule
]

{ #category : 'private' }
MCPToolMethodMutation >> shouldIncludeCritiqueRule: aRule [

	^ aRule severity = #error or: [
		  self allowedNonErrorCritiqueRuleClasses includes: aRule class ]
]

{ #category : 'private' }
MCPToolMethodMutation >> signalBlockingCritiquesForMethodNode: aMethodNode [

	| critiques |
	critiques := self blockingCritiqueDataForMethodNode: aMethodNode.
	critiques ifEmpty: [ ^ self ].
	MCPCommandError
		signalErrorCode: #CompileBlockedByCritiques
		message: 'Method compilation blocked by critiques.'
		details: {
			(#critiques -> critiques asArray).
			(#howToProceed -> 'Correct the source and resubmit method_compile.') }
				asDictionary
]

{ #category : 'private' }
MCPToolMethodMutation >> sourceIntervalForCritique: aCritique [

	| sourceAnchor |
	sourceAnchor := aCritique sourceAnchor.
	sourceAnchor ifNil: [ ^ nil ].
	sourceAnchor providesInterval ifFalse: [ ^ nil ].
	^ sourceAnchor interval
]

{ #category : 'metadata' }
MCPToolMethodMutation >> title [

	^ self methodToolSpec at: #title
]
