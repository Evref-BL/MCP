"
Lists classes in a chosen scope with optional filtering. It is optimized for class discovery rather than hierarchy inspection.
"
Class {
	#name : 'MCPToolSearchClasses',
	#superclass : 'MCPToolSearch',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolSearchClasses class >> toolName [

	^ 'class_search'
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> classEntriesForRequest: queryRequest [

	| entries |
	entries := OrderedCollection new.
	queryRequest scopeQuery classes do: [ :eachClass |
			| entry |
			entry := (MCPClassInfo fromClass: eachClass) asQueryDictionary.
			(self
				 matchesFieldFiltersOnClassEntry: entry
				 queryRequest: queryRequest) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - schema' }
MCPToolSearchClasses >> classEntrySchema [

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

{ #category : 'private - request' }
MCPToolSearchClasses >> classFilterFieldNames [

	^ #( 'className' 'tag' 'instanceSlot' 'classSlot' )
]

{ #category : 'private - schema' }
MCPToolSearchClasses >> classFilterInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description:
			   'Optional class-name text matched against class names.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description:
			   'Optional package-tag text matched against class tags.').
		  (self
			   schemaPropertyNamed: 'instanceSlot'
			   type: 'string'
			   description:
			   'Optional slot-name text matched against instance-side slots.').
		  (self
			   schemaPropertyNamed: 'classSlot'
			   type: 'string'
			   description:
			   'Optional slot-name text matched against class-side slots.') }
]

{ #category : 'private - schema' }
MCPToolSearchClasses >> classInfoDataProperties [

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
MCPToolSearchClasses >> defaultDescription [

	^ 'List classes and optionally filter them by class metadata. Omitting class scope searches the whole image. Multiple scope filters are unioned. Missing class or package names return warnings with suggestions. Use class_get when you know the class name.'
]

{ #category : 'defaults' }
MCPToolSearchClasses >> defaultInputSchema [

	| properties |
	properties := self classQueryScopeInputProperties
	              , self classFilterInputProperties , {
		              (self
			               filterModeSchemaPropertyWithDescription:
			               'How class metadata filters are matched.'
			               values: self basicFilterModes).
		              (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether class metadata matching is case-sensitive.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching classes to return. Use 0 to request counts only.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'defaults' }
MCPToolSearchClasses >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'classes'
		  entriesDescription:
		  'The class entries returned for the requested page.'
		  entrySchema: self classEntrySchema
		  itemNounPhrase: 'class entries'
]

{ #category : 'defaults' }
MCPToolSearchClasses >> defaultTitle [

	^ 'Search Classes'
]

{ #category : 'private - results' }
MCPToolSearchClasses >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'classes'
		  scope: scopeSummary
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> fieldTextsForClassEntry: anEntry fieldName: fieldName [

	fieldName = 'className' ifTrue: [ ^ { (anEntry at: #className) } ].
	fieldName = 'tag' ifTrue: [ ^ { (anEntry at: #tag) } ].
	fieldName = 'instanceSlot' ifTrue: [
		^ anEntry at: #instanceSlotNames ].
	fieldName = 'classSlot' ifTrue: [ ^ anEntry at: #classSlotNames ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> matchesFieldFiltersOnClassEntry: anEntry queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName |
			  self fieldTextsForClassEntry: anEntry fieldName: fieldName ]
		  mode: queryRequest filterMode
		  caseSensitive: queryRequest caseSensitive
]

{ #category : 'private - template' }
MCPToolSearchClasses >> queryEntriesForQueryRequest: queryRequest [

	^ self classEntriesForRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolSearchClasses >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #classes
]

{ #category : 'private - template' }
MCPToolSearchClasses >> requestedContextFromRequest: request [

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolSearchClasses >> searchRequestFromToolRequest: request [

	^ MCPSearchClassesRequest fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolSearchClasses >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope:
		  (self classAndMethodScopeSummaryForScopeQuery:
			   queryRequest scopeQuery)
		  page: page
]

{ #category : 'private - results' }
MCPToolSearchClasses >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'classes'
		  scope: scopeSummary
		  page: page
]
