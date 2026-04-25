"
Lists Iceberg repositories registered in the image.

The tool is read-only. It supports direct filters for repository names, locations, package names, modified state, and missing state, plus generic field filtering and pagination.
"
Class {
	#name : 'MCPToolFindRepositories',
	#superclass : 'MCPToolQuery',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindRepositories >> defaultDescription [

	^ 'List Iceberg repositories registered in the image. Filter by repository name, location path, package name, modified state, missing state, or repository-entry fields. The tool is read-only and includes disk location, branch/head description, package names, modified package names, and read-only remote names.'
]

{ #category : 'private - request' }
MCPToolFindRepositories >> defaultFilterTargets [

	^ #( 'name' )
]

{ #category : 'defaults' }
MCPToolFindRepositories >> defaultIcons [

	^ { (self pngCompositeBaseIconNamed: #box badgeIconNamed: #search) }
]

{ #category : 'defaults' }
MCPToolFindRepositories >> defaultInputSchema [

	| properties |
	properties := self repositoryFilterInputProperties , (self
		               baseFilteringInputPropertiesWithFilterDescription:
		               'Optional filter applied to the listed repository-entry fields. Use filterTargets to choose which fields are matched.'
		               filterTargetsDescription:
		               'Optional repository-entry fields matched by filter.'
		               filterModeDescription:
		               'How the repository filter is matched.'
		               filterModeValues: self basicFilterModes)
	              , { (self caseSensitiveSchemaPropertyWithDescription:
			               'Whether filter matching is case-sensitive.') }
	              , (self paginationInputPropertiesWithLimitDescription:
			               'Maximum number of matching repositories to return. Use 0 to request counts only.').
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'defaults' }
MCPToolFindRepositories >> defaultName [

	^ 'find-repositories'
]

{ #category : 'defaults' }
MCPToolFindRepositories >> defaultOutputSchema [

	^ self
		  minimalPagedQueryOutputSchemaForEntriesPropertyNamed:
		  'repositories'
		  entriesDescription:
		  'The repository entries returned for the requested page.'
		  entrySchema: self repositoryEntrySchema
		  itemNounPhrase: 'repository entries'
]

{ #category : 'defaults' }
MCPToolFindRepositories >> defaultTitle [

	^ 'Find Repositories'
]

{ #category : 'private - results' }
MCPToolFindRepositories >> failureMessageForScope: scopeSummary error: anError [

	^ self
		  scopeQueryFailureMessageFor: 'repositories'
		  scope: scopeSummary
		  error: anError
]

{ #category : 'private - filtering' }
MCPToolFindRepositories >> filterTextsForRepositoryEntry: anEntry targets: filterTargets [

	| texts |
	texts := OrderedCollection new.
	filterTargets do: [ :each |
		each = 'name' ifTrue: [ texts add: (anEntry at: #name) ].
		each = 'class' ifTrue: [ texts add: (anEntry at: #className) ].
		(each = 'location' or: [ each = 'directory' ]) ifTrue: [
			texts add: (anEntry at: #location) ].
		each = 'subdirectory' ifTrue: [
			texts add: (anEntry at: #subdirectory) ].
		each = 'branch' ifTrue: [ texts add: (anEntry at: #branchName) ].
		each = 'head' ifTrue: [ texts add: (anEntry at: #headDescription) ].
		each = 'package' ifTrue: [
			(anEntry at: #packageNames) do: [ :packageName |
				texts add: packageName ] ].
		each = 'modifiedPackage' ifTrue: [
			(anEntry at: #modifiedPackageNames) do: [ :packageName |
				texts add: packageName ] ].
		each = 'remote' ifTrue: [
			(anEntry at: #remoteNames) do: [ :remoteName |
				texts add: remoteName ] ] ].
	^ texts asArray
]

{ #category : 'private - filtering' }
MCPToolFindRepositories >> matchesFilterOnRepositoryEntry: anEntry matcher: aMatcher targets: filterTargets [

	^ (self filterTextsForRepositoryEntry: anEntry targets: filterTargets)
		  anySatisfy: [ :each | aMatcher value: each ]
]

{ #category : 'private - template' }
MCPToolFindRepositories >> queryEntriesForQueryRequest: queryRequest [

	^ self repositoryEntriesForRequest: queryRequest
]

{ #category : 'private - template' }
MCPToolFindRepositories >> queryRequestFromToolRequest: request [

	^ MCPRepositoryQuerySpec fromRequest: request tool: self
]

{ #category : 'private - template' }
MCPToolFindRepositories >> queryResultDataForQueryRequest: queryRequest page: page [

	^ self queryResultDataFrom: nil page: page entriesKey: #repositories
]

{ #category : 'private - filtering' }
MCPToolFindRepositories >> repositoryEntriesForRequest: queryRequest [

	| entries matcher sortedEntries |
	matcher := self
		           matcherForPattern: queryRequest filterPattern
		           mode: queryRequest filterMode
		           caseSensitive: queryRequest caseSensitive.
	entries := OrderedCollection new.
	IceRepository repositories do: [ :eachRepository |
		| entry |
		entry := (MCPRepositoryInfo fromRepository: eachRepository)
			         asQueryDictionary.
		(self
			 repositoryEntry: entry
			 matchesRequest: queryRequest
			 matcher: matcher) ifTrue: [ entries add: entry ] ].
	sortedEntries := entries asArray asSortedCollection: [ :left :right |
		                 (left at: #name) <= (right at: #name) ].
	^ sortedEntries asArray
]

{ #category : 'private - filtering' }
MCPToolFindRepositories >> repositoryEntry: anEntry matchesDirectFiltersFromRequest: queryRequest [

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
MCPToolFindRepositories >> repositoryEntry: anEntry matchesRequest: queryRequest matcher: matcher [

	(self
		 repositoryEntry: anEntry
		 matchesDirectFiltersFromRequest: queryRequest) ifFalse: [ ^ false ].
	queryRequest hasFilterPattern ifFalse: [ ^ true ].
	^ self
		  matchesFilterOnRepositoryEntry: anEntry
		  matcher: matcher
		  targets: queryRequest filterTargets
]

{ #category : 'private - schema' }
MCPToolFindRepositories >> repositoryEntrySchema [

	^ MCPStructureProperties new
		  name: 'repositoryEntry';
		  type: 'object';
		  description:
			  'Structured metadata for one registered Iceberg repository.';
		  properties: self repositoryInfoDataProperties;
		  required:
			  #( 'name' 'className' 'location' 'subdirectory' 'branchName'
			     'headDescription' 'isMissing' 'isModified' 'packageNames'
			     'modifiedPackageNames' 'remoteNames' );
		  additionalProperties: false;
		  yourself
]

{ #category : 'private - schema' }
MCPToolFindRepositories >> repositoryFilterInputProperties [

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
MCPToolFindRepositories >> repositoryInfoDataProperties [

	^ {
		  (self
			   schemaPropertyNamed: 'name'
			   type: 'string'
			   description: 'The Iceberg repository name in the image.').
		  (self
			   schemaPropertyNamed: 'className'
			   type: 'string'
			   description: 'The concrete Iceberg repository class name.').
		  (self
			   schemaPropertyNamed: 'location'
			   type: 'string'
			   description:
			   'The repository location path on disk, when available.').
		  (self
			   schemaPropertyNamed: 'subdirectory'
			   type: 'string'
			   description:
			   'The repository subdirectory used for packages, when any.').
		  (self
			   schemaPropertyNamed: 'branchName'
			   type: 'string'
			   description: 'The current branch name, when available.').
		  (self
			   schemaPropertyNamed: 'headDescription'
			   type: 'string'
			   description:
			   'A short description of the current head, when available.').
		  (self
			   booleanSchemaPropertyNamed: 'isMissing'
			   description: 'Whether the repository location is missing.').
		  (self
			   booleanSchemaPropertyNamed: 'isModified'
			   description:
			   'Whether the image working copy has repository changes.').
		  (self
			   stringArraySchemaNamed: 'packageNames'
			   description: 'The package names managed by the repository.'
			   itemDescription: 'A package name.').
		  (self
			   stringArraySchemaNamed: 'modifiedPackageNames'
			   description: 'The managed package names with image changes.'
			   itemDescription: 'A modified package name.').
		  (self
			   stringArraySchemaNamed: 'remoteNames'
			   description:
			   'Read-only remote names configured for the repository.'
			   itemDescription: 'A remote name.') }
]

{ #category : 'private - results' }
MCPToolFindRepositories >> repositoryScopeSummaryForAssociations: scopeAssociations [

	| labels |
	labels := OrderedCollection new.
	scopeAssociations do: [ :eachAssociation |
		eachAssociation value ifTrue: [
			self addScopeLabel: eachAssociation key to: labels ] ].
	^ self scopeSummaryFromLabels: labels
]

{ #category : 'private - results' }
MCPToolFindRepositories >> repositoryScopeSummaryForRequest: queryRequest [

	^ self repositoryScopeSummaryForAssociations: {
			  ('repositories' -> queryRequest repositoryNames notEmpty).
			  ('directories' -> queryRequest directoryPaths notEmpty).
			  ('packages' -> queryRequest packageNames notEmpty).
			  ('modified-state' -> queryRequest isModified notNil).
			  ('missing-state' -> queryRequest isMissing notNil) }
]

{ #category : 'private - template' }
MCPToolFindRepositories >> requestedContextFromRequest: request [

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
			    ('missing-state' -> (request hasArgumentNamed: 'isMissing')) })) }
		  asDictionary
]

{ #category : 'private - template' }
MCPToolFindRepositories >> successSummaryForQueryRequest: queryRequest page: page [

	^ self
		  successSummaryForScope:
		  (self repositoryScopeSummaryForRequest: queryRequest)
		  page: page
]

{ #category : 'private - results' }
MCPToolFindRepositories >> successSummaryForScope: scopeSummary page: page [

	^ self
		  scopeQuerySuccessSummaryFor: 'repositories'
		  scope: scopeSummary
		  page: page
]

{ #category : 'private - request' }
MCPToolFindRepositories >> supportedFilterTargets [

	^ #( 'name' 'class' 'location' 'directory' 'subdirectory'
	     'branch' 'head' 'package' 'modifiedPackage' 'remote' )
]
