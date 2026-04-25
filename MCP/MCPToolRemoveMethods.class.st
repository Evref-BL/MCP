"
Removes methods from one class in one batch. It is intentionally direct and does not perform sender safety checks.
"
Class {
	#name : 'MCPToolRemoveMethods',
	#superclass : 'MCPTool',
	#traits : '{} + TMCPMethodTool',
	#classTraits : '{} + TMCPMethodTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - execution' }
MCPToolRemoveMethods >> commandForRequest: removeRequest [

	^ MCPRemoveMethodsCommand tool: self request: removeRequest
]

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

	^ 'Remove methods from one class as a batch without sender safety checks. Use edit-method to create, rename, or recategorize methods instead.'
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
					   description: 'Whether to remove methods from the class side.';
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
					   description: 'The class from which methods were removed.').
				  (self
					   schemaPropertyNamed: 'classSide'
					   type: 'boolean'
					   description:
					   'Whether the removed methods were on the class side.').
				  ((self
					    schemaPropertyNamed: 'selectors'
					    type: 'array'
					    description: 'The selectors removed by the batch operation.')
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
										     description: 'The selector that was removed.').
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
										     description: 'The source code of the removed method.') };
							    required:
								    #( 'selector' 'protocol' 'packageName' 'isExtension'
								       'source' );
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

	| removeRequest result |
	removeRequest := self parsedRequestFromToolRequest: request.
	^ [
	  result := (self commandForRequest: removeRequest) execute.
	  self
		  successResultText: (self
				   successSummaryForClassName: result className
				   classSide: result classSide
				   selectors: result selectors)
		  data: result asDictionary
		  warnings: result warningMessages ]
		  on: Exception
		  do: [ :error |
			  self
				  errorResultForError: error
				  className: removeRequest className
				  classSide: removeRequest classSide
				  selectors: removeRequest selectors ]
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

{ #category : 'private - request' }
MCPToolRemoveMethods >> parsedRequestFromToolRequest: request [

	^ MCPRemoveMethodsRequest fromRequest: request tool: self
]

{ #category : 'private' }
MCPToolRemoveMethods >> selectorsFromRequest: request [

	| selectors |
	selectors := request uniqueStringCollectionArgumentNamed: 'selectors'.
	selectors ifEmpty: [
		Error signal: 'selectors must contain at least one selector.' ].
	^ selectors
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
