"
Tests for the repository specs and package describer, and for what the repository tools read from their request and put in their answers.
"
Class {
	#name : 'MCPRepositorySpecTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPRepositorySpecTest >> refusalFor: aReference [
	"What resolving aReference refuses with, nil when it resolves."

	^ [
		  aReference repository.
		  nil ]
		  on: MCPCommandError
		  do: [ :error | error messageText ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testAMissingRepositoryAmongManySuggestsTheClosestNames [
	"Past a few registered repositories, the refusal names those closest to the name asked for, or how many there are when none is close."

	| repositories |
	repositories := (1 to: 6) collect: [ :index |
			                self
				                newRepositoryNamed: 'Repo' , index printString
				                location: FileLocator imageDirectory / ('repo' , index printString)
				                packageNames: #(  ) ].
	self withRepositories: repositories do: [
			self
				assert: (self refusalFor: (MCPRepositoryReferenceSpec name: 'Repo7' location: nil))
				equals: 'No repository named Repo7 is registered. Did you mean: Repo1, Repo2, Repo3, Repo4, Repo5?'.
			self
				assert: (self refusalFor: (MCPRepositoryReferenceSpec name: 'Zzqxw' location: nil))
				equals: 'No repository named Zzqxw is registered. 6 repositories are registered: repository_search lists them.' ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testAMissingRepositoryNamesTheRegisteredOnes [
	"A name no registered repository has is refused saying what is registered: none, the few there are, or the same name at another location."

	| alpha beta |
	alpha := self newRepositoryNamed: 'Alpha' location: FileLocator imageDirectory / 'alpha' packageNames: #(  ).
	beta := self newRepositoryNamed: 'Beta' location: FileLocator imageDirectory / 'beta' packageNames: #(  ).
	self withRepositories: #(  ) do: [
			self
				assert: (self refusalFor: (MCPRepositoryReferenceSpec name: 'ZooKeeping' location: nil))
				equals: 'No repository named ZooKeeping is registered. The image has none: repository_attach registers an existing checkout.' ].
	self
		withRepositories: {
				alpha.
				beta }
		do: [
				self
					assert: (self refusalFor: (MCPRepositoryReferenceSpec name: 'Gamma' location: nil))
					equals: 'No repository named Gamma is registered. Registered: Alpha, Beta.'.
				self
					assert: (self refusalFor: (MCPRepositoryReferenceSpec name: 'Alpha' location: '/nowhere'))
					equals:
					('No repository named Alpha is registered at /nowhere. Alpha is registered at {1}.' format: { alpha location pathString }).
				self
					assert: (self refusalFor: (MCPRepositoryReferenceSpec name: nil location: '/nowhere'))
					equals: 'No repository is registered at /nowhere. Registered: Alpha, Beta.' ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testAdoptHeadNamesThePackagesItUnmarks [
	"Adopting clears the marks where the image holds what HEAD holds, so the answer names those the info before held and the repository no longer does, and those still marked, whose changes HEAD lacks."

	| afterInfo beforeInfo data repository tool unmarked |
	tool := MCPToolAdoptRepositoryHead new.
	repository := MCPTestIceRepository named: 'MCP Adopt Head Repository' location: FileSystem memory / 'adopt-head'.
	repository modifiedPackageNames: #( 'MCP' 'MCP-Tests' ).
	beforeInfo := MCPRepositoryInfo fromRepository: repository.
	repository modifiedPackageNames: #( 'MCP-Tests' ).
	afterInfo := MCPRepositoryInfo fromRepository: repository.
	unmarked := tool packageNamesMarkedIn: beforeInfo andNotIn: afterInfo.
	data := tool dataForUnmarkedPackageNames: unmarked modifiedPackageNames: afterInfo modifiedPackageNames.
	self assert: data keys asSet equals: #( unmarkedPackages modifiedPackages ) asSet.
	self assert: (data at: #unmarkedPackages) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPackages) equals: #( 'MCP-Tests' ).
	self
		assert: (tool
				 summaryForAdopting: (MCPIcebergCommitInfo idStringFrom: (MCPTestRepositoryCommit id: 'after'))
				 in: afterInfo
				 moved: true
				 unmarking: unmarked)
		equals:
		'Repository MCP Adopt Head Repository now refers to HEAD after on branch main, and no longer marks MCP as modified. It marks MCP-Tests as modified: the image differs from HEAD there.'.
	self deny: afterInfo isDetachedHead
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testAdoptHeadReadsItsRequest [

	| request tool |
	tool := MCPToolAdoptRepositoryHead new.
	request := tool requestFromToolCallArguments: {
			           (#repository -> 'MCP Repo').
			           (#branch -> 'main') } asDictionary.
	self assert: (tool mutationActionFor: request checked: true) equals: 'adoptHead'.
	self assert: (tool repositoryReferenceFor: request) name equals: 'MCP Repo'.
	self assert: (tool expectedBranchNameIn: request) equals: 'main'.
	self assert: ((tool requestedContextFor: request checked: true) at: #branch) equals: 'main'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testAnAmbiguousRepositoryNamesEachMatchWithItsLocation [
	"Two registrations under one name are told apart by location, which the refusal names; a reference naming nothing says which arguments name one."

	| first second |
	first := self newRepositoryNamed: 'Alpha' location: FileLocator imageDirectory / 'alpha-1' packageNames: #(  ).
	second := self newRepositoryNamed: 'Alpha' location: FileLocator imageDirectory / 'alpha-2' packageNames: #(  ).
	self
		withRepositories: {
				second.
				first }
		do: [
				self
					assert: (self refusalFor: (MCPRepositoryReferenceSpec name: 'Alpha' location: nil))
					equals: ('More than one registered repository matches: Alpha at {1}, Alpha at {2}. Pass location to choose one.' format: {
								 first location pathString.
								 second location pathString }).
				self
					assert: (self refusalFor: (MCPRepositoryReferenceSpec name: nil location: nil))
					equals: 'Repository tools require repository.' ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testAttachReadsItsRequest [

	| context request tool |
	tool := MCPToolAttachRepository new.
	request := tool requestFromToolCallArguments: {
			           (#repository -> 'MCP Repo').
			           (#location -> 'C:/src/MCP').
			           (#subdirectory -> 'src').
			           (#packages -> #( 'MCP' 'MCP-Tests' )) } asDictionary.
	context := tool requestedContextFor: request checked: true.
	self assert: (tool mutationActionFor: request checked: true) equals: 'attach'.
	self assert: (context at: #name) equals: 'MCP Repo'.
	self assert: (context at: #location) equals: 'C:/src/MCP'.
	self assert: (context at: #subdirectory) equals: 'src'.
	self assert: (context at: #packages) equals: #( 'MCP' 'MCP-Tests' )
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testCommitDataNamesPackagesAndOtherFiles [

	| data tool |
	tool := MCPToolCommitRepository new.
	data := tool dataForPackageNames: #( 'MCP' ) otherFiles: #( '.project' ).
	self assert: data keys asSet equals: #( packages otherFiles ) asSet.
	self assert: (data at: #packages) equals: #( 'MCP' ).
	self assert: (data at: #otherFiles) equals: #( '.project' ).
	self assert: (tool dataForPackageNames: #(  ) otherFiles: #(  )) isEmpty
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testDiffDataAndSummaryNameTheChanges [

	| data repository tool |
	tool := MCPToolListRepositoryChanges new.
	repository := self newRepositoryNamed: 'MCP Diff Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	data := tool dataForImageModifiedPackages: #( 'MCP' ) modifiedPaths: #( 'src/MCP.package' ).
	self assert: data keys asSet equals: #( imageModifiedPackages modifiedPaths ) asSet.
	self assert: (data at: #imageModifiedPackages) equals: #( 'MCP' ).
	self assert: (data at: #modifiedPaths) equals: #( 'src/MCP.package' ).
	self
		assert: (tool summaryForChangesOf: repository imageModifiedPackages: #( 'MCP' ) modifiedPaths: #( 'src/MCP.package' ))
		equals: 'Repository MCP Diff Repository has uncommitted changes.'.
	self
		assert: (tool summaryForChangesOf: repository imageModifiedPackages: #(  ) modifiedPaths: #(  ))
		equals: 'Repository MCP Diff Repository has no uncommitted changes: the image matches its files and git sees none.'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testExportDataNamesWrittenAndDeletedPaths [

	| data tool |
	tool := MCPToolExportRepository new.
	data := tool
		        dataForPackageNames: #( 'MCP' )
		        writtenPaths: #( 'src/MCP/MCPTool.class.st' )
		        deletedPaths: #( 'src/MCP/MCPGone.class.st' )
		        alsoUncommittedPaths: #( 'README.md' ).
	self assert: data keys asSet equals: #( packages written deleted alsoUncommitted ) asSet.
	self assert: (data at: #packages) equals: #( 'MCP' ).
	self assert: (data at: #written) equals: #( 'src/MCP/MCPTool.class.st' ).
	self assert: (data at: #deleted) equals: #( 'src/MCP/MCPGone.class.st' ).
	self assert: (data at: #alsoUncommitted) equals: #( 'README.md' ).
	self assert: (tool
			 dataForPackageNames: #(  )
			 writtenPaths: #(  )
			 deletedPaths: #(  )
			 alsoUncommittedPaths: #(  )) isEmpty
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testMutationToolsReadTheirRequests [

	| context request tool |
	tool := MCPToolCreateRepository new.
	request := tool requestFromToolCallArguments: {
			           (#repository -> 'MCP Repo').
			           (#location -> 'C:/src/MCP').
			           (#subdirectory -> 'src').
			           (#packages -> #( 'MCP' 'MCP-Tests' )) } asDictionary.
	context := tool requestedContextFor: request checked: true.
	self assert: (tool mutationActionFor: request checked: true) equals: 'create'.
	self assert: (context at: #name) equals: 'MCP Repo'.
	self assert: (context at: #location) equals: 'C:/src/MCP'.
	self assert: (context at: #subdirectory) equals: 'src'.
	self assert: (context at: #packages) equals: #( 'MCP' 'MCP-Tests' ).
	tool := MCPToolUpdateRepository new.
	request := tool requestFromToolCallArguments: {
			           (#repository -> 'MCP Repo').
			           (#subdirectory -> 'src').
			           (#addPackages -> #( 'New-Package' )).
			           (#removePackages -> #( 'Old-Package' )) } asDictionary.
	self assert: (tool mutationActionFor: request checked: true) equals: 'update'.
	self assert: (tool repositoryReferenceFor: request) name equals: 'MCP Repo'.
	self deny: (tool suppliedUpdateArgumentNamesIn: request) isEmpty.
	self
		assert: ((tool requestedContextFor: request checked: true) at: #updateActions)
		equals: #( 'setSubdirectory' 'addPackages' 'removePackages' ).
	tool := MCPToolExportRepository new.
	request := tool requestFromToolCallArguments: { (#repository -> 'MCP Repo') } asDictionary.
	self assert: (tool mutationActionFor: request checked: true) equals: 'export'.
	self assert: (tool repositoryReferenceFor: request) name equals: 'MCP Repo'.
	tool := MCPToolListRepositoryChanges new.
	request := tool requestFromToolCallArguments: { (#repository -> 'MCP Repo') } asDictionary.
	self assert: (tool mutationActionFor: request checked: true) equals: 'diff'.
	self assert: (tool repositoryReferenceFor: request) name equals: 'MCP Repo'.
	tool := MCPToolCommitRepository new.
	request := tool requestFromToolCallArguments: {
			           (#repository -> 'MCP Repo').
			           (#message -> 'Commit from test') } asDictionary.
	self assert: (tool mutationActionFor: request checked: true) equals: 'commit'.
	self assert: (tool messageIn: request) equals: 'Commit from test'.
	self assert: ((tool requestedContextFor: request checked: true) at: #message) equals: 'Commit from test'.
	tool := MCPToolReloadRepository new.
	request := tool requestFromToolCallArguments: { (#repository -> 'MCP Repo') } asDictionary.
	self assert: (tool mutationActionFor: request checked: true) equals: 'reload'.
	self assert: (tool repositoryReferenceFor: request) name equals: 'MCP Repo'
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testReloadDataNamesThePackages [

	| reloadData tool |
	tool := MCPToolReloadRepository new.
	reloadData := tool dataForPackageNames: #( 'MCP' 'MCP-Tests' ).
	self assert: reloadData keys asSet equals: #( packages ) asSet.
	self assert: (reloadData at: #packages) equals: #( 'MCP' 'MCP-Tests' ).
	self assert: (tool dataForPackageNames: #(  )) isEmpty
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testRepositoryReferenceResolvesByNameAndLocation [

	| repository reference |
	repository := self newRepositoryNamed: 'MCP Reference Repository' location: FileLocator imageDirectory packageNames: #( 'MCP' ).
	self withRepositories: { repository } do: [
			reference := MCPRepositoryReferenceSpec name: 'MCP Reference Repository' location: FileLocator imageDirectory pathString.
			self assert: reference repository identicalTo: repository.
			self assert: (reference requestedContext at: #repository) equals: 'MCP Reference Repository'.
			self assert: (reference requestedContext at: #location) equals: FileLocator imageDirectory pathString ]
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testVerifyIdentityReadsItsRequest [

	| context reference request tool |
	tool := MCPToolVerifyRepositoryIdentity new.
	request := tool requestFromToolCallArguments: {
			           (#repository -> 'MCP Repo').
			           (#location -> '/tmp/MCP').
			           (#branch -> 'main').
			           (#subdirectory -> 'src').
			           (#packages -> #( 'MCP' 'MCP-Tests' )).
			           (#modifiedPackages -> #( 'MCP' )).
			           (#isModified -> true) } asDictionary.
	context := tool requestedContextFor: request checked: true.
	reference := tool repositoryReferenceFor: request.
	self assert: (tool mutationActionFor: request checked: true) equals: 'verifyIdentity'.
	self assert: reference name equals: 'MCP Repo'.
	self assert: reference location equals: '/tmp/MCP'.
	self assert: (context at: #branch) equals: 'main'.
	self assert: (context at: #subdirectory) equals: 'src'.
	self assert: (context at: #packages) equals: #( 'MCP' 'MCP-Tests' ).
	self assert: (context at: #modifiedPackages) equals: #( 'MCP' ).
	self assert: (context at: #isModified) equals: true
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testVerifyIdentitySuccessAnswersNoData [
	"A mismatch is an error, so a success carries no data and its summary names the fields that held."

	| repository result tool |
	repository := MCPTestIceRepository named: 'MCP VerifyIdentity Repository' location: FileSystem memory / 'verifyIdentity'.
	repository workingCopy packageNames: #( 'MCP-Tests' 'MCP' ).
	repository modifiedPackageNames: #( 'MCP' ).
	tool := MCPToolVerifyRepositoryIdentity new.
	self withRepositories: { repository } do: [
			result := tool executeWithRequest: (tool requestFromToolCallArguments: {
						           (#repository -> repository name).
						           (#branch -> 'main').
						           (#packages -> #( 'MCP' 'MCP-Tests' )).
						           (#isModified -> true) } asDictionary) ].
	self deny: result isError.
	self assert: (result structuredContent at: #data) isEmpty.
	self
		assert: (result structuredContent at: #summary)
		equals: 'Verified repository MCP VerifyIdentity Repository: branch, packages, isModified as expected.'
]
