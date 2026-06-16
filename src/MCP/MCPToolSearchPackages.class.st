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

{ #category : 'defaults' }
MCPToolSearchPackages class >> toolName [

	^ 'package_search'
]

{ #category : 'defaults' }
MCPToolSearchPackages >> defaultDescription [

	^ 'List packages and optionally filter them by package metadata. Omit projectNames and packageNames to search all packages. Use projectNames to include packages from projects and packageNames to include exact packages. Multiple scope properties are unioned.'
]

{ #category : 'defaults' }
MCPToolSearchPackages >> defaultInputSchema [

	| properties |
	properties := self packageQueryScopeInputProperties
	              , self packageFilterInputProperties , {
		              (self
			               filterModeSchemaPropertyWithDescription:
			               'How package metadata filters are matched.'
			               values: self basicFilterModes).
		              (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether package metadata matching is case-sensitive.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching packages to return. Use 0 to return no entries.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'defaults' }
MCPToolSearchPackages >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'packages'
		  entriesDescription:
		  'The package entries returned for the requested page.'
		  entrySchema: self packageEntrySchema
		  itemNounPhrase: 'package entries'
]

{ #category : 'defaults' }
MCPToolSearchPackages >> defaultTitle [

	^ 'Search Packages'
]

{ #category : 'private - results' }
MCPToolSearchPackages >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'packages'
		  scope: scopeSummary
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> fieldTextsForPackageEntry: anEntry fieldName: fieldName [

	fieldName = 'packageName' ifTrue: [ ^ { (anEntry at: #packageName) } ].
	fieldName = 'projectName' ifTrue: [ ^ anEntry at: #projectNames ].
	fieldName = 'tag' ifTrue: [ ^ anEntry at: #tagNames ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchPackages >> matchesFieldFiltersOnPackageEntry: anEntry queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName |
			  self fieldTextsForPackageEntry: anEntry fieldName: fieldName ]
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
			projectNames := packageProjectNames
				                at: eachPackage name asString
				                ifAbsent: [ #(  ) ].
			entry := (MCPPackageInfo
				          fromPackage: eachPackage
				          projectNames: projectNames) asQueryDictionary.
			(self
				 matchesFieldFiltersOnPackageEntry: entry
				 queryRequest: queryRequest) ifTrue: [ entries add: entry ] ].
	^ entries asArray
]

{ #category : 'private - schema' }
MCPToolSearchPackages >> packageEntrySchema [

	^ MCPStructureProperties new
		  name: 'packageEntry';
		  type: 'object';
		  description: 'Structured metadata for one queried package.';
		  properties: self packageInfoDataProperties;
		  required: #( 'packageName' 'projectNames' 'tagNames' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - request' }
MCPToolSearchPackages >> packageFilterFieldNames [

	^ #( 'packageName' 'projectName' 'tag' )
]

{ #category : 'private - schema' }
MCPToolSearchPackages >> packageFilterInputProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description:
			   'Optional package-name text matched against package names.').
		  (self
			   schemaPropertyNamed: 'projectName'
			   type: 'string'
			   description:
			   'Optional project-name text matched against owning projects.').
		  (self
			   schemaPropertyNamed: 'tag'
			   type: 'string'
			   description:
			   'Optional tag-name text matched against package tags.') }
]

{ #category : 'private - schema' }
MCPToolSearchPackages >> packageInfoDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'packageName'
			   type: 'string'
			   description: 'The package name.').
		  (self
			   stringArraySchemaNamed: 'projectNames'
			   description: 'The project names that include the package.'
			   itemDescription: 'A project name.').
		  (self
			   stringArraySchemaNamed: 'tagNames'
			   description: 'The package tag names defined in the package.'
			   itemDescription: 'A package tag name.') }
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
		    packageScopeSummaryForProjectNames:
		    (request stringCollectionArgumentNamed: 'projectNames')
		    packageNames:
		    (request stringCollectionArgumentNamed: 'packageNames'))) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolSearchPackages >> searchRequestFromToolRequest: request [

	^ MCPSearchPackagesRequest fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolSearchPackages >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope: (self
				   packageScopeSummaryForProjectNames:
				   queryRequest scopeQuery projectNames
				   packageNames: queryRequest scopeQuery packageNames)
		  page: page
]

{ #category : 'private - results' }
MCPToolSearchPackages >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'packages'
		  scope: scopeSummary
		  page: page
]
