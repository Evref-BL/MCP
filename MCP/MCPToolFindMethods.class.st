"
Lists methods in a chosen scope with optional filtering. It is the general method discovery tool.
"
Class {
	#name : 'MCPToolFindMethods',
	#superclass : 'MCPMethodQueryTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindMethods >> defaultDescription [

	^ 'List methods in a scope and optionally filter the returned method entries. Use implementors to find definitions of a selector, and references to find methods that use a selector, class, or variable.'
]

{ #category : 'private - arguments' }
MCPToolFindMethods >> defaultFilterTargets [

	^ #( 'selector' )
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #page badgeIconNamed: #search) }
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultInputSchema [

	| filterTargetsProperty |
	filterTargetsProperty := self
		                         stringEnumArraySchemaNamed: 'filterTargets'
		                         description:
		                         'Optional method-entry fields matched by filter. Defaults to selector. This filters the listed methods; it does not perform reference lookup.'
		                         itemDescription: 'A filter target.'
		                         values: self supportedFilterTargets
		                         default: self defaultFilterTargets.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties:
			  (self
				   methodQueryScopeInputPropertiesWithScopeDescription:
					   'Where to search for methods. Defaults to image.') , (self
					   methodQueryFilteringInputPropertiesWithFilterDescription:
						   'Optional filter applied to the methods found in scope. Use filterTargets to choose which fields are matched.'
					   extraProperties: { filterTargetsProperty }
					   includeSourceDescription:
						   'Whether to include method source code in each result entry. Defaults to false.'
					   limitDescription:
						   'Maximum number of matching methods to return. Defaults to 100. Use 0 to request counts only.');
		  required: #(  );
		  yourself
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultName [

	^ 'find-methods'
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'methods'
		  entriesDescription:
		  'The method entries returned for the requested page.'
		  entrySchema: self methodEntrySchema
		  itemNounPhrase: 'methods'
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultTitle [

	^ 'Find Methods'
]

{ #category : 'private - template' }
MCPToolFindMethods >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolFindMethods >> failureMessageForScope: scope error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'methods'
		  scope: scope
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> filterTextsForMethodEntry: anEntry sourceText: sourceText targets: filterTargets [

	| texts |
	texts := OrderedCollection new.
	filterTargets do: [ :each |
		each = 'selector' ifTrue: [ texts add: (anEntry at: #selector) ].
		each = 'class' ifTrue: [ texts add: (anEntry at: #className) ].
		each = 'package' ifTrue: [ texts add: (anEntry at: #packageName) ].
		each = 'protocol' ifTrue: [ texts add: (anEntry at: #protocol) ].
		each = 'reference' ifTrue: [
			texts add: (self methodEntryLabel: anEntry) ].
		each = 'source' ifTrue: [ texts add: sourceText ] ].
	^ texts asArray
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> matchesFilterOnMethodEntry: anEntry sourceText: sourceText matcher: aMatcher targets: filterTargets [

	^ (self
		   filterTextsForMethodEntry: anEntry
		   sourceText: sourceText
		   targets: filterTargets) anySatisfy: [ :each |
		  aMatcher value: each ]
]

{ #category : 'private - methods' }
MCPToolFindMethods >> methodEntriesFromQuery: query filter: filterPattern filterTargets: filterTargets filterMode: filterMode caseSensitive: caseSensitive includeSource: includeSource [

	| entries matcher needsSourceForFiltering |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	needsSourceForFiltering := filterPattern notNil and: [
		                           filterTargets includes: 'source' ].
	entries := OrderedCollection new.
	query methodsDo: [ :eachMethod |
		| entry info sourceText |
		info := MCPCompiledMethodInfo fromMethod: eachMethod.
		entry := info asDictionaryIncludingSource: false.
		sourceText := needsSourceForFiltering
			              ifTrue: [ info source ]
			              ifFalse: [ nil ].
		(filterPattern isNil or: [
			 self
				 matchesFilterOnMethodEntry: entry
				 sourceText: sourceText
				 matcher: matcher
				 targets: filterTargets ]) ifTrue: [
			includeSource ifTrue: [
				sourceText ifNil: [ sourceText := info source ].
				entry at: #source put: sourceText ].
			entries add: entry ] ].
	^ (entries asSortedCollection: [ :left :right |
		   (self methodEntryLabel: left) <= (self methodEntryLabel: right) ])
		  asArray
]

{ #category : 'private - schema' }
MCPToolFindMethods >> methodEntrySchema [

	^ self
		  methodEntrySchemaNamed: 'method'
		  description: 'A method matching the query.'
		  subjectDescription: 'method'
		  selectorDescription: 'The selector name.'
		  sourceDescription:
		  'The formatted source code of the method when includeSource=true.'
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryEntriesForParameters: parameters [

	^ self
		  methodEntriesFromQuery: (parameters at: #query)
		  filter: (parameters at: #filterPattern)
		  filterTargets: (parameters at: #filterTargets)
		  filterMode: (parameters at: #filterMode)
		  caseSensitive: (parameters at: #caseSensitive)
		  includeSource: (parameters at: #includeSource)
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryParametersFromArguments: arguments [

	| parameters |
	parameters := self methodQueryParametersFromArguments:
		              arguments.
	parameters
		at: #filterTargets
		put: (self normalizedFilterTargetsFrom: arguments).
	^ parameters
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryResultDataForParameters: parameters page: page [

	^ self
		  methodQueryResultDataForPage: page
		  entriesKey: #methods
]

{ #category : 'private - template' }
MCPToolFindMethods >> requestedContextFromArguments: arguments [

	| scope |
	scope := self
		         argumentNamed: 'scope'
		         in: arguments
		         ifAbsent: [ 'image' ].
	scope := scope
		         ifNil: [ 'image' ]
		         ifNotNil: [ scope asString asLowercase ].
	^ { (#scope -> scope) } asDictionary
]

{ #category : 'private - template' }
MCPToolFindMethods >> successSummaryForParameters: parameters page: page [

	^ self
		  successSummaryForScope: (parameters at: #query) scope
		  returnedCount: (page at: #returnedCount)
		  totalCount: (page at: #totalCount)
		  truncated: (page at: #truncated)
]

{ #category : 'private - results' }
MCPToolFindMethods >> successSummaryForScope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ self
		  scopeQuerySuccessSummaryFor: 'methods'
		  scope: scope
		  returnedCount: returnedCount
		  totalCount: totalCount
		  truncated: truncated
]

{ #category : 'private - arguments' }
MCPToolFindMethods >> supportedFilterTargets [

	^ #( 'selector' 'class' 'package' 'protocol' 'reference' 'source' )
]
