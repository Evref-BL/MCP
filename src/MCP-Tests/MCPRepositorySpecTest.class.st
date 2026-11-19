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
MCPRepositorySpecTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each | repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'tests' }
MCPRepositorySpecTest >> testAdoptHeadNamesThePackagesItUnmarks [
	"Adopting clears the marks, so the answer names those the info before held and the repository no longer does."

	| afterInfo beforeInfo data repository tool unmarked |
	tool := MCPToolAdoptRepositoryHead new.
	repository := MCPTestIceRepository named: 'MCP Adopt Head Repository' location: 'memory://adopt-head'.
	repository modifiedPackageNames: #( 'MCP' ).
	beforeInfo := MCPRepositoryInfo fromRepository: repository.
	repository modifiedPackageNames: #(  ).
	afterInfo := MCPRepositoryInfo fromRepository: repository.
	unmarked := tool packageNamesMarkedIn: beforeInfo andNotIn: afterInfo.
	data := tool dataForUnmarkedPackageNames: unmarked.
	self assert: data keys asSet equals: #( unmarkedPackages ) asSet.
	self assert: (data at: #unmarkedPackages) equals: #( 'MCP' ).
	self
		assert: (tool
				 summaryForAdopting: (MCPIcebergCommitInfo idStringFrom: (MCPTestRepositoryCommit id: 'after'))
				 in: afterInfo
				 moved: true
				 unmarking: unmarked)
		equals: 'Repository MCP Adopt Head Repository now refers to HEAD after on branch main, and no longer marks MCP as modified.'.
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
	repository := MCPTestIceRepository named: 'MCP VerifyIdentity Repository' location: 'memory://verifyIdentity'.
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
