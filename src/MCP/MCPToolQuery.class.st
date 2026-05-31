"
Shared base class for query-style MCP tools. It centralizes paged result shaping and query-specific error handling.
"
Class {
	#name : 'MCPToolQuery',
	#superclass : 'MCPTool',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'testing' }
MCPToolQuery class >> isAbstract [

	^ self = MCPToolQuery
]

{ #category : 'private - results' }
MCPToolQuery >> addScopeLabel: aString to: labels [

	(labels includes: aString) ifFalse: [ labels add: aString ]
]

{ #category : 'private - schema' }
MCPToolQuery >> baseFilteringInputPropertiesWithFilterDescription: filterDescription filterTargetsDescription: targetsDescription filterModeDescription: modeDescription filterModeValues: modeValues [

	^ {
		  (self filterSchemaPropertyWithDescription: filterDescription).
		  (self filterTargetsSchemaPropertyWithDescription:
			   targetsDescription).
		  (self
			   filterModeSchemaPropertyWithDescription: modeDescription
			   values: modeValues) }
]

{ #category : 'private - schema' }
MCPToolQuery >> basicFilterModes [

	^ #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'private - schema' }
MCPToolQuery >> caseSensitiveSchemaPropertyWithDescription: caseSensitiveDescription [

	^ self
		  booleanSchemaPropertyNamed: 'caseSensitive'
		  description: caseSensitiveDescription
		  default: true
]

{ #category : 'private - results' }
MCPToolQuery >> classAndMethodScopeSummaryForScopeQuery: scopeQuery [

	^ self classAndMethodScopeSummaryFromAssociations: {
			  ('packages' -> scopeQuery packageNames).
			  ('classes' -> scopeQuery classNames).
			  ('hierarchy' -> scopeQuery hierarchyClassNames).
			  ('subclasses' -> scopeQuery subclassClassNames).
			  ('parents' -> scopeQuery parentClassNames) }
]

{ #category : 'private - results' }
MCPToolQuery >> classAndMethodScopeSummaryFromAssociations: scopeAssociations [

	| labels |
	labels := OrderedCollection new.
	scopeAssociations do: [ :eachAssociation |
		eachAssociation value notEmpty ifTrue: [
			self addScopeLabel: eachAssociation key to: labels ] ].
	^ self scopeSummaryFromLabels: labels
]

{ #category : 'private - results' }
MCPToolQuery >> classAndMethodScopeSummaryFromRequest: request [

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
MCPToolQuery >> classQueryScopeInputProperties [

	^ {
		  self classScopePackageNamesProperty.
		  self classScopeClassNamesProperty.
		  self classScopeHierarchyClassNamesProperty.
		  self classScopeSubclassClassNamesProperty.
		  self classScopeParentClassNamesProperty }
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopeClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'classNames'
		  description:
		  'Class scope: include these exact classes. Omit all class scope properties to search all classes.'
		  itemDescription: 'A class name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopeHierarchyClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description:
		  'Class scope: include each named class, its superclasses, and its subclasses. Omit all class scope properties to search all classes.'
		  itemDescription: 'A hierarchy root class name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Class scope: include classes defined in these packages. Omit all class scope properties to search all classes.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopeParentClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'parentClassNames'
		  description:
		  'Class scope: include superclasses of these classes. The named classes are excluded unless classNames also includes them.'
		  itemDescription: 'A class name whose superclasses are included.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopeSubclassClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'subclassClassNames'
		  description:
		  'Class scope: include subclasses of these classes. The named classes are excluded unless classNames also includes them.'
		  itemDescription: 'A class name whose subclasses are included.'
]

{ #category : 'private - execution' }
MCPToolQuery >> commandForRequest: queryRequest [

	^ MCPQueryToolCommand tool: self request: queryRequest
]

{ #category : 'private - request' }
MCPToolQuery >> defaultFilterMode [

	^ 'substring'
]

{ #category : 'private - request' }
MCPToolQuery >> defaultFilterTargets [

	self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolQuery >> errorResultForQueryError: anError requestedContext: requestedContext [

	| details normalizedContext |
	normalizedContext := requestedContext ifNil: [ Dictionary new ].
	(anError isKindOf: MCPCommandError) ifTrue: [
		details := anError structuredDetails copy.
		normalizedContext associationsDo: [ :each |
			each value ifNotNil: [ details at: each key put: each value ] ].
		^ self errorResultText: anError messageText details: details ].
	details := {
		           (#errorClass -> anError class name).
		           (#message -> anError messageText) } asDictionary.
	normalizedContext associationsDo: [ :each |
		each value ifNotNil: [ details at: each key put: each value ] ].
	^ self
		  errorResultText: (self
				   failureMessageForRequestedContext: normalizedContext
				   error: anError)
		  details: details
]

{ #category : 'executing' }
MCPToolQuery >> executeWithRequest: request [

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
MCPToolQuery >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - template' }
MCPToolQuery >> failureMessageForScope: scopeSummary error: anError [

	self subclassResponsibility
]

{ #category : 'private - filtering' }
MCPToolQuery >> fieldFilters: fieldFilters matchUsing: fieldTextsBlock mode: filterMode caseSensitive: caseSensitive [

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
MCPToolQuery >> fieldFiltersFromRequest: request fieldNames: fieldNames [

	| filters |
	filters := Dictionary new.
	fieldNames do: [ :fieldName |
			(request hasArgumentNamed: fieldName) ifTrue: [
					| value |
					value := request stringArgumentNamed: fieldName.
					(value isNil or: [ value trimBoth isEmpty ]) ifTrue: [
							MCPInvalidToolInput
								signalMissingRequiredArgumentNamed: fieldName
								forTool: self ].
					filters at: fieldName put: value trimBoth ] ].
	^ filters
]

{ #category : 'private - request' }
MCPToolQuery >> filterModeFromRequest: request [

	^ request
		  stringArgumentNamed: 'filterMode'
		  default: self defaultFilterMode
]

{ #category : 'private - schema' }
MCPToolQuery >> filterModeSchemaPropertyWithDescription: modeDescription values: modeValues [

	^ self
		  stringEnumSchemaPropertyNamed: 'filterMode'
		  description: modeDescription
		  values: modeValues
		  default: self defaultFilterMode
]

{ #category : 'private - request' }
MCPToolQuery >> filterPatternFromRequest: request [

	(request hasArgumentNamed: 'filter') ifFalse: [ ^ nil ].
	^ (request argumentNamed: 'filter' ifAbsent: [ nil ])
		  ifNil: [ nil ]
		  ifNotNil: [ :value | value asString trimBoth ]
]

{ #category : 'private - schema' }
MCPToolQuery >> filterSchemaPropertyWithDescription: filterDescription [

	^ self
		  schemaPropertyNamed: 'filter'
		  type: 'string'
		  description: filterDescription
]

{ #category : 'private - request' }
MCPToolQuery >> filterTargetsFromRequest: request [

	| filterTargets |
	filterTargets := request
		                 uniqueStringCollectionArgumentNamed:
		                 'filterTargets'
		                 default: self defaultFilterTargets.
	filterTargets ifEmpty: [
		Error signal: 'filterTargets must contain at least one target.' ].
	^ filterTargets
]

{ #category : 'private - schema' }
MCPToolQuery >> filterTargetsSchemaPropertyWithDescription: targetsDescription [

	^ self
		  stringEnumArraySchemaNamed: 'filterTargets'
		  description: targetsDescription
		  itemDescription: 'A filter target.'
		  values: self supportedFilterTargets
		  default: self defaultFilterTargets
]

{ #category : 'private - schema' }
MCPToolQuery >> includeSourceSchemaPropertyWithDescription: includeSourceDescription [

	^ self
		  booleanSchemaPropertyNamed: 'includeSource'
		  description: includeSourceDescription
		  default: false
]

{ #category : 'private - template' }
MCPToolQuery >> limitFromQueryRequest: queryRequest [

	^ queryRequest limit
]

{ #category : 'private - filtering' }
MCPToolQuery >> matcherForPattern: aPattern mode: aMode caseSensitive: aBoolean [

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
MCPToolQuery >> minimalPagedQueryOutputSchemaForEntriesPropertyNamed: entriesPropertyName entriesDescription: entriesDescription entrySchema: entrySchema itemNounPhrase: itemNounPhrase [

	| entriesProperty |
	entriesProperty := self
		                   schemaPropertyNamed: entriesPropertyName
		                   type: 'array'
		                   description: entriesDescription.
	entriesProperty items: entrySchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description: 'The total number of matching ' , itemNounPhrase
						   , ' before pagination.').
				  entriesProperty }
		  required: {
				  'totalCount'.
				  entriesPropertyName }
]

{ #category : 'private - filtering' }
MCPToolQuery >> normalizeFilterString: aValue caseSensitive: aBoolean [

	| normalized |
	normalized := aValue
		              ifNil: [ '' ]
		              ifNotNil: [ :value | value asString ].
	^ aBoolean
		  ifTrue: [ normalized ]
		  ifFalse: [ normalized asLowercase ]
]

{ #category : 'private - template' }
MCPToolQuery >> offsetFromQueryRequest: queryRequest [

	^ queryRequest offset
]

{ #category : 'private - schema' }
MCPToolQuery >> packageQueryScopeInputProperties [

	^ {
		  self packageScopeProjectNamesProperty.
		  self packageScopePackageNamesProperty }
]

{ #category : 'private - schema' }
MCPToolQuery >> packageScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Package scope: exact package names to include. Omit all package scope properties to search all packages. Combine with projectNames to union scopes.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> packageScopeProjectNamesProperty [

	^ self
		  stringArraySchemaNamed: 'projectNames'
		  description:
		  'Package scope: project names whose packages are included. Omit all package scope properties to search all packages. Combine with packageNames to union scopes.'
		  itemDescription: 'A project name.'
]

{ #category : 'private - results' }
MCPToolQuery >> packageScopeSummaryForProjectNames: projectNames packageNames: packageNames [

	| labels |
	labels := OrderedCollection new.
	projectNames notEmpty ifTrue: [
		self addScopeLabel: 'projects' to: labels ].
	packageNames notEmpty ifTrue: [
		self addScopeLabel: 'packages' to: labels ].
	^ self scopeSummaryFromLabels: labels
]

{ #category : 'private - schema' }
MCPToolQuery >> paginationInputPropertiesWithLimitDescription: limitDescription [

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

{ #category : 'private - request' }
MCPToolQuery >> parsedRequestFromToolRequest: request [

	^ self queryRequestFromToolRequest: request
]

{ #category : 'private - template' }
MCPToolQuery >> queryEntriesForQueryRequest: queryRequest [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolQuery >> queryInputSchemaWithProperties: inputProperties [

	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: inputProperties;
		  required: #(  );
		  yourself
]

{ #category : 'private - pagination' }
MCPToolQuery >> queryPageForEntries: entries limit: limit offset: offset [

	| endIndex pagedEntries startIndex totalCount truncated |
	totalCount := entries size.
	startIndex := offset + 1.
	pagedEntries := (startIndex > totalCount or: [ limit = 0 ])
		                ifTrue: [ #(  ) ]
		                ifFalse: [
			                endIndex := totalCount min: offset + limit.
			                (entries copyFrom: startIndex to: endIndex) asArray ].
	truncated := offset + pagedEntries size < totalCount.
	^ {
		  (#entries -> pagedEntries).
		  (#returnedCount -> pagedEntries size).
		  (#totalCount -> totalCount).
		  (#offset -> offset).
		  (#limit -> limit).
		  (#truncated -> truncated) } asDictionary
]

{ #category : 'private - template' }
MCPToolQuery >> queryRequestFromToolRequest: request [

	self subclassResponsibility
]

{ #category : 'private - template' }
MCPToolQuery >> queryResultDataForQueryRequest: queryRequest page: page [

	self subclassResponsibility
]

{ #category : 'private - pagination' }
MCPToolQuery >> queryResultDataFrom: baseData page: page entriesKey: entriesKey [

	^ {
		  (#totalCount -> (page at: #totalCount)).
		  (entriesKey -> (page at: #entries)) } asDictionary
]

{ #category : 'private - results' }
MCPToolQuery >> requestedContextForErrorFromRequest: request [

	^ [ self requestedContextFromRequest: request ]
		  on: Error
		  do: [ :ignored | Dictionary new ]
]

{ #category : 'private - template' }
MCPToolQuery >> requestedContextFromRequest: request [

	^ self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolQuery >> scopeQueryFailureMessageFor: resultKind scope: scopeSummary error: anError [

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
MCPToolQuery >> scopeQuerySuccessSummaryFor: resultKind scope: scopeSummary page: page [

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
MCPToolQuery >> scopeSummaryFromLabels: labels [

	labels ifEmpty: [ ^ 'image' ].
	^ String streamContents: [ :stream |
		  labels doWithIndex: [ :each :index |
			  index > 1 ifTrue: [ stream nextPut: $+ ].
			  stream nextPutAll: each ] ]
]

{ #category : 'private - template' }
MCPToolQuery >> successSummaryForQueryRequest: queryRequest page: page [

	self subclassResponsibility
]

{ #category : 'private - schema' }
MCPToolQuery >> supportedFilterModes [

	^ self basicFilterModes
]

{ #category : 'private - request' }
MCPToolQuery >> supportedFilterTargets [

	self subclassResponsibility
]

{ #category : 'private - results' }
MCPToolQuery >> warningsForQueryRequest: queryRequest [

	(queryRequest respondsTo: #scopeQuery) ifFalse: [ ^ #(  ) ].
	queryRequest scopeQuery ifNil: [ ^ #(  ) ].
	(queryRequest scopeQuery respondsTo: #warnings) ifFalse: [ ^ #(  ) ].
	^ queryRequest scopeQuery warnings
]
