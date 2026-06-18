"
Shared base class for search-style MCP tools. It centralizes paged result shaping and search-specific error handling.
"
Class {
	#name : 'MCPToolSearch',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolSearch class >> isAbstract [

	^ self = MCPToolSearch
]

{ #category : 'private - results' }
MCPToolSearch >> addScopeLabel: aString to: labels [

	(labels includes: aString) ifFalse: [ labels add: aString ]
]

{ #category : 'private - schema' }
MCPToolSearch >> basicFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'private - schema' }
MCPToolSearch >> caseSensitiveSchemaPropertyWithDescription: caseSensitiveDescription [

	^ self
		  booleanSchemaPropertyNamed: 'caseSensitive'
		  description: caseSensitiveDescription
		  default: true
]

{ #category : 'private - results' }
MCPToolSearch >> classAndMethodScopeSummaryForScopeQuery: scopeQuery [

	^ self classAndMethodScopeSummaryFromAssociations: {
			  ('packages' -> scopeQuery packageNames).
			  ('classes' -> scopeQuery classNames).
			  ('hierarchy' -> scopeQuery hierarchyClassNames).
			  ('subclasses' -> scopeQuery subclassClassNames).
			  ('parents' -> scopeQuery parentClassNames) }
]

{ #category : 'private - results' }
MCPToolSearch >> classAndMethodScopeSummaryFromAssociations: scopeAssociations [

	| labels |
	labels := OrderedCollection new.
	scopeAssociations do: [ :eachAssociation |
		eachAssociation value notEmpty ifTrue: [
			self addScopeLabel: eachAssociation key to: labels ] ].
	^ self scopeSummaryFromLabels: labels
]

{ #category : 'private - results' }
MCPToolSearch >> classAndMethodScopeSummaryFromRequest: request [

	^ self classAndMethodScopeSummaryFromAssociations: {
			  ('packages'
			   -> (request stringCollectionArgumentNamed: 'packageNames')).
			  ('classes'
			   -> (request stringCollectionArgumentNamed: 'classNames')).
			  ('hierarchy'
			   ->
			   (request stringCollectionArgumentNamed: 'hierarchyClassNames')).
			  ('subclasses'
			   -> (request stringCollectionArgumentNamed: 'subclassClassNames')).
			  ('parents'
			   -> (request stringCollectionArgumentNamed: 'parentClassNames')) }
]

{ #category : 'private - schema' }
MCPToolSearch >> classQueryScopeInputProperties [

	^ {
		  self classScopePackageNamesProperty.
		  self classScopeClassNamesProperty.
		  self classScopeHierarchyClassNamesProperty.
		  self classScopeSubclassClassNamesProperty.
		  self classScopeParentClassNamesProperty }
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopeClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'classNames'
		  description: 'Exact classes.'
		  itemDescription: 'Class name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopeHierarchyClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description: 'Classes plus superclasses and subclasses.'
		  itemDescription: 'Hierarchy root class.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description: 'Packages to include.'
		  itemDescription: 'Package name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopeParentClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'parentClassNames'
		  description: 'Superclasses of these classes; roots excluded.'
		  itemDescription: 'Subclass name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopeSubclassClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'subclassClassNames'
		  description: 'Subclasses of these classes; roots excluded.'
		  itemDescription: 'Superclass name.'
]

{ #category : 'private - execution' }
MCPToolSearch >> commandForRequest: searchRequest [

	^ MCPSearchToolCommand tool: self request: searchRequest
]

{ #category : 'private - request' }
MCPToolSearch >> defaultFilterMode [

	^ 'substring'
]

{ #category : 'private - pagination' }
MCPToolSearch >> defaultPageLimit [

	^ 25
]

{ #category : 'private - results' }
MCPToolSearch >> errorResultForQueryError: anError requestedContext: requestedContext [

	| normalizedContext |
	normalizedContext := requestedContext ifNil: [ Dictionary new ].
	^ anError
		  mcpCommandErrorDo: [ :commandError |
				  | details |
				  details := commandError structuredDetails copy.
				  normalizedContext associationsDo: [ :each |
					  each value ifNotNil: [ details at: each key put: each value ] ].
				  self errorResultText: commandError messageText details: details ]
		  otherwise: [ :queryError |
				  | details |
				  details := {
					             (#errorClass -> queryError class name).
					             (#message -> queryError messageText) } asDictionary.
				  normalizedContext associationsDo: [ :each |
					  each value ifNotNil: [ details at: each key put: each value ] ].
				  self
					  errorResultText: (self
							   failureMessageForRequestedContext: normalizedContext
							   error: queryError)
					  details: details ]
]

{ #category : 'executing' }
MCPToolSearch >> executeWithRequest: request [

	^ self
		  executeParsedRequestFrom: request
		  do: [ :queryRequest |
			  | command page |
			  command := self commandForRequest: queryRequest.
			  page := self
				          queryPageForEntries: command execute
				          limit: (self limitFromQueryRequest: queryRequest)
				          offset: (self offsetFromQueryRequest: queryRequest).
			  self
				  successResultText:
				  (self successSummaryForQueryRequest: queryRequest page: page)
				  data:
				  (self queryResultDataForQueryRequest: queryRequest page: page)
				  warnings: (self warningsForQueryRequest: queryRequest) ]
		  onError: [ :error :ignored |
			  self
				  errorResultForQueryError: error
				  requestedContext:
				  (self requestedContextForErrorFromRequest: request) ]
]

{ #category : 'private - template' }
MCPToolSearch >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - template' }
MCPToolSearch >> failureMessageForScope: scopeSummary error: anError [

	self subclassResponsibility
]

{ #category : 'private - filtering' }
MCPToolSearch >> fieldFilters: fieldFilters matchUsing: fieldTextsBlock mode: filterMode caseSensitive: caseSensitive [

	fieldFilters keysAndValuesDo: [ :fieldName :pattern |
			| matcher |
			matcher := self
				           matcherForPattern: pattern
				           mode: filterMode
				           caseSensitive: caseSensitive.
			((fieldTextsBlock value: fieldName) anySatisfy: [ :each |
				 matcher value: each ]) ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'private - request' }
MCPToolSearch >> fieldFiltersFromRequest: request fieldNames: fieldNames [

	| filters |
	filters := Dictionary new.
	fieldNames do: [ :fieldName |
			(request hasArgumentNamed: fieldName) ifTrue: [
					| value |
					value := request stringArgumentNamed: fieldName.
					value ifNil: [
							MCPInvalidToolInput
								signalMissingRequiredArgumentNamed: fieldName
								forTool: self ].
					value := value trimBoth.
					value isEmpty ifTrue: [
							MCPInvalidToolInput
								signalMissingRequiredArgumentNamed: fieldName
								forTool: self ].
					filters at: fieldName put: value ] ].
	^ filters
]

{ #category : 'private - request' }
MCPToolSearch >> filterModeFromRequest: request [

	^ request
		  stringArgumentNamed: 'filterMode'
		  default: self defaultFilterMode
]

{ #category : 'private - schema' }
MCPToolSearch >> filterModeSchemaPropertyWithDescription: modeDescription values: modeValues [

	^ self
		  stringEnumSchemaPropertyNamed: 'filterMode'
		  description: modeDescription
		  values: modeValues
		  default: self defaultFilterMode
]

{ #category : 'private - request' }
MCPToolSearch >> filterPatternFromRequest: request [

	(request hasArgumentNamed: 'filter') ifFalse: [ ^ nil ].
	^ (request argumentNamed: 'filter' ifAbsent: [ nil ]) ifNotNil: [
		  :value | value asString trimBoth ]
]

{ #category : 'private - schema' }
MCPToolSearch >> filterSchemaPropertyWithDescription: filterDescription [

	^ self
		  schemaPropertyNamed: 'filter'
		  type: 'string'
		  description: filterDescription
]

{ #category : 'private - schema' }
MCPToolSearch >> includeSourceSchemaPropertyWithDescription: includeSourceDescription [

	^ self
		  booleanSchemaPropertyNamed: 'includeSource'
		  description: includeSourceDescription
		  default: false
]

{ #category : 'private - template' }
MCPToolSearch >> limitFromQueryRequest: queryRequest [

	^ queryRequest limit
]

{ #category : 'private - filtering' }
MCPToolSearch >> matcherForPattern: aPattern mode: aMode caseSensitive: aBoolean [

	| normalizedPattern regex |
	aPattern ifNil: [ ^ [ :candidate | true ] ].
	aMode = 'regex' ifTrue: [
		regex := aBoolean
			         ifTrue: [ aPattern asRegex ]
			         ifFalse: [ aPattern asRegexIgnoringCase ].
		^ [ :candidate |
		  regex search:
			  (candidate ifNil: [ '' ] ifNotNil: [ candidate asString ]) ] ].
	normalizedPattern := self
		                     normalizeFilterString: aPattern
		                     caseSensitive: aBoolean.
	aMode = 'substring' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
			  includesSubstring: normalizedPattern ] ].
	aMode = 'prefix' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
			  beginsWith: normalizedPattern ] ].
	aMode = 'exact' ifTrue: [
		^ [ :candidate |
		  (self normalizeFilterString: candidate caseSensitive: aBoolean)
		  = normalizedPattern ] ].
	Error signal: 'Unsupported filter mode: ' , aMode
]

{ #category : 'private - schema' }
MCPToolSearch >> minimalPagedQueryOutputSchemaForEntriesPropertyNamed: entriesPropertyName entriesDescription: entriesDescription entrySchema: entrySchema itemNounPhrase: itemNounPhrase [

	| entriesProperty |
	entriesProperty := self
		                   schemaPropertyNamed: entriesPropertyName
		                   type: 'array'
		                   description: entriesDescription.
	entriesProperty items: entrySchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  entriesProperty.
				  (self
					   integerSchemaPropertyNamed: 'nextOffset'
					   description:
					   'Zero-based offset for the next page. Omitted when this is the final page.') }
		  required: { entriesPropertyName }
]

{ #category : 'private - filtering' }
MCPToolSearch >> normalizeFilterString: aValue caseSensitive: aBoolean [

	| normalized |
	normalized := aValue
		              ifNil: [ '' ]
		              ifNotNil: [ :value | value asString ].
	^ aBoolean
		  ifTrue: [ normalized ]
		  ifFalse: [ normalized asLowercase ]
]

{ #category : 'private - template' }
MCPToolSearch >> offsetFromQueryRequest: queryRequest [

	^ queryRequest offset
]

{ #category : 'private - schema' }
MCPToolSearch >> packageQueryScopeInputProperties [

	^ {
		  self packageScopeProjectNamesProperty.
		  self packageScopePackageNamesProperty }
]

{ #category : 'private - schema' }
MCPToolSearch >> packageScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description: 'Exact packages.'
		  itemDescription: 'Package name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> packageScopeProjectNamesProperty [

	^ self
		  stringArraySchemaNamed: 'projectNames'
		  description: 'Projects whose packages are included.'
		  itemDescription: 'Project name.'
]

{ #category : 'private - results' }
MCPToolSearch >> packageScopeSummaryForProjectNames: projectNames packageNames: packageNames [

	| labels |
	labels := OrderedCollection new.
	projectNames notEmpty ifTrue: [
		self addScopeLabel: 'projects' to: labels ].
	packageNames notEmpty ifTrue: [
		self addScopeLabel: 'packages' to: labels ].
	^ self scopeSummaryFromLabels: labels
]

{ #category : 'private - schema' }
MCPToolSearch >> paginationInputPropertiesWithLimitDescription: limitDescription [

	^ {
		  (self
			   integerSchemaPropertyNamed: 'limit'
			   description: limitDescription
			   default: self defaultPageLimit).
		  (self
			   integerSchemaPropertyNamed: 'offset'
			   description:
			   'Zero-based pagination offset applied after filtering.'
			   default: 0) }
]

{ #category : 'private - request' }
MCPToolSearch >> parsedRequestFromToolRequest: request [

	^ self searchRequestFromToolRequest: request
]

{ #category : 'private - template' }
MCPToolSearch >> queryEntriesForQueryRequest: queryRequest [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolSearch >> queryInputSchemaWithProperties: inputProperties [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: inputProperties;
		  required: #(  );
		  yourself
]

{ #category : 'private - pagination' }
MCPToolSearch >> queryPageForEntries: entries limit: limit offset: offset [

	^ MCPPaginationResult fromEntries: entries limit: limit offset: offset
]

{ #category : 'private - template' }
MCPToolSearch >> queryResultDataForQueryRequest: queryRequest page: page [

	self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPToolSearch >> queryResultDataFrom: baseData page: page entriesKey: entriesKey [

	^ page asDictionaryWithEntriesKey: entriesKey
]

{ #category : 'private - results' }
MCPToolSearch >> requestedContextForErrorFromRequest: request [

	^ [ self requestedContextFromRequest: request ]
		  on: Error
		  do: [ :ignored | Dictionary new ]
]

{ #category : 'private - template' }
MCPToolSearch >> requestedContextFromRequest: request [

	^ self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolSearch >> scopeQueryFailureMessageFor: resultKind scope: scopeSummary error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to query ';
			  nextPutAll: resultKind;
			  nextPutAll: ' [scope=';
			  nextPutAll: scopeSummary;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
]

{ #category : 'private - results' }
MCPToolSearch >> scopeQuerySuccessSummaryFor: resultKind scope: scopeSummary page: page [

	^ String streamContents: [ :stream |
			  stream
				  print: page returnedCount;
				  space;
				  nextPutAll: resultKind;
				  nextPutAll: ' found [scope=';
				  nextPutAll: scopeSummary;
				  nextPutAll: ']'.
			  page nextOffset ifNotNil: [ :offset |
					  stream
						  nextPutAll: ' More available at offset ';
						  print: offset ].
			  stream nextPut: $. ]
]

{ #category : 'private - results' }
MCPToolSearch >> scopeSummaryFromLabels: labels [

	labels ifEmpty: [ ^ 'image' ].
	^ String streamContents: [ :stream |
		  labels doWithIndex: [ :each :index |
			  index > 1 ifTrue: [ stream nextPut: $+ ].
			  stream nextPutAll: each ] ]
]

{ #category : 'private - template' }
MCPToolSearch >> searchRequestFromToolRequest: request [

	self subclassResponsibility
]

{ #category : 'private - template' }
MCPToolSearch >> successSummaryForQueryRequest: queryRequest page: page [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolSearch >> supportedFilterModes [

	^ self basicFilterModes
]

{ #category : 'private - results' }
MCPToolSearch >> warningsForQueryRequest: queryRequest [

	^ queryRequest warnings
]
