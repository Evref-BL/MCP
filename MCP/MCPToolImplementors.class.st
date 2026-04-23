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

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: { (self
				   schemaPropertyNamed: 'selector'
				   type: 'string'
				   description: 'The selector whose implementors should be found.') }
			  ,
				  (self
					   compiledMethodQueryScopeInputPropertiesWithScopeDescription:
						   'Where to search for implementors. Defaults to image.')
			  , (self
					   compiledMethodQueryFilteringInputPropertiesWithFilterDescription:
						   'Optional filter applied to implementor methods after selector matching.'
					   extraProperties: #(  )
					   includeSourceDescription:
						   'Whether to include implementor source code in each result entry. Defaults to false.'
					   limitDescription:
						   'Maximum number of matching implementors to return. Defaults to 100. Use 0 to request counts only.');
		  required: #( 'selector' );
		  yourself
]

{ #category : 'defaults' }
MCPToolImplementors >> defaultName [

	^ 'implementors'
]

{ #category : 'defaults' }
MCPToolImplementors >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed:
		  'implementors'
		  entriesDescription:
		  'The implementors returned for the requested page.'
		  entrySchema: self implementorEntrySchema
		  itemNounPhrase: 'implementors'
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
		  compiledMethodQueryResultDataForPage: page
		  entriesKey: #implementors
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
