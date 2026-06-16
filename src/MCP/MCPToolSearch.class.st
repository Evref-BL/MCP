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
		  description:
		  'Class scope: include these exact classes. Omit all class scope properties to search all classes.'
		  itemDescription: 'A class name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopeHierarchyClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description:
		  'Class scope: include each named class, its superclasses, and its subclasses. Omit all class scope properties to search all classes.'
		  itemDescription: 'A hierarchy root class name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Class scope: include classes defined in these packages. Omit all class scope properties to search all classes.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopeParentClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'parentClassNames'
		  description:
		  'Class scope: include superclasses of these classes. The named classes are excluded unless classNames also includes them.'
		  itemDescription: 'A class name whose superclasses are included.'
]

{ #category : 'private - schema' }
MCPToolSearch >> classScopeSubclassClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'subclassClassNames'
		  description:
		  'Class scope: include subclasses of these classes. The named classes are excluded unless classNames also includes them.'
		  itemDescription: 'A class name whose subclasses are included.'
]

{ #category : 'private - execution' }
MCPToolSearch >> commandForRequest: searchRequest [

	^ MCPSearchToolCommand tool: self request: searchRequest
]

{ #category : 'private - request' }
MCPToolSearch >> defaultFilterMode [

	^ 'substring'
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

	| dataProperties entriesProperty requiredProperties |
	entriesProperty := self
		                   schemaPropertyNamed: entriesPropertyName
		                   type: 'array'
		                   description: entriesDescription.
	entriesProperty items: entrySchema.
	dataProperties := (self
		                   paginationOutputSchemaPropertiesForItemNounPhrase:
		                   itemNounPhrase) copyWith: entriesProperty.
	requiredProperties := #( 'totalCount' 'returnedCount' 'omittedCount'
	                         'limit' 'offset' 'hasMore' ) copyWith:
		                      entriesPropertyName.
	^ self
		  standardOutputSchemaForDataProperties: dataProperties
		  required: requiredProperties
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
		  description:
		  'Package scope: exact package names to include. Omit all package scope properties to search all packages. Combine with projectNames to union scopes.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - schema' }
MCPToolSearch >> packageScopeProjectNamesProperty [

	^ self
		  stringArraySchemaNamed: 'projectNames'
		  description:
		  'Package scope: project names whose packages are included. Omit all package scope properties to search all packages. Combine with packageNames to union scopes.'
		  itemDescription: 'A project name.'
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
			   default: 100).
		  (self
			   integerSchemaPropertyNamed: 'offset'
			   description:
			   'Zero-based pagination offset applied after filtering.'
			   default: 0) }
]

{ #category : 'private - schema' }
MCPToolSearch >> paginationOutputSchemaPropertiesForItemNounPhrase: itemNounPhrase [

	^ {
		  (self
			   integerSchemaPropertyNamed: 'totalCount'
			   description:
			   'The total number matching ' , itemNounPhrase
			   , ' before pagination.').
		  (self
			   integerSchemaPropertyNamed: 'returnedCount'
			   description: 'Number of entries returned in this response.').
		  (self
			   integerSchemaPropertyNamed: 'omittedCount'
			   description:
			   'Number of matching entries omitted from this response.').
		  (self
			   integerSchemaPropertyNamed: 'limit'
			   description: 'Pagination limit used by this response.').
		  (self
			   integerSchemaPropertyNamed: 'offset'
			   description:
			   'Zero-based pagination offset used by this response.').
		  (self
			   booleanSchemaPropertyNamed: 'hasMore'
			   description:
			   'Whether another page is available after this response.') }
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

	| endIndex hasMore omittedCount pagedEntries startIndex totalCount |
	totalCount := entries size.
	startIndex := offset + 1.
	pagedEntries := (startIndex > totalCount or: [ limit = 0 ])
		                ifTrue: [ #(  ) ]
		                ifFalse: [
				                endIndex := totalCount min: offset + limit.
				                (entries copyFrom: startIndex to: endIndex)
					                asArray ].
	hasMore := offset + pagedEntries size < totalCount.
	omittedCount := totalCount - pagedEntries size.
	^ {
		  (#entries -> pagedEntries).
		  (#returnedCount -> pagedEntries size).
		  (#totalCount -> totalCount).
		  (#offset -> offset).
		  (#limit -> limit).
		  (#omittedCount -> omittedCount).
		  (#hasMore -> hasMore).
		  (#truncated -> hasMore) } asDictionary
]

{ #category : 'private - template' }
MCPToolSearch >> queryResultDataForQueryRequest: queryRequest page: page [

	self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPToolSearch >> queryResultDataFrom: baseData page: page entriesKey: entriesKey [

	| data |
	data := baseData
		        ifNil: [ Dictionary new ]
		        ifNotNil: [ baseData copy ].
	^ data
		  at: #totalCount put: (page at: #totalCount);
		  at: #returnedCount put: (page at: #returnedCount);
		  at: #omittedCount put: (page at: #omittedCount);
		  at: #limit put: (page at: #limit);
		  at: #offset put: (page at: #offset);
		  at: #hasMore put: (page at: #hasMore);
		  at: entriesKey put: (page at: #entries);
		  yourself
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
			  print: (page at: #returnedCount);
			  space;
			  nextPutAll: resultKind;
			  nextPutAll: ' found [scope=';
			  nextPutAll: scopeSummary;
			  nextPutAll: '] (';
			  print: (page at: #totalCount);
			  nextPutAll: ' matched'.
		  (page at: #truncated) ifTrue: [
			  stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
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
