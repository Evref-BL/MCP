"
Edits one method in the running image. It handles method creation or replacement, renaming, protocol changes, and returns post-create critiques when relevant.
"
Class {
	#name : 'MCPToolEditMethod',
	#superclass : 'MCPToolEdit',
	#traits : '{} + TMCPMethodTool',
	#classTraits : '{} + TMCPMethodTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolEditMethod >> allowedNonErrorCritiqueRuleClasses [

	^ {
		  ReExcessiveArgumentsRule.
		  ReMissingSuperSendsRule.
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

{ #category : 'private - execution' }
MCPToolEditMethod >> commandForRequest: methodRequest [

	(methodRequest isKindOf: MCPMethodCreateRequest) ifTrue: [
		^ MCPCreateMethodCommand tool: self request: methodRequest ].
	(methodRequest isKindOf: MCPMethodUpdateRequest) ifTrue: [
		^ MCPUpdateMethodCommand tool: self request: methodRequest ].
	^ super commandForRequest: methodRequest
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
MCPToolEditMethod >> defaultDescription [

	^ 'Create or update one method on the instance side or class side of a class. Use operation=create with methodSource and protocol to create or replace a method. Use operation=update with selector plus one patch field, such as newSelector or protocol. Rename updates can be scoped with packageNames, classNames, or hierarchyClassNames. force=false stops on refactoring warnings and returns impactMessages plus howToProceed; force=true continues and returns warnings in the output. Use remove-methods to delete methods.'
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #edit) }
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (self
					   operationSchemaPropertyWithDescription:
						   'The high-level method edit operation. operation=create creates or replaces a method. operation=update applies exactly one patch to an existing method, such as newSelector or protocol.'
					   supportedValuesLeadIn: 'Supported values are').
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description: 'The class whose method will be edited.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'classSide';
					   type: 'boolean';
					   description: 'Whether the target method is on the class side.';
					   default: false;
					   yourself).
				  self forceSchemaProperty.
				  (MCPStructureProperties new
					   name: 'selector';
					   type: 'string';
					   description:
						   'The existing selector to patch during operation=update. Not used for operation=create.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'methodSource';
					   type: 'string';
					   description:
						   'The full method source to compile when operation=create.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'protocol';
					   type: 'string';
					   description:
						   'The target protocol for operation=create. During operation=update this is a recategorization patch; do not combine it with another update action. For extension methods, use an extension protocol such as *Package-Name.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'newSelector';
					   type: 'string';
					   description:
						   'The replacement selector for an operation=update rename patch; do not combine it with another update action.';
					   yourself).
				  ((MCPStructureProperties new
					    name: 'permutation';
					    type: 'array';
					    description:
						    'Optional 1-based argument permutation for an operation=update rename patch.')
					   items: (MCPStructureProperties new
							    type: 'integer';
							    description: 'A 1-based argument index.';
							    yourself);
					   yourself).
				  self refactoringScopePackageNamesSchemaProperty.
				  self refactoringScopeClassNamesSchemaProperty.
				  self refactoringScopeHierarchyClassNamesSchemaProperty };
		  required: #( 'operation' 'className' );
		  oneOf: self operationBranchSchemas;
		  additionalProperties: false;
		  yourself
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultName [

	^ 'edit-method'
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultOutputSchema [

	^ self
		  standardOutputSchemaForDataProperties: self methodDataProperties
		  required:
			  #( 'selector' 'className' 'classSide' 'packageName' 'isExtension'
			     'protocol' 'source' )
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultTitle [

	^ 'Edit Method'
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
			   schemaPropertyNamed: 'operation'
			   type: 'string'
			   description:
			   'The public method edit operation that was performed: create or update.').
		  (self
			   schemaPropertyNamed: 'updateAction'
			   type: 'string'
			   description:
			   'The update action performed when operation=update.').
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
			   'The protocol/category containing the edited method after the operation.').
		  (self
			   schemaPropertyNamed: 'source'
			   type: 'string'
			   description:
			   'The formatted source code of the edited method after the operation.').
		  (self
			   schemaPropertyNamed: 'oldSelector'
			   type: 'string'
			   description:
			   'The previous selector when the update action is rename.').
		  (self
			   schemaPropertyNamed: 'newSelector'
			   type: 'string'
			   description:
			   'The new selector when the update action is rename.').
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
