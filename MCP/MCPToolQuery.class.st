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

{ #category : 'private - results' }
MCPToolQuery >> classAndMethodScopeSummaryForPackageNames: packageNames classNames: classNames hierarchyClassNames: hierarchyClassNames [

	| labels |
	labels := OrderedCollection new.
	packageNames notEmpty ifTrue: [
		self addScopeLabel: 'packages' to: labels ].
	classNames notEmpty ifTrue: [
		self addScopeLabel: 'classes' to: labels ].
	hierarchyClassNames notEmpty ifTrue: [
		self addScopeLabel: 'hierarchy' to: labels ].
	^ self scopeSummaryFromLabels: labels
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

	| command page queryRequest |
	^ [
	  queryRequest := self parsedRequestFromToolRequest: request.
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
		  on: Error
		  do: [ :error |
			  self
				  errorResultForQueryError: error
				  requestedContext:
				  (self requestedContextForErrorFromRequest: request) ]
]

{ #category : 'private - template' }
MCPToolQuery >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self subclassResponsibility
]

{ #category : 'private - request' }
MCPToolQuery >> filterModeFromRequest: request [

	^ request
		  stringArgumentNamed: 'filterMode'
		  default: self defaultFilterMode
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

{ #category : 'private - request' }
MCPToolQuery >> parsedRequestFromToolRequest: request [

	^ self queryRequestFromToolRequest: request
]

{ #category : 'private - template' }
MCPToolQuery >> queryEntriesForQueryRequest: queryRequest [

	self subclassResponsibility
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
	fieldName = 'side' ifTrue: [ key := #side ].
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
MCPToolQuery >> wherePredicateSchemaProperty [

	| anyItems allItems filterTargets notProperty nestedWhere whereProperty |
	allItems := MCPStructureProperties new
		            type: 'object';
		            description: 'A nested where predicate.';
		            additionalProperties: true;
		            yourself.
	anyItems := MCPStructureProperties new
		            type: 'object';
		            description: 'A nested where predicate.';
		            additionalProperties: true;
		            yourself.
	notProperty := MCPStructureProperties new
		               name: 'not';
		               type: 'object';
		               description:
			               'A nested predicate whose match is negated.';
		               additionalProperties: true;
		               yourself.
	nestedWhere := MCPStructureProperties new
		               name: 'where';
		               type: 'object';
		               description:
			               'Nested predicate used by exists and none relation predicates.';
		               additionalProperties: true;
		               yourself.
	filterTargets := self
		                 stringArraySchemaNamed: 'filterTargets'
		                 description:
		                 'Entry fields matched by a filter predicate.'
		                 itemDescription: 'A filter target.'.
	whereProperty := self
		                 schemaPropertyNamed: 'where'
		                 type: 'object'
		                 description:
		                 'Optional recursive predicate applied before pagination. Use all, any, and not for boolean composition; field, value, and mode for field matching; filter, filterMode, and filterTargets for top-level-style filtering; exists or none with relation names and nested where for relation queries. Method predicates support selectorReference, classReference, and variableReference filterMode.'.
	whereProperty
		properties: {
				((self
					  schemaPropertyNamed: 'all'
					  type: 'array'
					  description: 'All nested predicates must match.')
					 items: allItems;
					 yourself).
				((self
					  schemaPropertyNamed: 'any'
					  type: 'array'
					  description: 'At least one nested predicate must match.')
					 items: anyItems;
					 yourself).
				notProperty.
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
					 values: #( 'substring' 'prefix' 'exact' 'regex' )
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
					 values:
						 #( 'substring' 'prefix' 'exact' 'regex' 'selectorReference'
						    'classReference' 'variableReference' )
					 default: self defaultFilterMode).
				filterTargets.
				(self
					 booleanSchemaPropertyNamed: 'caseSensitive'
					 description: 'Whether text matching is case-sensitive.'
					 default: true).
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
				nestedWhere };
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
