"
Lists classes in a chosen scope with optional filtering. It is optimized for class discovery rather than hierarchy inspection.
"
Class {
	#name : 'MCPToolFindClasses',
	#superclass : 'MCPToolQuery',
	#traits : '{} + TMCPClassTool',
	#classTraits : '{} + TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'private - filtering' }
MCPToolFindClasses >> classEntriesForRequest: queryRequest [

	| entries matcher whereContext |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	whereContext := self newWhereContext.
	entries := OrderedCollection new.
	queryRequest scopeQuery classes do: [ :eachClass |
		| entry evaluation matchesFilter |
		entry := (MCPClassInfo fromClass: eachClass) asQueryDictionary.
		matchesFilter := queryRequest hasFilterPattern not or: [
			                 self
				                 matchesFilterOnClassEntry: entry
				                 matcher: matcher
				                 targets: queryRequest filterTargets ].
		evaluation := self
			              whereEvaluationForEntityKind: #class
			              entry: entry
			              object: eachClass
			              context: whereContext.
		(matchesFilter and: [
			 queryRequest whereSpec matchesEvaluation: evaluation ]) ifTrue: [
			entries add: entry ] ].
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

	^ 'List classes and optionally filter them by class metadata. Omit packageNames, classNames, and hierarchyClassNames to search all classes. Use packageNames for package-defined classes, classNames for exact classes, and hierarchyClassNames for hierarchy roots. Multiple scope properties are unioned. Use where for recursive boolean predicates and relation predicates. Use inspect-class when you already know the class to inspect.'
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

	| classNamesProperty filterModeProperty filterTargetsProperty hierarchyClassNamesProperty packageNamesProperty |
	packageNamesProperty := self
		                        stringArraySchemaNamed: 'packageNames'
		                        description:
		                        'Class scope: package names whose defined classes are included. Omit all class scope properties to search all classes. Combine with classNames and hierarchyClassNames to union scopes.'
		                        itemDescription: 'A package name.'.
	classNamesProperty := self
		                      stringArraySchemaNamed: 'classNames'
		                      description:
		                      'Class scope: exact class names to include. Omit all class scope properties to search all classes. Combine with packageNames and hierarchyClassNames to union scopes.'
		                      itemDescription: 'A class name.'.
	hierarchyClassNamesProperty := self
		                               stringArraySchemaNamed:
		                               'hierarchyClassNames'
		                               description:
		                               'Class scope: class names whose superclasses and subclasses are included. Omit all class scope properties to search all classes. Combine with packageNames and classNames to union scopes.'
		                               itemDescription:
		                               'A hierarchy root class name.'.
	filterModeProperty := self
		                      stringEnumSchemaPropertyNamed: 'filterMode'
		                      description: 'How the filter is matched.'
		                      values:
		                      #( 'substring' 'prefix' 'exact' 'regex' )
		                      default: self defaultFilterMode.
	filterTargetsProperty := self
		                         stringEnumArraySchemaNamed: 'filterTargets'
		                         description:
		                         'Optional class-entry fields matched by filter.'
		                         itemDescription: 'A filter target.'
		                         values: self supportedFilterTargets
		                         default: self defaultFilterTargets.
	^ MCPStructureInputSchema new
		  type: 'object';
		  properties: {
				  packageNamesProperty.
				  classNamesProperty.
				  hierarchyClassNamesProperty.
				  (self
					   schemaPropertyNamed: 'filter'
					   type: 'string'
					   description:
						   'Optional filter applied to the listed class-entry fields. Use filterTargets to choose which fields are matched.').
				  filterTargetsProperty.
				  filterModeProperty.
				  self wherePredicateSchemaProperty.
				  (self
					   booleanSchemaPropertyNamed: 'caseSensitive'
					   description: 'Whether filter matching is case-sensitive.'
					   default: true).
				  (self
					   integerSchemaPropertyNamed: 'limit'
					   description:
						   'Maximum number of matching classes to return. Use 0 to request counts only.'
					   default: 100).
				  (self
					   integerSchemaPropertyNamed: 'offset'
					   description:
						   'Zero-based pagination offset applied after filtering.'
					   default: 0) };
		  required: #(  );
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

{ #category : 'private - results' }
MCPToolFindClasses >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'classes'
		  scope: scopeSummary
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
MCPToolFindClasses >> queryEntriesForQueryRequest: queryRequest [

	^ self classEntriesForRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolFindClasses >> queryRequestFromToolRequest: request [

	^ MCPFindClassesRequest fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolFindClasses >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #classes
]

{ #category : 'private - template' }
MCPToolFindClasses >> requestedContextFromRequest: request [

	^ { (#scope -> (self
		    classAndMethodScopeSummaryForPackageNames:
		    (request stringCollectionArgumentNamed: 'packageNames')
		    classNames:
		    (request stringCollectionArgumentNamed: 'classNames')
		    hierarchyClassNames:
		    (request stringCollectionArgumentNamed: 'hierarchyClassNames'))) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolFindClasses >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope: (self
				   classAndMethodScopeSummaryForPackageNames:
				   queryRequest scopeQuery packageNames
				   classNames: queryRequest scopeQuery classNames
				   hierarchyClassNames:
				   queryRequest scopeQuery hierarchyClassNames)
		  page: page
]

{ #category : 'private - results' }
MCPToolFindClasses >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'classes'
		  scope: scopeSummary
		  page: page
]

{ #category : 'private - request' }
MCPToolFindClasses >> supportedFilterTargets [

	^ #( 'class' 'package' 'tag' 'instanceSlot' 'classSlot' )
]
