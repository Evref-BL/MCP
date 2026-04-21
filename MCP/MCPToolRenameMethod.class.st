Class {
	#name : 'MCPToolRenameMethod',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRenameMethod >> dataForCompiledMethod: aCompiledMethod className: className classSide: classSide oldSelector: oldSelector newSelector: newSelector permutation: permutation oldMethodReference: oldMethodReference [

	| info |
	info := MCPCompiledMethodInfo fromCompiledMethod: aCompiledMethod.
	^ {
		  (#className -> className).
		  (#classSide -> classSide).
		  (#oldSelector -> oldSelector).
		  (#newSelector -> newSelector).
		  (#permutation -> permutation asArray).
		  (#protocol -> info protocol).
		  (#packageName -> info packageName).
		  (#isExtension -> info isExtension).
		  (#source -> info source).
		  (#oldMethodReference -> oldMethodReference).
		  (#methodReference -> info methodReference) } asDictionary
]

{ #category : 'private' }
MCPToolRenameMethod >> errorResultForError: anError className: className classSide: classSide selector: oldSelector newSelector: newSelector [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self
		  errorResultText: (self
				   failureMessageForClassNamed: className
				   classSide: classSide
				   selector: oldSelector
				   newSelector: newSelector
				   error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#className -> className).
				  (#classSide -> classSide).
				  (#selector -> oldSelector).
				  (#newSelector -> newSelector) } asDictionary
]

{ #category : 'executing' }
MCPToolRenameMethod >> executeWithArguments: arguments [

	| behavior className classSide compiledMethod newCompiledMethod newSelector newSelectorSymbol oldMethodReference oldSelector oldSelectorSymbol permutation |
	className := arguments at: #className.
	classSide := arguments at: #classSide.
	oldSelector := arguments at: #selector.
	newSelector := arguments at: #newSelector.
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
				   dataForCompiledMethod: newCompiledMethod
				   className: className
				   classSide: classSide
				   oldSelector: oldSelector
				   newSelector: newSelector
				   permutation: permutation
				   oldMethodReference: oldMethodReference) ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForError: error
				  className: className
				  classSide: classSide
				  selector: oldSelector
				  newSelector: newSelector ]
]

{ #category : 'private' }
MCPToolRenameMethod >> failureMessageForClassNamed: className classSide: classSide selector: oldSelector newSelector: newSelector error: anError [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
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
MCPToolRenameMethod >> identityPermutationForSelector: aSelector [

	^ (1 to: aSelector numArgs) asArray
]

{ #category : 'initialization' }
MCPToolRenameMethod >> initialize [

	super initialize.
	name := 'pharo-rename-method'.
	title := 'Rename Pharo Method'.
	description := 'Rename a method on the instance side or class side of a Pharo class using ReRenameMethodRefactoring so senders are updated and argument permutation is supported.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The class that defines the method to rename.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'classSide';
					                type: 'boolean';
					                description:
						                'Whether the method is defined on the class side.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'selector';
					                type: 'string';
					                description: 'The existing selector to rename.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'newSelector';
					                type: 'string';
					                description: 'The new selector to install.';
					                yourself).
				               ((MCPStructureProperties new
					                 name: 'permutation';
					                 type: 'array';
					                 description:
						                 'Optional 1-based argument permutation describing how old arguments map to the new selector order. Defaults to the identity permutation.')
					                items: (MCPStructureProperties new
							                 type: 'number';
							                 description: 'A 1-based argument index.';
							                 yourself);
					                yourself) };
		               required:
		               #( 'className' 'classSide' 'selector' 'newSelector' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description:
					                 'The class whose method was renamed.').
				                (self
					                 schemaPropertyNamed: 'classSide'
					                 type: 'boolean'
					                 description:
					                 'Whether the renamed method is on the class side.').
				                (self
					                 schemaPropertyNamed: 'oldSelector'
					                 type: 'string'
					                 description: 'The selector before the rename.').
				                (self
					                 schemaPropertyNamed: 'newSelector'
					                 type: 'string'
					                 description: 'The selector after the rename.').
				                ((self
					                  schemaPropertyNamed: 'permutation'
					                  type: 'array'
					                  description:
						                  'The normalized 1-based argument permutation used for the refactoring.')
					                 items: (MCPStructureProperties new
							                  type: 'number';
							                  description: 'A 1-based argument index.';
							                  yourself);
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'protocol'
					                 type: 'string'
					                 description:
					                 'The protocol containing the renamed method.').
				                (self
					                 schemaPropertyNamed: 'packageName'
					                 type: 'string'
					                 description:
					                 'The package that owns the renamed method.').
				                (self
					                 schemaPropertyNamed: 'isExtension'
					                 type: 'boolean'
					                 description:
					                 'Whether the renamed method is an extension method.').
				                (self
					                 schemaPropertyNamed: 'source'
					                 type: 'string'
					                 description:
					                 'The source code of the renamed method after refactoring.').
				                (self
					                 schemaPropertyNamed: 'oldMethodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference for the original selector.').
				                (self
					                 schemaPropertyNamed: 'methodReference'
					                 type: 'string'
					                 description:
					                 'A readable method reference for the renamed selector.') }
		                required:
			                #( 'className' 'classSide' 'oldSelector'
			                   'newSelector' 'permutation' 'protocol'
			                   'packageName' 'isExtension' 'source' 'oldMethodReference'
			                   'methodReference' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRenameMethod >> normalizedPermutation: someIndexes [

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

{ #category : 'private' }
MCPToolRenameMethod >> permutationFromArguments: arguments selector: aSelector [

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
MCPToolRenameMethod >> validatePermutation: permutation forSelector: aSelector [

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
