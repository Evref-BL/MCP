"
Abstract base for method search tools.

It centralizes method scope parsing, method-entry result shaping, and shared selector/class/variable lookup helpers while concrete subclasses define their public request shape.
"
Class {
	#name : 'MCPToolMethodSearch',
	#superclass : 'MCPToolSearch',
	#traits : 'TMCPMethodTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolMethodSearch class >> isAbstract [

	^ self = MCPToolMethodSearch
]

{ #category : 'metadata' }
MCPToolMethodSearch >> buildOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'methods'
		  entriesDescription:
		  'The method entries returned for the requested page.'
		  entrySchema: self methodEntrySchema
		  itemNounPhrase: 'methods'
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> classBindingForClassName: aClassName [

	| binding |
	binding := Smalltalk globals
		           associationAt: aClassName asSymbol
		           ifAbsent: [ ^ nil ].
	^ binding value isBehavior ifTrue: [ binding ]
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> classReferenceEntriesForClassNamed: className queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods: (self
				   matchingClassReferencesForClassNamed: className
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> classReferenceEntriesForQueryRequest: queryRequest [

	^ self
		  classReferenceEntriesForClassNamed:
		  (queryRequest requiredFilterPatternForTool: self)
		  queryRequest: queryRequest
]

{ #category : 'private - request' }
MCPToolMethodSearch >> defaultFilterMode [

	^ 'exact'
]

{ #category : 'private - results' }
MCPToolMethodSearch >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'methods'
		  scope: scopeSummary
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> fieldTextsForMethodEntry: anEntry sourceText: sourceText fieldName: fieldName [

	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> filterTextsForMethodEntry: anEntry sourceText: sourceText [

	^ #(  )
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> implementorEntriesForQueryRequest: queryRequest [

	^ self
		  implementorEntriesForSelector: queryRequest filterPattern
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> implementorEntriesForSelector: selectorString queryRequest: queryRequest [

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
MCPToolMethodSearch >> matchesFieldFiltersOnMethodEntry: anEntry sourceText: sourceText queryRequest: queryRequest [

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
MCPToolMethodSearch >> matchesFilterOnMethodEntry: anEntry sourceText: sourceText matcher: aMatcher [

	^ (self filterTextsForMethodEntry: anEntry sourceText: sourceText)
		  anySatisfy: [ :each | aMatcher value: each ]
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> matchingClassReferencesForClassNamed: aClassName inMethods: compiledMethods [

	| classBinding |
	classBinding := self classBindingForClassName: aClassName.
	classBinding ifNil: [
		Error signal: 'There is no class named ' , aClassName , '.' ].
	^ (compiledMethods select: [ :eachMethod |
		   self method: eachMethod referencesAnyVariable: { classBinding } ])
		  asArray
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> matchingSelectorReferencesForSelector: aSelectorSymbol inMethods: compiledMethods [

	| specialSelectorIndex |
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil:
		                        aSelectorSymbol.
	^ (compiledMethods select: [ :eachMethod |
		   eachMethod
			   hasSelector: aSelectorSymbol
			   specialSelectorIndex: specialSelectorIndex ]) asArray
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> matchingVariableReferencesNamed: aVariableName scopeQuery: query inMethods: compiledMethods [

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

{ #category : 'private - searching' }
MCPToolMethodSearch >> method: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable |
		  eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> methodEntriesFromMethods: compiledMethods queryRequest: queryRequest [

	| entries |
	entries := OrderedCollection new.
	compiledMethods do: [ :eachMethod |
			| info |
			info := MCPCompiledMethodInfo fromMethod: eachMethod.
			entries add:
				(info asDictionaryIncludingSource: queryRequest includeSource) ].
	^ self sortedMethodEntries: entries
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> methodEntriesFromQueryRequest: queryRequest [

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
			sourceText := needsSourceForFiltering ifTrue: [ info source ].
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
MCPToolMethodSearch >> methodEntrySchema [

	^ self
		  methodEntrySchemaNamed: 'method'
		  description: 'A method matching the query.'
		  subjectDescription: 'method'
		  selectorDescription: 'The selector name.'
		  sourceDescription:
		  'The formatted source code of the method when includeSource=true.'
]

{ #category : 'private - schema' }
MCPToolMethodSearch >> methodEntrySchemaNamed: entryName description: entryDescription subjectDescription: subjectDescription selectorDescription: selectorDescription sourceDescription: sourceDescription [

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
MCPToolMethodSearch >> methodQueryResultDataForPage: page entriesKey: entriesKey [

	^ self queryResultDataFrom: nil page: page entriesKey: entriesKey
]

{ #category : 'private - schema' }
MCPToolMethodSearch >> methodQueryScopeInputProperties [

	^ {
		  self methodSideSchemaProperty.
		  self searchScopeSchemaProperty }
]

{ #category : 'private - filtering' }
MCPToolMethodSearch >> needsSourceForFiltering [

	^ false
]

{ #category : 'private - template' }
MCPToolMethodSearch >> queryEntriesForQueryRequest: queryRequest [

	^ self methodEntriesFromQueryRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolMethodSearch >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self methodQueryResultDataForPage: page entriesKey: #methods
]

{ #category : 'private - template' }
MCPToolMethodSearch >> requestedContextFromRequest: request [

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) }
		  asDictionary
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> selectorReferenceEntriesForQueryRequest: queryRequest [

	^ self
		  selectorReferenceEntriesForSelector:
		  (queryRequest requiredFilterPatternForTool: self)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> selectorReferenceEntriesForSelector: selectorString queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods: (self
				   matchingSelectorReferencesForSelector: selectorString asSymbol
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> sortedMethodEntries: entries [

	^ entries asArray sort: [ :left :right |
		  (self methodEntryLabel: left) <= (self methodEntryLabel: right) ]
]

{ #category : 'private - results' }
MCPToolMethodSearch >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'methods'
		  scope: scopeSummary
		  page: page
]

{ #category : 'private - schema' }
MCPToolMethodSearch >> supportedFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'private - searching' }
MCPToolMethodSearch >> variableBindingsNamed: aVariableName inBehaviors: behaviors [

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
MCPToolMethodSearch >> variableReferenceEntriesForQueryRequest: queryRequest [

	^ self
		  variableReferenceEntriesForVariableNamed:
		  (queryRequest requiredFilterPatternForTool: self)
		  queryRequest: queryRequest
]

{ #category : 'private - methods' }
MCPToolMethodSearch >> variableReferenceEntriesForVariableNamed: variableName queryRequest: queryRequest [

	^ self
		  methodEntriesFromMethods: (self
				   matchingVariableReferencesNamed: variableName
				   scopeQuery: queryRequest scopeQuery
				   inMethods: queryRequest scopeQuery methods)
		  queryRequest: queryRequest
]
