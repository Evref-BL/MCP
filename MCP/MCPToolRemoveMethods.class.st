Class {
	#name : 'MCPToolRemoveMethods',
	#superclass : 'MCPToolRemoveMethod',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveMethods >> dataForCompiledMethod: aCompiledMethod [

	^ {
		  (#selector -> aCompiledMethod selector asString).
		  (#protocol
		   -> (self protocolNameForCompiledMethod: aCompiledMethod)).
		  (#packageName
		   -> (self packageNameForCompiledMethod: aCompiledMethod)).
		  (#isExtension -> (self isExtensionCompiledMethod: aCompiledMethod)).
		  (#source -> (aCompiledMethod sourceCode ifNil: [ '' ])).
		  (#methodReference -> (self
			    methodReferenceFor: aCompiledMethod methodClass
			    selector: aCompiledMethod selector)) } asDictionary
]

{ #category : 'executing' }
MCPToolRemoveMethods >> executeWithArguments: arguments [

	| behavior className classSide removedMethods selectors selectorSymbols |
	className := arguments at: #className.
	classSide := arguments at: #classSide.
	selectors := self selectorsFromArguments: arguments.
	behavior := self behaviorFromArguments: arguments.
	selectorSymbols := selectors collect: #asSymbol.
	removedMethods := selectorSymbols collect: [ :selector |
		                  | compiledMethod |
		                  compiledMethod := behavior
			                                    compiledMethodAt: selector
			                                    ifAbsent: [
				                                    ^ self
					                                      missingMethodResultForClassName:
					                                      className
					                                      classSide: classSide
					                                      selector: selector asString ].
		                  self dataForCompiledMethod: compiledMethod ].
	^ [
	  (ReRemoveMethodsRefactoring
		   selectors: selectorSymbols
		   from: behavior) execute.
	  self
		  successResultText: (self
				   successSummaryForClassName: className
				   classSide: classSide
				   selectors: selectors)
		  data: {
				  (#className -> className).
				  (#classSide -> classSide).
				  (#selectors -> selectors asArray).
				  (#removedMethods -> removedMethods asArray) } asDictionary ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultText: (self
						   failureMessageForClassNamed: className
						   classSide: classSide
						   selectors: selectors
						   error: error)
				  details: {
						  (#errorClass -> error class name).
						  (#message -> error messageText).
						  (#className -> className).
						  (#classSide -> classSide).
						  (#selectors -> selectors asArray) } asDictionary ]
]

{ #category : 'private' }
MCPToolRemoveMethods >> failureMessageForClassNamed: className classSide: classSide selectors: selectors error: anError [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to remove methods from ';
			  nextPutAll: targetName;
			  nextPutAll: ': ';
			  nextPutAll: (', ' join: selectors);
			  nextPutAll: ' (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'initialization' }
MCPToolRemoveMethods >> initialize [

	super initialize.
	name := 'pharo-remove-methods'.
	title := 'Remove Pharo Methods'.
	description := 'Remove multiple methods from the instance side or class side of a Pharo class using ReRemoveMethodsRefactoring. The refactoring reasons about the batch and rejects removals that still have external senders.'.
	inputSchema := MCPStructureInputSchema new
		               type: 'object';
		               properties: {
				               (MCPStructureProperties new
					                name: 'className';
					                type: 'string';
					                description:
						                'The class from which methods will be removed.';
					                yourself).
				               (MCPStructureProperties new
					                name: 'classSide';
					                type: 'boolean';
					                description:
						                'Whether to remove methods from the class side.';
					                yourself).
				               ((MCPStructureProperties new
					                 name: 'selectors';
					                 type: 'array';
					                 description:
						                 'The selectors to remove as a single refactoring batch.')
					                items: (MCPStructureProperties new
							                 type: 'string';
							                 description: 'A selector to remove.';
							                 yourself);
					                yourself) };
		               required: #( 'className' 'classSide' 'selectors' );
		               yourself.
	outputSchema := self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'className'
					                 type: 'string'
					                 description:
					                 'The class from which methods were removed.').
				                (self
					                 schemaPropertyNamed: 'classSide'
					                 type: 'boolean'
					                 description:
					                 'Whether the removed methods were on the class side.').
				                ((self
					                  schemaPropertyNamed: 'selectors'
					                  type: 'array'
					                  description:
						                  'The selectors removed by the batch refactoring.')
					                 items: (MCPStructureProperties new
							                  type: 'string';
							                  description: 'A removed selector.';
							                  yourself);
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'removedMethods'
					                  type: 'array'
					                  description:
						                  'Structured details for each removed method in the batch.')
					                 items: (MCPStructureProperties new
							                  type: 'object';
							                  properties: {
									                  (self
										                   schemaPropertyNamed: 'selector'
										                   type: 'string'
										                   description:
											                   'The selector that was removed.').
									                  (self
										                   schemaPropertyNamed: 'protocol'
										                   type: 'string'
										                   description:
											                   'The protocol that contained the removed method.').
									                  (self
										                   schemaPropertyNamed: 'packageName'
										                   type: 'string'
										                   description:
											                   'The package that owned the removed method.').
									                  (self
										                   schemaPropertyNamed: 'isExtension'
										                   type: 'boolean'
										                   description:
											                   'Whether the removed method was an extension method.').
									                  (self
										                   schemaPropertyNamed: 'source'
										                   type: 'string'
										                   description:
											                   'The source code of the removed method.').
									                  (self
										                   schemaPropertyNamed: 'methodReference'
										                   type: 'string'
										                   description:
											                   'A readable method reference for the removed method.') };
							                  required:
								                  #( 'selector' 'protocol' 'packageName'
								                     'isExtension' 'source' 'methodReference' );
							                  additionalProperties: false;
							                  yourself);
					                 yourself) }
		                required:
		                #( 'className' 'classSide' 'selectors' 'removedMethods' ).
	icons := {  }
]

{ #category : 'private' }
MCPToolRemoveMethods >> selectorsFromArguments: arguments [

	| normalized selectors |
	selectors := arguments at: #selectors ifAbsent: [ #(  ) ].
	selectors ifNil: [ selectors := #(  ) ].
	normalized := OrderedCollection new.
	selectors do: [ :each |
		| selector |
		selector := each asString trimBoth.
		selector isEmpty ifTrue: [
			Error signal:
				'selectors must contain only non-empty selector strings.' ].
		(normalized includes: selector) ifFalse: [ normalized add: selector ] ].
	normalized ifEmpty: [
		Error signal: 'selectors must contain at least one selector.' ].
	^ normalized asArray
]

{ #category : 'private' }
MCPToolRemoveMethods >> successSummaryForClassName: className classSide: classSide selectors: selectors [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
	^ 'Removed ' , selectors size asString , ' methods from '
	  , targetName , ': ' , (', ' join: selectors) , '.'
]
