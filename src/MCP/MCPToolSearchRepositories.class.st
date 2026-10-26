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
		              (self
			               booleanSchemaPropertyNamed: 'isModified'
			               description: 'Keep only repositories the image holds changes for, or only those it does not.').
		              (self
			               booleanSchemaPropertyNamed: 'isMissing'
			               description: 'Keep only repositories whose checkout directory is gone, or only those still on disk.').
		              self offsetInputProperty }.
	^ self queryInputSchemaWithProperties: properties
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> classNamesForRepositoryEntry: anEntry [

	| classNames |
	classNames := OrderedCollection new.
	(anEntry at: #packages) do: [ :packageName |
			PackageOrganizer default
				packageNamed: packageName asSymbol
				ifPresent: [ :package | package definedClasses do: [ :class | classNames add: class name asString ] ] ].
	^ classNames asArray
]

{ #category : 'defaults' }
MCPToolSearchRepositories >> defaultPageLimit [
	"A repository entry carries an absolute path and its modified packages, so a page holds fewer."

	^ 10
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
	fieldName = 'package' ifTrue: [ ^ anEntry at: #packages ].
	fieldName = 'class' ifTrue: [ ^ self classNamesForRepositoryEntry: anEntry ].
	fieldName = 'modifiedPackage' ifTrue: [ ^ anEntry at: #modifiedPackages ].
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
MCPToolSearchRepositories >> repositoryFieldFilterInputProperties [

	^ {
		  (self repositoryTextFilterPropertyNamed: 'name' description: 'Keep repositories whose name contains this text, ignoring case.').
		  (self
			   repositoryTextFilterPropertyNamed: 'location'
			   description: 'Keep repositories whose checkout path contains this text, ignoring case.').
		  (self
			   repositoryTextFilterPropertyNamed: 'subdirectory'
			   description: 'Keep repositories whose source subdirectory contains this text, ignoring case.').
		  (self
			   repositoryTextFilterPropertyNamed: 'package'
			   description: 'Keep repositories managing a package whose name contains this text, ignoring case.').
		  (self
			   repositoryTextFilterPropertyNamed: 'class'
			   description: 'Keep repositories whose managed packages hold a class whose name contains this text, ignoring case.').
		  (self
			   repositoryTextFilterPropertyNamed: 'modifiedPackage'
			   description: 'Keep repositories holding a modified package whose name contains this text, ignoring case.') }
]

{ #category : 'private - request' }
MCPToolSearchRepositories >> repositoryFilterFieldNames [

	^ #( 'name' 'location' 'subdirectory' 'package' 'class' 'modifiedPackage' )
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
			  ('modified-state' -> queryRequest isModified isNotNil).
			  ('missing-state' -> queryRequest isMissing isNotNil).
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
