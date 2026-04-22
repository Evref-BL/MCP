Class {
	#name : 'MCPToolFindClasses',
	#superclass : 'MCPQueryTool',
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
		entry := (MCPClassInfo fromClass: eachClass) asDictionary.
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
		  required:
			  #( 'className' 'superclassName' 'packageName' 'tag' 'instanceSlotNames'
			     'classSlotNames' 'subclassNames' );
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
			   schemaPropertyNamed: 'superclassName'
			   type: 'string'
			   description:
			   'The direct superclass of the class, or an empty string for the root.').
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
			   itemDescription: 'A class-side slot name.').
		  (self
			   stringArraySchemaNamed: 'subclassNames'
			   description: 'The direct subclasses of the class.'
			   itemDescription: 'A subclass name.') }
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultDescription [

	^ 'List classes in the selected scope and optionally filter them by class metadata. Use inspect-class when you already know the class to inspect.'
]

{ #category : 'private - arguments' }
MCPToolFindClasses >> defaultFilterTargets [

	^ #( 'class' )
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #class badgeIconNamed: #search) }
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultInputSchema [

	| scopeProperty packageNamesProperty classNamesProperty filterModeProperty filterTargetsItemProperty filterTargetsProperty |
	scopeProperty := MCPStructureProperties new
		                 name: 'scope';
		                 type: 'string';
		                 description:
			                 'Where to search for classes. Defaults to image.';
		                 enum: #( 'image' 'packages' 'hierarchy' 'classes' );
		                 default: 'image';
		                 yourself.
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
	filterModeProperty := MCPStructureProperties new
		                      name: 'filterMode';
		                      type: 'string';
		                      description:
			                      'How the filter is matched. Defaults to substring.';
		                      enum:
			                      #( 'substring' 'prefix' 'exact' 'regex' );
		                      default: 'substring';
		                      yourself.
	filterTargetsItemProperty := MCPStructureProperties new
		                             type: 'string';
		                             description: 'A filter target.';
		                             enum: self supportedFilterTargets;
		                             yourself.
	filterTargetsProperty := (self
		                          schemaPropertyNamed: 'filterTargets'
		                          type: 'array'
		                          description:
			                          'Optional class-entry fields matched by filter. Defaults to class.')
		                         items: filterTargetsItemProperty;
		                         default: self defaultFilterTargets;
		                         yourself.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  scopeProperty.
				  packageNamesProperty.
				  classNamesProperty.
				  (MCPStructureProperties new
					   name: 'filter';
					   type: 'string';
					   description:
						   'Optional filter applied to the listed class-entry fields. Use filterTargets to choose which fields are matched.';
					   yourself).
				  filterTargetsProperty.
				  filterModeProperty.
				  (MCPStructureProperties new
					   name: 'caseSensitive';
					   type: 'boolean';
					   description:
						   'Whether filter matching is case-sensitive. Defaults to false.';
					   default: false;
					   yourself).
				  (MCPStructureProperties new
					   name: 'limit';
					   type: 'integer';
					   description:
						   'Maximum number of matching classes to return. Defaults to 100. Use 0 to request counts only.';
					   default: 100;
					   yourself).
				  (MCPStructureProperties new
					   name: 'offset';
					   type: 'integer';
					   description:
						   'Zero-based pagination offset applied after filtering. Defaults to 0.';
					   default: 0;
					   yourself) };
		  required: #(  );
		  yourself
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultName [

	^ 'find-classes'
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultOutputSchema [

	| packageNamesProperty classNamesProperty filterTargetsItemProperty filterTargetsProperty classesProperty |
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
	filterTargetsItemProperty := MCPStructureProperties new
		                             type: 'string';
		                             description: 'A filter target.';
		                             enum: self supportedFilterTargets;
		                             yourself.
	filterTargetsProperty := (self
		                          schemaPropertyNamed: 'filterTargets'
		                          type: 'array'
		                          description:
			                          'The class-entry fields matched by filter. Defaults to class.')
		                         items: filterTargetsItemProperty;
		                         yourself.
	classesProperty := self
		                   schemaPropertyNamed: 'classes'
		                   type: 'array'
		                   description:
		                   'The class entries returned for the requested page.'.
	classesProperty items: self classEntrySchema.
	^ self
		  standardOutputSchemaForDataProperties: {
				  ((self
					    schemaPropertyNamed: 'scope'
					    type: 'string'
					    description: 'The scope used to search for classes.')
					   enum: #( 'image' 'packages' 'hierarchy' 'classes' );
					   yourself).
				  packageNamesProperty.
				  classNamesProperty.
				  filterTargetsProperty.
				  (self
					   integerSchemaPropertyNamed: 'returnedCount'
					   description:
					   'The number of class entries returned in this page.').
				  (self
					   integerSchemaPropertyNamed: 'totalCount'
					   description:
					   'The total number of matching classes before pagination.').
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
					   'The zero-based pagination offset that was applied.').
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description: 'The maximum number of class entries requested.').
				  (self
					   schemaPropertyNamed: 'truncated'
					   type: 'boolean'
					   description:
					   'Whether additional matching classes exist beyond the returned page.').
				  classesProperty }
		  required:
			  #( 'scope' 'packageNames' 'classNames' 'filterTargets'
			     'returnedCount' 'totalCount' 'offset' 'limit' 'truncated'
			     'classes' )
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultTitle [

	^ 'Find Pharo Classes'
]

{ #category : 'private - template' }
MCPToolFindClasses >> failureMessageForRequestedContext: requestedContext error: anError [

	^ self
		  failureMessageForScope: (requestedContext at: #scope)
		  error: anError
]

{ #category : 'private - results' }
MCPToolFindClasses >> failureMessageForScope: scope error: anError [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Unable to query classes [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  nextPutAll: anError class name;
			  nextPutAll: '): ';
			  nextPutAll: anError messageText ]
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
MCPToolFindClasses >> queryParametersFromArguments: arguments [

	| scopeQuery |
	scopeQuery := MCPClassScopeQuery
		              scope:
		              (self stringArgumentNamed: 'scope' in: arguments)
		              packageNames:
		              (self
			               argumentNamed: 'packageNames'
			               in: arguments
			               ifAbsent: [ nil ])
		              classNames:
		              (self
			               argumentNamed: 'classNames'
			               in: arguments
			               ifAbsent: [ nil ]).
	^ {
		  (#filterPattern
		   -> (self stringArgumentNamed: 'filter' in: arguments)).
		  (#filterTargets -> (self normalizedFilterTargetsFrom: arguments)).
		  (#filterMode -> (self normalizedFilterModeFrom: arguments)).
		  (#caseSensitive -> (self
			    booleanArgumentNamed: 'caseSensitive'
			    in: arguments
			    default: false)).
		  (#limit -> (self
			    nonNegativeIntegerArgumentNamed: 'limit'
			    in: arguments
			    default: 100)).
		  (#offset -> (self
			    nonNegativeIntegerArgumentNamed: 'offset'
			    in: arguments
			    default: 0)).
		  (#scopeQuery -> scopeQuery) } asDictionary
]

{ #category : 'private - template' }
MCPToolFindClasses >> queryResultDataForParameters: parameters page: page [

	| scopeQuery |
	scopeQuery := parameters at: #scopeQuery.
	^ self
		  queryResultDataFrom: {
				  (#scope -> scopeQuery scope).
				  (#packageNames -> scopeQuery packageNames).
				  (#classNames -> scopeQuery classNames).
				  (#filterTargets -> (parameters at: #filterTargets)) }
				  asDictionary
		  page: page
		  entriesKey: #classes
]

{ #category : 'private - template' }
MCPToolFindClasses >> requestedContextFromArguments: arguments [

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

	^ String streamContents: [ :stream |
		  stream
			  print: returnedCount;
			  nextPutAll: ' classes found [scope=';
			  nextPutAll: scope;
			  nextPutAll: '] (';
			  print: totalCount;
			  nextPutAll: ' matched'.
		  truncated ifTrue: [ stream nextPutAll: ', more available' ].
		  stream nextPutAll: ').' ]
]

{ #category : 'private - arguments' }
MCPToolFindClasses >> supportedFilterTargets [

	^ #( 'class' 'package' 'tag' 'instanceSlot' 'classSlot' )
]
