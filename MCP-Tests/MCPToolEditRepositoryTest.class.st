"
Tests for edit-repository create/update behavior. These tests execute the tool directly so temporary Iceberg repository registry changes are not saved by the MCP RPC wrapper.
"
Class {
	#name : 'MCPToolEditRepositoryTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private - calling' }
MCPToolEditRepositoryTest >> callToolWith: someArguments [

	| request result tool |
	tool := MCPToolEditRepository new.
	request := tool requestFromToolCallArguments: someArguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private - classes' }
MCPToolEditRepositoryTest >> createClassNamed: aClassName inPackageNamed: aPackageName [

	^ self withoutEpiceaDuring: [
		  | builder |
		  builder := Object << aClassName asSymbol.
		  builder package: aPackageName.
		  builder tag: 'Generated'.
		  builder install ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> deleteDirectoryIfExists: aFileReference [

	aFileReference exists ifTrue: [ aFileReference deleteAll ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> directChildNamesOf: aFileReference [

	^ aFileReference exists
		  ifTrue: [
		  aFileReference children collect: [ :each | each basename ] ]
		  ifFalse: [ #(  ) ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each |
		repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> newTestRepositoryNamed: aRepositoryName [

	| repository |
	repository := MCPTestIceRepository
		              named: aRepositoryName
		              location: 'memory://' , aRepositoryName.
	repository remoteNames: #( 'origin' ).
	^ repository
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> packageNamesIn: aRepository [

	^ aRepository workingCopy packageNames asArray asSortedCollection
		  asArray
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> removeRegisteredRepositoriesNamed: aRepositoryName [

	| registry repositories |
	registry := IceRepository registry.
	repositories := registry select: [ :each |
		                each name asString = aRepositoryName ].
	repositories do: [ :each | registry remove: each ifAbsent: [  ] ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> temporaryRepositoryLocationNamed: aName [

	^ FileLocator imageDirectory / aName
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testCommitCreatesCommitAndReturnsResult [

	| data location packageName repository repositoryName result |
	repositoryName := 'MCP Edit Repository Commit Test'.
	packageName := 'MCPToolEditRepositoryCommitPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestCommit'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolEditRepositoryCommitClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#operation -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each |
						              each name asString = repositoryName ].
					self assert: repository headCommit isNoCommit.
					result := self callToolWith: {
							          (#operation -> 'commit').
							          (#repositoryName -> repositoryName).
							          (#message -> 'Initial commit from MCP test') }
							          asDictionary.
					data := self dataFrom: result.
					self deny: (result at: #isError ifAbsent: [ false ]).
					self assert: (data at: #action) equals: 'commit'.
					self
						assert: (data at: #changedPackageNames)
						equals: { packageName }.
					self assert: (data at: #modifiedPackageNames) equals: #(  ).
					self assert: (data includesKey: #commitId).
					self
						assert: (data at: #commitDescription)
						equals: 'Initial commit from MCP test'.
					self assert: (data includesKey: #headDescription).
					self
						assert: (data at: #repositoryLocation)
						equals: location pathString.
					self deny: repository headCommit isNoCommit ] ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testCommitParsesAndDispatchesToCommitCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolEditRepository new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#operation -> 'commit').
			              (#repositoryName -> 'MCP').
			              (#message -> 'Commit from test') } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self assert: parsedRequest class equals: MCPRepositoryCommitRequest.
	self assert: parsedRequest message equals: 'Commit from test'.
	self assert: command class equals: MCPCommitRepositoryCommand
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testCommitReportsIcebergRefusalErrors [

	| location packageName repositoryName result |
	repositoryName := 'MCP Edit Repository Refused Commit Test'.
	packageName := 'MCPToolEditRepositoryRefusedCommitPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestRefusedCommit'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolEditRepositoryRefusedCommitClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#operation -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					self callToolWith: {
							(#operation -> 'commit').
							(#repositoryName -> repositoryName).
							(#message -> 'Initial commit from MCP test') } asDictionary.
					result := self callToolWith: {
							          (#operation -> 'commit').
							          (#repositoryName -> repositoryName).
							          (#message -> 'Second commit from MCP test') }
							          asDictionary.
					self assert: (result at: #isError ifAbsent: [ false ]).
					self assert: ((self summaryFrom: result) includesSubstring:
							 'Failed to commit repository') ] ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testCommitRequestsImageSaveAfterSuccessfulExecution [

	| location packageName repositoryName result server |
	repositoryName := 'MCP Edit Repository Commit Save Test'.
	packageName := 'MCPToolEditRepositoryCommitSavePackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestCommitSave'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolEditRepositoryCommitSaveClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#operation -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					server := MCPSaveImageRecordingServer new.
					self deny: server didSaveImageSession.
					result := server rpcToolCall: 'edit-repository' withParams: {
							          (#operation -> 'commit').
							          (#repositoryName -> repositoryName).
							          (#message -> 'Commit and save from MCP test') }
							          asDictionary.
					self deny: (result at: #isError ifAbsent: [ false ]).
					self assert: server didSaveImageSession ] ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testCreateBranchReturnsResultReportsErrorsAndRequestsImageSave [

	| data duplicateResult failureResult repository result saveResult server |
	repository := self newTestRepositoryNamed:
		              'MCP Create Branch Test Repository'.
	self withRegisteredRepository: repository do: [
		server := MCPSaveImageRecordingServer new.
		result := self callToolWith: {
				          (#operation -> 'createBranch').
				          (#repositoryName -> repository name).
				          (#branchName -> 'feature') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: repository actionLog asArray
			equals: #( 'createBranch:feature' ).
		self assert: (data at: #action) equals: 'createBranch'.
		self assert: (data at: #previousBranchName) equals: 'main'.
		self assert: (data at: #branchName) equals: 'feature'.
		self assert: (data at: #previousHeadDescription) equals: 'initial'.
		self assert: (data at: #headDescription) equals: 'branch feature'.
		saveResult := server rpcToolCall: 'edit-repository' withParams: {
				              (#operation -> 'createBranch').
				              (#repositoryName -> repository name).
				              (#branchName -> 'feature-save') } asDictionary.
		self deny: (saveResult at: #isError ifAbsent: [ false ]).
		self assert: server didSaveImageSession.
		duplicateResult := self callToolWith: {
				                   (#operation -> 'createBranch').
				                   (#repositoryName -> repository name).
				                   (#branchName -> 'feature') } asDictionary.
		self assert: (duplicateResult at: #isError ifAbsent: [ false ]).
		self assert:
			((self summaryFrom: duplicateResult) includesSubstring:
				 'Failed to create repository branch').
		self assert:
			((self summaryFrom: duplicateResult) includesSubstring:
				 'Branch already exists') ].
	repository := self newTestRepositoryNamed:
		              'MCP Create Branch Invalid Test Repository'.
	repository failCreateBranch:
		IceGenericError -> 'Invalid branch name for test repository'.
	self withRegisteredRepository: repository do: [
		failureResult := self callToolWith: {
				                 (#operation -> 'createBranch').
				                 (#repositoryName -> repository name).
				                 (#branchName -> 'invalid') } asDictionary.
		self assert: (failureResult at: #isError ifAbsent: [ false ]).
		self assert: ((self summaryFrom: failureResult) includesSubstring:
				 'Failed to create repository branch').
		self assert: ((self summaryFrom: failureResult) includesSubstring:
				 'Invalid branch name') ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testCreateCreatesAndRegistersRepository [

	| data location repository repositoryName result |
	repositoryName := 'MCP Edit Repository Create Test'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestCreate'.
	self
		withCleanRepositoryNamed: repositoryName
		location: location
		do: [
			result := self callToolWith: {
					          (#operation -> 'create').
					          (#name -> repositoryName).
					          (#location -> location pathString).
					          (#subdirectory -> 'src').
					          (#packageNames -> #( 'MCP' 'MCP-Tests' )) }
					          asDictionary.
			data := self dataFrom: result.
			repository := IceRepository repositories detect: [ :each |
				              each name asString = repositoryName ].
			self deny: (result at: #isError ifAbsent: [ false ]).
			self
				assert: repository location pathString
				equals: location pathString.
			self assert: repository subdirectory equals: 'src'.
			self
				assert: (self packageNamesIn: repository)
				equals: #( 'MCP' 'MCP-Tests' ).
			self assert: (data at: #action) equals: 'create'.
			self
				assert: ((data at: #repository) at: #name)
				equals: repositoryName.
			self
				assert: (data at: #packageNames)
				equals: #( 'MCP' 'MCP-Tests' ) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testDiffParsesAndDispatchesToDiffCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolEditRepository new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#operation -> 'diff').
			              (#repositoryName -> 'MCP') } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self assert: parsedRequest class equals: MCPRepositoryDiffRequest.
	self assert: command class equals: MCPRepositoryDiffCommand
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testDiffReportsWorkingCopyDiffWithoutWriting [

	| childNames data location packageName repository repositoryName result |
	repositoryName := 'MCP Edit Repository Diff Test'.
	packageName := 'MCPToolEditRepositoryDiffPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestDiff'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolEditRepositoryDiffClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#operation -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each |
						              each name asString = repositoryName ].
					self assert: repository headCommit isNoCommit.
					self assert: repository index isEmpty.
					result := self callToolWith: {
							          (#operation -> 'diff').
							          (#repositoryName -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					childNames := self directChildNamesOf: location.
					self deny: (result at: #isError ifAbsent: [ false ]).
					self assert: (data at: #action) equals: 'diff'.
					self assert: (data at: #isEmpty) equals: false.
					self assert: (data at: #changeCount) > 0.
					self
						assert: (data at: #changedPackageNames)
						equals: { packageName }.
					self assert: (data at: #modifiedPaths) notEmpty.
					self
						assert: (data at: #repositoryLocation)
						equals: location pathString.
					self deny:
						(childNames anySatisfy: [ :each |
							 each includesSubstring: packageName ]).
					self assert: repository index isEmpty.
					self assert: repository headCommit isNoCommit ] ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testExportUpdatesDiskAndIndexWithoutCommitting [

	| childNames data location packageName repository repositoryName result |
	repositoryName := 'MCP Edit Repository Export Test'.
	packageName := 'MCPToolEditRepositoryExportPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolEditRepositoryTestExport'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolEditRepositoryExportClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#operation -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each |
						              each name asString = repositoryName ].
					self assert: repository headCommit isNoCommit.
					self assert: repository index isEmpty.
					result := self callToolWith: {
							          (#operation -> 'export').
							          (#repositoryName -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					childNames := self directChildNamesOf: location.
					self deny: (result at: #isError ifAbsent: [ false ]).
					self assert: (data at: #action) equals: 'export'.
					self assert: (data at: #didChange) equals: true.
					self
						assert: (data at: #changedPackageNames)
						equals: { packageName }.
					self assert: (data at: #modifiedPaths) notEmpty.
					self
						assert: (data at: #repositoryLocation)
						equals: location pathString.
					self assert:
						(childNames anySatisfy: [ :each |
							 each includesSubstring: packageName ]).
					self deny: repository index isEmpty.
					self assert: repository headCommit isNoCommit ] ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testFetchReturnsResultShapeAndReportsErrors [

	| data errorResult repository result |
	repository := self newTestRepositoryNamed:
		              'MCP Fetch Test Repository'.
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'fetch').
				          (#repositoryName -> repository name) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: repository actionLog asArray
			equals: #( 'fetch:origin' ).
		self assert: (data at: #action) equals: 'fetch'.
		self assert: (data at: #remoteNames) equals: #( 'origin' ).
		self assert: (data at: #branchName) equals: 'main'.
		self assert: (data includesKey: #repositoryBefore) ].
	repository := self newTestRepositoryNamed:
		              'MCP Fetch Error Test Repository'.
	repository failFetch: true.
	self withRegisteredRepository: repository do: [
		errorResult := self callToolWith: {
				               (#operation -> 'fetch').
				               (#repositoryName -> repository name) } asDictionary.
		self assert: (errorResult at: #isError ifAbsent: [ false ]).
		self assert: ((self summaryFrom: errorResult) includesSubstring:
				 'Failed to fetch repository') ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testPullReportsIcebergMergeAndLoadErrors [

	| loadErrorResult mergeErrorResult repository |
	repository := self newTestRepositoryNamed:
		              'MCP Pull Merge Error Test Repository'.
	repository failPull:
		IceMergeAborted -> 'Iceberg merge failed for test repository'.
	self withRegisteredRepository: repository do: [
		mergeErrorResult := self callToolWith: {
				                    (#operation -> 'pull').
				                    (#repositoryName -> repository name) }
				                    asDictionary.
		self assert: (mergeErrorResult at: #isError ifAbsent: [ false ]).
		self assert:
			((self summaryFrom: mergeErrorResult) includesSubstring:
				 'Failed to pull repository').
		self assert:
			((self summaryFrom: mergeErrorResult) includesSubstring:
				 'Iceberg merge failed') ].
	repository := self newTestRepositoryNamed:
		              'MCP Pull Load Error Test Repository'.
	repository failPull:
		IceCheckoutConflictError
		-> 'Iceberg load failed for test repository'.
	self withRegisteredRepository: repository do: [
		loadErrorResult := self callToolWith: {
				                   (#operation -> 'pull').
				                   (#repositoryName -> repository name) }
				                   asDictionary.
		self assert: (loadErrorResult at: #isError ifAbsent: [ false ]).
		self assert:
			((self summaryFrom: loadErrorResult) includesSubstring:
				 'Failed to pull repository').
		self assert:
			((self summaryFrom: loadErrorResult) includesSubstring:
				 'Iceberg load failed') ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testPullReturnsResultReportsErrorsAndRequestsImageSave [

	| data errorResult repository result saveResult server |
	repository := self newTestRepositoryNamed: 'MCP Pull Test Repository'.
	self withRegisteredRepository: repository do: [
		server := MCPSaveImageRecordingServer new.
		result := self callToolWith: {
				          (#operation -> 'pull').
				          (#repositoryName -> repository name) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: repository actionLog asArray equals: #( 'pull' ).
		self assert: (data at: #action) equals: 'pull'.
		self assert: (data at: #headDescription) equals: 'after pull'.
		self
			assert: (data at: #modifiedPackageNames)
			equals: #( 'MCP-Test-Pulled' ).
		saveResult := server rpcToolCall: 'edit-repository' withParams: {
				              (#operation -> 'pull').
				              (#repositoryName -> repository name) } asDictionary.
		self deny: (saveResult at: #isError ifAbsent: [ false ]).
		self assert: server didSaveImageSession ].
	repository := self newTestRepositoryNamed:
		              'MCP Pull Error Test Repository'.
	repository failPull: true.
	self withRegisteredRepository: repository do: [
		errorResult := self callToolWith: {
				               (#operation -> 'pull').
				               (#repositoryName -> repository name) } asDictionary.
		self assert: (errorResult at: #isError ifAbsent: [ false ]).
		self assert: ((self summaryFrom: errorResult) includesSubstring:
				 'Failed to pull repository') ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testPushReportsRemoteAndAuthenticationErrors [

	| authErrorResult remoteErrorResult repository |
	repository := self newTestRepositoryNamed:
		              'MCP Push Remote Error Test Repository'.
	repository failPush: IceRemoteNotFoundError
		-> 'Iceberg remote not found for test repository'.
	self withRegisteredRepository: repository do: [
		remoteErrorResult := self callToolWith: {
				                     (#operation -> 'push').
				                     (#repositoryName -> repository name) }
				                     asDictionary.
		self assert: (remoteErrorResult at: #isError ifAbsent: [ false ]).
		self assert:
			((self summaryFrom: remoteErrorResult) includesSubstring:
				 'Failed to push repository').
		self assert:
			((self summaryFrom: remoteErrorResult) includesSubstring:
				 'Iceberg remote not found') ].
	repository := self newTestRepositoryNamed:
		              'MCP Push Authentication Error Test Repository'.
	repository failPush: IceAuthenticationError
		-> 'Iceberg authentication failed for test repository'.
	self withRegisteredRepository: repository do: [
		authErrorResult := self callToolWith: {
				                   (#operation -> 'push').
				                   (#repositoryName -> repository name) }
				                   asDictionary.
		self assert: (authErrorResult at: #isError ifAbsent: [ false ]).
		self assert:
			((self summaryFrom: authErrorResult) includesSubstring:
				 'Failed to push repository').
		self assert:
			((self summaryFrom: authErrorResult) includesSubstring:
				 'Iceberg authentication failed') ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testPushReturnsResultReportsErrorsAndRequestsImageSave [

	| data errorResult repository result saveResult server |
	repository := self newTestRepositoryNamed: 'MCP Push Test Repository'.
	self withRegisteredRepository: repository do: [
		server := MCPSaveImageRecordingServer new.
		result := self callToolWith: {
				          (#operation -> 'push').
				          (#repositoryName -> repository name) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: repository actionLog asArray equals: #( 'push' ).
		self assert: (data at: #action) equals: 'push'.
		self assert: (data at: #remoteNames) equals: #( 'origin' ).
		self assert: (data at: #headDescription) equals: 'after push'.
		saveResult := server rpcToolCall: 'edit-repository' withParams: {
				              (#operation -> 'push').
				              (#repositoryName -> repository name) } asDictionary.
		self deny: (saveResult at: #isError ifAbsent: [ false ]).
		self assert: server didSaveImageSession ].
	repository := self newTestRepositoryNamed:
		              'MCP Push Error Test Repository'.
	repository failPush: true.
	self withRegisteredRepository: repository do: [
		errorResult := self callToolWith: {
				               (#operation -> 'push').
				               (#repositoryName -> repository name) } asDictionary.
		self assert: (errorResult at: #isError ifAbsent: [ false ]).
		self assert: ((self summaryFrom: errorResult) includesSubstring:
				 'Failed to push repository') ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testRemoteAndBranchOperationsParseAndDispatch [

	| cases tool |
	tool := MCPToolEditRepository new.
	cases := {
		         {
			         (#operation -> 'fetch').
			         (#requestClass -> MCPRepositoryFetchRequest).
			         (#commandClass -> MCPFetchRepositoryCommand).
			         (#arguments -> { (#repositoryName -> 'MCP') } asDictionary) }
			         asDictionary.
		         {
			         (#operation -> 'pull').
			         (#requestClass -> MCPRepositoryPullRequest).
			         (#commandClass -> MCPPullRepositoryCommand).
			         (#arguments -> { (#repositoryName -> 'MCP') } asDictionary) }
			         asDictionary.
		         {
			         (#operation -> 'push').
			         (#requestClass -> MCPRepositoryPushRequest).
			         (#commandClass -> MCPPushRepositoryCommand).
			         (#arguments -> { (#repositoryName -> 'MCP') } asDictionary) }
			         asDictionary.
		         {
			         (#operation -> 'createBranch').
			         (#requestClass -> MCPRepositoryCreateBranchRequest).
			         (#commandClass -> MCPCreateRepositoryBranchCommand).
			         (#arguments -> {
				          (#repositoryName -> 'MCP').
				          (#branchName -> 'feature') } asDictionary) }
			         asDictionary.
		         {
			         (#operation -> 'switchBranch').
			         (#requestClass -> MCPRepositorySwitchBranchRequest).
			         (#commandClass -> MCPSwitchRepositoryBranchCommand).
			         (#arguments -> {
				          (#repositoryName -> 'MCP').
				          (#branchName -> 'main') } asDictionary) } asDictionary }.
	cases do: [ :each |
		| arguments command parsedRequest rawRequest |
		arguments := (each at: #arguments) copy.
		arguments at: #operation put: (each at: #operation).
		rawRequest := tool requestFromToolCallArguments: arguments.
		parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
		command := tool commandForRequest: parsedRequest.
		self assert: parsedRequest class equals: (each at: #requestClass).
		self assert: parsedRequest operation equals: (each at: #operation).
		self assert: command class equals: (each at: #commandClass) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testRepositoryErrorDetailsUseActionNotOperation [

	| errorDetails repository result |
	repository := self newTestRepositoryNamed:
		              'MCP Repository Error Action Test Repository'.
	repository failPush: true.
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'push').
				          (#repositoryName -> repository name) } asDictionary.
		self assert: (result at: #isError ifAbsent: [ false ]).
		errorDetails := self errorFrom: result.
		self assert: (errorDetails at: #action) equals: 'push'.
		self deny: (errorDetails includesKey: #operation).
		self deny: (errorDetails includesKey: #updateAction) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testSwitchBranchReturnsResultReportsErrorsAndRequestsImageSave [

	| data conflictResult loadResult missingResult repository result saveResult server |
	repository := self newTestRepositoryNamed:
		              'MCP Switch Branch Test Repository'.
	repository createBranch: 'feature'.
	repository switchToBranchNamed: 'main'.
	self withRegisteredRepository: repository do: [
		server := MCPSaveImageRecordingServer new.
		result := self callToolWith: {
				          (#operation -> 'switchBranch').
				          (#repositoryName -> repository name).
				          (#branchName -> 'feature') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #action) equals: 'switchBranch'.
		self assert: (data at: #previousBranchName) equals: 'main'.
		self assert: (data at: #branchName) equals: 'feature'.
		self
			assert: (data at: #previousHeadDescription)
			equals: 'branch main'.
		self assert: (data at: #headDescription) equals: 'branch feature'.
		saveResult := server rpcToolCall: 'edit-repository' withParams: {
				              (#operation -> 'switchBranch').
				              (#repositoryName -> repository name).
				              (#branchName -> 'main') } asDictionary.
		self deny: (saveResult at: #isError ifAbsent: [ false ]).
		self assert: server didSaveImageSession.
		missingResult := self callToolWith: {
				                 (#operation -> 'switchBranch').
				                 (#repositoryName -> repository name).
				                 (#branchName -> 'missing') } asDictionary.
		self assert: (missingResult at: #isError ifAbsent: [ false ]).
		self assert: ((self summaryFrom: missingResult) includesSubstring:
				 'Failed to switch repository branch').
		self assert: ((self summaryFrom: missingResult) includesSubstring:
				 'Branch not found') ].
	repository := self newTestRepositoryNamed:
		              'MCP Switch Branch Conflict Test Repository'.
	repository createBranch: 'feature'.
	repository failSwitchBranch: IceCheckoutConflictError
		-> 'Iceberg checkout conflict for test repository'.
	self withRegisteredRepository: repository do: [
		conflictResult := self callToolWith: {
				                  (#operation -> 'switchBranch').
				                  (#repositoryName -> repository name).
				                  (#branchName -> 'feature') } asDictionary.
		self assert: (conflictResult at: #isError ifAbsent: [ false ]).
		self assert: ((self summaryFrom: conflictResult) includesSubstring:
				 'Failed to switch repository branch').
		self assert: ((self summaryFrom: conflictResult) includesSubstring:
				 'Iceberg checkout conflict') ].
	repository := self newTestRepositoryNamed:
		              'MCP Switch Branch Load Test Repository'.
	repository createBranch: 'feature'.
	repository failSwitchBranch:
		IceGenericError -> 'Iceberg load failed for test repository'.
	self withRegisteredRepository: repository do: [
		loadResult := self callToolWith: {
				              (#operation -> 'switchBranch').
				              (#repositoryName -> repository name).
				              (#branchName -> 'feature') } asDictionary.
		self assert: (loadResult at: #isError ifAbsent: [ false ]).
		self assert: ((self summaryFrom: loadResult) includesSubstring:
				 'Failed to switch repository branch').
		self assert: ((self summaryFrom: loadResult) includesSubstring:
				 'Iceberg load failed') ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testUpdateAddsPackageToWorkingCopy [

	| data packageName repository result |
	packageName := 'MCPToolEditRepositoryAddedPackage'.
	repository := self
		              newRepositoryNamed: 'MCP Edit Repository Add Test'
		              location: FileLocator imageDirectory
		              packageNames: #(  ).
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'update').
				          (#repositoryName -> repository name).
				          (#addPackageNames -> { packageName }) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: (self packageNamesIn: repository)
			equals: { packageName }.
		self assert: (data at: #action) equals: 'update'.
		self assert: (data at: #updateActions) equals: #( 'addPackages' ).
		self assert: (data at: #addedPackageNames) equals: { packageName }.
		self assert: (data at: #removedPackageNames) equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testUpdateCanReplacePackageMembership [

	| data repository result |
	repository := self
		              newRepositoryNamed: 'MCP Edit Repository Replace Test'
		              location: FileLocator imageDirectory
		              packageNames:
		              #( 'MCPToolEditRepositoryOldA'
		                 'MCPToolEditRepositoryOldB' ).
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'update').
				          (#repositoryName -> repository name).
				          (#packageNames
				           ->
				           #( 'MCPToolEditRepositoryNewC'
				              'MCPToolEditRepositoryOldB' )) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self
			assert: (self packageNamesIn: repository)
			equals:
			#( 'MCPToolEditRepositoryNewC' 'MCPToolEditRepositoryOldB' ).
		self
			assert: (data at: #updateActions)
			equals: #( 'replacePackages' ).
		self
			assert: (data at: #addedPackageNames)
			equals: #( 'MCPToolEditRepositoryNewC' ).
		self
			assert: (data at: #removedPackageNames)
			equals: #( 'MCPToolEditRepositoryOldA' ) ]
]

{ #category : 'tests' }
MCPToolEditRepositoryTest >> testUpdateRemovesPackageWithoutUnloading [

	| data packageName repository result |
	packageName := 'MCPToolEditRepositoryRemovalPackage'.
	self withoutEpiceaDuring: [
		PackageOrganizer default ensurePackage: packageName ].
	[
	repository := self
		              newRepositoryNamed: 'MCP Edit Repository Remove Test'
		              location: FileLocator imageDirectory
		              packageNames: { packageName }.
	self withRegisteredRepository: repository do: [
		result := self callToolWith: {
				          (#operation -> 'update').
				          (#repositoryName -> repository name).
				          (#removePackageNames -> { packageName }) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (self packageNamesIn: repository) equals: #(  ).
		self assert: (PackageOrganizer default hasPackage: packageName).
		self assert: (data at: #action) equals: 'update'.
		self assert: (data at: #updateActions) equals: #( 'removePackages' ).
		self assert: (data at: #addedPackageNames) equals: #(  ).
		self assert: (data at: #removedPackageNames) equals: { packageName } ] ]
		ensure: [ self removePackageNamed: packageName ]
]

{ #category : 'private - calling' }
MCPToolEditRepositoryTest >> toolName [

	^ 'edit-repository'
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> withCleanRepositoryNamed: aRepositoryName location: aFileReference do: aBlock [

	[
	self removeRegisteredRepositoriesNamed: aRepositoryName.
	self deleteDirectoryIfExists: aFileReference.
	aBlock value ] ensure: [
		self removeRegisteredRepositoriesNamed: aRepositoryName.
		self deleteDirectoryIfExists: aFileReference ]
]

{ #category : 'private - classes' }
MCPToolEditRepositoryTest >> withExportPackageNamed: aPackageName className: aClassName do: aBlock [

	[
	self removeClassNamed: aClassName.
	self removePackageNamed: aPackageName.
	self createClassNamed: aClassName inPackageNamed: aPackageName.
	aBlock value ] ensure: [
		self removeClassNamed: aClassName.
		self removePackageNamed: aPackageName ]
]

{ #category : 'private' }
MCPToolEditRepositoryTest >> withRegisteredRepository: aRepository do: aBlock [

	| registry |
	registry := IceRepository registry.
	registry add: aRepository.
	[ aBlock value ] ensure: [
		registry remove: aRepository ifAbsent: [  ] ]
]
