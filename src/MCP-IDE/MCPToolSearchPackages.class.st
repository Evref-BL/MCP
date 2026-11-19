"
Lists packages in the image or a project with optional filtering. It is the general package discovery tool.
"
Class {
	#name : 'MCPToolSearchPackages',
	#superclass : 'MCPToolSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchPackages class >> groupName [

	^ self packagesGroupName
]

{ #category : 'metadata' }
MCPToolSearchPackages class >> toolName [

	^ 'package_search'
]

{ #category : 'metadata' }
MCPToolSearchPackages >> buildInputSchema [

	| properties |
	properties := self packageQueryScopeInputProperties , self packageFilterInputProperties , { self offsetInputProperty }.
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'metadata' }
MCPToolSearchPackages >> defaultExposure [

	^ 'static'
]

{ #category : 'metadata' }
MCPToolSearchPackages >> description [

	^ 'Search packages by name, project, or tag.'
]

{ #category : 'private - results' }
MCPToolSearchPackages >> entryNameKeys [
	"A row is a package."

	^ #( package )
]

{ #category : 'private - request' }
MCPToolSearchPackages >> fieldFilterNames [

	^ #( 'query' 'project' 'tag' )
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> fieldTextsForPackageEntry: anEntry fieldName: fieldName [

	fieldName = 'query' ifTrue: [ ^ { (anEntry at: #package) } ].
	fieldName = 'project' ifTrue: [ ^ anEntry at: #projects ].
	fieldName = 'tag' ifTrue: [ ^ anEntry at: #tags ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> packageEntriesFromPackages: packages projectNames: packageProjectNames fieldFilters: fieldFilters [
	"The packages whose fields hold the field filters, ignoring case, each with the projects that own it."

	| entries |
	entries := OrderedCollection new.
	packages do: [ :eachPackage |
			| entry projectNames |
			projectNames := packageProjectNames at: eachPackage name asString ifAbsent: [ #(  ) ].
			entry := (MCPPackageInfo fromPackage: eachPackage projectNames: projectNames) asQueryDictionary.
			(self
				 fieldFilters: fieldFilters
				 matchUsing: [ :fieldName | self fieldTextsForPackageEntry: entry fieldName: fieldName ]
				 mode: self defaultFilterMode
				 caseSensitive: false) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - schema' }
MCPToolSearchPackages >> packageFilterInputProperties [

	^ {
		  (self schemaPropertyNamed: 'query' type: 'string' description: 'Keep packages whose name contains this text, ignoring case.').
		  (self
			   schemaPropertyNamed: 'project'
			   type: 'string'
			   description: 'Keep packages whose owning project contains this text, ignoring case.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description: 'Keep packages carrying a tag that contains this text, ignoring case.') }
]

{ #category : 'private - request' }
MCPToolSearchPackages >> packageScopeQueryFromRequest: request [

	^ MCPPackageScopeQuery new
		  projectNames: (request stringCollectionArgumentNamed: 'projects');
		  packageNames: (request stringCollectionArgumentNamed: 'packages');
		  yourself
]

{ #category : 'private - template' }
MCPToolSearchPackages >> queryEntriesForRequest: request scopeQuery: scopeQuery [

	| fieldFilters |
	fieldFilters := self fieldFiltersFromRequest: request.
	^ self packageEntriesFromPackages: scopeQuery packages projectNames: scopeQuery packageProjectNamesMap fieldFilters: fieldFilters
]

{ #category : 'private - template' }
MCPToolSearchPackages >> queryResultDataForPage: page [

	^ page asDictionaryWithEntriesKey: #packages
]

{ #category : 'private - template' }
MCPToolSearchPackages >> scopeQueryFromRequest: request [

	^ self packageScopeQueryFromRequest: request
]

{ #category : 'private - template' }
MCPToolSearchPackages >> searchedNoun [

	^ 'package'
]

{ #category : 'private - results' }
MCPToolSearchPackages >> successSummaryForRequest: request scopeQuery: scopeQuery page: page [
	"A package the page lists or the scope names says what the image lost of it since its last save: what the image holds of a package is not all the work done on it."

	^ MCPToolListLostChanges
		  summary: (super successSummaryForRequest: request scopeQuery: scopeQuery page: page)
		  notingLostChangesToPackagesNamed: (page entries collect: [ :each | each at: #package ]) , scopeQuery packageNames
		  classesNamed: #(  )
]

{ #category : 'metadata' }
MCPToolSearchPackages >> title [

	^ 'Search Packages'
]
