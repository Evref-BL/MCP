"
Tests for repository request/spec and DTO classes used by repository management tools.
"
Class {
	#name : 'MCPRepositorySpecTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPRepositorySpecTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each | repository workingCopy addPackageNamed: each ].
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
					                     (#name -> 'MCP Repo').
					                     (#branch -> 'main') } asDictionary)
		                    tool: nil.
	self assert: adoptHeadRequest operation equals: 'adoptHead'.
	self assert: adoptHeadRequest repositoryReference name equals: 'MCP Repo'.
	self assert: adoptHeadRequest branchName equals: 'main'.
	self assert: (adoptHeadRequest requestedContext at: #branch) equals: 'main'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryAdoptHeadResultReturnsDictionary [

	| data repository result |
	repository := MCPTestIceRepository named: 'MCP Adopt Head Repository' location: 'memory://adopt-head'.
	repository modifiedPackageNames: #( 'MCP' ).
	repository workingCopy referenceCommit: (MCPTestRepositoryCommit id: 'after').
	result := MCPRepositoryAdoptHeadResult
		          repositoryBefore: (MCPRepositoryInfo fromRepository: repository)
		          after: repository
		          previousReferenceCommit: (MCPTestRepositoryCommit id: 'before')
		          adoptedCommit: (MCPTestRepositoryCommit id: 'after')
		          didAdopt: true.
	data := result asDictionary.
	self
		assert: data keys asSet
		equals: #( adoptedCommitId branch didAdopt headDescription modifiedPackageNamesAfter modifiedPackageNamesBefore
			   previousReferenceCommitId referenceCommitId ) asSet.
	self assert: (data at: #previousReferenceCommitId) equals: 'before'.
	self assert: (data at: #referenceCommitId) equals: 'after'.
	self assert: (data at: #adoptedCommitId) equals: 'after'.
	self assert: (data at: #didAdopt).
	self assert: (data at: #modifiedPackageNamesBefore) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPackageNamesAfter) equals: #( 'MCP' ).
	self assert: (data at: #branch) equals: 'main'.
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
					                  (#packages -> #( 'MCP' 'MCP-Tests' )) } asDictionary)
		                 tool: nil.
	self assert: attachRequest operation equals: 'attach'.
	self assert: attachRequest name equals: 'MCP Repo'.
	self assert: attachRequest location equals: 'C:/src/MCP'.
	self assert: attachRequest subdirectory equals: 'src'.
	self assert: attachRequest packageNames equals: #( 'MCP' 'MCP-Tests' )
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryCommitResultReturnsDictionary [

	| data repository result |
	repository := self newRepositoryNamed: 'MCP Commit Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	result := (MCPRepositoryCommitResult repository: repository)
		          packageNames: #( 'MCP' );
		          otherFiles: #( '.project' );
		          yourself.
	data := result asDictionary.
	self assert: data keys asSet equals: #( packages otherFiles ) asSet.
	self assert: (data at: #packages) equals: #( 'MCP' ).
	self assert: (data at: #otherFiles) equals: #( '.project' ).
	self assert: (MCPRepositoryCommitResult repository: repository) asDictionary isEmpty
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryCreateUpdateExportRequestsParseTypedInput [

	| commitRequest createRequest diffRequest exportRequest reloadRequest updateRequest |
	createRequest := MCPRepositoryCreateRequest
		                 fromRequest: (self requestWithArguments: {
					                  (#name -> 'MCP Repo').
					                  (#location -> 'C:/src/MCP').
					                  (#subdirectory -> 'src').
					                  (#packages -> #( 'MCP' 'MCP-Tests' )) } asDictionary)
		                 tool: nil.
	self assert: createRequest operation equals: 'create'.
	self assert: createRequest name equals: 'MCP Repo'.
	self assert: createRequest location equals: 'C:/src/MCP'.
	self assert: createRequest subdirectory equals: 'src'.
	self assert: createRequest packageNames equals: #( 'MCP' 'MCP-Tests' ).
	updateRequest := MCPRepositoryUpdateRequest
		                 fromRequest: (self requestWithArguments: {
					                  (#name -> 'MCP Repo').
					                  (#subdirectory -> 'src').
					                  (#addPackages -> #( 'New-Package' )).
					                  (#removePackages -> #( 'Old-Package' )) } asDictionary)
		                 tool: nil.
	self assert: updateRequest operation equals: 'update'.
	self assert: updateRequest repositoryReference name equals: 'MCP Repo'.
	self assert: updateRequest hasUpdates.
	self assert: updateRequest requestedRepositoryUpdateActions equals: #( 'setSubdirectory' 'addPackages' 'removePackages' ).
	exportRequest := MCPRepositoryExportRequest
		                 fromRequest: (self requestWithArguments: { (#name -> 'MCP Repo') } asDictionary)
		                 tool: nil.
	self assert: exportRequest operation equals: 'export'.
	self assert: exportRequest repositoryReference name equals: 'MCP Repo'.
	diffRequest := MCPRepositoryDiffRequest
		               fromRequest: (self requestWithArguments: { (#name -> 'MCP Repo') } asDictionary)
		               tool: nil.
	self assert: diffRequest operation equals: 'diff'.
	self assert: diffRequest repositoryReference name equals: 'MCP Repo'.
	commitRequest := MCPRepositoryCommitRequest
		                 fromRequest: (self requestWithArguments: {
					                  (#name -> 'MCP Repo').
					                  (#message -> 'Commit from test') } asDictionary)
		                 tool: nil.
	self assert: commitRequest operation equals: 'commit'.
	self assert: commitRequest message equals: 'Commit from test'.
	reloadRequest := MCPRepositoryReloadRequest
		                 fromRequest: (self requestWithArguments: { (#name -> 'MCP Repo') } asDictionary)
		                 tool: nil.
	self assert: reloadRequest operation equals: 'reload'.
	self assert: reloadRequest repositoryReference name equals: 'MCP Repo'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryDiffResultReturnsDictionary [

	| data repository result |
	repository := self newRepositoryNamed: 'MCP Diff Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	result := MCPRepositoryDiffResult
		          repository: repository
		          changedPackageNames: #( 'MCP' )
		          imageModifiedPackages: #( 'MCP' )
		          modifiedPaths: #( 'src/MCP.package' ).
	data := result asDictionary.
	self assert: data keys asSet equals: #( changeCount changedPackages imageModifiedPackages isEmpty modifiedPaths ) asSet.
	self assert: (data at: #changedPackages) equals: #( 'MCP' ).
	self assert: (data at: #imageModifiedPackages) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPaths) equals: #( 'src/MCP.package' ).
	self assert: (data at: #changeCount) equals: 1.
	self assert: (data at: #isEmpty) equals: false
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryExportResultReturnsDictionary [

	| data repository result |
	repository := self newRepositoryNamed: 'MCP Export Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	result := (MCPRepositoryExportResult repository: repository)
		          packageNames: #( 'MCP' );
		          writtenPaths: #( 'src/MCP/MCPTool.class.st' );
		          deletedPaths: #( 'src/MCP/MCPGone.class.st' );
		          alsoUncommittedPaths: #( 'README.md' );
		          yourself.
	data := result asDictionary.
	self assert: data keys asSet equals: #( packages written deleted alsoUncommitted ) asSet.
	self assert: (data at: #packages) equals: #( 'MCP' ).
	self assert: (data at: #written) equals: #( 'src/MCP/MCPTool.class.st' ).
	self assert: (data at: #deleted) equals: #( 'src/MCP/MCPGone.class.st' ).
	self assert: (data at: #alsoUncommitted) equals: #( 'README.md' ).
	self assert: (MCPRepositoryExportResult repository: repository) asDictionary isEmpty
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryPackageInfoReturnsDictionary [

	| packageData repository |
	repository := self
		              newRepositoryNamed: 'MCP Package Info Repository'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCP' ).
	packageData := (MCPRepositoryPackageInfo fromPackage: repository workingCopy packages first) asDictionary.
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
		           (#name -> 'MCP') } asDictionary.
	spec := tool searchRequestFromToolRequest: request.
	self assert: spec class equals: MCPRepositoryQuerySpec.
	self assert: spec isModified equals: false.
	self assert: spec isMissing isNil.
	self assert: (spec fieldFilters at: 'name') equals: 'MCP'.
	self assert: spec limit equals: tool defaultPageLimit.
	self assert: spec offset equals: 0
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryReferenceResolvesByNameAndLocation [

	| repository reference |
	repository := self newRepositoryNamed: 'MCP Reference Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	self withRepositories: { repository } do: [
			reference := MCPRepositoryReferenceSpec name: 'MCP Reference Repository' location: FileLocator imageDirectory pathString.
			self assert: reference repository identicalTo: repository.
			self assert: (reference requestedContext at: #name) equals: 'MCP Reference Repository'.
			self assert: (reference requestedContext at: #location) equals: FileLocator imageDirectory pathString ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryReloadResultReturnsDictionary [

	MCPTestGitRepositoryFixture withConfig: MCPTestGitRepositoryFixture standardConfig do: [ :repositoryDirectory |
			| reloadData repository |
			repository := MCPTestIceRepository named: 'MCP Reload Repository' location: repositoryDirectory pathString.
			reloadData := (MCPRepositoryReloadResult repository: repository packageNames: #( 'MCP' 'MCP-Tests' )) asDictionary.
			self assert: reloadData keys asSet equals: #( packages ) asSet.
			self assert: (reloadData at: #packages) equals: #( 'MCP' 'MCP-Tests' ).
			self assert: (MCPRepositoryReloadResult repository: repository packageNames: #(  )) asDictionary isEmpty ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryVerifyIdentityRequestParsesTypedInput [

	| context verifyIdentityRequest |
	verifyIdentityRequest := MCPRepositoryVerifyIdentityRequest
		                         fromRequest: (self requestWithArguments: {
					                          (#name -> 'MCP Repo').
					                          (#location -> '/tmp/MCP').
					                          (#branch -> 'main').
					                          (#subdirectory -> 'src').
					                          (#packages -> #( 'MCP' 'MCP-Tests' )).
					                          (#modifiedPackages -> #( 'MCP' )).
					                          (#isModified -> true) } asDictionary)
		                         tool: nil.
	context := verifyIdentityRequest requestedContext.
	self assert: verifyIdentityRequest operation equals: 'verifyIdentity'.
	self assert: verifyIdentityRequest repositoryReference name equals: 'MCP Repo'.
	self assert: verifyIdentityRequest repositoryReference location equals: '/tmp/MCP'.
	self assert: verifyIdentityRequest branchName equals: 'main'.
	self assert: verifyIdentityRequest subdirectory equals: 'src'.
	self assert: verifyIdentityRequest packageNames equals: #( 'MCP' 'MCP-Tests' ).
	self assert: verifyIdentityRequest modifiedPackageNames equals: #( 'MCP' ).
	self assert: verifyIdentityRequest isModified equals: true.
	self assert: (context at: #branch) equals: 'main'.
	self assert: (context at: #subdirectory) equals: 'src'.
	self assert: (context at: #isModified) equals: true
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryVerifyIdentityResultReturnsDictionary [

	| data repository result |
	repository := MCPTestIceRepository named: 'MCP VerifyIdentity Repository' location: 'memory://verifyIdentity'.
	repository workingCopy packageNames: #( 'MCP-Tests' 'MCP' ).
	repository modifiedPackageNames: #( 'MCP' ).
	result := MCPRepositoryVerifyIdentityResult repository: repository checkedFields: #( 'branch' 'packages' 'isModified' ).
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
