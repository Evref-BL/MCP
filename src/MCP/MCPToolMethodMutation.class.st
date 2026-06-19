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

	| critiques |
	critiques := aCompiledMethod critiques select: [ :each |
		             self shouldIncludeCritique: each ].
	^ (critiques asArray sort: [ :left :right |
			   left title = right title
				   ifTrue: [ left rule class name < right rule class name ]
				   ifFalse: [ left title < right title ] ]) collect: [ :each |
		  self critiqueDataFor: each ]
]

{ #category : 'defaults' }
MCPToolMethodMutation >> defaultDescription [

	^ self methodToolSpec at: #description
]

{ #category : 'defaults' }
MCPToolMethodMutation >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: self inputProperties;
		  required: self requiredInputProperties;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolMethodMutation >> defaultOutputSchema [

	^ self
		standardOutputSchemaForDataProperties: {
			(self schemaPropertyNamed: 'changeKind' type: 'string' description: 'Whether method_compile created or replaced a method.').
			self methodCritiquesSchemaProperty }
		required: #(  )
]

{ #category : 'defaults' }
MCPToolMethodMutation >> defaultTitle [

	^ self methodToolSpec at: #title
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

	| compiledMethod |
	compiledMethod := aBehavior >> aSelector.
	compiledMethod reformat.
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
MCPToolMethodMutation >> sourceIntervalForCritique: aCritique [

	| sourceAnchor |
	sourceAnchor := aCritique sourceAnchor.
	sourceAnchor ifNil: [ ^ nil ].
	sourceAnchor providesInterval ifFalse: [ ^ nil ].
	^ sourceAnchor interval
]

{ #category : 'validating' }
MCPToolMethodMutation >> validateRequest: request [

	self requiredInputProperties do: [ :each |
			(request argumentNamed: each ifAbsent: [ nil ]) ifNil: [
					MCPInvalidToolInput
						signalMissingRequiredArgumentNamed: each
						forTool: self ] ]
]
