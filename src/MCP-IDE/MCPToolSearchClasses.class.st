"
Lists the classes of a scope, kept by name and tag. Hierarchy questions go through the scope, which names superclasses, subclasses and whole hierarchies.
"
Class {
	#name : 'MCPToolSearchClasses',
	#superclass : 'MCPToolSearch',
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

	^ MCPStructureInputSchema
		  properties: self classQueryScopeInputProperties , self classFilterInputProperties , { self offsetInputProperty }
		  required: #(  )
]

{ #category : 'private - schema' }
MCPToolSearchClasses >> classFilterInputProperties [

	^ {
		  (self schemaPropertyNamed: 'query' type: 'string' description: 'Keep classes whose name contains this text, ignoring case.').
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

	^ 'Search classes by name or tag within a scope: the packages, classes, superclasses, subclasses or hierarchies it names. Use class_get when you already know the class name.'
]

{ #category : 'private - results' }
MCPToolSearchClasses >> entryNameKeys [
	"A row is a class."

	^ #( class )
]

{ #category : 'private - request' }
MCPToolSearchClasses >> fieldFilterNames [

	^ #( 'query' 'tag' )
]

{ #category : 'private - filtering' }
MCPToolSearchClasses >> fieldTextsForClassInfo: anInfo fieldName: fieldName [

	fieldName = 'query' ifTrue: [ ^ { anInfo className } ].
	fieldName = 'tag' ifTrue: [ ^ { anInfo tag } ].
	^ #(  )
]

{ #category : 'private - results' }
MCPToolSearchClasses >> keyOrder [
	"What a class inherits from, then where it lives."

	^ #( superclass package tag )
]

{ #category : 'private - template' }
MCPToolSearchClasses >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"The classes of the scope whose fields hold the field filters, ignoring case; a class is described only once it passes them. A scope that reaches them by inheritance gives each its superclass, since the rows come by name and would not otherwise say how they inherit."

	| entries fieldFilters hierarchy |
	fieldFilters := self fieldFiltersFromRequest: request.
	hierarchy := scopeQuery asksForAHierarchy.
	entries := OrderedCollection new.
	scopeQuery classes do: [ :eachClass |
			| info |
			info := MCPClassInfo fromClass: eachClass.
			(self
				 fieldFilters: fieldFilters
				 matchUsing: [ :fieldName | self fieldTextsForClassInfo: info fieldName: fieldName ]
				 mode: self defaultFilterMode
				 caseSensitive: false) ifTrue: [
					| entry |
					entry := info asDictionary.
					(hierarchy and: [ eachClass superclass isNotNil ]) ifTrue: [ entry at: #superclass put: eachClass superclass name asString ].
					entries add: entry ] ].
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
