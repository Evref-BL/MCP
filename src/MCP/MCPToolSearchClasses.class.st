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

{ #category : 'metadata' }
MCPToolSearchClasses class >> toolName [

	^ 'class_search'
]

{ #category : 'metadata' }
MCPToolSearchClasses >> buildInputSchema [

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
			               'Maximum number of matching classes to return. Use 0 to return no entries.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'metadata' }
MCPToolSearchClasses >> buildOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'classes'
		  entriesDescription:
		  'The class entries returned for the requested page.'
		  entrySchema: self classEntrySchema
		  itemNounPhrase: 'class entries'
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
		  description: 'One class search result.';
		  properties: self classInfoDataProperties;
		  required: #( 'className' 'packageName' 'tag' );
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
			   description: 'Class name.').
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'Defining package.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description: 'Package tag.') }
]

{ #category : 'metadata' }
MCPToolSearchClasses >> description [

	^ 'Search classes by name, package, tag, hierarchy, or slot. Use class_get when you already know the class name.'
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

	| data |
	data := Dictionary new.
	data at: #classes put: (page entries
			 collect: [ :each | self queryResultEntryFromClassEntry: each ]
			 as: Array).
	page nextOffset ifNotNil: [ :offset |
		data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'private - results' }
MCPToolSearchClasses >> queryResultEntryFromClassEntry: anEntry [

	^ {
		  (#className -> (anEntry at: #className)).
		  (#packageName -> (anEntry at: #packageName)).
		  (#tag -> (anEntry at: #tag)) } asDictionary
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

{ #category : 'private - results' }
MCPToolSearchClasses >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'classes'
		  scope: scopeSummary
		  page: page
]

{ #category : 'metadata' }
MCPToolSearchClasses >> title [

	^ 'Search Classes'
]
