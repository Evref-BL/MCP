"
Tests for repository request/spec and DTO classes used by repository management tools.
"
Class {
	#name : 'MCPRepositorySpecTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Requests',
	#package : 'MCP-Tests',
	#tag : 'Requests'
}

{ #category : 'private' }
MCPRepositorySpecTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each |
		repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'private' }
MCPRepositorySpecTest >> requestWithArguments: aDictionary [

	^ MCPToolRequest new
		  arguments: aDictionary;
		  yourself
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryCommitResultReturnsDictionary [

	| data repository result |
	repository := self
		              newRepositoryNamed: 'MCP Commit Repository'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCP' ).
	result := MCPRepositoryCommitResult
		          repository: repository
		          changedPackageNames: #( 'MCP' )
		          commit: nil.
	data := result asDictionary.
	self
		assert: ((data at: #repository) at: #name)
		equals: 'MCP Commit Repository'.
	self assert: (data at: #changedPackageNames) equals: #( 'MCP' ).
	self assert: (data includesKey: #modifiedPackageNames).
	self assert: (data at: #commitId) equals: ''.
	self assert: (data at: #commitDescription) equals: ''.
	self assert: (data includesKey: #headDescription).
	self
		assert: (data at: #repositoryLocation)
		equals: FileLocator imageDirectory pathString.
	self assert: ((data at: #packages) first at: #name) equals: 'MCP'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryCreateUpdateExportAndWriteRequestsParseTypedInput [

	| commitRequest createBranchRequest createRequest diffRequest exportRequest fetchRequest pullRequest pushRequest switchBranchRequest updateRequest writeRequest |
	createRequest := MCPRepositoryCreateRequest
		                 fromRequest: (self requestWithArguments: {
					                  (#name -> 'MCP Repo').
					                  (#location -> 'C:/src/MCP').
					                  (#subdirectory -> 'src').
					                  (#packageNames -> #( 'MCP' 'MCP-Tests' )) }
					                  asDictionary)
		                 tool: nil.
	self assert: createRequest operation equals: 'create'.
	self assert: createRequest name equals: 'MCP Repo'.
	self assert: createRequest location equals: 'C:/src/MCP'.
	self assert: createRequest subdirectory equals: 'src'.
	self
		assert: createRequest packageNames
		equals: #( 'MCP' 'MCP-Tests' ).
	updateRequest := MCPRepositoryUpdateRequest
		                 fromRequest: (self requestWithArguments: {
					                  (#repositoryName -> 'MCP Repo').
					                  (#subdirectory -> 'src').
					                  (#addPackageNames -> #( 'New-Package' )).
					                  (#removePackageNames -> #( 'Old-Package' )) }
					                  asDictionary)
		                 tool: nil.
	self assert: updateRequest operation equals: 'update'.
	self
		assert: updateRequest repositoryReference name
		equals: 'MCP Repo'.
	self assert: updateRequest hasUpdates.
	self
		assert: updateRequest requestedRepositoryUpdateActions
		equals: #( 'setSubdirectory' 'addPackages' 'removePackages' ).
	exportRequest := MCPRepositoryExportRequest
		                 fromRequest: (self requestWithArguments:
				                  { (#repositoryName -> 'MCP Repo') } asDictionary)
		                 tool: nil.
	self assert: exportRequest operation equals: 'export'.
	self
		assert: exportRequest repositoryReference name
		equals: 'MCP Repo'.
	diffRequest := MCPRepositoryDiffRequest
		               fromRequest: (self requestWithArguments:
				                { (#repositoryName -> 'MCP Repo') } asDictionary)
		               tool: nil.
	self assert: diffRequest operation equals: 'diff'.
	self assert: diffRequest repositoryReference name equals: 'MCP Repo'.
	commitRequest := MCPRepositoryCommitRequest
		                 fromRequest: (self requestWithArguments: {
					                  (#repositoryName -> 'MCP Repo').
					                  (#message -> 'Commit from test') } asDictionary)
		                 tool: nil.
	self assert: commitRequest operation equals: 'commit'.
	self assert: commitRequest message equals: 'Commit from test'.
	fetchRequest := MCPRepositoryFetchRequest
		                fromRequest: (self requestWithArguments:
				                 { (#repositoryName -> 'MCP Repo') } asDictionary)
		                tool: nil.
	self assert: fetchRequest operation equals: 'fetch'.
	pullRequest := MCPRepositoryPullRequest
		               fromRequest: (self requestWithArguments:
				                { (#repositoryName -> 'MCP Repo') } asDictionary)
		               tool: nil.
	self assert: pullRequest operation equals: 'pull'.
	pushRequest := MCPRepositoryPushRequest
		               fromRequest: (self requestWithArguments:
				                { (#repositoryName -> 'MCP Repo') } asDictionary)
		               tool: nil.
	self assert: pushRequest operation equals: 'push'.
	createBranchRequest := MCPRepositoryCreateBranchRequest
		                       fromRequest: (self requestWithArguments: {
					                        (#repositoryName -> 'MCP Repo').
					                        (#branchName -> 'feature') } asDictionary)
		                       tool: nil.
	self assert: createBranchRequest operation equals: 'createBranch'.
	self assert: createBranchRequest branchName equals: 'feature'.
	switchBranchRequest := MCPRepositorySwitchBranchRequest
		                       fromRequest: (self requestWithArguments: {
					                        (#repositoryName -> 'MCP Repo').
					                        (#branchName -> 'main') } asDictionary)
		                       tool: nil.
	self assert: switchBranchRequest operation equals: 'switchBranch'.
	self assert: switchBranchRequest branchName equals: 'main'.
	writeRequest := MCPRepositoryWriteRequest
		                fromRequest: (self requestWithArguments:
				                 { (#repositoryName -> 'MCP Repo') } asDictionary)
		                tool: nil.
	self assert: writeRequest repositoryReference name equals: 'MCP Repo'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryDiffResultReturnsDictionary [

	| data repository result |
	repository := self
		              newRepositoryNamed: 'MCP Diff Repository'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCP' ).
	result := MCPRepositoryDiffResult
		          repository: repository
		          changedPackageNames: #( 'MCP' )
		          modifiedPaths: #( 'src/MCP.package' )
		          isEmpty: false.
	data := result asDictionary.
	self
		assert: ((data at: #repository) at: #name)
		equals: 'MCP Diff Repository'.
	self assert: (data at: #changedPackageNames) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPaths) equals: #( 'src/MCP.package' ).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (data at: #isEmpty) equals: false.
	self
		assert: (data at: #repositoryLocation)
		equals: FileLocator imageDirectory pathString.
	self assert: ((data at: #packages) first at: #name) equals: 'MCP'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryExportResultReturnsDictionary [

	| data repository result |
	repository := self
		              newRepositoryNamed: 'MCP Export Repository'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCP' ).
	result := MCPRepositoryExportResult
		          repository: repository
		          changedPackageNames: #( 'MCP' )
		          modifiedPaths: #( 'src/MCP.package' ).
	result didChange: true.
	data := result asDictionary.
	self
		assert: ((data at: #repository) at: #name)
		equals: 'MCP Export Repository'.
	self assert: (data at: #changedPackageNames) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPaths) equals: #( 'src/MCP.package' ).
	self assert: (data at: #didChange) equals: true.
	self
		assert: (data at: #repositoryLocation)
		equals: FileLocator imageDirectory pathString.
	self assert: ((data at: #packages) first at: #name) equals: 'MCP'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryPackageInfoAndWriteResultReturnDictionaries [

	| data packageData repository result |
	repository := self
		              newRepositoryNamed: 'MCP Write Repository'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCP' ).
	result := MCPRepositoryWriteResult
		          repository: repository
		          writtenPackageNames: #( 'MCP' )
		          changeCount: 3.
	data := result asDictionary.
	packageData := (data at: #packages) first.
	self
		assert: ((data at: #repository) at: #name)
		equals: 'MCP Write Repository'.
	self assert: (data at: #writtenPackageNames) equals: #( 'MCP' ).
	self assert: (data at: #changeCount) equals: 3.
	self assert: (packageData at: #name) equals: 'MCP'.
	self assert: (packageData includesKey: #directoryName).
	self assert: (packageData includesKey: #isLoaded).
	self assert: (packageData includesKey: #isModified)
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryQuerySpecParsesOptionalBooleanFilters [

	| request spec tool |
	tool := MCPToolFindRepositories new.
	request := MCPToolRequest tool: tool arguments: {
			           (#isModified -> false).
			           (#filter -> 'MCP').
			           (#filterTargets -> #( 'name' )).
			           (#limit -> 5) } asDictionary.
	spec := tool queryRequestFromToolRequest: request.
	self assert: spec class equals: MCPRepositoryQuerySpec.
	self assert: spec isModified equals: false.
	self assert: spec isMissing isNil.
	self assert: spec filterPattern equals: 'MCP'.
	self assert: spec filterTargets equals: #( 'name' ).
	self assert: spec limit equals: 5.
	self assert: spec offset equals: 0
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryReferenceResolvesByNameAndLocation [

	| repository reference |
	repository := self
		              newRepositoryNamed: 'MCP Reference Repository'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCP' ).
	self withRepositories: { repository } do: [
		reference := MCPRepositoryReferenceSpec
			             name: 'MCP Reference Repository'
			             location: FileLocator imageDirectory pathString.
		self assert: reference repository identicalTo: repository.
		self
			assert: (reference requestedContext at: #repositoryName)
			equals: 'MCP Reference Repository'.
		self
			assert: (reference requestedContext at: #location)
			equals: FileLocator imageDirectory pathString ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryRemoteAndBranchResultsReturnDictionaries [

	| branchData branchResult fetchData fetchResult pullData pullResult pushData pushResult repository beforeInfo |
	repository := MCPTestIceRepository
		              named: 'MCP Remote Repository'
		              location: 'memory://remote'.
	repository remoteNames: #( 'origin' ).
	repository modifiedPackageNames: #( 'MCP-Modified' ).
	beforeInfo := MCPRepositoryInfo fromRepository: repository.
	repository branchName: 'feature'.
	repository headDescription: 'after'.
	fetchResult := MCPRepositoryFetchResult
		               repositoryBefore: beforeInfo
		               after: repository.
	fetchData := fetchResult asDictionary.
	self
		assert: ((fetchData at: #repository) at: #name)
		equals: repository name.
	self assert: (fetchData at: #remoteNames) equals: #( 'origin' ).
	self assert: (fetchData at: #branchName) equals: 'feature'.
	self assert: (fetchData includesKey: #repositoryBefore).
	pullResult := MCPRepositoryPullResult
		              repositoryBefore: beforeInfo
		              after: repository.
	pullData := pullResult asDictionary.
	self
		assert: (pullData at: #modifiedPackageNames)
		equals: #( 'MCP-Modified' ).
	self assert: (pullData at: #headDescription) equals: 'after'.
	pushResult := MCPRepositoryPushResult repository: repository.
	pushData := pushResult asDictionary.
	self assert: (pushData at: #remoteNames) equals: #( 'origin' ).
	self assert: (pushData at: #branchName) equals: 'feature'.
	branchResult := MCPRepositoryBranchResult
		                repositoryBefore: beforeInfo
		                after: repository.
	branchData := branchResult asDictionary.
	self assert: (branchData at: #previousBranchName) equals: 'main'.
	self assert: (branchData at: #branchName) equals: 'feature'.
	self
		assert: (branchData at: #previousHeadDescription)
		equals: 'initial'.
	self assert: (branchData at: #headDescription) equals: 'after'
]

{ #category : 'private' }
MCPRepositorySpecTest >> withRepositories: repositories do: aBlock [

	| previousRepositories registry |
	registry := IceRepository registry.
	previousRepositories := registry copy.
	[
	registry removeAll.
	registry addAll: repositories.
	aBlock value ] ensure: [
		registry removeAll.
		registry addAll: previousRepositories ]
]
