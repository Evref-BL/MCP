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
		  'Class scope: exact class names to include. Omit all class scope properties to search all classes. Combine with other class scope properties to union scopes.'
		  itemDescription: 'A class name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopeHierarchyClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description:
		  'Class scope: class names whose superclasses, subclasses, and the named classes are included. Omit all class scope properties to search all classes. Combine with other class scope properties to union scopes.'
		  itemDescription: 'A hierarchy root class name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Class scope: package names whose defined classes are included. Omit all class scope properties to search all classes. Combine with other class scope properties to union scopes.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopeParentClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'parentClassNames'
		  description:
		  'Class scope: class names whose superclasses are included. The named classes are excluded unless classNames also includes them. Combine with other class scope properties to union scopes.'
		  itemDescription: 'A class name whose superclasses are included.'
]

{ #category : 'private - schema' }
MCPToolQuery >> classScopeSubclassClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'subclassClassNames'
		  description:
		  'Class scope: class names whose subclasses are included. The named classes are excluded unless classNames also includes them. Combine with other class scope properties to union scopes.'
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
				  (self queryResultDataForQueryRequest: queryRequest page: page) ]
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

{ #category : 'private - schema' }
MCPToolQuery >> fieldFilteringInputPropertiesWithFilterDescription: filterDescription filterTargetsDescription: targetsDescription filterModeDescription: modeDescription limitDescription: limitDescription [

	^ (self
		   baseFilteringInputPropertiesWithFilterDescription:
		   filterDescription
		   filterTargetsDescription: targetsDescription
		   filterModeDescription: modeDescription
		   filterModeValues: self basicFilterModes) , {
		  self wherePredicateSchemaProperty.
		  (self caseSensitiveSchemaPropertyWithDescription:
			   'Whether filter matching is case-sensitive.') }
	  ,
	  (self paginationInputPropertiesWithLimitDescription:
		   limitDescription)
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
MCPToolQuery >> methodFilteringInputPropertiesWithFilterDescription: filterDescription includeSourceDescription: includeSourceDescription limitDescription: limitDescription [

	^ (self
		   baseFilteringInputPropertiesWithFilterDescription:
		   filterDescription
		   filterTargetsDescription:
		   'Optional method-entry fields matched by filter for field filtering. Ignored by reference lookup modes: selectorReference, classReference, and variableReference.'
		   filterModeDescription:
		   'How the filter is matched or interpreted. Reference modes on find-methods are selectorReference for senders, classReference for class references, and variableReference for variable references.'
		   filterModeValues: self supportedFilterModes) , {
		  self wherePredicateSchemaProperty.
		  (self caseSensitiveSchemaPropertyWithDescription:
			   'Whether filter matching is case-sensitive. Reference lookup modes ignore this option.').
		  (self includeSourceSchemaPropertyWithDescription:
			   includeSourceDescription) }
	  ,
	  (self paginationInputPropertiesWithLimitDescription:
		   limitDescription)
]

{ #category : 'private - schema' }
MCPToolQuery >> methodQueryScopeInputProperties [

	^ {
		  self methodSideSchemaProperty.
		  self methodScopePackageNamesProperty.
		  self methodScopeClassNamesProperty.
		  self methodScopeHierarchyClassNamesProperty.
		  self methodScopeSubclassClassNamesProperty.
		  self methodScopeParentClassNamesProperty }
]

{ #category : 'private - schema' }
MCPToolQuery >> methodScopeClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'classNames'
		  description:
		  'Method scope. Exact class names whose methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A class name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> methodScopeHierarchyClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'hierarchyClassNames'
		  description:
		  'Method scope. Class names whose superclasses, subclasses, and own methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A hierarchy root class name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> methodScopePackageNamesProperty [

	^ self
		  stringArraySchemaNamed: 'packageNames'
		  description:
		  'Method scope. Package names whose defined methods and extension methods are included. Omit all method scope properties to search all methods. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A package name.'
]

{ #category : 'private - schema' }
MCPToolQuery >> methodScopeParentClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'parentClassNames'
		  description:
		  'Method scope. Class names whose superclass methods are included. The named classes are excluded unless classNames also includes them. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A class name whose superclasses are included.'
]

{ #category : 'private - schema' }
MCPToolQuery >> methodScopeSubclassClassNamesProperty [

	^ self
		  stringArraySchemaNamed: 'subclassClassNames'
		  description:
		  'Method scope. Class names whose subclass methods are included. The named classes are excluded unless classNames also includes them. Combine with other method scope properties to union scopes.'
		  itemDescription: 'A class name whose subclasses are included.'
]

{ #category : 'private - schema' }
MCPToolQuery >> methodSideSchemaProperty [

	^ self
		  stringEnumSchemaPropertyNamed: 'side'
		  description:
		  'Which method side to search. instance searches instance-side methods, class searches class-side methods, and both searches both sides.'
		  values: #( 'instance' 'class' 'both' )
		  default: 'both'
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

{ #category : 'private - where' }
MCPToolQuery >> newWhereContext [

	^ Dictionary new
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

{ #category : 'private - schema' }
MCPToolQuery >> queryInputSchemaWithProperties: inputProperties allOf: conditionSchemas [

	| schema |
	schema := self queryInputSchemaWithProperties: inputProperties.
	conditionSchemas ifNotEmpty: [ schema allOf: conditionSchemas ].
	^ schema
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

{ #category : 'private - where' }
MCPToolQuery >> whereClassBindingNamed: className context: context [

	| bindings |
	bindings := context
		            at: #classBindings
		            ifAbsentPut: [ Dictionary new ].
	^ bindings at: className ifAbsentPut: [
		  | binding |
		  binding := Smalltalk globals
			             associationAt: className asSymbol
			             ifAbsent: [ nil ].
		  (binding notNil and: [ binding value isBehavior ])
			  ifTrue: [ binding ]
			  ifFalse: [ nil ] ]
]

{ #category : 'private - where' }
MCPToolQuery >> whereClassFieldTextsForField: fieldName evaluation: evaluation [

	| key |
	(#( 'class' 'className' ) includes: fieldName) ifTrue: [
		key := #className ].
	(#( 'package' 'packageName' ) includes: fieldName) ifTrue: [
		key := #packageName ].
	fieldName = 'tag' ifTrue: [ key := #tag ].
	(#( 'instanceSlot' 'instanceSlotName' 'instanceSlotNames' )
		 includes: fieldName) ifTrue: [ key := #instanceSlotNames ].
	(#( 'classSlot' 'classSlotName' 'classSlotNames' ) includes:
		 fieldName) ifTrue: [ key := #classSlotNames ].
	key ifNil: [
		Error signal: 'Unsupported class where field: ' , fieldName ].
	^ self whereTextArrayFrom:
		  (self whereEntryValueAt: key in: evaluation entry)
]

{ #category : 'private - where' }
MCPToolQuery >> whereCompiledMethodForReferenceSpec: methodReferenceSpec context: context [

	| cache |
	cache := context
		         at: #methodReferenceCache
		         ifAbsentPut: [ Dictionary new ].
	^ cache
		  at: methodReferenceSpec cacheKey
		  ifAbsentPut: [ methodReferenceSpec compiledMethod ]
]

{ #category : 'private - where' }
MCPToolQuery >> whereDefaultFilterTargetsForEntityKind: entityKind [

	entityKind = #package ifTrue: [ ^ #( 'package' ) ].
	entityKind = #class ifTrue: [ ^ #( 'class' ) ].
	entityKind = #method ifTrue: [ ^ #( 'selector' ) ].
	Error signal: 'Unsupported where entity kind: ' , entityKind asString
]

{ #category : 'private - where' }
MCPToolQuery >> whereEntryForEntityKind: entityKind object: object context: context [

	| projectNames |
	entityKind = #package ifTrue: [
		projectNames := (self wherePackageProjectNamesMapIn: context)
			                at: object name asString
			                ifAbsent: [ #(  ) ].
		^ (MCPPackageInfo fromPackage: object projectNames: projectNames)
			  asQueryDictionary ].
	entityKind = #class ifTrue: [
		^ (MCPClassInfo fromClass: object) asQueryDictionary ].
	entityKind = #method ifTrue: [
		^ (MCPCompiledMethodInfo fromMethod: object)
			  asDictionaryIncludingSource: false ].
	Error signal: 'Unsupported where entity kind: ' , entityKind asString
]

{ #category : 'private - where' }
MCPToolQuery >> whereEntryValueAt: key in: entry [

	^ entry at: key ifAbsent: [ nil ]
]

{ #category : 'private - schema' }
MCPToolQuery >> whereEquivalentToSchemaProperty [

	^ MCPStructureProperties new
		  name: 'equivalentTo';
		  type: 'object';
		  description:
			  'Method reference used by method predicates to match methods with an equivalent AST.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'className'
					   type: 'string'
					   description: 'The class that defines the referenced method.').
				  (self
					   schemaPropertyNamed: 'selector'
					   type: 'string'
					   description: 'The referenced method selector.').
				  (self
					   booleanSchemaPropertyNamed: 'classSide'
					   description:
						   'Whether the referenced method is on the class side.'
					   default: false) };
		  required: #( 'className' 'selector' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - where' }
MCPToolQuery >> whereEquivalentToSpec: whereSpec matchesEvaluation: evaluation [

	evaluation entityKind = #method ifFalse: [
		MCPCommandError
			signalErrorCode: #WhereEquivalentToRequiresMethodEntity
			message:
			'equivalentTo where predicates can only match method entries.'
			details: {
					(#entityKind -> evaluation entityKind asString).
					(#equivalentTo -> whereSpec methodReferenceSpec asDictionary) }
					asDictionary ].
	^ evaluation object equivalentTo: (self
			   whereCompiledMethodForReferenceSpec:
			   whereSpec methodReferenceSpec
			   context: evaluation context)
]

{ #category : 'private - where' }
MCPToolQuery >> whereEvaluationForEntityKind: entityKind entry: entry object: object context: context [

	^ MCPWhereEvaluation new
		  tool: self;
		  entityKind: entityKind;
		  entry: entry;
		  object: object;
		  context: context;
		  yourself
]

{ #category : 'private - where' }
MCPToolQuery >> whereFieldSpec: whereSpec matchesEvaluation: evaluation [

	| matcher texts |
	matcher := self
		           matcherForPattern: whereSpec value
		           mode: whereSpec mode
		           caseSensitive: whereSpec caseSensitive.
	texts := self
		         whereFieldTextsForField: whereSpec field
		         evaluation: evaluation.
	^ texts anySatisfy: [ :each | matcher value: each ]
]

{ #category : 'private - where' }
MCPToolQuery >> whereFieldTextsForField: fieldName evaluation: evaluation [

	evaluation entityKind = #package ifTrue: [
		^ self
			  wherePackageFieldTextsForField: fieldName
			  evaluation: evaluation ].
	evaluation entityKind = #class ifTrue: [
		^ self
			  whereClassFieldTextsForField: fieldName
			  evaluation: evaluation ].
	evaluation entityKind = #method ifTrue: [
		^ self
			  whereMethodFieldTextsForField: fieldName
			  evaluation: evaluation ].
	Error signal:
		'Unsupported where entity kind: ' , evaluation entityKind asString
]

{ #category : 'private - where' }
MCPToolQuery >> whereFilterSpec: whereSpec matchesEvaluation: evaluation [

	| matcher targets |
	((self whereReferenceFilterModes includes: whereSpec mode) and: [
		 evaluation entityKind ~= #method ]) ifTrue: [
		Error signal:
			'Reference where filter modes can only match method predicates.' ].
	(self whereReferenceFilterModes includes: whereSpec mode) ifTrue: [
		^ self
			  whereMethod: evaluation object
			  matchesReferenceFilter: whereSpec value
			  mode: whereSpec mode
			  context: evaluation context ].
	targets := whereSpec filterTargets ifNil: [
		           self whereDefaultFilterTargetsForEntityKind:
			           evaluation entityKind ].
	targets ifEmpty: [
		Error signal:
			'where filterTargets must contain at least one target.' ].
	matcher := self
		           matcherForPattern: whereSpec value
		           mode: whereSpec mode
		           caseSensitive: whereSpec caseSensitive.
	^ targets anySatisfy: [ :eachTarget |
		  (self whereFieldTextsForField: eachTarget evaluation: evaluation)
			  anySatisfy: [ :eachText | matcher value: eachText ] ]
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethod: aCompiledMethod matchesReferenceFilter: filterValue mode: filterMode context: context [

	filterMode = 'selectorReference' ifTrue: [
		^ self whereMethod: aCompiledMethod sendsSelectorNamed: filterValue ].
	filterMode = 'classReference' ifTrue: [
		^ self
			  whereMethod: aCompiledMethod
			  referencesClassNamed: filterValue
			  context: context ].
	filterMode = 'variableReference' ifTrue: [
		^ self
			  whereMethod: aCompiledMethod
			  referencesVariableNamed: filterValue ].
	Error signal:
		'Unsupported reference where filter mode: ' , filterMode
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethod: aCompiledMethod referencesAnyVariable: variables [

	^ variables anySatisfy: [ :eachVariable |
		  eachVariable isAccessedIn: aCompiledMethod ]
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethod: aCompiledMethod referencesClassNamed: className context: context [

	| classBinding |
	classBinding := self
		                whereClassBindingNamed: className
		                context: context.
	classBinding ifNil: [
		Error signal: 'There is no class named ' , className , '.' ].
	^ self
		  whereMethod: aCompiledMethod
		  referencesAnyVariable: { classBinding }
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethod: aCompiledMethod referencesVariableNamed: variableName [

	^ self whereMethod: aCompiledMethod referencesAnyVariable: (self
			   whereVariableBindingsNamed: variableName
			   forMethod: aCompiledMethod)
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethod: aCompiledMethod sendsSelectorNamed: selectorName [

	| selector specialSelectorIndex |
	selector := selectorName asSymbol.
	specialSelectorIndex := Smalltalk specialSelectorIndexOrNil: selector.
	^ aCompiledMethod
		  hasSelector: selector
		  specialSelectorIndex: specialSelectorIndex
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethodFieldTextsForField: fieldName evaluation: evaluation [

	| key |
	fieldName = 'selector' ifTrue: [ key := #selector ].
	(#( 'class' 'className' ) includes: fieldName) ifTrue: [
		key := #className ].
	(#( 'package' 'packageName' ) includes: fieldName) ifTrue: [
		key := #packageName ].
	fieldName = 'protocol' ifTrue: [ key := #protocol ].
	fieldName = 'classSide' ifTrue: [ key := #classSide ].
	fieldName = 'isExtension' ifTrue: [ key := #isExtension ].
	fieldName = 'source' ifTrue: [
		^ self whereTextArrayFrom:
			  (self whereSourceForMethod: evaluation object) ].
	key ifNil: [
		Error signal: 'Unsupported method where field: ' , fieldName ].
	^ self whereTextArrayFrom:
		  (self whereEntryValueAt: key in: evaluation entry)
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethodsForClass: aClass [

	| methods |
	methods := OrderedCollection new.
	aClass localMethods do: [ :eachMethod | methods add: eachMethod ].
	aClass classSide localMethods do: [ :eachMethod |
		methods add: eachMethod ].
	^ methods asArray
]

{ #category : 'private - where' }
MCPToolQuery >> whereMethodsForPackage: aPackage [

	| methods |
	methods := IdentitySet new.
	aPackage definedClasses do: [ :eachClass |
		eachClass localMethods do: [ :eachMethod | methods add: eachMethod ].
		eachClass classSide localMethods do: [ :eachMethod |
			methods add: eachMethod ] ].
	aPackage extensionMethods do: [ :eachMethod |
		methods add: eachMethod ].
	^ methods asArray
]

{ #category : 'private - schema' }
MCPToolQuery >> whereNestedPredicatePropertyNamed: propertyName description: propertyDescription [

	^ MCPStructureProperties new
		  name: propertyName;
		  type: 'object';
		  description: propertyDescription;
		  additionalProperties: true;
		  yourself
]

{ #category : 'private - schema' }
MCPToolQuery >> whereNestedPredicateSchema [

	^ MCPStructureProperties new
		  type: 'object';
		  description: 'A nested where predicate.';
		  additionalProperties: true;
		  yourself
]

{ #category : 'private - where' }
MCPToolQuery >> wherePackageFieldTextsForField: fieldName evaluation: evaluation [

	| key |
	(#( 'package' 'packageName' ) includes: fieldName) ifTrue: [
		key := #packageName ].
	(#( 'project' 'projectName' 'projectNames' ) includes: fieldName)
		ifTrue: [ key := #projectNames ].
	(#( 'tag' 'tagName' 'tagNames' ) includes: fieldName) ifTrue: [
		key := #tagNames ].
	key ifNil: [
		Error signal: 'Unsupported package where field: ' , fieldName ].
	^ self whereTextArrayFrom:
		  (self whereEntryValueAt: key in: evaluation entry)
]

{ #category : 'private - where' }
MCPToolQuery >> wherePackageForMethod: aCompiledMethod [

	^ aCompiledMethod package
		  ifNil: [ aCompiledMethod methodClass instanceSide package ]
		  ifNotNil: [ :package | package ]
]

{ #category : 'private - where' }
MCPToolQuery >> wherePackageProjectNamesMapIn: context [

	^ context
		  at: #packageProjectNames
		  ifAbsentPut: [ MCPPackageScopeQuery new packageProjectNamesMap ]
]

{ #category : 'private - schema' }
MCPToolQuery >> wherePredicateArrayPropertyNamed: propertyName description: propertyDescription [

	^ (self
		   schemaPropertyNamed: propertyName
		   type: 'array'
		   description: propertyDescription)
		  items: self whereNestedPredicateSchema;
		  yourself
]

{ #category : 'private - schema' }
MCPToolQuery >> wherePredicateFilterTargetsSchemaProperty [

	^ self
		  stringArraySchemaNamed: 'filterTargets'
		  description: 'Entry fields matched by a filter predicate.'
		  itemDescription: 'A filter target.'
]

{ #category : 'private - schema' }
MCPToolQuery >> wherePredicateProperties [

	^ {
		  (self
			   wherePredicateArrayPropertyNamed: 'all'
			   description: 'All nested predicates must match.').
		  (self
			   wherePredicateArrayPropertyNamed: 'any'
			   description: 'At least one nested predicate must match.').
		  (self
			   whereNestedPredicatePropertyNamed: 'not'
			   description: 'A nested predicate whose match is negated.').
		  (self
			   schemaPropertyNamed: 'field'
			   type: 'string'
			   description: 'Entry field name to match.').
		  (self
			   schemaPropertyNamed: 'value'
			   type: 'string'
			   description: 'Text matched by a field predicate.').
		  (self
			   stringEnumSchemaPropertyNamed: 'mode'
			   description: 'How a field predicate is matched.'
			   values: self basicFilterModes
			   default: self defaultFilterMode).
		  (self
			   schemaPropertyNamed: 'filter'
			   type: 'string'
			   description:
			   'Text matched by a filter predicate or reference lookup predicate.').
		  (self
			   stringEnumSchemaPropertyNamed: 'filterMode'
			   description:
			   'How a filter predicate is matched. Reference modes apply to method predicates.'
			   values: self supportedFilterModes
			   default: self defaultFilterMode).
		  self wherePredicateFilterTargetsSchemaProperty.
		  (self
			   booleanSchemaPropertyNamed: 'caseSensitive'
			   description: 'Whether text matching is case-sensitive.'
			   default: true).
		  self whereEquivalentToSchemaProperty.
		  (self
			   schemaPropertyNamed: 'exists'
			   type: 'string'
			   description:
			   'Relation name for which at least one related entity must match nested where.').
		  (self
			   schemaPropertyNamed: 'none'
			   type: 'string'
			   description:
			   'Relation name for which no related entity may match nested where.').
		  (self
			   whereNestedPredicatePropertyNamed: 'where'
			   description:
			   'Nested predicate used by exists and none relation predicates.') }
]

{ #category : 'private - schema' }
MCPToolQuery >> wherePredicateSchemaProperty [

	| whereProperty |
	whereProperty := self
		                 schemaPropertyNamed: 'where'
		                 type: 'object'
		                 description:
		                 'Optional recursive predicate applied before pagination. Use all, any, and not for boolean composition; field, value, and mode for field matching; filter, filterMode, and filterTargets for top-level-style filtering; equivalentTo for AST equivalence to a referenced method; exists or none with relation names and nested where for relation queries. Method predicates support selectorReference, classReference, variableReference, and equivalentTo.'.
	whereProperty
		properties: self wherePredicateProperties;
		additionalProperties: true.
	^ whereProperty
]

{ #category : 'private - where' }
MCPToolQuery >> whereReferenceFilterModes [

	^ #( 'selectorReference' 'classReference' 'variableReference' )
]

{ #category : 'private - where' }
MCPToolQuery >> whereRelatedEvaluationsForRelation: relationName evaluation: evaluation [

	| normalized objects relatedKind |
	normalized := relationName asString.
	evaluation entityKind = #package ifTrue: [
		(self whereRelation: normalized matchesAny: #( 'class' 'classes' ))
			ifTrue: [
				relatedKind := #class.
				objects := evaluation object definedClasses ].
		(self whereRelation: normalized matchesAny: #( 'method' 'methods' ))
			ifTrue: [
				relatedKind := #method.
				objects := self whereMethodsForPackage: evaluation object ] ].
	evaluation entityKind = #class ifTrue: [
		(self
			 whereRelation: normalized
			 matchesAny: #( 'package' 'packages' )) ifTrue: [
			relatedKind := #package.
			objects := { evaluation object package } ].
		(self whereRelation: normalized matchesAny: #( 'method' 'methods' ))
			ifTrue: [
				relatedKind := #method.
				objects := self whereMethodsForClass: evaluation object ].
		(self
			 whereRelation: normalized
			 matchesAny: #( 'subclass' 'subclasses' )) ifTrue: [
			relatedKind := #class.
			objects := evaluation object subclasses ].
		(self
			 whereRelation: normalized
			 matchesAny: #( 'superclass' 'superclasses' )) ifTrue: [
			relatedKind := #class.
			objects := evaluation object superclass
				           ifNil: [ #(  ) ]
				           ifNotNil: [ :superclass | { superclass } ] ] ].
	evaluation entityKind = #method ifTrue: [
		(self whereRelation: normalized matchesAny: #( 'class' 'classes' ))
			ifTrue: [
				relatedKind := #class.
				objects := { evaluation object methodClass instanceSide } ].
		(self
			 whereRelation: normalized
			 matchesAny: #( 'package' 'packages' )) ifTrue: [
			relatedKind := #package.
			objects := { (self wherePackageForMethod: evaluation object) } ] ].
	relatedKind ifNil: [
		Error signal:
			'Unsupported where relation ' , relationName asString , ' for '
			, evaluation entityKind asString , '.' ].
	^ objects
		  collect: [ :eachObject |
			  | entry |
			  entry := self
				           whereEntryForEntityKind: relatedKind
				           object: eachObject
				           context: evaluation context.
			  evaluation
				  forEntityKind: relatedKind
				  entry: entry
				  object: eachObject ]
		  as: Array
]

{ #category : 'private - where' }
MCPToolQuery >> whereRelation: relationName matchesAny: aliases [

	^ aliases includes: relationName
]

{ #category : 'private - where' }
MCPToolQuery >> whereRelationSpec: whereSpec matchesEvaluation: evaluation expectAny: expectAny [

	| relatedEvaluations matches |
	relatedEvaluations := self
		                      whereRelatedEvaluationsForRelation:
		                      whereSpec relation
		                      evaluation: evaluation.
	matches := relatedEvaluations anySatisfy: [ :eachEvaluation |
		           whereSpec whereSpec matchesEvaluation: eachEvaluation ].
	^ expectAny
		  ifTrue: [ matches ]
		  ifFalse: [ matches not ]
]

{ #category : 'private - where' }
MCPToolQuery >> whereSourceForMethod: aCompiledMethod [

	^ aCompiledMethod sourceCode ifNil: [ '' ]
]

{ #category : 'private - where' }
MCPToolQuery >> whereTextArrayFrom: value [

	| texts |
	value ifNil: [ ^ #(  ) ].
	value isString ifTrue: [ ^ { value } ].
	(value respondsTo: #do:) ifFalse: [ ^ { value asString } ].
	texts := OrderedCollection new.
	value do: [ :each | each ifNotNil: [ texts add: each asString ] ].
	^ texts asArray
]

{ #category : 'private - where' }
MCPToolQuery >> whereVariableBindingsNamed: variableName forMethod: aCompiledMethod [

	| behavior variables |
	behavior := aCompiledMethod methodClass.
	variables := IdentitySet new.
	behavior allSlots do: [ :eachSlot |
		eachSlot name asString = variableName ifTrue: [
			variables add: eachSlot ] ].
	(behavior bindingOf: variableName) ifNotNil: [ :binding |
		variables add: binding ].
	^ variables asArray
]
