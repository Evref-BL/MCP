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
MCPRepositorySpecTest >> testRepositoryAdoptHeadRequestParsesTypedInput [

	| adoptHeadRequest |
	adoptHeadRequest := MCPRepositoryAdoptHeadRequest
		                    fromRequest: (self requestWithArguments: {
					                     (#repositoryName -> 'MCP Repo').
					                     (#branchName -> 'main') } asDictionary)
		                    tool: nil.
	self assert: adoptHeadRequest operation equals: 'adoptHead'.
	self
		assert: adoptHeadRequest repositoryReference name
		equals: 'MCP Repo'.
	self assert: adoptHeadRequest branchName equals: 'main'.
	self
		assert: (adoptHeadRequest requestedContext at: #branchName)
		equals: 'main'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryAdoptHeadResultReturnsDictionary [

	| data repository result |
	repository := MCPTestIceRepository
		              named: 'MCP Adopt Head Repository'
		              location: 'memory://adopt-head'.
	repository modifiedPackageNames: #( 'MCP' ).
	repository workingCopy referenceCommit:
		(MCPTestRepositoryCommit id: 'after').
	result := MCPRepositoryAdoptHeadResult
		          repositoryBefore:
		          (MCPRepositoryInfo fromRepository: repository)
		          after: repository
		          previousReferenceCommit:
		          (MCPTestRepositoryCommit id: 'before')
		          adoptedCommit: (MCPTestRepositoryCommit id: 'after')
		          didAdopt: true.
	data := result asDictionary.
	self
		assert: data keys asSet
		equals:
			#( adoptedCommitId branchName didAdopt headDescription
			   modifiedPackageNamesAfter modifiedPackageNamesBefore
			   previousReferenceCommitId referenceCommitId ) asSet.
	self assert: (data at: #previousReferenceCommitId) equals: 'before'.
	self assert: (data at: #referenceCommitId) equals: 'after'.
	self assert: (data at: #adoptedCommitId) equals: 'after'.
	self assert: (data at: #didAdopt).
	self
		assert: (data at: #modifiedPackageNamesBefore)
		equals: #( 'MCP' ).
	self assert: (data at: #modifiedPackageNamesAfter) equals: #( 'MCP' ).
	self assert: (data at: #branchName) equals: 'main'.
	self assert: (data at: #headDescription) equals: 'initial'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryAttachRequestParsesTypedInput [

	| attachRequest |
	attachRequest := MCPRepositoryAttachRequest
		                 fromRequest: (self requestWithArguments: {
					                  (#name -> 'MCP Repo').
					                  (#location -> 'C:/src/MCP').
					                  (#subdirectory -> 'src').
					                  (#packageNames -> #( 'MCP' 'MCP-Tests' )) }
					                  asDictionary)
		                 tool: nil.
	self assert: attachRequest operation equals: 'attach'.
	self assert: attachRequest name equals: 'MCP Repo'.
	self assert: attachRequest location equals: 'C:/src/MCP'.
	self assert: attachRequest subdirectory equals: 'src'.
	self
		assert: attachRequest packageNames
		equals: #( 'MCP' 'MCP-Tests' )
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
	self assert: data keys asSet equals: #( changedPackageNames ) asSet.
	self assert: (data at: #changedPackageNames) equals: #( 'MCP' )
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryCreateUpdateExportRequestsParseTypedInput [

	| commitRequest createBranchRequest createRequest diffRequest exportRequest fetchRequest pullRequest pushRequest switchBranchRequest updateRequest |
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
	self assert: switchBranchRequest branchName equals: 'main'
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
		assert: data keys asSet
		equals:
		#( changeCount changedPackageNames isEmpty modifiedPaths ) asSet.
	self assert: (data at: #changedPackageNames) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPaths) equals: #( 'src/MCP.package' ).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (data at: #isEmpty) equals: false
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
		assert: data keys asSet
		equals: #( changedPackageNames didChange modifiedPaths ) asSet.
	self assert: (data at: #changedPackageNames) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPaths) equals: #( 'src/MCP.package' ).
	self assert: (data at: #didChange) equals: true
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryPackageInfoReturnsDictionary [

	| packageData repository |
	repository := self
		              newRepositoryNamed: 'MCP Package Info Repository'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCP' ).
	packageData := (MCPRepositoryPackageInfo fromPackage:
		                repository workingCopy packages first) asDictionary.
	self assert: (packageData at: #name) equals: 'MCP'.
	self assert: (packageData includesKey: #directoryName).
	self assert: (packageData includesKey: #isLoaded).
	self assert: (packageData includesKey: #isModified)
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryQuerySpecParsesOptionalBooleanFilters [

	| request spec tool |
	tool := MCPToolSearchRepositories new.
	request := MCPToolRequest tool: tool arguments: {
			           (#isModified -> false).
			           (#repositoryName -> 'MCP').
			           (#limit -> 5) } asDictionary.
	spec := tool searchRequestFromToolRequest: request.
	self assert: spec class equals: MCPRepositoryQuerySpec.
	self assert: spec isModified equals: false.
	self assert: spec isMissing isNil.
	self assert: (spec fieldFilters at: 'repositoryName') equals: 'MCP'.
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

	MCPTestGitRepositoryFixture
		withConfig: MCPTestGitRepositoryFixture standardConfig
		do: [ :repositoryDirectory |
				| branchData branchResult beforeInfo fetchData fetchResult pullData pullResult pushData pushResult repository |
				repository := MCPTestIceRepository
					              named: 'MCP Remote Repository'
					              location: repositoryDirectory pathString.
				repository modifiedPackageNames: #( 'MCP-Modified' ).
				beforeInfo := MCPRepositoryInfo fromRepository: repository.
				repository branchName: 'feature'.
				repository headDescription: 'after'.
				fetchResult := MCPRepositoryFetchResult
					               repositoryBefore: beforeInfo
					               after: repository.
				fetchData := fetchResult asDictionary.
				self
					assert: fetchData keys asSet
					equals: #( branchName headDescription ) asSet.
				self assert: (fetchData at: #branchName) equals: 'feature'.
				self assert: (fetchData at: #headDescription) equals: 'after'.
				pullResult := MCPRepositoryPullResult
					              repositoryBefore: beforeInfo
					              after: repository.
				pullData := pullResult asDictionary.
				self
					assert: pullData keys asSet
					equals:
					#( branchName headDescription modifiedPackageNames ) asSet.
				self
					assert: (pullData at: #modifiedPackageNames)
					equals: #( 'MCP-Modified' ).
				self assert: (pullData at: #headDescription) equals: 'after'.
				pushResult := MCPRepositoryPushResult repository: repository.
				pushData := pushResult asDictionary.
				self
					assert: pushData keys asSet
					equals: #( branchName headDescription ) asSet.
				self assert: (pushData at: #branchName) equals: 'feature'.
				self assert: (pushData at: #headDescription) equals: 'after'.
				branchResult := MCPRepositoryBranchResult
					                repositoryBefore: beforeInfo
					                after: repository.
				branchData := branchResult asDictionary.
				self
					assert: branchData keys asSet
					equals:
						#( branchName headDescription previousBranchName
						   previousHeadDescription ) asSet.
				self assert: (branchData at: #previousBranchName) equals: 'main'.
				self assert: (branchData at: #branchName) equals: 'feature'.
				self
					assert: (branchData at: #previousHeadDescription)
					equals: 'initial'.
				self assert: (branchData at: #headDescription) equals: 'after' ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryVerifyIdentityRequestParsesTypedInput [

	| context verifyIdentityRequest |
	verifyIdentityRequest := MCPRepositoryVerifyIdentityRequest
		                         fromRequest: (self requestWithArguments: {
					                          (#repositoryName -> 'MCP Repo').
					                          (#location -> '/tmp/MCP').
					                          (#branchName -> 'main').
					                          (#subdirectory -> 'src').
					                          (#packageNames
					                           -> #( 'MCP' 'MCP-Tests' )).
					                          (#modifiedPackageNames -> #( 'MCP' )).
					                          (#isModified -> true) } asDictionary)
		                         tool: nil.
	context := verifyIdentityRequest requestedContext.
	self assert: verifyIdentityRequest operation equals: 'verifyIdentity'.
	self
		assert: verifyIdentityRequest repositoryReference name
		equals: 'MCP Repo'.
	self
		assert: verifyIdentityRequest repositoryReference location
		equals: '/tmp/MCP'.
	self assert: verifyIdentityRequest branchName equals: 'main'.
	self assert: verifyIdentityRequest subdirectory equals: 'src'.
	self
		assert: verifyIdentityRequest packageNames
		equals: #( 'MCP' 'MCP-Tests' ).
	self
		assert: verifyIdentityRequest modifiedPackageNames
		equals: #( 'MCP' ).
	self assert: verifyIdentityRequest isModified equals: true.
	self assert: (context at: #branchName) equals: 'main'.
	self assert: (context at: #subdirectory) equals: 'src'.
	self assert: (context at: #isModified) equals: true
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryVerifyIdentityResultReturnsDictionary [

	| data repository result |
	repository := MCPTestIceRepository
		              named: 'MCP VerifyIdentity Repository'
		              location: 'memory://verifyIdentity'.
	repository workingCopy packageNames: #( 'MCP-Tests' 'MCP' ).
	repository modifiedPackageNames: #( 'MCP' ).
	result := MCPRepositoryVerifyIdentityResult
		          repository: repository
		          checkedFields:
		          #( 'branchName' 'packageNames' 'isModified' ).
	data := result asDictionary.
	self assert: data keys asSet equals: #( matched ) asSet.
	self assert: (data at: #matched)
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
