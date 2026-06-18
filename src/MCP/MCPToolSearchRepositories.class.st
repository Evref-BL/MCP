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

{ #category : 'defaults' }
MCPToolSearchRepositories class >> toolName [

	^ 'repository_search'
]

{ #category : 'defaults' }
MCPToolSearchRepositories >> defaultDescription [

	^ 'List Iceberg repositories registered in image. Filter by repository identity, package, branch, modified state, or field-specific text.'
]

{ #category : 'defaults' }
MCPToolSearchRepositories >> defaultInputSchema [

	| properties |
	properties := self repositoryFilterInputProperties
	              , self repositoryFieldFilterInputProperties , {
		              (self
			               filterModeSchemaPropertyWithDescription:
			               'How repository text filters are matched.'
			               values: self basicFilterModes).
		              (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether repository text matching is case-sensitive.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching repositories to return. Use 0 to return no entries.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'defaults' }
MCPToolSearchRepositories >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed:
		  'repositories'
		  entriesDescription:
		  'The repository entries returned for the requested page.'
		  entrySchema: self repositoryEntrySchema
		  itemNounPhrase: 'repository entries'
]

{ #category : 'defaults' }
MCPToolSearchRepositories >> defaultTitle [

	^ 'Search Repositories'
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'repositories'
		  scope: scopeSummary
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> fieldTextsForRepositoryEntry: anEntry fieldName: fieldName [

	fieldName = 'repositoryName' ifTrue: [ ^ { (anEntry at: #name) } ].
	fieldName = 'repositoryClassName' ifTrue: [
		^ { (anEntry at: #className) } ].
	fieldName = 'location' ifTrue: [ ^ { (anEntry at: #location) } ].
	fieldName = 'subdirectory' ifTrue: [
		^ { (anEntry at: #subdirectory) } ].
	fieldName = 'branchName' ifTrue: [ ^ { (anEntry at: #branchName) } ].
	fieldName = 'headDescription' ifTrue: [
		^ { (anEntry at: #headDescription) } ].
	fieldName = 'headClassName' ifTrue: [
		^ { (anEntry at: #headClassName) } ].
	fieldName = 'headCommitId' ifTrue: [
		^ { (anEntry at: #headCommitId) } ].
	fieldName = 'packageName' ifTrue: [ ^ anEntry at: #packageNames ].
	fieldName = 'modifiedPackageName' ifTrue: [
		^ anEntry at: #modifiedPackageNames ].
	fieldName = 'remoteName' ifTrue: [
		^ (anEntry at: #remotes) collect: [ :remote | remote at: #name ] ].
	fieldName = 'remoteUrl' ifTrue: [
		^ (anEntry at: #remotes) collect: [ :remote | remote at: #url ] ].
	fieldName = 'upstreamRemoteName' ifTrue: [
		^ { (anEntry at: #upstreamRemoteName) } ].
	fieldName = 'upstreamBranchName' ifTrue: [
		^ { (anEntry at: #upstreamBranchName) } ].
	fieldName = 'upstreamRemoteUrl' ifTrue: [
		^ { (anEntry at: #upstreamRemoteUrl) } ].
	^ #(  )
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> matchesFieldFiltersOnRepositoryEntry: anEntry queryRequest: queryRequest [

	^ self
		  fieldFilters: queryRequest fieldFilters
		  matchUsing: [ :fieldName |
			  self fieldTextsForRepositoryEntry: anEntry fieldName: fieldName ]
		  mode: queryRequest filterMode
		  caseSensitive: queryRequest caseSensitive
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
			(self repositoryEntry: queryEntry matchesRequest: queryRequest)
				ifTrue: [ entries add: repositoryInfo asSearchDictionary ] ].
	sortedEntries := entries asArray sort: [ :left :right |
		                 (left at: #name) <= (right at: #name) ].
	^ sortedEntries
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> repositoryEntry: anEntry matchesDirectFiltersFromRequest: queryRequest [

	(queryRequest repositoryNames notEmpty and: [
		 (queryRequest repositoryNames includes: (anEntry at: #name)) not ])
		ifTrue: [ ^ false ].
	(queryRequest directoryPaths notEmpty and: [
		 (queryRequest directoryPaths includes: (anEntry at: #location)) not ])
		ifTrue: [ ^ false ].
	(queryRequest packageNames notEmpty and: [
		 (queryRequest packageNames anySatisfy: [ :each |
			  (anEntry at: #packageNames) includes: each ]) not ]) ifTrue: [
		^ false ].
	queryRequest isModified ifNotNil: [ :expected |
		(anEntry at: #isModified) = expected ifFalse: [ ^ false ] ].
	queryRequest isMissing ifNotNil: [ :expected |
		(anEntry at: #isMissing) = expected ifFalse: [ ^ false ] ].
	^ true
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> repositoryEntry: anEntry matchesRequest: queryRequest [

	(self
		 repositoryEntry: anEntry
		 matchesDirectFiltersFromRequest: queryRequest) ifFalse: [ ^ false ].
	^ self
		  matchesFieldFiltersOnRepositoryEntry: anEntry
		  queryRequest: queryRequest
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryEntrySchema [

	^ MCPStructureProperties new
		  name: 'repositoryEntry';
		  type: 'object';
		  description:
			  'Compact metadata for one registered Iceberg repository.';
		  properties: self repositoryInfoDataProperties;
		  required: #( 'name' 'location' 'isModified' 'isMissing' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryFieldFilterInputProperties [

	^ {
		  (self
			   repositoryTextFilterPropertyNamed: 'repositoryName'
			   description:
			   'Optional repository-name text matched against repository names.').
		  (self
			   repositoryTextFilterPropertyNamed: 'repositoryClassName'
			   description:
			   'Optional class-name text matched against concrete Iceberg repository class names.').
		  (self
			   repositoryTextFilterPropertyNamed: 'location'
			   description:
			   'Optional path text matched against repository locations.').
		  (self
			   repositoryTextFilterPropertyNamed: 'subdirectory'
			   description:
			   'Optional path text matched against repository source subdirectories.').
		  (self
			   repositoryTextFilterPropertyNamed: 'branchName'
			   description:
			   'Optional branch-name text matched against current local branches.').
		  (self
			   repositoryTextFilterPropertyNamed: 'headDescription'
			   description:
			   'Optional text matched against repository head descriptions.').
		  (self
			   repositoryTextFilterPropertyNamed: 'headClassName'
			   description:
			   'Optional class-name text matched against repository head reference classes.').
		  (self
			   repositoryTextFilterPropertyNamed: 'headCommitId'
			   description:
			   'Optional commit-id text matched against exact head commit ids.').
		  (self
			   repositoryTextFilterPropertyNamed: 'packageName'
			   description:
			   'Optional package-name text matched against managed package names.').
		  (self
			   repositoryTextFilterPropertyNamed: 'modifiedPackageName'
			   description:
			   'Optional package-name text matched against modified package names.').
		  (self
			   repositoryTextFilterPropertyNamed: 'remoteName'
			   description:
			   'Optional remote-name text matched against configured remotes.').
		  (self
			   repositoryTextFilterPropertyNamed: 'remoteUrl'
			   description:
			   'Optional URL text matched against configured remotes.').
		  (self
			   repositoryTextFilterPropertyNamed: 'upstreamRemoteName'
			   description:
			   'Optional remote-name text matched against upstream remotes.').
		  (self
			   repositoryTextFilterPropertyNamed: 'upstreamBranchName'
			   description:
			   'Optional branch-name text matched against upstream branches.').
		  (self
			   repositoryTextFilterPropertyNamed: 'upstreamRemoteUrl'
			   description:
			   'Optional URL text matched against upstream remote URLs.') }
]

{ #category : 'private - request' }
MCPToolSearchRepositories >> repositoryFilterFieldNames [

	^ #( 'repositoryName' 'repositoryClassName' 'location' 'subdirectory'
	     'branchName' 'headDescription' 'headClassName' 'headCommitId'
	     'packageName' 'modifiedPackageName' 'remoteName' 'remoteUrl'
	     'upstreamRemoteName' 'upstreamBranchName' 'upstreamRemoteUrl' )
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryFilterInputProperties [

	^ {
		  (self
			   stringArraySchemaNamed: 'repositoryNames'
			   description:
			   'Exact repository names to include. Direct repository filters are combined.'
			   itemDescription: 'A repository name.').
		  (self
			   stringArraySchemaNamed: 'directoryPaths'
			   description:
			   'Exact repository location paths to include. Direct repository filters are combined.'
			   itemDescription: 'A repository location path.').
		  (self
			   stringArraySchemaNamed: 'packageNames'
			   description:
			   'Include repositories containing any of these package names. Direct repository filters are combined.'
			   itemDescription: 'A package name.').
		  (self
			   booleanSchemaPropertyNamed: 'isModified'
			   description:
			   'When present, include only repositories whose modified state equals this value.').
		  (self
			   booleanSchemaPropertyNamed: 'isMissing'
			   description:
			   'When present, include only repositories whose missing state equals this value.') }
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryInfoDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'name'
			   type: 'string'
			   description: 'Repository name.').
		  (self
			   schemaPropertyNamed: 'location'
			   type: 'string'
			   description: 'Repository directory.').
		  (self
			   schemaPropertyNamed: 'subdirectory'
			   type: 'string'
			   description: 'Repository source subdirectory.').
		  (self
			   schemaPropertyNamed: 'branchName'
			   type: 'string'
			   description: 'Current branch.').
		  (self
			   schemaPropertyNamed: 'headDescription'
			   type: 'string'
			   description: 'Current HEAD description.').
		  (self
			   schemaPropertyNamed: 'headCommitId'
			   type: 'string'
			   description: 'Current HEAD commit id.').
		  (self
			   booleanSchemaPropertyNamed: 'isModified'
			   description: 'Whether repository has image-side modifications.').
		  (self
			   booleanSchemaPropertyNamed: 'isMissing'
			   description: 'Whether repository directory is missing.').
		  (self
			   booleanSchemaPropertyNamed: 'isDetachedHead'
			   description: 'Whether repository is detached.').
		  (self
			   stringArraySchemaNamed: 'packageNames'
			   description: 'Managed packages.'
			   itemDescription: 'Package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNames'
			   description: 'Modified packages.'
			   itemDescription: 'Package name.').
		  (self
			   schemaPropertyNamed: 'upstreamRemoteName'
			   type: 'string'
			   description: 'Upstream remote name when configured.').
		  (self
			   schemaPropertyNamed: 'upstreamBranchName'
			   type: 'string'
			   description: 'Upstream branch when configured.').
		  (self
			   schemaPropertyNamed: 'upstreamRemoteUrl'
			   type: 'string'
			   description: 'Upstream remote URL when configured.') }
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryRemoteEntrySchema [

	^ MCPStructureProperties new
		  name: 'repositoryRemoteEntry';
		  type: 'object';
		  description:
			  'Structured metadata for one configured repository remote.';
		  properties: {
				  (self
					   schemaPropertyNamed: 'name'
					   type: 'string'
					   description: 'The remote name.').
				  (self
					   schemaPropertyNamed: 'url'
					   type: 'string'
					   description: 'The remote URL.') };
		  required: #( 'name' 'url' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> repositoryScopeSummaryForAssociations: scopeAssociations [

	| labels |
	labels := OrderedCollection new.
	scopeAssociations do: [ :eachAssociation |
		eachAssociation value ifTrue: [
			self addScopeLabel: eachAssociation key to: labels ] ].
	^ self scopeSummaryFromLabels: labels
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> repositoryScopeSummaryForRequest: queryRequest [

	^ self repositoryScopeSummaryForAssociations: {
			  ('repositories' -> queryRequest repositoryNames notEmpty).
			  ('directories' -> queryRequest directoryPaths notEmpty).
			  ('packages' -> queryRequest packageNames notEmpty).
			  ('modified-state' -> queryRequest isModified notNil).
			  ('missing-state' -> queryRequest isMissing notNil).
			  ('field-filters' -> queryRequest hasFieldFilters) }
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryTextFilterPropertyNamed: propertyName description: descriptionString [

	^ self
		  schemaPropertyNamed: propertyName
		  type: 'string'
		  description: descriptionString
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> requestedContextFromRequest: request [

	^ { (#scope -> (self repositoryScopeSummaryForAssociations: {
			    ('repositories'
			     ->
			     (request stringCollectionArgumentNamed: 'repositoryNames')
				     notEmpty).
			    ('directories'
			     ->
			     (request stringCollectionArgumentNamed: 'directoryPaths')
				     notEmpty).
			    ('packages'
			     ->
			     (request stringCollectionArgumentNamed: 'packageNames')
				     notEmpty).
			    ('modified-state' -> (request hasArgumentNamed: 'isModified')).
			    ('missing-state' -> (request hasArgumentNamed: 'isMissing')).
			    ('field-filters'
			     ->
				     (self repositoryFilterFieldNames anySatisfy: [ :fieldName |
					      request hasArgumentNamed: fieldName ])) })) } asDictionary
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> searchRequestFromToolRequest: request [

	^ MCPRepositoryQuerySpec fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope:
		  (self repositoryScopeSummaryForRequest: queryRequest)
		  page: page
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'repositories'
		  scope: scopeSummary
		  page: page
]
