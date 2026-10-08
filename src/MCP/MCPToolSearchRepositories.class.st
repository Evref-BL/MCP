"
Lists Iceberg repositories registered in the image.

The tool is read-only. It supports direct filters for repository names, locations, package names, modified state, and missing state, plus generic field filtering and pagination.
"
Class {
	#name : 'MCPToolSearchRepositories',
	#superclass : 'MCPToolSearch',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSearchRepositories class >> groupName [

	^ self repositoriesGroupName
]

{ #category : 'metadata' }
MCPToolSearchRepositories class >> toolName [

	^ 'repository_search'
]

{ #category : 'metadata' }
MCPToolSearchRepositories >> additionalKeywords [

	^ #( 'repository' 'repositories' 'repo' 'iceberg' 'package' 'packages' 'class' 'classes' )
]

{ #category : 'metadata' }
MCPToolSearchRepositories >> buildInputSchema [

	| properties |
	properties := self repositoryFieldFilterInputProperties , {
		              (self booleanSchemaPropertyNamed: 'isModified' description: 'Filter by image-side modified state.').
		              (self booleanSchemaPropertyNamed: 'isMissing' description: 'Filter by missing repository directory state.').
		              (self filterModeSchemaPropertyWithDescription: 'Filter match mode.' values: self basicFilterModes) }
	              , (self paginationInputPropertiesWithLimitDescription: 'Maximum number of matching repositories to return.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'metadata' }
MCPToolSearchRepositories >> buildOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed: 'repositories'
		  entriesDescription: 'The repository entries returned for the requested page.'
		  entrySchema: self repositoryEntrySchema
		  itemNounPhrase: 'repository entries'
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> classNamesForRepositoryEntry: anEntry [

	| classNames |
	classNames := OrderedCollection new.
	(anEntry at: #packageNames) do: [ :packageName |
			PackageOrganizer default
				packageNamed: packageName asSymbol
				ifPresent: [ :package | package definedClasses do: [ :class | classNames add: class name asString ] ] ].
	^ classNames asArray
]

{ #category : 'metadata' }
MCPToolSearchRepositories >> description [

	^ 'Search registered repositories by image-side repository, package, class, and modification state.'
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> failureMessageForScope: scopeSummary error: anError [

	^ self scopeQueryFailureMessageFor: 'repositories' scope: scopeSummary error: anError
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> fieldTextsForRepositoryEntry: anEntry fieldName: fieldName [

	fieldName = 'name' ifTrue: [ ^ { (anEntry at: #name) } ].
	fieldName = 'location' ifTrue: [ ^ { (anEntry at: #location) } ].
	fieldName = 'subdirectory' ifTrue: [ ^ { (anEntry at: #subdirectory) } ].
	fieldName = 'packageName' ifTrue: [ ^ anEntry at: #packageNames ].
	fieldName = 'className' ifTrue: [ ^ self classNamesForRepositoryEntry: anEntry ].
	fieldName = 'modifiedPackageName' ifTrue: [ ^ anEntry at: #modifiedPackageNames ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> matchesFieldFiltersOnRepositoryEntry: anEntry queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName | self fieldTextsForRepositoryEntry: anEntry fieldName: fieldName ]
		  mode: queryRequest filterMode
		  caseSensitive: false
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> queryEntriesForQueryRequest: queryRequest [

	^ self repositoryEntriesForRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #repositories
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> repositoryEntriesForRequest: queryRequest [

	| entries sortedEntries |
	entries := OrderedCollection new.
	IceRepository repositories do: [ :eachRepository |
			| repositoryInfo queryEntry |
			repositoryInfo := MCPRepositoryInfo fromRepository: eachRepository.
			queryEntry := repositoryInfo asQueryDictionary.
			(self repositoryEntry: queryEntry matchesRequest: queryRequest) ifTrue: [ entries add: repositoryInfo asSearchDictionary ] ].
	sortedEntries := entries asArray sort: [ :left :right | (left at: #name) <= (right at: #name) ].
	^ sortedEntries
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> repositoryEntry: anEntry matchesRequest: queryRequest [

	queryRequest isModified ifNotNil: [ :value | (anEntry at: #isModified) = value ifFalse: [ ^ false ] ].
	queryRequest isMissing ifNotNil: [ :value | (anEntry at: #isMissing) = value ifFalse: [ ^ false ] ].
	^ self matchesFieldFiltersOnRepositoryEntry: anEntry queryRequest: queryRequest
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryEntrySchema [

	^ MCPStructureProperties new
		  name: 'repositoryEntry';
		  type: 'object';
		  description: 'Compact metadata for one registered Iceberg repository.';
		  properties: self repositoryInfoDataProperties;
		  required: #( 'name' 'location' 'isModified' 'isMissing' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryFieldFilterInputProperties [

	^ {
		  (self repositoryTextFilterPropertyNamed: 'name' description: 'Match repository names case-insensitively.').
		  (self repositoryTextFilterPropertyNamed: 'location' description: 'Match repository directory paths case-insensitively.').
		  (self repositoryTextFilterPropertyNamed: 'subdirectory' description: 'Match source subdirectories case-insensitively.').
		  (self repositoryTextFilterPropertyNamed: 'packageName' description: 'Match managed package names case-insensitively.').
		  (self
			   repositoryTextFilterPropertyNamed: 'className'
			   description: 'Match loaded class names in managed packages case-insensitively.').
		  (self repositoryTextFilterPropertyNamed: 'modifiedPackageName' description: 'Match modified package names case-insensitively.') }
]

{ #category : 'private - request' }
MCPToolSearchRepositories >> repositoryFilterFieldNames [

	^ #( 'name' 'location' 'subdirectory' 'packageName' 'className' 'modifiedPackageName' )
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryInfoDataProperties [

	^ {
		  (self schemaPropertyNamed: 'name' type: 'string' description: 'Repository name.').
		  (self schemaPropertyNamed: 'location' type: 'string' description: 'Repository directory.').
		  (self schemaPropertyNamed: 'subdirectory' type: 'string' description: 'Repository source subdirectory.').
		  (self booleanSchemaPropertyNamed: 'isModified' description: 'Whether repository has image-side modifications.').
		  (self booleanSchemaPropertyNamed: 'isMissing' description: 'Whether repository directory is missing.').
		  (self stringArraySchemaNamed: 'packageNames' description: 'Managed packages.' itemDescription: 'Package name.').
		  (self stringArraySchemaNamed: 'modifiedPackageNames' description: 'Modified packages.' itemDescription: 'Package name.') }
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryRemoteEntrySchema [

	^ MCPStructureProperties new
		  name: 'repositoryRemoteEntry';
		  type: 'object';
		  description: 'Structured metadata for one configured repository remote.';
		  properties: {
				  (self schemaPropertyNamed: 'name' type: 'string' description: 'The remote name.').
				  (self schemaPropertyNamed: 'url' type: 'string' description: 'The remote URL.') };
		  required: #( 'name' 'url' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> repositoryScopeSummaryForAssociations: scopeAssociations [

	| labels |
	labels := OrderedCollection new.
	scopeAssociations do: [ :eachAssociation | eachAssociation value ifTrue: [ self addScopeLabel: eachAssociation key to: labels ] ].
	^ self scopeSummaryFromLabels: labels
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> repositoryScopeSummaryForRequest: queryRequest [

	^ self repositoryScopeSummaryForAssociations: {
			  ('modified-state' -> queryRequest isModified notNil).
			  ('missing-state' -> queryRequest isMissing notNil).
			  ('field-filters' -> queryRequest hasFieldFilters) }
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryTextFilterPropertyNamed: propertyName description: descriptionString [

	^ self schemaPropertyNamed: propertyName type: 'string' description: descriptionString
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> requestedContextFromRequest: request [

	^ { (#scope -> (self repositoryScopeSummaryForAssociations: {
			    ('modified-state' -> (request hasArgumentNamed: 'isModified')).
			    ('missing-state' -> (request hasArgumentNamed: 'isMissing')).
			    ('field-filters' -> (self repositoryFilterFieldNames anySatisfy: [ :fieldName | request hasArgumentNamed: fieldName ])) })) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> searchRequestFromToolRequest: request [

	^ MCPRepositoryQuerySpec fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> successSummaryForQueryRequest: queryRequest page: page [

	^ self successSummaryForScope: (self repositoryScopeSummaryForRequest: queryRequest) page: page
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> successSummaryForScope: scopeSummary page: page [

	^ self scopeQuerySuccessSummaryFor: 'repositories' scope: scopeSummary page: page
]

{ #category : 'metadata' }
MCPToolSearchRepositories >> title [

	^ 'Search Repositories'
]
