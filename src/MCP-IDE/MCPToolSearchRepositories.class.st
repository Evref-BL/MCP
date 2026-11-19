"
Lists Iceberg repositories registered in the image.

The tool is read-only. It supports direct filters for repository names, locations, package names, modified state, and missing state, plus generic field filtering and pagination.
"
Class {
	#name : 'MCPToolSearchRepositories',
	#superclass : 'MCPToolSearch',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
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

	^ #( 'repository' 'repositories' 'repo' 'iceberg' 'package' 'packages' 'class' 'classes' 'status' 'modified' 'dirty' 'committed'
	     'uncommitted' 'unsaved' )
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
			self packageOrganizer
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
MCPToolSearchRepositories >> entryNameKeys [
	"A row is a repository."

	^ #( name )
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> failureScopePhraseFromRequest: request [

	^ 'the image'
]

{ #category : 'private - request' }
MCPToolSearchRepositories >> fieldFilterNames [

	^ #( 'query' 'location' 'subdirectory' 'package' 'class' 'modifiedPackage' )
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> fieldTextsForRepositoryEntry: anEntry fieldName: fieldName [

	fieldName = 'query' ifTrue: [ ^ { (anEntry at: #name) } ].
	fieldName = 'location' ifTrue: [ ^ { (anEntry at: #location) } ].
	fieldName = 'subdirectory' ifTrue: [ ^ { (anEntry at: #subdirectory) } ].
	fieldName = 'package' ifTrue: [ ^ anEntry at: #packages ].
	fieldName = 'class' ifTrue: [ ^ self classNamesForRepositoryEntry: anEntry ].
	fieldName = 'modifiedPackage' ifTrue: [ ^ anEntry at: #modifiedPackages ].
	^ #(  )
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> filtersRequest: request [
	"Its filters are its fields and the two states it can keep."

	^ (self fieldFiltersFromRequest: request) isNotEmpty or: [
		  self stateNames anySatisfy: [ :each | request hasArgumentNamed: each ] ]
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> queryEntriesForRequest: request scopeQuery: scopeQuery [
	"The repositories registered with the image that keep the states and hold the field filters, ignoring case, by name."

	| entries fieldFilters |
	fieldFilters := self fieldFiltersFromRequest: request.
	entries := OrderedCollection new.
	IceRepository repositories do: [ :eachRepository |
			| repositoryInfo |
			repositoryInfo := MCPRepositoryInfo fromRepository: eachRepository.
			(self repositoryEntry: repositoryInfo asQueryDictionary matches: request fieldFilters: fieldFilters) ifTrue: [
				entries add: repositoryInfo asSearchDictionary ] ].
	^ entries asArray sort: [ :left :right | (left at: #name) <= (right at: #name) ]
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> queryResultDataForPage: page [

	^ page asDictionaryWithEntriesKey: #repositories
]

{ #category : 'private - filtering' }
MCPToolSearchRepositories >> repositoryEntry: anEntry matches: request fieldFilters: fieldFilters [

	self stateNames do: [ :stateName |
			(request hasArgumentNamed: stateName) ifTrue: [
				(anEntry at: stateName asSymbol) = (request booleanArgumentNamed: stateName) ifFalse: [ ^ false ] ] ].
	^ self
		  fieldFilters: fieldFilters
		  matchUsing: [ :fieldName | self fieldTextsForRepositoryEntry: anEntry fieldName: fieldName ]
		  mode: self defaultFilterMode
		  caseSensitive: false
]

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryFieldFilterInputProperties [

	^ {
		  (self
			   repositoryTextFilterPropertyNamed: 'query'
			   description: 'Keep repositories whose name contains this text, ignoring case.').
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

{ #category : 'private - schema' }
MCPToolSearchRepositories >> repositoryTextFilterPropertyNamed: propertyName description: descriptionString [

	^ self schemaPropertyNamed: propertyName type: 'string' description: descriptionString
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> scopePhraseForScopeQuery: scopeQuery [
	"Repositories are registered with the image, so the image is where this looks."

	^ 'the image'
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> scopeQueryFromRequest: request [
	"Repositories are registered with the image, which has no scope to narrow it to."

	^ nil
]

{ #category : 'private - template' }
MCPToolSearchRepositories >> searchedNoun [

	^ 'repository'
]

{ #category : 'private - request' }
MCPToolSearchRepositories >> stateNames [
	"The states a caller keeps by naming them, true or false. Left out, a state keeps every repository."

	^ #( 'isModified' 'isMissing' )
]

{ #category : 'metadata' }
MCPToolSearchRepositories >> title [

	^ 'Search Repositories'
]

{ #category : 'private - results' }
MCPToolSearchRepositories >> warningsForScopeQuery: scopeQuery [
	"With no scope, there is no name in it that could fail to resolve."

	^ #(  )
]
