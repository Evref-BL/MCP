Class {
	#name : 'MCPToolImplementors',
	#superclass : 'MCPCompiledMethodQueryTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolImplementors >> defaultDescription [

	^ 'Find methods that define a given selector, optionally scoped and filtered. Use references for callers or usages, and find-methods to list methods without selector matching.'
]

{ #category : 'defaults' }
MCPToolImplementors >> defaultIcons [

	^ { (self pngHorizontallyFlippedIconNamed: #references) }
]

{ #category : 'defaults' }
MCPToolImplementors >> defaultInputSchema [

	| scopeProperty sideProperty packageNamesProperty classNamesProperty |
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for implementors. Defaults to image.';
		                 enum: #( 'image' 'packages' 'hierarchy' 'classes' );
		                 default: 'image';
		                 yourself.
	sideProperty := MCPStructureProperties new
		                name: 'side';
		                type: 'string';
		                description:
			                'Which method side to search. Defaults to both.';
		                enum: #( 'instance' 'class' 'both' );
		                default: 'both';
		                yourself.
	packageNamesProperty := self
		                        stringArraySchemaNamed: 'packageNames'
		                        description:
		                        'The package names that define the packages scope. Required when scope=packages.'
		                        itemDescription: 'A package name.'.
	classNamesProperty := self
		                      stringArraySchemaNamed: 'classNames'
		                      description:
		                      'The class names that define the classes or hierarchy scope. Required when scope=classes or scope=hierarchy.'
		                      itemDescription: 'A class name.'.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  (MCPStructureProperties new
					   name: 'selector';
					   type: 'string';
					   description:
						   'The selector whose implementors should be found.';
					   yourself).
				  scopeProperty.
				  sideProperty.
				  packageNamesProperty.
				  classNamesProperty.
				  (MCPStructureProperties new
					   name: 'filter';
					   type: 'string';
					   description:
						   'Optional filter applied to implementor methods after selector matching.';
					   yourself).
				  (MCPStructureProperties new
					   name: 'filterMode';
					   type: 'string';
					   description:
						   'How the filter is matched. Defaults to substring.';
					   enum: #( 'substring' 'prefix' 'exact' 'regex' );
					   default: 'substring';
					   yourself).
				  (MCPStructureProperties new
					   name: 'caseSensitive';
					   type: 'boolean';
					   description:
						   'Whether filter matching is case-sensitive. Defaults to false.';
					   default: false;
					   yourself).
				  (MCPStructureProperties new
					   name: 'includeSource';
					   type: 'boolean';
					   description:
						   'Whether to include implementor source code in each result entry. Defaults to false.';
					   default: false;
					   yourself).
				  (MCPStructureProperties new
					   name: 'limit';
					   type: 'integer';
					   description:
						   'Maximum number of matching implementors to return. Defaults to 100. Use 0 to request counts only.';
					   default: 100;
					   yourself).
				  (MCPStructureProperties new
					   name: 'offset';
					   type: 'integer';
					   description:
						   'Zero-based pagination offset applied after filtering. Defaults to 0.';
					   default: 0;
					   yourself) };
		  required: #( 'selector' );
		  yourself
]

{ #category : 'defaults' }
MCPToolImplementors >> defaultName [

	^ 'implementors'
]

{ #category : 'defaults' }
MCPToolImplementors >> defaultOutputSchema [

	| packageNamesProperty classNamesProperty implementorsProperty |
	packageNamesProperty := self
		                        stringArraySchemaNamed: 'packageNames'
		                        description:
		                        'The package names that define the packages scope. Required when scope=packages.'
		                        itemDescription: 'A package name.'.
	classNamesProperty := self
		                      stringArraySchemaNamed: 'classNames'
		                      description:
		                      'The class names that define the classes or hierarchy scope. Required when scope=classes or scope=hierarchy.'
		                      itemDescription: 'A class name.'.
	implementorsProperty := self
		                        schemaPropertyNamed: 'implementors'
		                        type: 'array'
		                        description:
		                        'The implementors returned for the requested page.'.
	implementorsProperty items: self implementorEntrySchema.
	^ self
		                standardOutputSchemaForDataProperties: {
				                (self
					                 schemaPropertyNamed: 'selector'
					                 type: 'string'
					                 description: 'The selector that was searched.').
				                ((self
					                  schemaPropertyNamed: 'scope'
					                  type: 'string'
					                  description:
						                  'The scope used to search for implementors.')
					                 enum:
						                 #( 'image' 'packages' 'hierarchy' 'classes' );
					                 yourself).
				                ((self
					                  schemaPropertyNamed: 'side'
					                  type: 'string'
					                  description: 'The searched method side.')
					                 enum: #( 'instance' 'class' 'both' );
					                 yourself).
				                (self
					                 schemaPropertyNamed: 'sourceIncluded'
					                 type: 'boolean'
					                 description:
					                 'Whether implementor source was included in the returned entries.').
				                packageNamesProperty.
				                classNamesProperty.
				                (self
					                 integerSchemaPropertyNamed: 'returnedCount'
					                 description:
					                 'The number of implementors returned in this page.').
				                (self
					                 integerSchemaPropertyNamed: 'totalCount'
					                 description:
					                 'The total number of matching implementors before pagination.').
				                (self
					                 integerSchemaPropertyNamed: 'offset'
					                 description:
					                 'The zero-based pagination offset that was applied.').
				                (self
					                 integerSchemaPropertyNamed: 'limit'
					                 description:
					                 'The maximum number of implementors requested.').
				                (self
					                 schemaPropertyNamed: 'truncated'
					                 type: 'boolean'
					                 description:
					                 'Whether additional matching implementors exist beyond the returned page.').
				                implementorsProperty }
		                required:
			                #( 'selector' 'scope' 'side' 'sourceIncluded'
			                   'packageNames' 'classNames' 'returnedCount'
			                   'totalCount' 'offset' 'limit' 'truncated'
			                   'implementors' )
]

{ #category : 'defaults' }
MCPToolImplementors >> defaultTitle [

	^ 'Find Pharo Implementors'
]

{ #category : 'private - template' }
MCPToolImplementors >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForSelector:
		  (requestedContext at: #selector ifAbsent: [ '' ])
		  scope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolImplementors >> failureMessageForSelector: selectorString scope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to find implementors for #';
			  nextPutAll: selectorString;
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - schema' }
MCPToolImplementors >> implementorEntrySchema [

	^ self
		  compiledMethodEntrySchemaNamed: 'implementor'
		  description: 'A method implementing the requested selector.'
		  subjectDescription: 'implementor'
		  selectorDescription: 'The implemented selector.'
		  sourceDescription:
		  'The formatted source code of the implementor when includeSource=true.'
]

{ #category : 'private - template' }
MCPToolImplementors >> queryEntriesForParameters: parameters [

	| compiledMethods query selectorString |
	query := parameters at: #query.
	selectorString := parameters at: #selector.
	compiledMethods := query compiledMethods select: [ :eachMethod |
		                   eachMethod selector = selectorString asSymbol ].
	^ self
		  compiledMethodEntriesFrom: compiledMethods asArray
		  filter: (parameters at: #filterPattern)
		  filterMode: (parameters at: #filterMode)
		  caseSensitive: (parameters at: #caseSensitive)
		  includeSource: (parameters at: #includeSource)
]

{ #category : 'private - template' }
MCPToolImplementors >> queryParametersFromArguments: arguments [

	| parameters |
	parameters := self compiledMethodQueryParametersFromArguments:
		              arguments.
	parameters at: #selector put: (self selectorStringFrom: arguments).
	^ parameters
]

{ #category : 'private - template' }
MCPToolImplementors >> queryResultDataForParameters: parameters page: page [

	^ self
		  compiledMethodQueryResultDataForParameters: parameters
		  page: page
		  entriesKey: #implementors
		  extraData:
		  { (#selector -> (parameters at: #selector)) } asDictionary
]

{ #category : 'private - template' }
MCPToolImplementors >> requestedContextFromArguments: arguments [

	| scope selectorString |
	scope := self
		         argumentNamed: 'scope'
		         in: arguments
		         ifAbsent: [ 'image' ].
	scope := scope
		         ifNil: [ 'image' ]
		         ifNotNil: [ scope asString asLowercase ].
	selectorString := self
		                  argumentNamed: 'selector'
		                  in: arguments
		                  ifAbsent: [ nil ].
	selectorString := selectorString
		                  ifNil: [ nil ]
		                  ifNotNil: [ selectorString asString ].
	^ {
		  (#scope -> scope).
		  (#selector -> selectorString) } asDictionary
]

{ #category : 'private - template' }
MCPToolImplementors >> successSummaryForParameters: parameters page: page [

	^ self
		  successSummaryForSelector: (parameters at: #selector)
		  scope: (parameters at: #query) scope
		  returnedCount: (page at: #returnedCount)
		  totalCount: (page at: #totalCount)
		  truncated: (page at: #truncated)
]

{ #category : 'private - results' }
MCPToolImplementors >> successSummaryForSelector: selectorString scope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' implementors returned for #';
			  nextPutAll: selectorString;
			  nextPutAll: ' [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]
