"
Lists classes in a chosen scope with optional filtering. It is optimized for class discovery rather than hierarchy inspection.
"
Class {
	#name : 'MCPToolFindClasses',
	#superclass : 'MCPToolQuery',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'icons' }
MCPToolFindClasses class >> toolIconSpec [

	^ MCPToolIconSpec baseIconNamed: #class badgeIconNamed: #search
]

{ #category : 'defaults' }
MCPToolFindClasses class >> toolName [

	^ 'class_search'
]

{ #category : 'private - filtering' }
MCPToolFindClasses >> classEntriesForRequest: queryRequest [

	| entries matcher |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	entries := OrderedCollection new.
	queryRequest scopeQuery classes do: [ :eachClass |
			| entry matchesFilter |
			entry := (MCPClassInfo fromClass: eachClass) asQueryDictionary.
			matchesFilter := queryRequest hasFilterPattern not or: [
					                 self
						                 matchesFilterOnClassEntry: entry
						                 matcher: matcher
						                 targets: queryRequest filterTargets ].
			matchesFilter ifTrue: [ entries add: entry ] ].
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

	^ 'List classes and optionally filter them by class metadata. Omitting class scope searches the whole image. Multiple scope filters are unioned. Missing class or package names return warnings with suggestions. Use class_get when you know the class name.'
]

{ #category : 'private - request' }
MCPToolFindClasses >> defaultFilterTargets [

	^ #( 'class' )
]

{ #category : 'defaults' }
MCPToolFindClasses >> defaultInputSchema [

	| properties |
	properties := self classQueryScopeInputProperties , (self
		               baseFilteringInputPropertiesWithFilterDescription:
		               'Optional filter applied to the listed class-entry fields. Use filterTargets to choose which fields are matched.'
		               filterTargetsDescription:
		               'Optional class-entry fields matched by filter.'
		               filterModeDescription: 'How the filter is matched.'
		               filterModeValues: self basicFilterModes)
	              , { (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether filter matching is case-sensitive.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching classes to return. Use 0 to request counts only.').
	^ self queryInputSchemaWithProperties: properties
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

	^ 'Search Classes'
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

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolFindClasses >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope:
		  (self classAndMethodScopeSummaryForScopeQuery:
			   queryRequest scopeQuery)
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
