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
MCPToolSearchClasses class >> groupName [

	^ self classesGroupName
]

{ #category : 'metadata' }
MCPToolSearchClasses class >> toolName [

	^ 'class_search'
]

{ #category : 'metadata' }
MCPToolSearchClasses >> buildInputSchema [

	| properties |
	properties := self classQueryScopeInputProperties , self classFilterInputProperties , { self offsetInputProperty }.
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> classEntriesForRequest: queryRequest [

	| entries |
	entries := OrderedCollection new.
	queryRequest scopeQuery classes do: [ :eachClass |
			| entry |
			entry := (MCPClassInfo fromClass: eachClass) asQueryDictionary.
			(self matchesFieldFiltersOnClassEntry: entry queryRequest: queryRequest) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - request' }
MCPToolSearchClasses >> classFilterFieldNames [

	^ #( 'name' 'package' 'tag' )
]

{ #category : 'private - schema' }
MCPToolSearchClasses >> classFilterInputProperties [

	^ {
		  (self schemaPropertyNamed: 'name' type: 'string' description: 'Keep classes whose name contains this text, ignoring case.').
		  (self
			   schemaPropertyNamed: 'package'
			   type: 'string'
			   description:
			   'Keep classes whose package name contains this text, ignoring case. Name packages exactly under scope.packages instead.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description: 'Keep classes whose package tag contains this text, ignoring case.') }
]

{ #category : 'metadata' }
MCPToolSearchClasses >> defaultExposure [

	^ 'static'
]

{ #category : 'defaults' }
MCPToolSearchClasses >> defaultPageLimit [
	"A class entry is one short line, so a page can hold more of them."

	^ 50
]

{ #category : 'metadata' }
MCPToolSearchClasses >> description [

	^ 'Search classes by name, package, tag, or superclass/subclass scope. Use class_get when you already know the class name.'
]

{ #category : 'private - results' }
MCPToolSearchClasses >> failureMessageForScope: scopeSummary error: anError [

	^ self scopeQueryFailureMessageFor: 'classes' scope: scopeSummary error: anError
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> fieldTextsForClassEntry: anEntry fieldName: fieldName [

	fieldName = 'name' ifTrue: [ ^ { (anEntry at: #class) } ].
	fieldName = 'package' ifTrue: [ ^ { (anEntry at: #package ifAbsent: [ '' ]) } ].
	fieldName = 'tag' ifTrue: [ ^ { (anEntry at: #tag) } ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> matchesFieldFiltersOnClassEntry: anEntry queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName | self fieldTextsForClassEntry: anEntry fieldName: fieldName ]
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
	data at: #classes put: (page entries collect: [ :each | self queryResultEntryFromClassEntry: each ] as: Array).
	data at: #pagination put: page paginationDictionary.
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'private - results' }
MCPToolSearchClasses >> queryResultEntryFromClassEntry: anEntry [

	^ {
		  (#class -> (anEntry at: #class)).
		  (#package -> (anEntry at: #package)).
		  (#tag -> (anEntry at: #tag)) } asDictionary
]

{ #category : 'private - template' }
MCPToolSearchClasses >> requestedContextFromRequest: request [

	^ { (#scope -> (self classAndMethodScopeSummaryFromRequest: request)) } asDictionary
]

{ #category : 'private - template' }
MCPToolSearchClasses >> searchRequestFromToolRequest: request [

	^ MCPSearchClassesRequest fromRequest: request tool: self
]

{ #category : 'private - results' }
MCPToolSearchClasses >> successSummaryForScope: scopeSummary page: page [

	^ self scopeQuerySuccessSummaryFor: 'classes' scope: scopeSummary page: page
]

{ #category : 'metadata' }
MCPToolSearchClasses >> title [

	^ 'Search Classes'
]
