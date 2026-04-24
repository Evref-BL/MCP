"
Removes methods from one class in one batch. It is intentionally direct and does not perform sender safety checks.
"
Class {
	#name : 'MCPToolRemoveMethods',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveMethods >> dataForMethod: aCompiledMethod [

	| info |
	info := MCPCompiledMethodInfo fromMethod: aCompiledMethod.
	^ {
		  (#selector -> info selector).
		  (#protocol -> info protocol).
		  (#packageName -> info packageName).
		  (#isExtension -> info isExtension).
		  (#source -> info source) } asDictionary
]

{ #category : 'defaults' }
MCPToolRemoveMethods >> defaultDescription [

	^ 'Remove methods from one class as a batch without sender safety checks. Use edit-method to compile, rename, or recategorize methods instead.'
]

{ #category : 'defaults' }
MCPToolRemoveMethods >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #delete) }
]

{ #category : 'defaults' }
MCPToolRemoveMethods >> defaultInputSchema [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'className';
					   type: 'string';
					   description: 'The class from which methods will be removed.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'classSide';
					   type: 'boolean';
					   description:
						   'Whether to remove methods from the class side. Defaults to false.';
					   default: false;
					   yourself).
				  ((MCPStructureProperties new
					    name: 'selectors';
					    type: 'array';
					    description:
						    'The selectors to remove as a single force-removal batch.')
					   items: (MCPStructureProperties new
							    type: 'string';
							    description: 'A selector to remove.';
							    yourself);
					   yourself) };
		  required: #( 'className' 'selectors' );
		  yourself
]

{ #category : 'defaults' }
MCPToolRemoveMethods >> defaultName [

	^ 'remove-methods'
]

{ #category : 'defaults' }
MCPToolRemoveMethods >> defaultOutputSchema [

	^ self
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
						                  'The selectors removed by the batch operation.')
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
											                   'The source code of the removed method.') };
							                  required:
								                  #( 'selector' 'protocol' 'packageName'
								                     'isExtension' 'source' );
							                  additionalProperties: false;
							                  yourself);
					                 yourself) }
		                required:
		                #( 'className' 'classSide' 'selectors' 'removedMethods' )
]

{ #category : 'defaults' }
MCPToolRemoveMethods >> defaultTitle [

	^ 'Remove Methods'
]

{ #category : 'private' }
MCPToolRemoveMethods >> errorResultForError: anError className: className classSide: classSide selectors: selectors [

	(anError isKindOf: MCPCommandError) ifTrue: [
		^ self
			  errorResultText: anError messageText
			  details: anError structuredDetails ].
	^ self
		  errorResultText: (self
				   failureMessageForClassNamed: className
				   classSide: classSide
				   selectors: selectors
				   error: anError)
		  details: {
				  (#errorClass -> anError class name).
				  (#message -> anError messageText).
				  (#className -> className).
				  (#classSide -> classSide).
				  (#selectors -> selectors asArray) } asDictionary
]

{ #category : 'executing' }
MCPToolRemoveMethods >> executeWithRequest: request [

	| behavior className classSide removedMethods selectors selectorSymbols warningMessage |
	className := request stringArgumentNamed: 'className'.
	classSide := request booleanArgumentNamed: 'classSide' default: false.
	selectors := self selectorsFromRequest: request.
	selectorSymbols := selectors collect: #asSymbol.
	warningMessage := 'This bypasses sender checks and may leave broken senders.'.
	^ [
	  behavior := self behaviorNamed: className classSide: classSide.
	  removedMethods := selectorSymbols collect: [ :selector |
		                    | compiledMethod |
		                    compiledMethod := behavior
			                                      compiledMethodAt: selector
			                                      ifAbsent: [
				                                      MCPCommandError
					                                      signalMissingMethodInClassName:
					                                      className
					                                      classSide: classSide
					                                      selector: selector asString ].
		                    self dataForMethod: compiledMethod ].
	  self forceRemoveSelectors: selectorSymbols from: behavior.
	  self
		  successResultText: (self
				   successSummaryForClassName: className
				   classSide: classSide
				   selectors: selectors)
		  data: {
				  (#className -> className).
				  (#classSide -> classSide).
				  (#selectors -> selectors asArray).
				  (#removedMethods -> removedMethods asArray) } asDictionary
		  warnings: { warningMessage } ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForError: error
				  className: className
				  classSide: classSide
				  selectors: selectors ]
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

{ #category : 'private' }
MCPToolRemoveMethods >> forceRemoveSelectors: selectorSymbols from: aBehavior [

	| refactoring |
	refactoring := ReRemoveMethodsRefactoring
		               selectors: selectorSymbols
		               from: aBehavior.
	refactoring checkSuperMethods.
	refactoring removeMethodChanges.
	refactoring performChanges
]

{ #category : 'private' }
MCPToolRemoveMethods >> successSummaryForClassName: className classSide: classSide selectors: selectors [

	| targetName |
	targetName := classSide
		              ifTrue: [ className , ' class' ]
		              ifFalse: [ className ].
	^ 'Force-removed ' , selectors size asString , ' methods from '
	  , targetName , ': ' , (', ' join: selectors) , '.'
]
