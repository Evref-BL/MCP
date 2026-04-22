Class {
	#name : 'MCPToolRemoveMethods',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveMethods >> dataForCompiledMethod: aCompiledMethod [

	| info |
	info := MCPCompiledMethodInfo fromCompiledMethod: aCompiledMethod.
	^ {
		  (#selector -> info selector).
		  (#protocol -> info protocol).
		  (#packageName -> info packageName).
		  (#isExtension -> info isExtension).
		  (#source -> info source) } asDictionary
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
MCPToolRemoveMethods >> executeWithArguments: arguments [

	| behavior className classSide removedMethods selectors selectorSymbols |
	className := arguments at: #className.
	classSide := arguments at: #classSide.
	selectors := self selectorsFromArguments: arguments.
	selectorSymbols := selectors collect: #asSymbol.
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
		                    self dataForCompiledMethod: compiledMethod ].
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
				  (#removedMethods -> removedMethods asArray) } asDictionary ]
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

{ #category : 'initialization' }
MCPToolRemoveMethods >> initialize [

	super initialize.
	name := 'pharo-remove-methods'.
	title := 'Remove Pharo Methods'.
	description := 'Force remove multiple methods from the instance side or class side of a Pharo class as one batch. This bypasses sender checks, so existing senders may be left broken.'.
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
						                 'The selectors to remove as a single force-removal batch.')
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
	^ 'Force-removed ' , selectors size asString , ' methods from '
	  , targetName , ': ' , (', ' join: selectors)
	  ,
	  '. Warning: this bypasses sender checks and may leave broken senders.'
]
