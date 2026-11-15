"
Lists classes in a chosen scope with optional filtering. It is optimized for class discovery rather than hierarchy inspection.
"
Class {
	#name : 'MCPToolSearchClasses',
	#superclass : 'MCPToolSearch',
	#traits : 'TMCPClassTool',
	#classTraits : 'TMCPClassTool classTrait',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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
MCPToolSearchClasses >> entryNameKeys [
	"A row is a class."

	^ #( class )
]

{ #category : 'private - request' }
MCPToolSearchClasses >> fieldFilterNames [

	^ #( 'name' 'package' 'tag' )
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> fieldTextsForClassEntry: anEntry fieldName: fieldName [

	fieldName = 'name' ifTrue: [ ^ { (anEntry at: #class) } ].
	fieldName = 'package' ifTrue: [ ^ { (anEntry at: #package ifAbsent: [ '' ]) } ].
	fieldName = 'tag' ifTrue: [ ^ { (anEntry at: #tag) } ].
	^ #(  )
]

{ #category : 'private - template' }
MCPToolSearchClasses >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"The classes of the scope whose fields hold the field filters, ignoring case."

	| entries fieldFilters |
	fieldFilters := self fieldFiltersFromRequest: request.
	entries := OrderedCollection new.
	scopeQuery classes do: [ :eachClass |
			| entry |
			entry := (MCPClassInfo fromClass: eachClass) asQueryDictionary.
			(self
				 fieldFilters: fieldFilters
				 matchUsing: [ :fieldName | self fieldTextsForClassEntry: entry fieldName: fieldName ]
				 mode: self defaultFilterMode
				 caseSensitive: false) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - template' }
MCPToolSearchClasses >> queryResultDataForPage: page [

	| data |
	data := Dictionary new.
	data at: #classes put: (page entries collect: [ :each | self queryResultEntryFromClassEntry: each ] as: Array).
	data at: #pagination put: page paginationDictionary.
	page nextOffset ifNotNil: [ :offset | data at: #nextOffset put: offset ].
	^ data
]

{ #category : 'private - results' }
MCPToolSearchClasses >> queryResultEntryFromClassEntry: anEntry [
	"A class that is not tagged sits in its package's root tag, which says nothing a row needs."

	| entry |
	entry := {
		         (#class -> (anEntry at: #class)).
		         (#package -> (anEntry at: #package)) } asDictionary.
	(anEntry at: #hasTag) ifTrue: [ entry at: #tag put: (anEntry at: #tag) ].
	^ entry
]

{ #category : 'private - template' }
MCPToolSearchClasses >> scopeQueryFromRequest: request [

	^ self classScopeQueryFromRequest: request
]

{ #category : 'private - template' }
MCPToolSearchClasses >> searchedNoun [

	^ 'class'
]

{ #category : 'metadata' }
MCPToolSearchClasses >> title [

	^ 'Search Classes'
]
