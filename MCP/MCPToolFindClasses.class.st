"
Lists classes in a chosen scope with optional filtering. It is optimized for class discovery rather than hierarchy inspection.
"
Class {
	#name : 'MCPToolFindClasses',
	#superclass : 'MCPToolQuery',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - filtering' }
MCPToolFindClasses >> classEntriesFrom: classes filter: filterPattern filterTargets: filterTargets filterMode: filterMode caseSensitive: caseSensitive [

	| entries matcher |
	matcher := self
		           matcherForPattern: filterPattern
		           mode: filterMode
		           caseSensitive: caseSensitive.
	entries := OrderedCollection new.
	classes do: [ :eachClass |
		| entry |
		entry := (MCPClassInfo fromClass: eachClass) asQueryDictionary.
		(filterPattern isNil or: [
			 self
				 matchesFilterOnClassEntry: entry
				 matcher: matcher
				 targets: filterTargets ]) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - schema' }
MCPToolFindClasses >> classEntrySchema [

	^ MCPStructureProperties new
		  name: 'classEntry';
		  type: 'object';
		  description: 'Structured metadata for one queried class.';
		  properties: self classInfoDataProperties;
		  required: #( 'className' 'packageName' 'tag' 'instanceSlotNames'
			     'classSlotNames' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolFindClasses >> classInfoDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The class name.').
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'The package that defines the class.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description: 'The package tag assigned to the class.').
		  (self
			   stringArraySchemaNamed: 'instanceSlotNames'
			   description: 'The instance-side slots defined on the class.'
			   itemDescription: 'An instance-side slot name.').
		  (self
			   stringArraySchemaNamed: 'classSlotNames'
			   description: 'The class-side slots defined on the class.'
			   itemDescription: 'A class-side slot name.') }
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultDescription [

	^ 'List classes in the selected scope and optionally filter them by class metadata. Use inspect-class when you already know the class to inspect.'
]

{ #category : 'private - request' }
MCPToolFindClasses >> defaultFilterTargets [

	^ #( 'class' )
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #class badgeIconNamed: #search) }
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultInputSchema [

	| scopeProperty packageNamesProperty classNamesProperty filterModeProperty filterTargetsProperty |
	scopeProperty := self
		                 stringEnumSchemaPropertyNamed: 'scope'
		                 description:
		                 'Where to search for classes. Defaults to image.'
		                 values:
		                 #( 'image' 'packages' 'hierarchy' 'classes' )
		                 default: 'image'.
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
	filterModeProperty := self
		                      stringEnumSchemaPropertyNamed: 'filterMode'
		                      description:
			                      'How the filter is matched. Defaults to '
			                      , self defaultFilterMode , '.'
		                      values:
		                      #( 'substring' 'prefix' 'exact' 'regex' )
		                      default: self defaultFilterMode.
	filterTargetsProperty := self
		                         stringEnumArraySchemaNamed: 'filterTargets'
		                         description:
		                         'Optional class-entry fields matched by filter. Defaults to class.'
		                         itemDescription: 'A filter target.'
		                         values: self supportedFilterTargets
		                         default: self defaultFilterTargets.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  scopeProperty.
				  packageNamesProperty.
				  classNamesProperty.
				  (self
					   schemaPropertyNamed: 'filter'
					   type: 'string'
					   description:
						   'Optional filter applied to the listed class-entry fields. Use filterTargets to choose which fields are matched.').
				  filterTargetsProperty.
				  filterModeProperty.
				  (self
					   booleanSchemaPropertyNamed: 'caseSensitive'
					   description:
						   'Whether filter matching is case-sensitive. Defaults to true.'
					   default: true).
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description:
						   'Maximum number of matching classes to return. Defaults to 100. Use 0 to request counts only.'
					   default: 100).
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
						   'Zero-based pagination offset applied after filtering. Defaults to 0.'
					   default: 0) };
		  required: #(  );
		  oneOf: self scopeBranchSchemasForClassAndMethodQueries;
		  yourself
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultName [

	^ 'find-classes'
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'classes'
		  entriesDescription:
		  'The class entries returned for the requested page.'
		  entrySchema: self classEntrySchema
		  itemNounPhrase: 'class entries'
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultTitle [

	^ 'Find Classes'
]

{ #category : 'private - template' }
MCPToolFindClasses >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolFindClasses >> failureMessageForScope: scope error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'classes'
		  scope: scope
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolFindClasses >> filterTextsForClassEntry: anEntry targets: filterTargets [

	| texts |
	texts := OrderedCollection new.
	filterTargets do: [ :each |
		each = 'class' ifTrue: [ texts add: (anEntry at: #className) ].
		each = 'package' ifTrue: [ texts add: (anEntry at: #packageName) ].
		each = 'tag' ifTrue: [ texts add: (anEntry at: #tag) ].
		each = 'instanceSlot' ifTrue: [
			(anEntry at: #instanceSlotNames) do: [ :slotName |
				texts add: slotName ] ].
		each = 'classSlot' ifTrue: [
			(anEntry at: #classSlotNames) do: [ :slotName |
				texts add: slotName ] ] ].
	^ texts asArray
]

{ #category : 'private - filtering' }
MCPToolFindClasses >> matchesFilterOnClassEntry: anEntry matcher: aMatcher targets: filterTargets [

	^ (self filterTextsForClassEntry: anEntry targets: filterTargets)
		  anySatisfy: [ :each | aMatcher value: each ]
]

{ #category : 'private - template' }
MCPToolFindClasses >> queryEntriesForParameters: parameters [

	^ self
		  classEntriesFrom: (parameters at: #scopeQuery) classes
		  filter: (parameters at: #filterPattern)
		  filterTargets: (parameters at: #filterTargets)
		  filterMode: (parameters at: #filterMode)
		  caseSensitive: (parameters at: #caseSensitive)
]

{ #category : 'private - template' }
MCPToolFindClasses >> queryParametersFromRequest: request [

	| scopeQuery |
	scopeQuery := MCPClassScopeQuery
		              scope:
		              (request stringArgumentNamed: 'scope' default: 'image')
		              packageNames:
		              (request stringCollectionArgumentNamed: 'packageNames')
		              classNames:
		              (request stringCollectionArgumentNamed: 'classNames').
	^ {
		  (#filterPattern -> (request stringArgumentNamed: 'filter')).
		  (#filterTargets -> (self filterTargetsFromRequest: request)).
		  (#filterMode -> (self filterModeFromRequest: request)).
		  (#caseSensitive
		   -> (request booleanArgumentNamed: 'caseSensitive' default: true)).
		  (#limit
		   ->
		   (request nonNegativeIntegerArgumentNamed: 'limit' default: 100)).
		  (#offset
		   -> (request nonNegativeIntegerArgumentNamed: 'offset' default: 0)).
		  (#scopeQuery -> scopeQuery) } asDictionary
]

{ #category : 'private - template' }
MCPToolFindClasses >> queryResultDataForParameters: parameters page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #classes
]

{ #category : 'private - template' }
MCPToolFindClasses >> requestedContextFromRequest: request [

	^ { (#scope
	   -> (request stringArgumentNamed: 'scope' default: 'image')) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolFindClasses >> successSummaryForParameters: parameters page: page [

	| scopeQuery |
	scopeQuery := parameters at: #scopeQuery.
	^ self
		  successSummaryForScope: scopeQuery scope
		  returnedCount: (page at: #returnedCount)
		  totalCount: (page at: #totalCount)
		  truncated: (page at: #truncated)
]

{ #category : 'private - results' }
MCPToolFindClasses >> successSummaryForScope: scope returnedCount: returnedCount totalCount: totalCount truncated: truncated [

	^ self
		  scopeQuerySuccessSummaryFor: 'classes'
		  scope: scope
		  returnedCount: returnedCount
		  totalCount: totalCount
		  truncated: truncated
]

{ #category : 'private - request' }
MCPToolFindClasses >> supportedFilterTargets [

	^ #( 'class' 'package' 'tag' 'instanceSlot' 'classSlot' )
]
