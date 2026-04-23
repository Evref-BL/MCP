"
Edits one method in the running image. It handles compilation, renaming, protocol changes, and returns post-compile critiques when relevant.
"
Class {
	#name : 'MCPToolEditMethod',
	#superclass : 'MCPEditTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolEditMethod >> allowedNonErrorCritiqueRuleClasses [

	^ {
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

{ #category : 'private - schema' }
MCPToolEditMethod >> compiledMethodCritiqueSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description:
			  'One included Renraku critique reported for the compiled method.';
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
MCPToolEditMethod >> compiledMethodCritiquesSchemaProperty [

	^ (self
		   schemaPropertyNamed: 'critiques'
		   type: 'array'
		   description:
			   'Renraku critiques included in compile output: all error-severity critiques plus selected non-error rules.')
		  items: self compiledMethodCritiqueSchema;
		  yourself
]

{ #category : 'private - schema' }
MCPToolEditMethod >> compiledMethodDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'selector'
			   type: 'string'
			   description:
			   'The selector of the method after the edit completes.').
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The class that defines the edited method.').
		  ((self
			    schemaPropertyNamed: 'side'
			    type: 'string'
			    description: 'The side on which the edited method is defined.')
			   enum: #( 'instance' 'class' );
			   yourself).
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
		  self compiledMethodCritiquesSchemaProperty }
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
MCPToolEditMethod >> critiqueDataForCompiledMethod: aCompiledMethod [

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
MCPToolEditMethod >> dataForCompiledMethod: aCompiledMethod [

	^ (MCPCompiledMethodInfo fromCompiledMethod: aCompiledMethod)
		  asDictionaryIncludingSource: true
]

{ #category : 'private' }
MCPToolEditMethod >> dataForCompiledMethodWithCritiques: aCompiledMethod [

	| critiques data |
	data := self dataForCompiledMethod: aCompiledMethod.
	critiques := self critiqueDataForCompiledMethod: aCompiledMethod.
	critiques ifNotEmpty: [ data at: #critiques put: critiques ].
	^ data
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultDescription [

	^ 'Compile, rename, or recategorize one method on the instance side or class side of a class. Use remove-methods to delete methods.'
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
						   'The edit operation to perform.'
					   supportedValuesLeadIn: 'Supported canonical values are').
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description: 'The class whose method will be edited.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'classSide';
					   type: 'boolean';
					   description:
						   'Whether the target method is on the class side. Defaults to false.';
					   default: false;
					   yourself).
				  self forceSchemaProperty.
				  (MCPStructureProperties new
					   name: 'selector';
					   type: 'string';
					   description:
						   'The existing selector to rename or changeProtocol. Not used for compile.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'methodSource';
					   type: 'string';
					   description:
						   'The full method source to compile when operation=compile.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'protocol';
					   type: 'string';
					   description:
						   'The target protocol for operation=compile or changeProtocol. For extension methods, use an extension protocol such as *Package-Name.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'newSelector';
					   type: 'string';
					   description:
						   'The new selector to install when operation=rename.';
					   yourself).
				  ((MCPStructureProperties new
					    name: 'permutation';
					    type: 'array';
					    description:
						    'Optional 1-based argument permutation for operation=rename. Defaults to the identity permutation.')
					   items: (MCPStructureProperties new
							    type: 'integer';
							    description: 'A 1-based argument index.';
							    yourself);
					   yourself) };
		  required: #( 'operation' 'className' );
		  yourself
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultName [

	^ 'edit-method'
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultOutputSchema [

	^ self
		                standardOutputSchemaForDataProperties:
		                self compiledMethodDataProperties
		                required:
			                #( 'selector' 'className' 'side' 'packageName'
			                   'isExtension' 'protocol' 'source' )
]

{ #category : 'defaults' }
MCPToolEditMethod >> defaultTitle [

	^ 'Edit Pharo Method'
]

{ #category : 'executing' }
MCPToolEditMethod >> executeChangeProtocolWithArguments: arguments [

	| behavior className classSide force newCompiledMethod protocol requestedContext selector selectorSymbol |
	className := self stringArgumentNamed: 'className' in: arguments.
	classSide := self
		             booleanArgumentNamed: 'classSide'
		             in: arguments
		             default: false.
	force := self forceFromArguments: arguments.
	selector := self selectorStringFrom: arguments.
	protocol := self stringArgumentNamed: 'protocol' in: arguments.
	selectorSymbol := selector asSymbol.
	requestedContext := {
		                    (#className -> className).
		                    (#classSide -> classSide).
		                    (#selector -> selector).
		                    (#protocol -> protocol) } asDictionary.
	^ self
		  executeEditOperation: 'changeProtocol'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  behavior := self behaviorNamed: className classSide: classSide.
			  behavior compiledMethodAt: selectorSymbol ifAbsent: [
				  MCPCommandError
					  signalMissingMethodInClassName: className
					  classSide: classSide
					  selector: selector ].
			  (RBMethodProtocolTransformation
				   protocol: protocol
				   inMethod: selectorSymbol
				   inClass:
				   (self classReferenceNameFor: className classSide: classSide))
				  execute.
			  newCompiledMethod := behavior compiledMethodAt: selectorSymbol ]
		  successResult: [ :warningMessages |
			  self
				  successResultText: 'Changed protocol for '
					  ,
					  (self
						   methodReferenceForBehavior: behavior
						   selector: selectorSymbol) , '.'
				  data: (self dataForCompiledMethod: newCompiledMethod)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForChangeProtocolClassNamed: className
				  classSide: classSide
				  selector: selector
				  protocol: protocol
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditMethod >> executeCompileWithArguments: arguments [

	| behavior className classSide compiledMethod force methodSource protocol requestedContext selector |
	className := self stringArgumentNamed: 'className' in: arguments.
	classSide := self
		             booleanArgumentNamed: 'classSide'
		             in: arguments
		             default: false.
	force := self forceFromArguments: arguments.
	protocol := self stringArgumentNamed: 'protocol' in: arguments.
	methodSource := self
		                argumentNamed: 'methodSource'
		                in: arguments
		                ifAbsent: [ JRPCInvalidParameters signal ].
	requestedContext := {
		                    (#className -> className).
		                    (#classSide -> classSide).
		                    (#protocol -> protocol) } asDictionary.
	^ self
		  executeEditOperation: 'compile'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  behavior := self behaviorNamed: className classSide: classSide.
			  selector := behavior compile: methodSource classified: protocol.
			  compiledMethod := self
				                    reformattedCompiledMethodForBehavior: behavior
				                    selector: selector ]
		  successResult: [ :warningMessages |
			  self
				  successResultText: 'Compiled '
					  ,
					  (self methodReferenceForBehavior: behavior selector: selector)
					  , '.'
				  data: (self dataForCompiledMethodWithCritiques: compiledMethod)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForCompileClassNamed: className
				  classSide: classSide
				  error: error ]
]

{ #category : 'executing' }
MCPToolEditMethod >> executeRenameWithArguments: arguments [

	| behavior className classSide force newCompiledMethod newSelector newSelectorSymbol oldMethodReference oldSelector oldSelectorSymbol permutation requestedContext |
	className := self stringArgumentNamed: 'className' in: arguments.
	classSide := self
		             booleanArgumentNamed: 'classSide'
		             in: arguments
		             default: false.
	force := self forceFromArguments: arguments.
	oldSelector := self selectorStringFrom: arguments.
	newSelector := self stringArgumentNamed: 'newSelector' in: arguments.
	oldSelectorSymbol := oldSelector asSymbol.
	newSelectorSymbol := newSelector asSymbol.
	permutation := self
		               permutationFromArguments: arguments
		               selector: oldSelectorSymbol.
	requestedContext := {
		                    (#className -> className).
		                    (#classSide -> classSide).
		                    (#selector -> oldSelector).
		                    (#newSelector -> newSelector) } asDictionary.
	^ self
		  executeEditOperation: 'rename'
		  force: force
		  requestedContext: requestedContext
		  work: [
			  behavior := self behaviorNamed: className classSide: classSide.
			  behavior compiledMethodAt: oldSelectorSymbol ifAbsent: [
				  MCPCommandError
					  signalMissingMethodInClassName: className
					  classSide: classSide
					  selector: oldSelector ].
			  oldMethodReference := self
				                        methodReferenceForBehavior: behavior
				                        selector: oldSelectorSymbol.
			  (ReRenameMethodRefactoring
				   renameMethod: oldSelectorSymbol
				   in: behavior
				   to: newSelectorSymbol
				   permutation: permutation) execute.
			  newCompiledMethod := self
				                       reformattedCompiledMethodForBehavior:
				                       behavior
				                       selector: newSelectorSymbol ]
		  successResult: [ :warningMessages |
			  self
				  successResultText: 'Renamed ' , oldMethodReference , ' to '
					  ,
					  (self
						   methodReferenceForBehavior: behavior
						   selector: newSelectorSymbol) , '.'
				  data: (self dataForCompiledMethod: newCompiledMethod)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  self
				  failureMessageForRenameClassNamed: className
				  classSide: classSide
				  selector: oldSelector
				  newSelector: newSelector
				  error: error ]
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

{ #category : 'private' }
MCPToolEditMethod >> identityPermutationForSelector: aSelector [

	^ (1 to: aSelector numArgs) asArray
]

{ #category : 'private' }
MCPToolEditMethod >> normalizedPermutation: someIndexes [

	^ someIndexes
		  collect: [ :each |
			  (each isInteger and: [ each > 0 ])
				  ifTrue: [ each ]
				  ifFalse: [
					  | text |
					  text := each asString trimBoth.
					  (text notEmpty and: [
						   text allSatisfy: [ :character | character isDigit ] ])
						  ifTrue: [ text asInteger ]
						  ifFalse: [
						  Error signal:
							  'permutation must contain only positive integers.' ] ] ]
		  as: Array
]

{ #category : 'private - operations' }
MCPToolEditMethod >> operationSpecifications [

	^ {
		  {
			  (#name -> 'compile').
			  (#requiredArguments -> #( 'methodSource' 'protocol' )).
			  (#executeSelector -> #executeCompileWithArguments:) }
			  asDictionary.
		  {
			  (#name -> 'rename').
			  (#requiredArguments -> #( 'selector' 'newSelector' )).
			  (#executeSelector -> #executeRenameWithArguments:) } asDictionary.
		  {
			  (#name -> 'changeProtocol').
			  (#requiredArguments -> #( 'selector' 'protocol' )).
			  (#executeSelector -> #executeChangeProtocolWithArguments:) }
			  asDictionary }
]

{ #category : 'private' }
MCPToolEditMethod >> permutationFromArguments: arguments selector: aSelector [

	| permutation |
	permutation := arguments
		               at: #permutation
		               ifAbsent: [
		               ^ self identityPermutationForSelector: aSelector ].
	permutation ifNil: [
		^ self identityPermutationForSelector: aSelector ].
	permutation := self normalizedPermutation: permutation.
	self validatePermutation: permutation forSelector: aSelector.
	^ permutation
]

{ #category : 'private' }
MCPToolEditMethod >> reformattedCompiledMethodForBehavior: aBehavior selector: aSelector [

	| compiledMethod |
	compiledMethod := aBehavior >> aSelector.
	compiledMethod reformat.
	^ aBehavior >> aSelector
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

{ #category : 'private' }
MCPToolEditMethod >> validatePermutation: permutation forSelector: aSelector [

	| expected |
	expected := self identityPermutationForSelector: aSelector.
	permutation size = expected size ifFalse: [
		Error signal:
			'permutation must contain one index for each method argument.' ].
	permutation asSet = expected asSet ifFalse: [
		Error signal:
			'permutation must be a reordering of the integers from 1 to '
			, expected size asString , '.' ]
]
