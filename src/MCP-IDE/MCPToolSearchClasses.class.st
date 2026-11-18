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

{ #category : 'private - results' }
MCPToolSearchClasses >> keyOrder [
	"What a class inherits from, then where it lives."

	^ #( superclass package tag )
]

{ #category : 'private - template' }
MCPToolSearchClasses >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"The classes of the scope whose fields hold the field filters, ignoring case. A scope that reaches them by inheritance gives each its superclass, since the rows come by name and would not otherwise say how they inherit."

	| entries fieldFilters hierarchy |
	fieldFilters := self fieldFiltersFromRequest: request.
	hierarchy := scopeQuery asksForAHierarchy.
	entries := OrderedCollection new.
	scopeQuery classes do: [ :eachClass |
			| entry |
			entry := (MCPClassInfo fromClass: eachClass) asQueryDictionary.
			(hierarchy and: [ eachClass superclass isNotNil ]) ifTrue: [ entry at: #superclass put: eachClass superclass name asString ].
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
	"A class that is not tagged sits in its package's root tag, which says nothing a row needs. A row reached by inheritance says what its class inherits from."

	| entry |
	entry := {
		         (#class -> (anEntry at: #class)).
		         (#package -> (anEntry at: #package)) } asDictionary.
	(anEntry at: #hasTag) ifTrue: [ entry at: #tag put: (anEntry at: #tag) ].
	anEntry at: #superclass ifPresent: [ :name | entry at: #superclass put: name ].
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

{ #category : 'private - results' }
MCPToolSearchClasses >> successSummaryForRequest: request scopeQuery: scopeQuery page: page [
	"The package of a class the page lists, a package the scope names and a class it names say what the image lost of them since its last save. A package is named rather than each class listed, since a class lost with the rest of the work is in no list."

	^ MCPToolListLostChanges
		  summary: (super successSummaryForRequest: request scopeQuery: scopeQuery page: page)
		  notingLostChangesToPackagesNamed: (page entries collect: [ :each | each at: #package ]) , scopeQuery packageNames
		  classesNamed: (scopeQuery classNames collect: [ :each | each copyUpTo: Character space ])
]

{ #category : 'metadata' }
MCPToolSearchClasses >> title [

	^ 'Search Classes'
]
