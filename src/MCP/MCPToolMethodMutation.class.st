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

{ #category : 'private' }
MCPToolMethodMutation >> dataForMethod: aCompiledMethod [

	^ (MCPCompiledMethodInfo fromMethod: aCompiledMethod)
		  asDictionaryIncludingSource: true
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
		  standardOutputSchemaForDataProperties: self methodDataProperties
		  required:
			  #( 'selector' 'className' 'classSide' 'packageName' 'isExtension'
			     'protocol' 'source' )
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
MCPToolMethodMutation >> methodAppliedChangeOutputSchemaProperty [

	| property resultClassProperty resultProperty updateActionProperty |
	updateActionProperty := self
		                        schemaPropertyNamed: 'updateAction'
		                        type: 'string'
		                        description:
		                        'The method update action that produced the applied change.'.
	resultClassProperty := self
		                       schemaPropertyNamed: 'resultClassName'
		                       type: 'string'
		                       description:
		                       'The result DTO class returned by the method update action.'.
	resultProperty := self
		                  schemaPropertyNamed: 'result'
		                  type: 'object'
		                  description:
		                  'The method update result DTO serialized as a dictionary.'.
	resultProperty additionalProperties: true.
	property := self
		            schemaPropertyNamed: 'appliedChange'
		            type: 'object'
		            description:
		            'The applied method update change and its result DTO.'.
	property
		properties: {
				updateActionProperty.
				resultClassProperty.
				resultProperty };
		required: #( 'updateAction' 'resultClassName' 'result' );
		additionalProperties: false.
	^ property
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

{ #category : 'private - schema' }
MCPToolMethodMutation >> methodDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'action'
			   type: 'string'
			   description:
			   'The public method mutation action that was performed: create or update.').
		  (self
			   schemaPropertyNamed: 'changeKind'
			   type: 'string'
			   description:
			   'For method_create, whether the tool created a new method or replaced an existing method.').
		  (self
			   schemaPropertyNamed: 'updateAction'
			   type: 'string'
			   description:
			   'The update action performed when action=update.').
		  self methodUpdatePlanOutputSchemaProperty.
		  self methodAppliedChangeOutputSchemaProperty.
		  (self
			   schemaPropertyNamed: 'selector'
			   type: 'string'
			   description:
			   'The selector of the method after the update completes.').
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The class that defines the updated method.').
		  (self
			   schemaPropertyNamed: 'classSide'
			   type: 'boolean'
			   description: 'Whether the updated method is on the class side.').
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'The package that owns the updated method.').
		  (self
			   schemaPropertyNamed: 'isExtension'
			   type: 'boolean'
			   description:
			   'Whether the updated method is an extension on its class package.').
		  (self
			   schemaPropertyNamed: 'protocol'
			   type: 'string'
			   description:
			   'The protocol/category containing the updated method after the action.').
		  (self
			   schemaPropertyNamed: 'source'
			   type: 'string'
			   description:
			   'The formatted source code of the updated method after the action.').
		  (self
			   schemaPropertyNamed: 'oldSelector'
			   type: 'string'
			   description:
			   'The previous selector when updateAction changes the selector.').
		  (self
			   schemaPropertyNamed: 'newSelector'
			   type: 'string'
			   description:
			   'The target selector when updateAction changes the selector.').
		  (self
			   schemaPropertyNamed: 'oldProtocol'
			   type: 'string'
			   description:
			   'The previous protocol when the update action is changeProtocol.').
		  (self
			   schemaPropertyNamed: 'newProtocol'
			   type: 'string'
			   description:
			   'The new protocol when the update action is changeProtocol.').
		  self methodCritiquesSchemaProperty }
]

{ #category : 'private - specs' }
MCPToolMethodMutation >> methodToolSpec [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolMethodMutation >> methodUpdatePlanOutputSchemaProperty [

	| property requestedContextProperty updateActionProperty |
	updateActionProperty := self
		                        schemaPropertyNamed: 'updateAction'
		                        type: 'string'
		                        description:
		                        'The method update action selected by the tool request.'.
	requestedContextProperty := self
		                            schemaPropertyNamed: 'requestedContext'
		                            type: 'object'
		                            description:
		                            'The normalized request context used to execute the update.'.
	requestedContextProperty additionalProperties: true.
	property := self
		            schemaPropertyNamed: 'updatePlan'
		            type: 'object'
		            description:
		            'The planned method update action before it is executed.'.
	property
		properties: {
				updateActionProperty.
				requestedContextProperty };
		required: #( 'updateAction' 'requestedContext' );
		additionalProperties: false.
	^ property
]

{ #category : 'private - actions' }
MCPToolMethodMutation >> mutationAction [

	^ self methodToolSpec at: #action
]

{ #category : 'private - errors' }
MCPToolMethodMutation >> mutationActionForErrorFromParsedRequest: mutationRequest rawRequest: rawRequest [

	^ self mutationAction
]

{ #category : 'private - request' }
MCPToolMethodMutation >> parsedRequestFromToolRequest: request [

	| requestClass |
	requestClass := self mutationAction = 'create'
		                ifTrue: [ MCPMethodCreateRequest ]
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
