"
Shared implementation for focused method editing tools. It parses create/update method requests, dispatches method create/update commands, and returns post-create critiques when relevant.
"
Class {
	#name : 'MCPToolEditMethod',
	#superclass : 'MCPToolEdit',
	#traits : 'TMCPMethodTool',
	#classTraits : 'TMCPMethodTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolEditMethod class >> isAbstract [

	^ self = MCPToolEditMethod
]

{ #category : 'private - refactoring' }
MCPToolEditMethod >> addParameterRefactoringForSelector: oldSelectorSymbol inBehavior: aBehavior to: newSelectorSymbol permutation: permutation newArgs: newArguments model: refactoringModel [

	^ RBAddParameterRefactoring
		  model: refactoringModel
		  addParameterToMethod: oldSelectorSymbol
		  in: aBehavior
		  newSelector: newSelectorSymbol
		  permutation: permutation
		  newArgs: newArguments
]

{ #category : 'private' }
MCPToolEditMethod >> allowedNonErrorCritiqueRuleClasses [

	^ {
		  MCPRespondsToUsageRule.
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
MCPToolEditMethod >> classReferenceNameFor: className classSide: classSide [

	^ classSide
		  ifTrue: [ className , ' class' ]
		  ifFalse: [ className ]
]

{ #category : 'private' }
MCPToolEditMethod >> critiqueDataFor: aCritique [

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
MCPToolEditMethod >> critiqueDataForMethod: aCompiledMethod [

	| critiques |
	critiques := aCompiledMethod critiques select: [ :each |
		             self shouldIncludeCritique: each ].
	^ ((critiques asSortedCollection: [ :left :right |
		    left title = right title
			    ifTrue: [ left rule class name < right rule class name ]
			    ifFalse: [ left title < right title ] ]) collect: [ :each |
		   self critiqueDataFor: each ]) asArray
]

{ #category : 'private' }
MCPToolEditMethod >> dataForMethod: aCompiledMethod [

	^ (MCPCompiledMethodInfo fromMethod: aCompiledMethod)
		  asDictionaryIncludingSource: true
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: self methodDataProperties
		  required:
			  #( 'selector' 'className' 'classSide' 'packageName' 'isExtension'
			     'protocol' 'source' )
]

{ #category : 'private' }
MCPToolEditMethod >> failureMessageForArgumentUpdateAction: updateAction classNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

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
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditMethod >> failureMessageForChangeProtocolClassNamed: className classSide: classSide selector: selector protocol: protocol error: anError [

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
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditMethod >> failureMessageForCompileClassNamed: className classSide: classSide error: anError [

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
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private' }
MCPToolEditMethod >> failureMessageForRenameClassNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

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
				  (self normalizedCauseMessageForOperationError: anError) ]
]

{ #category : 'private - schema' }
MCPToolEditMethod >> methodAppliedChangeOutputSchemaProperty [

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
MCPToolEditMethod >> methodCritiqueSchema [

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
MCPToolEditMethod >> methodCritiquesSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'critiques'
		   type: 'array'
		   description:
			   'Renraku critiques included in compile output: all error-severity critiques plus selected non-error rules.')
		  items: self methodCritiqueSchema;
		  yourself
]

{ #category : 'private - schema' }
MCPToolEditMethod >> methodDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'action'
			   type: 'string'
			   description:
			   'The public method edit action that was performed: create or update.').
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
			   'The selector of the method after the edit completes.').
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The class that defines the edited method.').
		  (self
			   schemaPropertyNamed: 'classSide'
			   type: 'boolean'
			   description: 'Whether the edited method is on the class side.').
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'The package that owns the edited method.').
		  (self
			   schemaPropertyNamed: 'isExtension'
			   type: 'boolean'
			   description:
			   'Whether the edited method is an extension on its class package.').
		  (self
			   schemaPropertyNamed: 'protocol'
			   type: 'string'
			   description:
			   'The protocol/category containing the edited method after the action.').
		  (self
			   schemaPropertyNamed: 'source'
			   type: 'string'
			   description:
			   'The formatted source code of the edited method after the action.').
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

{ #category : 'private - schema' }
MCPToolEditMethod >> methodUpdatePlanOutputSchemaProperty [

	| property requestedContextProperty updateActionProperty |
	updateActionProperty := self
		                        schemaPropertyNamed: 'updateAction'
		                        type: 'string'
		                        description:
		                        'The method update action selected from operation=update.'.
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

{ #category : 'private - operations' }
MCPToolEditMethod >> operationSpecifications [

	^ {
		  {
			  (#name -> 'create').
			  (#requiredProperties -> #( 'methodSource' 'protocol' )) }
			  asDictionary.
		  {
			  (#name -> 'update').
			  (#requiredProperties -> #( 'selector' )) } asDictionary }
]

{ #category : 'private - request' }
MCPToolEditMethod >> parsedRequestFromToolRequest: request [

	| operation |
	operation := self operationFromRequest: request.
	self
		validateRequiredPropertiesForOperation: operation
		inRequest: request.
	operation = 'create' ifTrue: [
		^ MCPMethodCreateRequest fromRequest: request tool: self ].
	operation = 'update' ifTrue: [
		^ MCPMethodUpdateRequest fromRequest: request tool: self ].
	Error signal: self operationValidationErrorMessage
]

{ #category : 'private' }
MCPToolEditMethod >> reformattedMethodForBehavior: aBehavior selector: aSelector [

	| compiledMethod |
	compiledMethod := aBehavior >> aSelector.
	compiledMethod reformat.
	^ aBehavior >> aSelector
]

{ #category : 'private - refactoring' }
MCPToolEditMethod >> removeParameterRefactoringForArgumentNamed: argumentName inBehavior: aBehavior selector: selectorSymbol model: refactoringModel [

	^ RBRemoveParameterRefactoring
		  model: refactoringModel
		  removeParameter: argumentName
		  in: aBehavior
		  selector: selectorSymbol
]

{ #category : 'private - refactoring' }
MCPToolEditMethod >> renameRefactoringForSelector: oldSelectorSymbol inBehavior: aBehavior to: newSelectorSymbol permutation: permutation model: refactoringModel [

	^ ReRenameMethodRefactoring
		  model: refactoringModel
		  renameMethod: oldSelectorSymbol
		  in: aBehavior
		  to: newSelectorSymbol
		  permutation: permutation
]

{ #category : 'private' }
MCPToolEditMethod >> shouldIncludeCritique: aCritique [

	^ self shouldIncludeCritiqueRule: aCritique rule
]

{ #category : 'private' }
MCPToolEditMethod >> shouldIncludeCritiqueRule: aRule [

	^ aRule severity = #error or: [
		  self allowedNonErrorCritiqueRuleClasses anySatisfy: [ :each |
			  aRule isKindOf: each ] ]
]

{ #category : 'private' }
MCPToolEditMethod >> sourceIntervalForCritique: aCritique [

	| sourceAnchor |
	sourceAnchor := aCritique sourceAnchor.
	(sourceAnchor notNil and: [ sourceAnchor providesInterval ])
		ifFalse: [ ^ nil ].
	^ sourceAnchor interval
]
