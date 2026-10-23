"
Lists packages in the image or a project with optional filtering. It is the general package discovery tool.
"
Class {
	#name : 'MCPToolSearchPackages',
	#superclass : 'MCPToolSearch',
	#category : 'MCP-Tools',
	#package : 'MCP',
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
MCPToolSearchPackages >> description [

	^ 'Search packages by name, project, or tag.'
]

{ #category : 'private - results' }
MCPToolSearchPackages >> failureMessageForScope: scopeSummary error: anError [

	^ self scopeQueryFailureMessageFor: 'packages' scope: scopeSummary error: anError
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> fieldTextsForPackageEntry: anEntry fieldName: fieldName [

	fieldName = 'name' ifTrue: [ ^ { (anEntry at: #package) } ].
	fieldName = 'project' ifTrue: [ ^ anEntry at: #projects ].
	fieldName = 'tag' ifTrue: [ ^ anEntry at: #tags ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> matchesFieldFiltersOnPackageEntry: anEntry queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName | self fieldTextsForPackageEntry: anEntry fieldName: fieldName ]
		  mode: queryRequest filterMode
		  caseSensitive: queryRequest caseSensitive
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> packageEntriesForRequest: queryRequest [

	^ self
		  packageEntriesFromPackages: queryRequest scopeQuery packages
		  projectNames: queryRequest scopeQuery packageProjectNamesMap
		  usingRequest: queryRequest
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> packageEntriesFromPackages: packages projectNames: packageProjectNames usingRequest: queryRequest [

	| entries |
	entries := OrderedCollection new.
	packages do: [ :eachPackage |
			| entry projectNames |
			projectNames := packageProjectNames at: eachPackage name asString ifAbsent: [ #(  ) ].
			entry := (MCPPackageInfo fromPackage: eachPackage projectNames: projectNames) asQueryDictionary.
			(self matchesFieldFiltersOnPackageEntry: entry queryRequest: queryRequest) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - request' }
MCPToolSearchPackages >> packageFilterFieldNames [

	^ #( 'name' 'project' 'tag' )
]

{ #category : 'private - schema' }
MCPToolSearchPackages >> packageFilterInputProperties [

	^ {
		  (self schemaPropertyNamed: 'name' type: 'string' description: 'Match package names.').
		  (self schemaPropertyNamed: 'project' type: 'string' description: 'Match owning projects.').
		  (self schemaPropertyNamed: 'tag' type: 'string' description: 'Match package tags.') }
]

{ #category : 'private - template' }
MCPToolSearchPackages >> queryEntriesForQueryRequest: queryRequest [

	^ self packageEntriesForRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolSearchPackages >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #packages
]

{ #category : 'private - template' }
MCPToolSearchPackages >> requestedContextFromRequest: request [

	^ { (#scope -> (self
		    packageScopeSummaryForProjectNames: (request stringCollectionArgumentNamed: 'projects')
		    packageNames: (request stringCollectionArgumentNamed: 'packages'))) } asDictionary
]

{ #category : 'private - template' }
MCPToolSearchPackages >> searchRequestFromToolRequest: request [

	^ MCPSearchPackagesRequest fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolSearchPackages >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope:
		  (self
			   packageScopeSummaryForProjectNames: queryRequest scopeQuery projectNames
			   packageNames: queryRequest scopeQuery packageNames)
		  page: page
]

{ #category : 'private - results' }
MCPToolSearchPackages >> successSummaryForScope: scopeSummary page: page [

	^ self scopeQuerySuccessSummaryFor: 'packages' scope: scopeSummary page: page
]

{ #category : 'metadata' }
MCPToolSearchPackages >> title [

	^ 'Search Packages'
]
