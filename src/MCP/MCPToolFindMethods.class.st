"
Lists methods in a chosen scope with optional filtering. It is the general method discovery tool.
"
Class {
	#name : 'MCPToolFindMethods',
	#superclass : 'MCPToolQuery',
	#traits : 'TMCPMethodTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindMethods class >> toolName [

	^ 'method_metadata_search'
]

{ #category : 'private - searching' }
MCPToolFindMethods >> classBindingForClassName: aClassName [

	| binding |
	binding := Smalltalk globals
		           associationAt: aClassName asSymbol
		           ifAbsent: [ ^ nil ].
	^ binding value isBehavior
		  ifTrue: [ binding ]
		  ifFalse: [ nil ]
]

{ #category : 'private - methods' }
MCPToolFindMethods >> classReferenceEntriesForClassNamed: className queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods: (self
				   matchingClassReferencesForClassNamed: className
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolFindMethods >> classReferenceEntriesForQueryRequest: queryRequest [

	^ self
		  classReferenceEntriesForClassNamed:
		  (queryRequest requiredFilterPatternForTool: self)
		  queryRequest: queryRequest
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultDescription [

	^ 'List and search methods by selector, protocol, class, package, or scope. Missing class or package names return warnings with suggestions. Use method_source_search for source text, method_equivalent_search for equivalent ASTs, method_implementor_search for selector implementors, method_sender_search for selector sends, method_class_reference_search for class binding references, and method_variable_reference_search for variable references.'
]

{ #category : 'private - request' }
MCPToolFindMethods >> defaultFilterMode [

	^ 'exact'
]

{ #category : 'defaults' }
MCPToolFindMethods >> defaultInputSchema [

	| properties |
	properties := self methodQueryScopeInputProperties
	              , self metadataFilterInputProperties , {
		              (self
			               filterModeSchemaPropertyWithDescription:
			               'How selector and protocol filters are matched.'
			               values: self supportedFilterModes).
		              (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether selector and protocol matching is case-sensitive.').
		              (self includeSourceSchemaPropertyWithDescription:
			               'Whether to include method source code in each result entry.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching methods to return. Use 0 to request counts only.').
	^ self queryInputSchemaWithProperties: properties
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

	^ 'Search Method Metadata'
]

{ #category : 'private - results' }
MCPToolFindMethods >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'methods'
		  scope: scopeSummary
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> fieldTextsForMethodEntry: anEntry sourceText: sourceText fieldName: fieldName [

	fieldName = 'selector' ifTrue: [ ^ { (anEntry at: #selector) } ].
	fieldName = 'protocol' ifTrue: [ ^ { (anEntry at: #protocol) } ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> filterTextsForMethodEntry: anEntry sourceText: sourceText [

	^ #(  )
]

{ #category : 'private - methods' }
MCPToolFindMethods >> implementorEntriesForQueryRequest: queryRequest [

	^ self
		  implementorEntriesForSelector: queryRequest filterPattern
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolFindMethods >> implementorEntriesForSelector: selectorString queryRequest: queryRequest [

	| compiledMethods selectorSymbol |
	selectorSymbol := selectorString asSymbol.
	compiledMethods := queryRequest scopeQuery methods select: [
		                   :eachMethod |
		                   eachMethod selector = selectorSymbol ].
	^ self
		  methodEntriesFromMethods: compiledMethods asArray
		  queryRequest: queryRequest
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> matchesFieldFiltersOnMethodEntry: anEntry sourceText: sourceText queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName |
				  self
					  fieldTextsForMethodEntry: anEntry
					  sourceText: sourceText
					  fieldName: fieldName ]
		  mode: queryRequest filterMode
		  caseSensitive: queryRequest caseSensitive
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> matchesFilterOnMethodEntry: anEntry sourceText: sourceText matcher: aMatcher [

	^ (self filterTextsForMethodEntry: anEntry sourceText: sourceText)
		  anySatisfy: [ :each | aMatcher value: each ]
]

{ #category : 'private - searching' }
MCPToolFindMethods >> matchingClassReferencesForClassNamed: aClassName inMethods: compiledMethods [

	| classBinding |
	classBinding := self classBindingForClassName: aClassName.
	classBinding ifNil: [
		Error signal: 'There is no class named ' , aClassName , '.' ].
	^ (compiledMethods select: [ :eachMethod |
		   self method: eachMethod referencesAnyVariable: { classBinding } ])
		  asArray
]

{ #category : 'private - searching' }
MCPToolFindMethods >> matchingSelectorReferencesForSelector: aSelectorSymbol inMethods: compiledMethods [

	| specialSelectorIndex |
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil:
		                        aSelectorSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   eachMethod
			   hasSelector: aSelectorSymbol
			   specialSelectorIndex: specialSelectorIndex ]) asArray
]

{ #category : 'private - searching' }
MCPToolFindMethods >> matchingVariableReferencesNamed: aVariableName scopeQuery: query inMethods: compiledMethods [

	| variables |
	variables := self
		             variableBindingsNamed: aVariableName
		             inBehaviors: query behaviors.
	variables ifEmpty: [
		Error signal: 'No variable named ' , aVariableName
			, ' is accessible in the requested scope.' ].
	^ (compiledMethods select: [ :eachMethod |
		   self method: eachMethod referencesAnyVariable: variables ])
		  asArray
]

{ #category : 'private - request' }
MCPToolFindMethods >> metadataFilterFieldNames [

	^ #( 'selector' 'protocol' )
]

{ #category : 'private - schema' }
MCPToolFindMethods >> metadataFilterInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'selector'
			   type: 'string'
			   description:
			   'Optional selector text matched against method selectors.').
		  (self
			   schemaPropertyNamed: 'protocol'
			   type: 'string'
			   description:
			   'Optional protocol/category text matched against method protocols.') }
]

{ #category : 'private - searching' }
MCPToolFindMethods >> method: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable |
		  eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'private - methods' }
MCPToolFindMethods >> methodEntriesFromMethods: compiledMethods queryRequest: queryRequest [

	| entries needsSourceText |
	needsSourceText := queryRequest includeSource.
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
			| entry info sourceText |
			info := MCPCompiledMethodInfo fromMethod: eachMethod.
			sourceText := needsSourceText
				              ifTrue: [ info source ]
				              ifFalse: [ nil ].
			entry := info asDictionaryIncludingSource:
				         queryRequest includeSource.
			queryRequest includeSource ifTrue: [
				entry at: #source put: sourceText ].
			entries add: entry ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - methods' }
MCPToolFindMethods >> methodEntriesFromQueryRequest: queryRequest [

	| entries matcher needsSourceForFiltering |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	needsSourceForFiltering := self needsSourceForFiltering.
	entries := OrderedCollection new.
	queryRequest scopeQuery methodsDo: [ :eachMethod |
			| entry info matchesFilter sourceText |
			info := MCPCompiledMethodInfo fromMethod: eachMethod.
			entry := info asDictionaryIncludingSource: false.
			sourceText := needsSourceForFiltering
				              ifTrue: [ info source ]
				              ifFalse: [ nil ].
			matchesFilter := (queryRequest hasFilterPattern not or: [
					                  self
						                  matchesFilterOnMethodEntry: entry
						                  sourceText: sourceText
						                  matcher: matcher ]) and: [
					                 self
						                 matchesFieldFiltersOnMethodEntry: entry
						                 sourceText: sourceText
						                 queryRequest: queryRequest ].
			matchesFilter ifTrue: [
					queryRequest includeSource ifTrue: [
							sourceText ifNil: [ sourceText := info source ].
							entry at: #source put: sourceText ].
					entries add: entry ] ].
	^ self sortedMethodEntries: entries
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

{ #category : 'private - schema' }
MCPToolFindMethods >> methodEntrySchemaNamed: entryName description: entryDescription subjectDescription: subjectDescription selectorDescription: selectorDescription sourceDescription: sourceDescription [

	^ MCPStructureProperties new
		  name: entryName;
		  type: 'object';
		  description: entryDescription;
		  properties: {
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: selectorDescription).
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description:
						   'The base class that defines the ' , subjectDescription , '.').
				  (self
					   schemaPropertyNamed: 'classSide'
					   type: 'boolean'
					   description:
						   'Whether the ' , subjectDescription
						   , ' is defined on the class side.').
				  (self
					   schemaPropertyNamed: 'packageName'
					   type: 'string'
					   description:
						   'The package that owns the ' , subjectDescription , '.').
				  (self
					   booleanSchemaPropertyNamed: 'isExtension'
					   description: 'Whether the ' , subjectDescription
						   , ' is an extension on its class package.').
				  (self
					   schemaPropertyNamed: 'protocol'
					   type: 'string'
					   description:
						   'The protocol/category containing the ' , subjectDescription
						   , '.').
				  (self
					   schemaPropertyNamed: 'source'
					   type: 'string'
					   description: sourceDescription) };
		  required:
			  #( 'selector' 'className' 'classSide' 'packageName' 'isExtension'
			     'protocol' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolFindMethods >> methodQueryResultDataForPage: page entriesKey: entriesKey [

	^ self queryResultDataFrom: nil page: page entriesKey: entriesKey
]

{ #category : 'private - filtering' }
MCPToolFindMethods >> needsSourceForFiltering [

	^ false
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryEntriesForQueryRequest: queryRequest [

	^ self methodEntriesFromQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryRequestFromToolRequest: request [

	^ MCPFindMethodsRequest fromMetadataRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolFindMethods >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self methodQueryResultDataForPage: page entriesKey: #methods
]

{ #category : 'private - template' }
MCPToolFindMethods >> requestedContextFromRequest: request [

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) }
		  asDictionary
]

{ #category : 'private - methods' }
MCPToolFindMethods >> selectorReferenceEntriesForQueryRequest: queryRequest [

	^ self
		  selectorReferenceEntriesForSelector:
		  (queryRequest requiredFilterPatternForTool: self)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolFindMethods >> selectorReferenceEntriesForSelector: selectorString queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods: (self
				   matchingSelectorReferencesForSelector: selectorString asSymbol
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolFindMethods >> sortedMethodEntries: entries [

	^ (entries asSortedCollection: [ :left :right |
		   (self methodEntryLabel: left) <= (self methodEntryLabel: right) ])
		  asArray
]

{ #category : 'private - template' }
MCPToolFindMethods >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope:
		  (self classAndMethodScopeSummaryForScopeQuery:
			   queryRequest scopeQuery)
		  page: page
]

{ #category : 'private - results' }
MCPToolFindMethods >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'methods'
		  scope: scopeSummary
		  page: page
]

{ #category : 'private - schema' }
MCPToolFindMethods >> supportedFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'private - searching' }
MCPToolFindMethods >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

	| variables |
	variables := IdentitySet new.
	behaviors do: [ :eachBehavior |
		eachBehavior allSlots do: [ :eachSlot |
			eachSlot name asString = aVariableName ifTrue: [
				variables add: eachSlot ] ].
		(eachBehavior bindingOf: aVariableName) ifNotNil: [ :binding |
			variables add: binding ] ].
	^ variables asArray
]

{ #category : 'private - methods' }
MCPToolFindMethods >> variableReferenceEntriesForQueryRequest: queryRequest [

	^ self
		  variableReferenceEntriesForVariableNamed:
		  (queryRequest requiredFilterPatternForTool: self)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolFindMethods >> variableReferenceEntriesForVariableNamed: variableName queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods: (self
				   matchingVariableReferencesNamed: variableName
				   scopeQuery: queryRequest scopeQuery
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]
