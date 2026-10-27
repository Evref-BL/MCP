"
Tests for repository operation behavior. These tests execute the internal dispatcher directly so temporary Iceberg repository registry changes are not saved by the MCP RPC wrapper.
"
Class {
	#name : 'MCPToolRepositoryOperationTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> callToolNamed: aToolName with: someArguments [

	| request result tool |
	tool := MCPToolRegistry default toolNamed: aToolName ifAbsent: [ Error signal: 'Unknown MCP tool: ' , aToolName ].
	request := tool requestFromToolCallArguments: someArguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> callToolWith: someArguments [

	| action arguments request result tool toolClass |
	arguments := someArguments copy.
	action := arguments removeKey: #action ifAbsent: [ arguments removeKey: #action ifAbsent: [ nil ] ].
	toolClass := Dictionary new
		             at: 'create' put: MCPToolCreateRepository;
		             at: 'attach' put: MCPToolAttachRepository;
		             at: 'update' put: MCPToolUpdateRepository;
		             at: 'verifyIdentity' put: MCPToolVerifyRepositoryIdentity;
		             at: 'diff' put: MCPToolListRepositoryChanges;
		             at: 'discard' put: MCPToolDiscardRepositoryChanges;
		             at: 'export' put: MCPToolExportRepository;
		             at: 'commit' put: MCPToolCommitRepository;
		             at: 'adoptHead' put: MCPToolAdoptRepositoryHead;
		             at: 'reload' put: MCPToolReloadRepository;
		             at: action ifAbsent: [ Error signal: 'Unknown repository action: ' , action asString ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> commitAllIn: aRepositoryLocation message: aMessage [

	self shellCommand: 'git -C ' , (self shellQuote: aRepositoryLocation pathString) , ' add .'.
	self shellCommand:
		'git -C ' , (self shellQuote: aRepositoryLocation pathString) , ' -c user.name=' , (self shellQuote: 'MCP Test')
		, ' -c user.email=' , (self shellQuote: 'mcp-test@example.com') , ' commit -m ' , (self shellQuote: aMessage)
]

{ #category : 'private - classes' }
MCPToolRepositoryOperationTest >> createClassNamed: aClassName inPackageNamed: aPackageName [

	^ self withoutEpiceaDuring: [
			  | builder |
			  builder := Object << aClassName asSymbol.
			  builder package: aPackageName.
			  builder tag: 'Generated'.
			  builder install ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> deleteDirectoryIfExists: aFileReference [

	aFileReference exists ifTrue: [ aFileReference deleteAll ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> deleteTemporaryMetadataRepositoryFor: aRepository [

	| location |
	location := aRepository location asFileReference.
	(location basename beginsWith: 'mcp-test-repository-metadata-') ifFalse: [ ^ self ].
	location exists ifTrue: [ location deleteAll ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> directChildNamesOf: aFileReference [

	^ aFileReference exists
		  ifTrue: [ aFileReference children collect: [ :each | each basename ] ]
		  ifFalse: [ #(  ) ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each | repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> newTestRepositoryNamed: aRepositoryName [

	| location repository |
	location := FileLocator temp asFileReference / ('mcp-test-repository-metadata-' , UUID new asString).
	location ensureCreateDirectory.
	MCPTestGitRepositoryFixture writeConfig: MCPTestGitRepositoryFixture standardConfig in: location.
	repository := MCPTestIceRepository named: aRepositoryName location: location pathString.
	repository remoteNames: #( 'origin' ).
	^ repository
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> packageNamesIn: aRepository [

	^ aRepository workingCopy packageNames asArray sort
]

{ #category : 'private - assertions' }
MCPToolRepositoryOperationTest >> remoteNamed: remoteName in: remoteDictionaries [

	^ remoteDictionaries detect: [ :each | (each at: #name) = remoteName ] ifNone: [ self fail: 'Missing remote ' , remoteName ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> removeRegisteredRepositoriesNamed: aRepositoryName [

	| registry repositories |
	registry := IceRepository registry.
	repositories := registry select: [ :each | each name asString = aRepositoryName ].
	repositories do: [ :each | registry remove: each ifAbsent: [ ] ]
]

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> searchRepositoriesWith: someArguments [

	| request result tool |
	tool := MCPToolSearchRepositories new.
	request := tool requestFromToolCallArguments: someArguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> shellCommand: aCommandString [

	| status |
	status := LibC uniqueInstance system: aCommandString.
	self assert: status equals: 0
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> shellOutput: aCommandString [

	| command output outputFile status |
	outputFile := FileLocator temp asFileReference / ('mcp-test-shell-command-' , UUID new asString , '.log').
	command := aCommandString , ' > ' , (self shellQuote: outputFile pathString) , ' 2>&1'.
	status := LibC uniqueInstance system: command.
	output := outputFile exists
		          ifTrue: [ outputFile contents ]
		          ifFalse: [ '' ].
	outputFile exists ifTrue: [ outputFile delete ].
	self assert: status = 0 description: output.
	^ output
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> shellQuote: aString [

	^ '''' , (aString copyReplaceAll: '''' with: '''"''"''') , ''''
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> temporaryRepositoryLocationNamed: aName [

	^ FileLocator imageDirectory / aName
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadAdoptsRepositoryHeadAndReportsBeforeAfterModifiedPackages [

	| data repository result |
	repository := self newTestRepositoryNamed: 'MCP Adopt Head Test Repository'.
	repository headCommitId: 'head-2'.
	repository headDescription: 'main'.
	repository modifiedPackageNames: #( 'MCP' 'MCP-Tests' ).
	repository workingCopy referenceCommit: (MCPTestRepositoryCommit id: 'head-1').
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'adoptHead').
					          (#name -> repository name).
					          (#branch -> 'main') } asDictionary.
			data := self dataFrom: result.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self assert: repository modifiedPackages isEmpty.
			self assert: repository workingCopy referenceCommit id equals: 'head-2'.
			self
				assert: data keys asSet
				equals: #( adoptedCommitId branch didAdopt headDescription modifiedPackageNamesBefore previousReferenceCommitId
					   referenceCommitId ) asSet.
			self assert: (data at: #modifiedPackageNamesBefore) equals: #( 'MCP' 'MCP-Tests' ).
			self assert: (data at: #previousReferenceCommitId) equals: 'head-1'.
			self assert: (data at: #adoptedCommitId) equals: 'head-2'.
			self assert: (data at: #referenceCommitId) equals: 'head-2'.
			self assert: (data at: #didAdopt).
			self assert: (data at: #branch) equals: 'main'.
			self assert: (data at: #headDescription) equals: 'main' ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadClearsModifiedPackagesWhenReferenceAlreadyMatchesHead [

	| data repository result |
	repository := self newTestRepositoryNamed: 'MCP Adopt Clean Test Repository'.
	repository headCommitId: 'head-1'.
	repository headDescription: 'main'.
	repository modifiedPackageNames: #( 'MCP' ).
	repository workingCopy referenceCommit: (MCPTestRepositoryCommit id: 'head-1').
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'adoptHead').
					          (#name -> repository name).
					          (#branch -> 'main') } asDictionary.
			data := self dataFrom: result.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self assert: repository modifiedPackages isEmpty.
			self deny: (data at: #didAdopt).
			self assert: (data at: #modifiedPackageNamesBefore) equals: #( 'MCP' ).
			self assert: (data at: #referenceCommitId) equals: 'head-1' ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadOperationRequiresRepositoryAndParses [

	| command parsedRequest rawRequest tool |
	tool := MCPToolAdoptRepositoryHead new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#name -> 'MCP').
			              (#branch -> 'main') } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.
	self assert: parsedRequest class equals: MCPRepositoryAdoptHeadRequest.
	self assert: parsedRequest operation equals: 'adoptHead'.
	self assert: parsedRequest branchName equals: 'main'.
	self assert: command class equals: MCPAdoptRepositoryHeadCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadValidatesExpectedBranch [

	| errorDetails repository result |
	repository := self newTestRepositoryNamed: 'MCP Adopt Head Branch Guard Test Repository'.
	repository branchName: 'main'.
	repository headCommitId: 'head-1'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'adoptHead').
					          (#name -> repository name).
					          (#branch -> 'feature') } asDictionary.
			self assert: (self resultIndicatesError: result).
			self assert: ((self summaryFrom: result) includesSubstring: 'branch mismatch').
			errorDetails := self errorFrom: result.
			self assert: (errorDetails at: #action) equals: 'adoptHead'.
			self assert: (errorDetails at: #expectedBranch) equals: 'feature'.
			self assert: (errorDetails at: #actualBranch) equals: 'main'.
			self assert: repository actionLog asArray equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachParsesAndDispatchesToAttachCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolAttachRepository new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#name -> 'MCP').
			              (#location -> 'C:/src/MCP').
			              (#packages -> #( 'MCP' )) } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self assert: parsedRequest class equals: MCPRepositoryAttachRequest.
	self assert: parsedRequest operation equals: 'attach'.
	self assert: command class equals: MCPAttachRepositoryCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachRegistersExistingGitCheckout [

	| location packageName repository repositoryName result |
	repositoryName := 'MCP Repository Command Attach Test'.
	packageName := 'MCPToolRepositoryOperationAttachPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttach'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationAttachClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#subdirectory -> 'src').
							(#packages -> { packageName }) } asDictionary.
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					self callToolWith: {
							(#action -> 'commit').
							(#name -> repositoryName).
							(#message -> 'Prepare existing checkout attach test') } asDictionary.
					self removeRegisteredRepositoriesNamed: repositoryName.
					result := self callToolWith: {
							          (#action -> 'attach').
							          (#name -> repositoryName).
							          (#location -> location pathString).
							          (#subdirectory -> 'src').
							          (#packages -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: repository location pathString equals: location pathString.
					self assert: repository subdirectory equals: 'src'.
					self assert: (self packageNamesIn: repository) equals: { packageName } ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachRegistersLinkedGitWorktreeCheckout [

	| linkedLocation location packageName repository repositoryName result |
	repositoryName := 'MCP Repository Command Attach Linked Test'.
	packageName := 'MCPToolRepositoryOperationAttachLinkedPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachLinkedBase'.
	linkedLocation := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachLinkedWorktree'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationAttachLinkedClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self deleteDirectoryIfExists: linkedLocation.
					[
						self callToolWith: {
								(#action -> 'create').
								(#name -> repositoryName).
								(#location -> location pathString).
								(#subdirectory -> 'src').
								(#packages -> { packageName }) } asDictionary.
						self callToolWith: {
								(#action -> 'export').
								(#name -> repositoryName) } asDictionary.
						self callToolWith: {
								(#action -> 'commit').
								(#name -> repositoryName).
								(#message -> 'Prepare linked checkout for attach test') } asDictionary.
						self shellCommand: 'git -C ' , (self shellQuote: location pathString) , ' worktree add -b attach-linked-test '
							, (self shellQuote: linkedLocation pathString).
						self removeRegisteredRepositoriesNamed: repositoryName.
						result := self callToolWith: {
								          (#action -> 'attach').
								          (#name -> repositoryName).
								          (#location -> linkedLocation pathString).
								          (#subdirectory -> 'src').
								          (#packages -> { packageName }) } asDictionary.
						self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
						repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
						self assert: repository location pathString equals: linkedLocation pathString.
						self assert: repository subdirectory equals: 'src'.
						self assert: (self packageNamesIn: repository) equals: { packageName } ] ensure: [
							self removeRegisteredRepositoriesNamed: repositoryName.
							linkedLocation exists ifTrue: [
									LibC uniqueInstance system:
										'git -C ' , (self shellQuote: location pathString) , ' worktree remove --force '
										, (self shellQuote: linkedLocation pathString).
									self deleteDirectoryIfExists: linkedLocation ] ] ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachRejectsSubdirectoryForUnbornRepository [

	| error location repositoryName result |
	repositoryName := 'MCP Attach Unborn Subdirectory Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachUnbornSubdirectory'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			location ensureCreateDirectory.
			self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
			result := self callToolWith: {
					          (#action -> 'attach').
					          (#name -> repositoryName).
					          (#location -> location pathString).
					          (#subdirectory -> 'src') } asDictionary.
			self assert: (self resultIndicatesError: result).
			error := self errorFrom: result.
			self assert: (error at: #errorCode) equals: 'RepositorySubdirectoryRequiresHead'.
			self assert: ((self summaryFrom: result) includesSubstring: 'initial commit') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachReportsDuplicateRepository [

	| location repository repositoryName result |
	repositoryName := 'MCP Attach Duplicate Test Repository'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachDuplicate'.
	repository := self newRepositoryNamed: repositoryName location: location packageNames: #(  ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'attach').
					          (#name -> repositoryName).
					          (#location -> location pathString) } asDictionary.
			self assert: (self resultIndicatesError: result).
			self assert: ((self summaryFrom: result) includesSubstring: 'already registered') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCheckoutBranchLoadsTargetBranchSnapshot [

	| baseBranch checkoutResult className extraSelector featureBranch location packageName repository repositoryName |
	repositoryName := 'MCP Repository Command Checkout Branch Test'.
	packageName := 'MCPToolRepositoryOperationCheckoutPackage'.
	className := 'MCPToolRepositoryOperationCheckoutClass'.
	extraSelector := #staleBranchOnlyValue.
	featureBranch := 'feature-with-stale-method'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCheckoutBranch'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					self commitAllIn: location message: 'Prepare checkout base branch'.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					baseBranch := repository branchName.
					self shellCommand: 'git -C ' , (self shellQuote: location pathString) , ' checkout -b ' , (self shellQuote: featureBranch).
					(Smalltalk at: className asSymbol) compile: 'staleBranchOnlyValue ^ 42' classified: 'tests'.
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					self commitAllIn: location message: 'Add branch-only method'.
					self removeRegisteredRepositoriesNamed: repositoryName.
					self callToolWith: {
							(#action -> 'attach').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					self assert: ((Smalltalk at: className asSymbol) includesSelector: extraSelector).
					self shellCommand: 'git -C ' , (self shellQuote: location pathString) , ' checkout ' , (self shellQuote: baseBranch).
					checkoutResult := self callToolWith: {
							                  (#action -> 'reload').
							                  (#name -> repositoryName) } asDictionary.
					self deny: (self resultIndicatesError: checkoutResult) description: (self summaryFrom: checkoutResult).
					self deny: ((Smalltalk at: className asSymbol) includesSelector: extraSelector) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitCreatesCommitAndReturnsResult [

	| data location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Commit Test'.
	packageName := 'MCPToolRepositoryOperationCommitPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommit'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCommitClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					result := self callToolWith: {
							          (#action -> 'commit').
							          (#name -> repositoryName).
							          (#message -> 'Initial commit MCP test') } asDictionary.
					data := self dataFrom: result.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: data keys asSet equals: #( changedPackages commitDescription commitId headDescription ) asSet.
					self assert: (data at: #changedPackages) equals: { packageName }.
					self assert: (data at: #commitId) notEmpty.
					self assert: (data at: #commitDescription) equals: 'Initial commit MCP test'.
					self assert: (data at: #headDescription) notEmpty ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitParsesAndDispatchesToCommitCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolCommitRepository new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#name -> 'MCP').
			              (#message -> 'Commit from test') } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self assert: parsedRequest class equals: MCPRepositoryCommitRequest.
	self assert: parsedRequest message equals: 'Commit from test'.
	self assert: parsedRequest operation equals: 'commit'.
	self assert: command class equals: MCPCommitRepositoryCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitReportsIcebergRefusalErrors [

	| location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Refused Commit Test'.
	packageName := 'MCPToolRepositoryOperationRefusedCommitPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestRefusedCommit'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationRefusedCommitClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					self callToolWith: {
							(#action -> 'commit').
							(#name -> repositoryName).
							(#message -> 'Initial commit from MCP test') } asDictionary.
					result := self callToolWith: {
							          (#action -> 'commit').
							          (#name -> repositoryName).
							          (#message -> 'Second commit from MCP test') } asDictionary.
					self assert: (self resultIndicatesError: result).
					self assert: ((self summaryFrom: result) includesSubstring: 'Failed to commit repository') ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitUsesFallbackGitIdentityWhenGitSignatureIsUnavailable [

	| data location message packageName repositoryName result |
	repositoryName := 'MCP Repository Command Commit Fallback Identity Test'.
	packageName := 'MCPToolRepositoryOperationCommitFallbackIdentityPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommitFallbackIdentity'.
	message := 'Commit with fallback identity from MCP test'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCommitFallbackIdentityClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					self shellCommand: 'git -C ' , (self shellQuote: location pathString) , ' config user.name ' , (self shellQuote: '').
					self shellCommand: 'git -C ' , (self shellQuote: location pathString) , ' config user.email ' , (self shellQuote: '').
					result := self callToolWith: {
							          (#action -> 'commit').
							          (#name -> repositoryName).
							          (#message -> message) } asDictionary.
					data := self dataFrom: result.
					self assert: (data at: #commitDescription) equals: message.
					self
						assert: (self shellOutput: 'git -C ' , (self shellQuote: location pathString) , ' log -1 --format=%an') trimBoth
						equals: 'MCP' ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateCreatesAndRegistersRepository [

	| location repository repositoryName result |
	repositoryName := 'MCP Repository Command Create Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreate'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			result := self callToolWith: {
					          (#action -> 'create').
					          (#name -> repositoryName).
					          (#location -> location pathString).
					          (#subdirectory -> 'src').
					          (#packages -> #( 'MCP' 'MCP-Tests' )) } asDictionary.
			repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self assert: repository location pathString equals: location pathString.
			self assert: repository subdirectory equals: 'src'.
			self assert: (self packageNamesIn: repository) equals: #( 'MCP' 'MCP-Tests' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffCanReportImageModifiedPackagesWithoutWorkingCopyDiff [

	| data repository result |
	repository := self newTestRepositoryNamed: 'MCP Diff Package Only Test Repository'.
	repository modifiedPackageNames: #( 'MCP-Test-Dirty' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'diff').
					          (#name -> repository name) } asDictionary.
			data := self dataFrom: result.
			self deny: (result at: #isError ifAbsent: false).
			self assert: (data at: #isEmpty) equals: false.
			self assert: (data at: #changeCount) equals: 1.
			self assert: (data at: #changedPackages) equals: #( 'MCP-Test-Dirty' ).
			self deny: (data includesKey: #modifiedPaths) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffParsesAndDispatchesToDiffCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolListRepositoryChanges new.
	rawRequest := tool requestFromToolCallArguments: { (#name -> 'MCP') } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self assert: parsedRequest class equals: MCPRepositoryDiffRequest.
	self assert: parsedRequest operation equals: 'diff'.
	self assert: command class equals: MCPRepositoryDiffCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffReportsWorkingCopyDiffWithoutWriting [

	| childNames data location packageName repository repositoryName result |
	repositoryName := 'MCP Repository Command Diff Test'.
	packageName := 'MCPToolRepositoryOperationDiffPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestDiff'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationDiffClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self assert: repository index isEmpty.
					result := self callToolWith: {
							          (#action -> 'diff').
							          (#name -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					childNames := self directChildNamesOf: location.
					self deny: (result at: #isError ifAbsent: false).
					self assert: data keys asSet equals: #( changeCount changedPackages isEmpty ) asSet.
					self assert: (data at: #isEmpty) equals: false.
					self assert: (data at: #changeCount) > 0.
					self assert: (data at: #changedPackages) equals: { packageName }.
					self deny: (data includesKey: #modifiedPaths).
					self deny: (childNames anySatisfy: [ :each | each includesSubstring: packageName ]) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiscardCleanRepositoryDoesNothing [

	| data repository result |
	repository := self newTestRepositoryNamed: 'MCP Discard Clean Test Repository'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'discard').
					          (#name -> repository name) } asDictionary.
			data := self dataFrom: result.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #isEmpty) equals: true.
			self assert: (data at: #changeCount) equals: 0.
			self deny: (data includesKey: #discardedPackages).
			self deny: (data includesKey: #discardedPaths).
			self assert: repository actionLog asArray equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiscardClearsImageModifiedPackages [

	| data repository result |
	repository := self newTestRepositoryNamed: 'MCP Discard Package Only Test Repository'.
	repository modifiedPackageNames: #( 'MCP-Test-Dirty' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'discard').
					          (#name -> repository name) } asDictionary.
			data := self dataFrom: result.
			self deny: (result at: #isError ifAbsent: [ false ]).
			self assert: (data at: #isEmpty) equals: false.
			self assert: (data at: #changeCount) equals: 1.
			self assert: (data at: #discardedPackages) equals: #( 'MCP-Test-Dirty' ).
			self deny: (data includesKey: #discardedPaths).
			self assert: repository modifiedPackages isEmpty.
			self assert: repository actionLog asArray equals: #( 'discard' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiscardParsesAndDispatchesToDiscardCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolDiscardRepositoryChanges new.
	rawRequest := tool requestFromToolCallArguments: { (#name -> 'MCP') } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self assert: parsedRequest class equals: MCPRepositoryDiscardRequest.
	self assert: parsedRequest operation equals: 'discard'.
	self assert: command class equals: MCPDiscardRepositoryChangesCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportAndReloadUseTheFormatTheCheckoutDeclares [

	| className data location packageDirectory packageName repository repositoryName result |
	repositoryName := 'MCP Repository Command Filetree Test'.
	packageName := 'MCPToolRepositoryOperationFiletreePackage'.
	className := 'MCPToolRepositoryOperationFiletreeClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestFiletree'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					repository workingCopy repositoryProperties fileFormatId: #filetree.
					(Smalltalk at: className asSymbol) compile: 'filetreeOnlyValue ^ 42' classified: 'tests'.
					result := self callToolWith: {
							          (#action -> 'export').
							          (#name -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					packageDirectory := location / (packageName , '.package').
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: packageDirectory exists description: 'A filetree checkout keeps the package in a .package directory.'.
					self deny: (location / packageName) exists description: 'Exporting must not leave a Tonel tree beside the filetree source.'.
					self assert: (packageDirectory / (className , '.class') / 'instance' / 'filetreeOnlyValue.st') exists.
					self assert: (data at: #changedPackages) equals: { packageName }.
					self
						deny: (location / '.filetree') exists
						description: 'Exporting must not leave a filetree marker at the root of the checkout.'.
					self commitAllIn: location message: 'Export filetree source'.
					(Smalltalk at: className asSymbol) removeSelector: #filetreeOnlyValue.
					result := self callToolWith: {
							          (#action -> 'reload').
							          (#name -> repositoryName) } asDictionary.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self
						assert: ((Smalltalk at: className asSymbol) includesSelector: #filetreeOnlyValue)
						description: 'Reloading a filetree checkout must restore what its files hold.'.
					self
						deny: (location / '.filetree') exists
						description: 'Reading the source must not leave a filetree marker at the root of the checkout.' ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportHonoursTheTonelVersionTheCheckoutPins [

	| className location packageName repository repositoryName sourceFile |
	repositoryName := 'MCP Repository Command Tonel Version Test'.
	packageName := 'MCPToolRepositoryOperationTonelVersionPackage'.
	className := 'MCPToolRepositoryOperationTonelVersionClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestTonelVersion'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					sourceFile := location / packageName / (className , '.class.st').
					self assert: sourceFile exists.
					self
						assert: (sourceFile contents includesSubstring: '#package :')
						description: 'A checkout that pins no version is written in the current Tonel format.'.
					repository workingCopy repositoryProperties at: #version put: #'1.0'.
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					self
						deny: (sourceFile contents includesSubstring: '#package :')
						description: 'A checkout pinned to Tonel 1.0 must not be written in the version 3 format.' ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportUpdatesDiskAndIndexWithoutCommitting [

	| childNames data location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Export Test'.
	packageName := 'MCPToolRepositoryOperationExportPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExport'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationExportClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					result := self callToolWith: {
							          (#action -> 'export').
							          (#name -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					childNames := self directChildNamesOf: location.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: data keys asSet equals: #( changedPackages didChange modifiedPaths ) asSet.
					self assert: (data at: #didChange) equals: true.
					self assert: (data at: #changedPackages) equals: { packageName }.
					self assert: (data at: #modifiedPaths) notEmpty.
					self assert: (childNames anySatisfy: [ :each | each includesSubstring: packageName ]) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testGitCommandFailureSignalsStructuredCommandError [

	| command error |
	command := MCPCommitRepositoryCommand tool: MCPToolCommitRepository new request: nil.
	error := [
		         command
			         signalGitCommandFailed: {
					         (#status -> 128).
					         (#output -> 'fatal: no upstream') } asDictionary
			         action: 'commit'.
		         nil ]
		         on: MCPCommandError
		         do: [ :caught | caught ].
	self assert: error errorCode equals: 'commitGitCommandFailed'.
	self assert: error messageText equals: 'fatal: no upstream'.
	self assert: (error details at: #exitStatus) equals: 128.
	self assert: (error details at: #output) equals: 'fatal: no upstream'
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testLinkedWorktreeAttachExportsOnLinkedBranch [

	| repositoryName packageName initialClassName exportedClassName location linkedLocation branchName createResult exportResult commitResult attachResult searchResult searchData entry exportedClassFile |
	repositoryName := 'MCP Repository Command Linked Worktree Contract Test'.
	packageName := 'MCPToolRepositoryOperationLinkedWorktreePackage'.
	initialClassName := 'MCPToolRepositoryOperationLinkedWorktreeClass'.
	exportedClassName := 'MCPToolRepositoryOperationLinkedWorktreeExportClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestLinkedWorktreeBase'.
	linkedLocation := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestLinkedWorktree'.
	branchName := 'attach-linked-test'.
	exportedClassFile := linkedLocation / 'src' / packageName / (exportedClassName , '.class.st').
	self withExportPackageNamed: packageName className: initialClassName do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					linkedLocation exists ifTrue: [ linkedLocation deleteAll ].
					createResult := self callToolWith: {
							                (#action -> 'create').
							                (#name -> repositoryName).
							                (#location -> location pathString).
							                (#subdirectory -> 'src').
							                (#packages -> { packageName }) } asDictionary.
					self deny: (self resultIndicatesError: createResult) description: (self summaryFrom: createResult).
					exportResult := self callToolWith: {
							                (#action -> 'export').
							                (#name -> repositoryName) } asDictionary.
					self deny: (self resultIndicatesError: exportResult) description: (self summaryFrom: exportResult).
					commitResult := self callToolWith: {
							                (#action -> 'commit').
							                (#name -> repositoryName).
							                (#message -> 'Prepare linked checkout contract test') } asDictionary.
					self deny: (self resultIndicatesError: commitResult) description: (self summaryFrom: commitResult).
					self shellCommand: 'git -C ' , (self shellQuote: location pathString) , ' remote add origin https://example.com/worktree.git'.
					self shellCommand: 'git -C ' , (self shellQuote: location pathString) , ' worktree add -b ' , branchName , ' '
						, (self shellQuote: linkedLocation pathString).
					[
						self shellCommand:
							'git -C ' , (self shellQuote: linkedLocation pathString) , ' config branch.' , branchName , '.remote origin'.
						self shellCommand:
							'git -C ' , (self shellQuote: linkedLocation pathString) , ' config branch.' , branchName , '.merge refs/heads/'
							, branchName.
						self removeRegisteredRepositoriesNamed: repositoryName.
						attachResult := self callToolWith: {
								                (#action -> 'attach').
								                (#name -> repositoryName).
								                (#location -> linkedLocation pathString).
								                (#subdirectory -> 'src').
								                (#packages -> { packageName }) } asDictionary.
						self deny: (self resultIndicatesError: attachResult) description: (self summaryFrom: attachResult).
						searchResult := self searchRepositoriesWith: {
								                (#name -> repositoryName) } asDictionary.
						self deny: (self resultIndicatesError: searchResult) description: (self summaryFrom: searchResult).
						searchData := self dataFrom: searchResult.
						entry := (searchData at: #repositories) anyOne.
						self assert: (entry at: #location) equals: linkedLocation pathString.
						self assert: (entry at: #subdirectory) equals: 'src'.
						self assert: (entry at: #packageCount) equals: 1.
						self createClassNamed: exportedClassName inPackageNamed: packageName.
						exportResult := self callToolWith: {
								                (#action -> 'export').
								                (#name -> repositoryName) } asDictionary.
						self deny: (self resultIndicatesError: exportResult) description: (self summaryFrom: exportResult).
						self assert: exportedClassFile exists ] ensure: [
							self removeClassNamed: exportedClassName.
							self shellCommand:
								'git -C ' , (self shellQuote: location pathString) , ' worktree remove --force '
								, (self shellQuote: linkedLocation pathString).
							linkedLocation exists ifTrue: [ linkedLocation deleteAll ] ] ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testReloadRefusesWhenAPackageHasNoSourceOnDisk [

	| location packageDirectory packageName repositoryName result |
	repositoryName := 'MCP Repository Command Reload Missing Source Test'.
	packageName := 'MCPToolRepositoryOperationReloadMissingPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestReloadMissing'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationReloadMissingClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					packageDirectory := (location allChildrenMatching: packageName) detect: [ :each | each isDirectory ] ifNone: [ nil ].
					self deny: packageDirectory isNil description: 'The exported repository should hold the package on disk.'.
					packageDirectory deleteAll.
					result := self callToolWith: {
							          (#action -> 'reload').
							          (#name -> repositoryName) } asDictionary.
					self
						assert: (self resultIndicatesError: result)
						description: 'Reloading a package with no source on disk must not report success.'.
					self assert: ((self summaryFrom: result) includesSubstring: 'has no source on disk for ' , packageName) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testRestoreOrderOnlyTonelChurnRestoresOriginalFile [

	| command file location packageDirectory repository restored snapshot |
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestOrderOnly'.
	self deleteDirectoryIfExists: location.
	[
		packageDirectory := location / 'MCP-Order'.
		packageDirectory ensureCreateDirectory.
		file := packageDirectory / 'MCPOrderTestClass.class.st'.
		file writeStreamDo: [ :stream | stream nextPutAll: (self tonelClassSourceWithMethods: #( 'alpha' 'beta' )) ].
		repository := self newRepositoryNamed: 'MCP Order Only Test' location: location packageNames: #(  ).
		command := MCPExportRepositoryCommand new.
		snapshot := command snapshotTonelFilesFor: repository.
		file writeStreamDo: [ :stream | stream nextPutAll: (self tonelClassSourceWithMethods: #( 'beta' 'alpha' )) ].
		restored := command restoreOrderOnlyTonelChurnFor: repository fromSnapshot: snapshot.
		self assert: restored equals: #( 'MCP-Order/MCPOrderTestClass.class.st' ).
		self assert: file contents equals: (self tonelClassSourceWithMethods: #( 'alpha' 'beta' )) ] ensure: [
		self deleteDirectoryIfExists: location ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testSourceFormatChoosesItsOwnReaderAndWriter [

	| command |
	command := MCPRepositoryCommand new.
	self assert: (command sourceRepositoryClassForWriter: IceLibgitTonelWriter) equals: TonelRepository.
	self assert: (command sourceRepositoryClassForWriter: IceLibgitFiletreeWriter) equals: MCFileTreeRepository
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testSourceFormatNamesPackageDirectoriesItsOwnWay [

	| command |
	command := MCPRepositoryCommand new.
	self assert: (command packageNameFromDirectoryName: 'MCP-Tests' writer: IceLibgitTonelWriter) equals: 'MCP-Tests'.
	self assert: (command packageNameFromDirectoryName: 'MCP-Tests.package' writer: IceLibgitFiletreeWriter) equals: 'MCP-Tests'
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testSourceFormatSupportsEveryFormatIcebergWrites [

	| command icebergFormats |
	command := MCPRepositoryCommand new.
	icebergFormats := (TIceRepositoryWriter users collect: [ :each | each id asString ]) asArray sort.
	self
		assert: command supportedSourceFormatIds = icebergFormats
		description:
			'Every format Iceberg writes must be one this reads back, but it writes ' , icebergFormats printString , ' and this reads '
			, command supportedSourceFormatIds printString.
	self assert: command supportedSourceFormatIds equals: #( 'filetree' 'tonel' )
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testTonelMethodOrderComparisonIgnoresMethodChunkOrder [

	| command original reordered |
	command := MCPExportRepositoryCommand new.
	original := self tonelClassSourceWithMethods: #( 'alpha' 'beta' ).
	reordered := self tonelClassSourceWithMethods: #( 'beta' 'alpha' ).
	self assert: (command tonelMethodOrderEquivalent: original to: reordered)
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testTonelMethodOrderComparisonKeepsSemanticChanges [

	| changed command original |
	command := MCPExportRepositoryCommand new.
	original := self tonelClassSourceWithMethods: #( 'alpha' 'beta' ).
	changed := original copyReplaceAll: '^ #beta' with: '^ #changed'.
	self deny: (command tonelMethodOrderEquivalent: original to: changed)
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateAddsPackageToWorkingCopy [

	| data packageName repository result |
	packageName := 'MCPToolRepositoryOperationAddedPackage'.
	repository := self newRepositoryNamed: 'MCP Repository Command Add Test' location: FileLocator imageDirectory packageNames: #(  ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'update').
					          (#name -> repository name).
					          (#addPackages -> { packageName }) } asDictionary.
			data := self dataFrom: result.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self assert: (self packageNamesIn: repository) equals: { packageName }.
			self assert: data keys asSet equals: #( addedPackages updateActions ) asSet.
			self assert: (data at: #updateActions) equals: #( 'addPackages' ).
			self assert: (data at: #addedPackages) equals: { packageName } ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateCanReplacePackageMembership [

	| data repository result |
	repository := self
		              newRepositoryNamed: 'MCP Repository Command Replace Test'
		              location: FileLocator imageDirectory
		              packageNames: #( 'MCPToolRepositoryOperationOldA' 'MCPToolRepositoryOperationOldB' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'update').
					          (#name -> repository name).
					          (#packages -> #( 'MCPToolRepositoryOperationNewC' 'MCPToolRepositoryOperationOldB' )) } asDictionary.
			data := self dataFrom: result.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self assert: (self packageNamesIn: repository) equals: #( 'MCPToolRepositoryOperationNewC' 'MCPToolRepositoryOperationOldB' ).
			self assert: (data at: #updateActions) equals: #( 'replacePackages' ).
			self assert: (data at: #addedPackages) equals: #( 'MCPToolRepositoryOperationNewC' ).
			self assert: (data at: #removedPackageNames) equals: #( 'MCPToolRepositoryOperationOldA' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateRejectsSubdirectoryForUnbornRepository [

	| error location repositoryName result |
	repositoryName := 'MCP Update Unborn Subdirectory Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestUpdateUnbornSubdirectory'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			location ensureCreateDirectory.
			self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
			result := self callToolWith: {
					          (#action -> 'attach').
					          (#name -> repositoryName).
					          (#location -> location pathString) } asDictionary.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			result := self callToolWith: {
					          (#action -> 'update').
					          (#name -> repositoryName).
					          (#subdirectory -> 'src') } asDictionary.
			self assert: (self resultIndicatesError: result).
			error := self errorFrom: result.
			self assert: (error at: #errorCode) equals: 'RepositorySubdirectoryRequiresHead'.
			self assert: ((self summaryFrom: result) includesSubstring: 'initial commit') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateRemovesPackageWithoutUnloading [

	| data packageName repository result |
	packageName := 'MCPToolRepositoryOperationRemovalPackage'.
	self withoutEpiceaDuring: [ PackageOrganizer default ensurePackage: packageName ].
	[
		repository := self
			              newRepositoryNamed: 'MCP Repository Command Remove Test'
			              location: FileLocator imageDirectory
			              packageNames: { packageName }.
		self withRegisteredRepository: repository do: [
				result := self callToolWith: {
						          (#action -> 'update').
						          (#name -> repository name).
						          (#removePackages -> { packageName }) } asDictionary.
				data := self dataFrom: result.
				self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
				self assert: (self packageNamesIn: repository) equals: #(  ).
				self assert: (PackageOrganizer default hasPackage: packageName).
				self assert: data keys asSet equals: #( removedPackageNames updateActions ) asSet.
				self assert: (data at: #updateActions) equals: #( 'removePackages' ).
				self assert: (data at: #removedPackageNames) equals: { packageName } ] ] ensure: [ self removePackageNamed: packageName ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityOperationRequiresRepositoryAndParses [

	| command parsedRequest rawRequest tool |
	tool := MCPToolVerifyRepositoryIdentity new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#name -> 'MCP').
			              (#branch -> 'main').
			              (#packages -> #( 'MCP' )).
			              (#isModified -> false) } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self assert: parsedRequest class equals: MCPRepositoryVerifyIdentityRequest.
	self assert: parsedRequest operation equals: 'verifyIdentity'.
	self assert: parsedRequest branchName equals: 'main'.
	self assert: parsedRequest isModified equals: false.
	self assert: command class equals: MCPRepositoryVerifyIdentityCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityPassesWhenExpectedIdentityMatches [

	| data repository result |
	repository := self newTestRepositoryNamed: 'MCP VerifyIdentity Match Test Repository'.
	repository workingCopy packageNames: #( 'MCP-Tests' 'MCP' ).
	repository modifiedPackageNames: #( 'MCP' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#name -> repository name).
					          (#location -> repository location).
					          (#branch -> 'main').
					          (#subdirectory -> '').
					          (#packages -> #( 'MCP' 'MCP-Tests' )).
					          (#modifiedPackages -> #( 'MCP' )).
					          (#isModified -> true) } asDictionary.
			data := self dataFrom: result.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self assert: data keys asSet equals: #( matched ) asSet.
			self assert: (data at: #matched).
			self assert: repository actionLog asArray equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityReadsItsMismatchesWithoutStructuredContent [

	| contentText repository result |
	repository := self newTestRepositoryNamed: 'MCP VerifyIdentity Content Test Repository'.
	repository workingCopy packageNames: #( 'MCP' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#name -> repository name).
					          (#branch -> 'feature').
					          (#packages -> #( 'MCP' 'MCP-Tests' )) } asDictionary.
			self assert: (self resultIndicatesError: result).
			contentText := (result at: #content) first at: #text.
			self assert: (contentText includesSubstring: 'Repository identity verification failed').
			self assert: (contentText includesSubstring: 'branch: expected feature, actual main').
			self assert: (contentText includesSubstring: 'packages: expected (MCP, MCP-Tests), actual (MCP)') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityReportsStructuredMismatch [

	| branchMismatch errorDetails mismatchFields repository result |
	repository := self newTestRepositoryNamed: 'MCP VerifyIdentity Mismatch Test Repository'.
	repository workingCopy packageNames: #( 'MCP' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#name -> repository name).
					          (#branch -> 'feature').
					          (#packages -> #( 'MCP' 'MCP-Tests' )).
					          (#isModified -> true) } asDictionary.
			self assert: (self resultIndicatesError: result).
			self assert: ((self summaryFrom: result) includesSubstring: 'Repository identity verification failed').
			errorDetails := self errorFrom: result.
			self assert: (errorDetails at: #errorCode) equals: 'RepositoryIdentityMismatch'.
			self assert: (errorDetails at: #action) equals: 'verifyIdentity'.
			mismatchFields := (errorDetails at: #mismatches) collect: [ :each | each at: #field ].
			self assert: mismatchFields asArray sort equals: #( 'branch' 'isModified' 'packages' ).
			branchMismatch := (errorDetails at: #mismatches) detect: [ :each | (each at: #field) = 'branch' ].
			self assert: (branchMismatch at: #expected) equals: 'feature'.
			self assert: (branchMismatch at: #actual) equals: 'main'.
			self assert: repository actionLog asArray equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityReportsWrongLocationAsIdentityMismatch [

	| errorDetails locationMismatch repository result |
	repository := self newTestRepositoryNamed: 'MCP VerifyIdentity Location Mismatch Test Repository'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#name -> repository name).
					          (#location -> 'memory://different-location') } asDictionary.
			self assert: (self resultIndicatesError: result).
			errorDetails := self errorFrom: result.
			self assert: (errorDetails at: #errorCode) equals: 'RepositoryIdentityMismatch'.
			locationMismatch := (errorDetails at: #mismatches) detect: [ :each | (each at: #field) = 'location' ].
			self assert: (locationMismatch at: #expected) equals: 'memory://different-location'.
			self assert: (locationMismatch at: #actual) equals: repository location ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityRequiresExpectedIdentityField [

	| errorDetails repository result |
	repository := self newTestRepositoryNamed: 'MCP VerifyIdentity Missing Expected Field Test Repository'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#name -> repository name) } asDictionary.
			self assert: (self resultIndicatesError: result).
			errorDetails := self errorFrom: result.
			self assert: (errorDetails at: #errorCode) equals: 'RepositoryIdentityExpectationRequired'.
			self assert: ((self summaryFrom: result) includesSubstring: 'requires at least one expected identity field') ]
]

{ #category : 'private - fixtures' }
MCPToolRepositoryOperationTest >> tonelClassSourceWithMethods: methodSelectors [

	| stream |
	stream := WriteStream on: String new.
	stream
		nextPutAll: '"Order-only Tonel fixture"';
		nextPut: Character lf;
		nextPutAll: 'Class {';
		nextPut: Character lf;
		nextPutAll: String tab , '#name : ''MCPOrderTestClass'',';
		nextPut: Character lf;
		nextPutAll: String tab , '#superclass : ''Object'',';
		nextPut: Character lf;
		nextPutAll: String tab , '#category : ''MCP-Order''';
		nextPut: Character lf;
		nextPutAll: '}';
		nextPut: Character lf.
	methodSelectors do: [ :selector |
			stream
				nextPut: Character lf;
				nextPutAll: '{ #category : ''tests'' }';
				nextPut: Character lf;
				nextPutAll: 'MCPOrderTestClass >> ' , selector;
				nextPut: Character lf;
				nextPutAll: '[';
				nextPut: Character lf;
				nextPutAll: String tab , '^ #' , selector;
				nextPut: Character lf;
				nextPutAll: ']';
				nextPut: Character lf ].
	^ stream contents
]

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> toolName [

	self shouldNotImplement
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> withCleanRepositoryNamed: aRepositoryName location: aFileReference do: aBlock [

	[
		self removeRegisteredRepositoriesNamed: aRepositoryName.
		self deleteDirectoryIfExists: aFileReference.
		aBlock value ] ensure: [
			self removeRegisteredRepositoriesNamed: aRepositoryName.
			self deleteDirectoryIfExists: aFileReference ]
]

{ #category : 'private - classes' }
MCPToolRepositoryOperationTest >> withExportPackageNamed: aPackageName className: aClassName do: aBlock [

	[
		self removeClassNamed: aClassName.
		self removePackageNamed: aPackageName.
		self createClassNamed: aClassName inPackageNamed: aPackageName.
		aBlock value ] ensure: [
			self removeClassNamed: aClassName.
			self removePackageNamed: aPackageName ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> withRegisteredRepository: aRepository do: aBlock [

	| registry |
	registry := IceRepository registry.
	registry add: aRepository.
	[ aBlock value ] ensure: [
			registry remove: aRepository ifAbsent: [ ].
			self deleteTemporaryMetadataRepositoryFor: aRepository ]
]
