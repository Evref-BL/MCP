Class {
	#name : 'MCPToolEditMethod',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolEditMethod >> changeProtocolDataForCompiledMethod: aCompiledMethod className: className classSide: classSide oldProtocol: oldProtocol [

	| data |
	data := self
		        dataForCompiledMethod: aCompiledMethod
		        className: className
		        classSide: classSide
		        operation: 'changeProtocol'.
	data at: #oldProtocol put: oldProtocol.
	^ data
]

{ #category : 'private' }
MCPToolEditMethod >> dataForCompiledMethod: aCompiledMethod className: className classSide: classSide operation: operation [

	| info |
	info := MCPCompiledMethodInfo fromCompiledMethod: aCompiledMethod.
	^ {
		  (#operation -> operation).
		  (#className -> className).
		  (#classSide -> classSide).
		  (#selector -> info selector).
		  (#protocol -> info protocol).
		  (#packageName -> info packageName).
		  (#isExtension -> info isExtension).
		  (#source -> info source).
		  (#methodReference -> info methodReference) } asDictionary
]

{ #category : 'private' }
MCPToolEditMethod >> errorResultForChangeProtocolError: anError className: className classSide: classSide selector: selector protocol: protocol [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultForCommandError: anError
			  operation: 'changeProtocol' ].
	^ self
		  errorResultText: (self
				   failureMessageForChangeProtocolClassNamed: className
				   classSide: classSide
				   selector: selector
				   protocol: protocol
				   error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#operation -> 'changeProtocol').
				  (#className -> className).
				  (#classSide -> classSide).
				  (#selector -> selector).
				  (#protocol -> protocol) } asDictionary
]

{ #category : 'private' }
MCPToolEditMethod >> errorResultForCommandError: anError operation: operation [

	| details |
	details := anError structuredDetails copy.
	details at: #operation put: operation.
	^ self errorResultText: anError messageText details: details
]

{ #category : 'private' }
MCPToolEditMethod >> errorResultForCompileError: anError className: className classSide: classSide protocol: protocol [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self errorResultForCommandError: anError operation: 'compile' ].
	^ self
		  errorResultText: (self
				   failureMessageForCompileClassNamed: className
				   classSide: classSide
				   error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#operation -> 'compile').
				  (#className -> className).
				  (#classSide -> classSide).
				  (#protocol -> protocol) } asDictionary
]

{ #category : 'private' }
MCPToolEditMethod >> errorResultForRenameError: anError className: className classSide: classSide selector: oldSelector newSelector: newSelector [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self errorResultForCommandError: anError operation: 'rename' ].
	^ self
		  errorResultText: (self
				   failureMessageForRenameClassNamed: className
				   classSide: classSide
				   selector: oldSelector
				   newSelector: newSelector
				   error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#operation -> 'rename').
				  (#className -> className).
				  (#classSide -> classSide).
				  (#selector -> oldSelector).
				  (#newSelector -> newSelector) } asDictionary
]

{ #category : 'executing' }
MCPToolEditMethod >> executeChangeProtocolWithArguments: arguments [

	| behavior className classSide compiledMethod newCompiledMethod oldProtocol protocol selector selectorSymbol |
	className := self stringArgumentNamed: 'className' in: arguments.
	classSide := self
		             booleanArgumentNamed: 'classSide'
		             in: arguments
		             default: false.
	selector := self selectorStringFrom: arguments.
	protocol := self stringArgumentNamed: 'protocol' in: arguments.
	selectorSymbol := selector asSymbol.
	^ [
	  behavior := self behaviorNamed: className classSide: classSide.
	  compiledMethod := behavior
		                    compiledMethodAt: selectorSymbol
		                    ifAbsent: [
			                    MCPCommandError
				                    signalMissingMethodInClassName: className
				                    classSide: classSide
				                    selector: selector ].
	  oldProtocol := (MCPCompiledMethodInfo fromCompiledMethod:
		                  compiledMethod) protocol.
	  (RBMethodProtocolTransformation
		   protocol: protocol
		   inMethod: selectorSymbol
		   inClass:
		   (self transformationClassNameFor: className classSide: classSide))
		  execute.
	  newCompiledMethod := behavior compiledMethodAt: selectorSymbol.
	  self
		  successResultText: 'Changed protocol for '
			  ,
			  (self
				   methodReferenceForBehavior: behavior
				   selector: selectorSymbol) , '.'
		  data: (self
				   changeProtocolDataForCompiledMethod: newCompiledMethod
				   className: className
				   classSide: classSide
				   oldProtocol: oldProtocol) ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForChangeProtocolError: error
				  className: className
				  classSide: classSide
				  selector: selector
				  protocol: protocol ]
]

{ #category : 'executing' }
MCPToolEditMethod >> executeCompileWithArguments: arguments [

	| behavior className classSide compiledMethod methodSource protocol selector |
	className := self stringArgumentNamed: 'className' in: arguments.
	classSide := self
		             booleanArgumentNamed: 'classSide'
		             in: arguments
		             default: false.
	protocol := self stringArgumentNamed: 'protocol' in: arguments.
	methodSource := self
		                argumentNamed: 'methodSource'
		                in: arguments
		                ifAbsent: [ JRPCInvalidParameters signal ].
	^ [
	  behavior := self behaviorNamed: className classSide: classSide.
	  selector := behavior
		              compile:
		              (self normalizedMethodSourceFrom: methodSource)
		              classified: protocol.
	  compiledMethod := behavior >> selector.
	  compiledMethod reformat.
	  self
		  successResultText: 'Compiled '
			  , (self methodReferenceForBehavior: behavior selector: selector)
			  , '.'
		  data: (self
				   dataForCompiledMethod: compiledMethod
				   className: className
				   classSide: classSide
				   operation: 'compile') ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForCompileError: error
				  className: className
				  classSide: classSide
				  protocol: protocol ]
]

{ #category : 'executing' }
MCPToolEditMethod >> executeRenameWithArguments: arguments [

	| behavior className classSide compiledMethod newCompiledMethod newSelector newSelectorSymbol oldMethodReference oldSelector oldSelectorSymbol permutation |
	className := self stringArgumentNamed: 'className' in: arguments.
	classSide := self
		             booleanArgumentNamed: 'classSide'
		             in: arguments
		             default: false.
	oldSelector := self selectorStringFrom: arguments.
	newSelector := self stringArgumentNamed: 'newSelector' in: arguments.
	oldSelectorSymbol := oldSelector asSymbol.
	newSelectorSymbol := newSelector asSymbol.
	permutation := self
		               permutationFromArguments: arguments
		               selector: oldSelectorSymbol.
	^ [
	  behavior := self behaviorNamed: className classSide: classSide.
	  compiledMethod := behavior
		                    compiledMethodAt: oldSelectorSymbol
		                    ifAbsent: [
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
	  newCompiledMethod := behavior compiledMethodAt: newSelectorSymbol.
	  self
		  successResultText: 'Renamed ' , oldMethodReference , ' to '
			  ,
			  (self
				   methodReferenceForBehavior: behavior
				   selector: newSelectorSymbol) , '.'
		  data: (self
				   renameDataForCompiledMethod: newCompiledMethod
				   className: className
				   classSide: classSide
				   oldSelector: oldSelector
				   newSelector: newSelector
				   permutation: permutation
				   oldMethodReference: oldMethodReference) ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForRenameError: error
				  className: className
				  classSide: classSide
				  selector: oldSelector
				  newSelector: newSelector ]
]

{ #category : 'executing' }
MCPToolEditMethod >> executeWithArguments: arguments [

	| operation |
	operation := self operationFromArguments: arguments.
	self validateRequiredArgumentsForOperation: operation in: arguments.
	operation = 'compile' ifTrue: [
		^ self executeCompileWithArguments: arguments ].
	operation = 'rename' ifTrue: [
		^ self executeRenameWithArguments: arguments ].
	operation = 'changeProtocol' ifTrue: [
		^ self executeChangeProtocolWithArguments: arguments ].
	Error signal:
		'operation must be one of compile, rename, or changeProtocol.'
]

{ #category : 'private' }
MCPToolEditMethod >> failureMessageForChangeProtocolClassNamed: className classSide: classSide selector: selector protocol: protocol error: anError [

	| targetName |
	targetName := self
		              targetNameForClassName: className
		              classSide: classSide.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to change protocol for ';
			  nextPutAll: targetName;
			  nextPutAll: '>>';
			  nextPutAll: selector;
			  nextPutAll: ' to ';
			  nextPutAll: protocol;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private' }
MCPToolEditMethod >> failureMessageForCompileClassNamed: className classSide: classSide error: anError [

	| targetName |
	targetName := self
		              targetNameForClassName: className
		              classSide: classSide.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to compile method on ';
			  nextPutAll: targetName;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private' }
MCPToolEditMethod >> failureMessageForRenameClassNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

	| targetName |
	targetName := self
		              targetNameForClassName: className
		              classSide: classSide.
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to rename method ';
			  nextPutAll: targetName;
			  nextPutAll: '>>';
			  nextPutAll: oldSelector;
			  nextPutAll: ' to ';
			  nextPutAll: newSelector;
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private' }
MCPToolEditMethod >> identityPermutationForSelector: aSelector [

	^ (1 to: aSelector numArgs) asArray
]

{ #category : 'initialization' }
MCPToolEditMethod >> initialize [

	super initialize.
	name := 'pharo-edit-method'.
	title := 'Edit Pharo Method'.
	description := 'Edit a method on the instance side or class side of a Pharo class by compiling source, renaming a selector, or changing a protocol.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'operation';
					                type: 'string';
					                description:
						                'The edit operation to perform. Supported values are compile, rename, and changeProtocol.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The class whose method will be edited.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'classSide';
					                type: 'boolean';
					                description:
						                'Whether the target method is on the class side.';
					                yourself).
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
						                'The target method protocol for compile or changeProtocol, including extension protocols.';
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
							                 type: 'number';
							                 description: 'A 1-based argument index.';
							                 yourself);
					                yourself) };
		               required: #( 'operation' 'className' 'classSide' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'operation'
					                 type: 'string'
					                 description:
					                 'The edit operation that was performed.').
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description:
					                 'The class whose method was edited.').
				                (self
					                 schemaPropertyNamed: 'classSide'
					                 type: 'boolean'
					                 description:
					                 'Whether the edited method is on the class side.').
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description:
					                 'The selector after the edit operation completes.').
				                (self
					                 schemaPropertyNamed: 'protocol'
					                 type: 'string'
					                 description:
					                 'The protocol containing the edited method after the operation.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owns the edited method after the operation.').
				                (self
					                 schemaPropertyNamed: 'isExtension'
					                 type: 'boolean'
					                 description:
					                 'Whether the edited method is an extension method after the operation.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The method source after the operation.').
				                (self
					                 schemaPropertyNamed: 'methodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference for the edited method after the operation.').
				                (self
					                 schemaPropertyNamed: 'oldSelector'
					                 type: 'string'
					                 description:
					                 'The selector before a rename operation.').
				                (self
					                 schemaPropertyNamed: 'newSelector'
					                 type: 'string'
					                 description:
					                 'The selector after a rename operation.').
				                ((self
					                  schemaPropertyNamed: 'permutation'
					                  type: 'array'
					                  description:
						                  'The normalized permutation used for a rename operation.')
					                 items: (MCPStructureProperties new
							                  type: 'number';
							                  description: 'A 1-based argument index.';
							                  yourself);
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'oldMethodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference for the original selector before a rename operation.').
				                (self
					                 schemaPropertyNamed: 'oldProtocol'
					                 type: 'string'
					                 description:
					                 'The protocol before a changeProtocol operation.') }
		                required:
			                #( 'operation' 'className' 'classSide' 'selector'
			                   'protocol' 'packageName' 'isExtension'
			                   'source' 'methodReference' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolEditMethod >> normalizedMethodSourceFrom: aMethodSource [

	^ aMethodSource withInternalLineEndings
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

{ #category : 'private - arguments' }
MCPToolEditMethod >> operationFromArguments: arguments [

	| normalized operation |
	operation := self stringArgumentNamed: 'operation' in: arguments.
	operation ifNil: [ JRPCInvalidParameters signal ].
	normalized := operation asLowercase.
	normalized = 'compile' ifTrue: [ ^ 'compile' ].
	normalized = 'rename' ifTrue: [ ^ 'rename' ].
	(#( 'changeprotocol' 'change-protocol' ) includes: normalized)
		ifTrue: [ ^ 'changeProtocol' ].
	Error signal:
		'operation must be one of compile, rename, or changeProtocol.'
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
MCPToolEditMethod >> renameDataForCompiledMethod: aCompiledMethod className: className classSide: classSide oldSelector: oldSelector newSelector: newSelector permutation: permutation oldMethodReference: oldMethodReference [

	| data |
	data := self
		        dataForCompiledMethod: aCompiledMethod
		        className: className
		        classSide: classSide
		        operation: 'rename'.
	data
		at: #oldSelector put: oldSelector;
		at: #newSelector put: newSelector;
		at: #permutation put: permutation asArray;
		at: #oldMethodReference put: oldMethodReference.
	^ data
]

{ #category : 'private' }
MCPToolEditMethod >> targetNameForClassName: className classSide: classSide [

	^ classSide
		  ifTrue: [ className , ' class' ]
		  ifFalse: [ className ]
]

{ #category : 'private' }
MCPToolEditMethod >> transformationClassNameFor: className classSide: classSide [

	^ classSide
		  ifTrue: [ className , ' class' ]
		  ifFalse: [ className ]
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

{ #category : 'private - arguments' }
MCPToolEditMethod >> validateRequiredArgumentsForOperation: operation in: arguments [

	operation = 'compile' ifTrue: [
		(self
			 argumentNamed: 'methodSource'
			 in: arguments
			 ifAbsent: [ JRPCInvalidParameters signal ]) ifNil: [
			JRPCInvalidParameters signal ].
		(self stringArgumentNamed: 'protocol' in: arguments) ifNil: [
			JRPCInvalidParameters signal ].
		^ self ].
	operation = 'rename' ifTrue: [
		(self selectorStringFrom: arguments) ifNil: [
			JRPCInvalidParameters signal ].
		(self stringArgumentNamed: 'newSelector' in: arguments) ifNil: [
			JRPCInvalidParameters signal ].
		^ self ].
	operation = 'changeProtocol' ifTrue: [
		(self selectorStringFrom: arguments) ifNil: [
			JRPCInvalidParameters signal ].
		(self stringArgumentNamed: 'protocol' in: arguments) ifNil: [
			JRPCInvalidParameters signal ].
		^ self ].
	Error signal:
		'operation must be one of compile, rename, or changeProtocol.'
]
