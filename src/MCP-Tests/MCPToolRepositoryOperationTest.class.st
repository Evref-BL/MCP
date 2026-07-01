"
Tests for repository operation behavior. These tests execute the internal dispatcher directly so temporary Iceberg repository registry changes are not saved by the MCP RPC wrapper.
"
Class {
	#name : 'MCPToolRepositoryOperationTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> callToolNamed: aToolName with: someArguments [

	| request result tool |
	tool := MCPToolRegistry
		        toolNamed: aToolName
		        ifAbsent: [ Error signal: 'Unknown MCP tool: ' , aToolName ].
	request := tool requestFromToolCallArguments: someArguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> callToolWith: someArguments [

	| action arguments request result tool toolClass |
	arguments := someArguments copy.
	action := arguments
		          removeKey: #action
		          ifAbsent: [
		          arguments removeKey: #action ifAbsent: [ nil ] ].
	toolClass := Dictionary new
		             at: 'create' put: MCPToolCreateRepository;
		             at: 'attach' put: MCPToolAttachRepository;
		             at: 'update' put: MCPToolUpdateRepository;
		             at: 'verifyIdentity'
		             put: MCPToolVerifyRepositoryIdentity;
		             at: 'diff' put: MCPToolListRepositoryChanges;
		             at: 'export' put: MCPToolExportRepository;
		             at: 'commit' put: MCPToolCommitRepository;
		             at: 'adoptHead' put: MCPToolAdoptRepositoryHead;
		             at: 'fetch' put: MCPToolFetchRepository;
		             at: 'pull' put: MCPToolPullRepository;
		             at: 'push' put: MCPToolPushRepository;
		             at: 'createBranch' put: MCPToolCreateRepositoryBranch;
		             at: 'switchBranch' put: MCPToolSwitchRepositoryBranch;
		             at: 'checkoutBranch'
		             put: MCPToolCheckoutRepositoryBranch;
		             at: action
		             ifAbsent: [
			             Error signal:
					             'Unknown repository action: ' , action asString ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> commitAllIn: aRepositoryLocation message: aMessage [

	self shellCommand:
		'git -C ' , (self shellQuote: aRepositoryLocation pathString)
		, ' add .'.
	self shellCommand:
		'git -C ' , (self shellQuote: aRepositoryLocation pathString)
		, ' -c user.name=' , (self shellQuote: 'MCP Test')
		, ' -c user.email=' , (self shellQuote: 'mcp-test@example.com')
		, ' commit -m ' , (self shellQuote: aMessage)
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
	(location basename beginsWith: 'mcp-test-repository-metadata-')
		ifFalse: [ ^ self ].
	location exists ifTrue: [ location deleteAll ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> directChildNamesOf: aFileReference [

	^ aFileReference exists
		  ifTrue: [
		  aFileReference children collect: [ :each | each basename ] ]
		  ifFalse: [ #(  ) ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> newRepositoryNamed: aRepositoryName location: aFileReference packageNames: somePackageNames [

	| repository |
	repository := IceLibgitRepository new.
	repository name: aRepositoryName.
	repository location: aFileReference.
	somePackageNames do: [ :each |
		repository workingCopy addPackageNamed: each ].
	^ repository
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> newTestRepositoryNamed: aRepositoryName [

	| location repository |
	location := FileLocator temp asFileReference
	            / ('mcp-test-repository-metadata-' , UUID new asString).
	location ensureCreateDirectory.
	MCPTestGitRepositoryFixture
		writeConfig: MCPTestGitRepositoryFixture standardConfig
		in: location.
	repository := MCPTestIceRepository
		              named: aRepositoryName
		              location: location pathString.
	repository remoteNames: #( 'origin' ).
	^ repository
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> packageNamesIn: aRepository [

	^ aRepository workingCopy packageNames asArray sort
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> removeRegisteredRepositoriesNamed: aRepositoryName [

	| registry repositories |
	registry := IceRepository registry.
	repositories := registry select: [ :each |
		                each name asString = aRepositoryName ].
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
	outputFile := FileLocator temp asFileReference
	              / ('mcp-test-shell-command-' , UUID new asString , '.log').
	command := aCommandString , ' > ' , (self shellQuote: outputFile pathString)
	           , ' 2>&1'.
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
	repository := self newTestRepositoryNamed:
		              'MCP Adopt Head Test Repository'.
	repository headCommitId: 'head-2'.
	repository headDescription: 'main'.
	repository modifiedPackageNames: #( 'MCP' 'MCP-Tests' ).
	repository workingCopy referenceCommit:
		(MCPTestRepositoryCommit id: 'head-1').
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'adoptHead').
					          (#repositoryName -> repository name).
					          (#branchName -> 'main') } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self assert: repository modifiedPackages isEmpty.
			self
				assert: repository workingCopy referenceCommit id
				equals: 'head-2'.
			self
				assert: data keys asSet
				equals:
					#( adoptedCommitId branchName didAdopt headDescription
					   modifiedPackageNamesBefore previousReferenceCommitId
					   referenceCommitId ) asSet.
			self
				assert: (data at: #modifiedPackageNamesBefore)
				equals: #( 'MCP' 'MCP-Tests' ).
			self assert: (data at: #previousReferenceCommitId) equals: 'head-1'.
			self assert: (data at: #adoptedCommitId) equals: 'head-2'.
			self assert: (data at: #referenceCommitId) equals: 'head-2'.
			self assert: (data at: #didAdopt).
			self assert: (data at: #branchName) equals: 'main'.
			self assert: (data at: #headDescription) equals: 'main' ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadClearsModifiedPackagesWhenReferenceAlreadyMatchesHead [

	| data repository result |
	repository := self newTestRepositoryNamed:
		              'MCP Adopt Clean Test Repository'.
	repository headCommitId: 'head-1'.
	repository headDescription: 'main'.
	repository modifiedPackageNames: #( 'MCP' ).
	repository workingCopy referenceCommit:
		(MCPTestRepositoryCommit id: 'head-1').
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'adoptHead').
					          (#repositoryName -> repository name).
					          (#branchName -> 'main') } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self assert: repository modifiedPackages isEmpty.
			self deny: (data at: #didAdopt).
			self
				assert: (data at: #modifiedPackageNamesBefore)
				equals: #( 'MCP' ).
			self assert: (data at: #referenceCommitId) equals: 'head-1' ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadOperationRequiresRepositoryAndParses [

	| command parsedRequest rawRequest tool |
	tool := MCPToolAdoptRepositoryHead new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#repositoryName -> 'MCP').
			              (#branchName -> 'main') } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.
	self
		assert: parsedRequest class
		equals: MCPRepositoryAdoptHeadRequest.
	self assert: parsedRequest operation equals: 'adoptHead'.
	self assert: parsedRequest branchName equals: 'main'.
	self assert: command class equals: MCPAdoptRepositoryHeadCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadValidatesExpectedBranch [

	| errorDetails repository result |
	repository := self newTestRepositoryNamed:
		              'MCP Adopt Head Branch Guard Test Repository'.
	repository branchName: 'main'.
	repository headCommitId: 'head-1'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'adoptHead').
					          (#repositoryName -> repository name).
					          (#branchName -> 'feature') } asDictionary.
			self assert: (self resultIndicatesError: result).
			self assert:
				((self summaryFrom: result) includesSubstring: 'branch mismatch').
			errorDetails := self errorFrom: result.
			self assert: (errorDetails at: #action) equals: 'adoptHead'.
			self
				assert: (errorDetails at: #expectedBranchName)
				equals: 'feature'.
			self assert: (errorDetails at: #actualBranchName) equals: 'main'.
			self assert: repository actionLog asArray equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachParsesAndDispatchesToAttachCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolAttachRepository new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#name -> 'MCP').
			              (#location -> 'C:/src/MCP').
			              (#packageNames -> #( 'MCP' )) } asDictionary.
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
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestAttach'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationAttachClass'
		do: [
				self
					withCleanRepositoryNamed: repositoryName
					location: location
					do: [
							self callToolWith: {
									(#action -> 'create').
									(#name -> repositoryName).
									(#location -> location pathString).
									(#subdirectory -> 'src').
									(#packageNames -> { packageName }) } asDictionary.
							self callToolWith: {
									(#action -> 'export').
									(#repositoryName -> repositoryName) } asDictionary.
							self callToolWith: {
									(#action -> 'commit').
									(#repositoryName -> repositoryName).
									(#message -> 'Prepare existing checkout attach test') }
									asDictionary.
							self removeRegisteredRepositoriesNamed: repositoryName.
							result := self callToolWith: {
									          (#action -> 'attach').
									          (#name -> repositoryName).
									          (#location -> location pathString).
									          (#subdirectory -> 'src').
									          (#packageNames -> { packageName }) } asDictionary.
							repository := IceRepository repositories detect: [ :each |
								              each name asString = repositoryName ].
							self
								deny: (self resultIndicatesError: result)
								description: (self summaryFrom: result).
							self
								assert: repository location pathString
								equals: location pathString.
							self assert: repository subdirectory equals: 'src'.
							self
								assert: (self packageNamesIn: repository)
								equals: { packageName } ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachRegistersLinkedGitWorktreeCheckout [

	| linkedLocation location packageName repository repositoryName result |
	repositoryName := 'MCP Repository Command Attach Linked Test'.
	packageName := 'MCPToolRepositoryOperationAttachLinkedPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestAttachLinkedBase'.
	linkedLocation := self temporaryRepositoryLocationNamed:
		                  'MCPToolRepositoryOperationTestAttachLinkedWorktree'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationAttachLinkedClass'
		do: [
				self
					withCleanRepositoryNamed: repositoryName
					location: location
					do: [
							self deleteDirectoryIfExists: linkedLocation.
							[
								self callToolWith: {
										(#action -> 'create').
										(#name -> repositoryName).
										(#location -> location pathString).
										(#subdirectory -> 'src').
										(#packageNames -> { packageName }) } asDictionary.
								self callToolWith: {
										(#action -> 'export').
										(#repositoryName -> repositoryName) } asDictionary.
								self callToolWith: {
										(#action -> 'commit').
										(#repositoryName -> repositoryName).
										(#message -> 'Prepare linked checkout for attach test') }
										asDictionary.
								self shellCommand:
									'git -C ' , (self shellQuote: location pathString)
									, ' worktree add -b attach-linked-test '
									, (self shellQuote: linkedLocation pathString).
								self removeRegisteredRepositoriesNamed: repositoryName.
								result := self callToolWith: {
										          (#action -> 'attach').
										          (#name -> repositoryName).
										          (#location -> linkedLocation pathString).
										          (#subdirectory -> 'src').
										          (#packageNames -> { packageName }) } asDictionary.
								self
									deny: (self resultIndicatesError: result)
									description: (self summaryFrom: result).
								repository := IceRepository repositories detect: [ :each |
									              each name asString = repositoryName ].
								self
									assert: repository location pathString
									equals: linkedLocation pathString.
								self assert: repository subdirectory equals: 'src'.
								self
									assert: (self packageNamesIn: repository)
									equals: { packageName } ] ensure: [
									self removeRegisteredRepositoriesNamed: repositoryName.
									linkedLocation exists ifTrue: [
											LibC uniqueInstance system:
												'git -C ' , (self shellQuote: location pathString)
												, ' worktree remove --force '
												, (self shellQuote: linkedLocation pathString).
											self deleteDirectoryIfExists: linkedLocation ] ] ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachReportsDuplicateRepository [

	| location repository repositoryName result |
	repositoryName := 'MCP Attach Duplicate Test Repository'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestAttachDuplicate'.
	repository := self
		              newRepositoryNamed: repositoryName
		              location: location
		              packageNames: #(  ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'attach').
					          (#name -> repositoryName).
					          (#location -> location pathString) } asDictionary.
			self assert: (self resultIndicatesError: result).
			self assert:
				((self summaryFrom: result) includesSubstring:
					 'already registered') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCheckoutBranchLoadsTargetBranchSnapshot [

	| baseBranch checkoutResult className extraSelector featureBranch location packageName repository repositoryName |
	repositoryName := 'MCP Repository Command Checkout Branch Test'.
	packageName := 'MCPToolRepositoryOperationCheckoutPackage'.
	className := 'MCPToolRepositoryOperationCheckoutClass'.
	extraSelector := #staleBranchOnlyValue.
	featureBranch := 'feature-with-stale-method'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestCheckoutBranch'.
	self withExportPackageNamed: packageName className: className do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
						self callToolWith: {
								(#action -> 'create').
								(#name -> repositoryName).
								(#location -> location pathString).
								(#packageNames -> { packageName }) } asDictionary.
						self callToolWith: {
								(#action -> 'export').
								(#repositoryName -> repositoryName) } asDictionary.
						self
							commitAllIn: location
							message: 'Prepare checkout base branch'.
						repository := IceRepository repositories detect: [ :each |
							              each name asString = repositoryName ].
						baseBranch := repository branchName.
						self shellCommand:
							'git -C ' , (self shellQuote: location pathString)
							, ' checkout -b ' , (self shellQuote: featureBranch).
						(Smalltalk at: className asSymbol)
							compile: 'staleBranchOnlyValue ^ 42'
							classified: 'tests'.
						self callToolWith: {
								(#action -> 'export').
								(#repositoryName -> repositoryName) } asDictionary.
						self commitAllIn: location message: 'Add branch-only method'.
						self removeRegisteredRepositoriesNamed: repositoryName.
						self callToolWith: {
								(#action -> 'attach').
								(#name -> repositoryName).
								(#location -> location pathString).
								(#packageNames -> { packageName }) } asDictionary.
						self assert:
							((Smalltalk at: className asSymbol) includesSelector:
								 extraSelector).
						checkoutResult := self
							                  callToolNamed: 'repository_branch_checkout'
							                  with: {
									                  (#repositoryName -> repositoryName).
									                  (#branchName -> baseBranch) } asDictionary.
						self
							deny: (self resultIndicatesError: checkoutResult)
							description: (self summaryFrom: checkoutResult).
						self deny:
							((Smalltalk at: className asSymbol) includesSelector:
								 extraSelector) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitCreatesCommitAndReturnsResult [

	| data location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Commit Test'.
	packageName := 'MCPToolRepositoryOperationCommitPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestCommit'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationCommitClass'
		do: [
				self
					withCleanRepositoryNamed: repositoryName
					location: location
					do: [
							self callToolWith: {
									(#action -> 'create').
									(#name -> repositoryName).
									(#location -> location pathString).
									(#packageNames -> { packageName }) } asDictionary.
							result := self callToolWith: {
									          (#action -> 'commit').
									          (#repositoryName -> repositoryName).
									          (#message -> 'Initial commit MCP test') }
									          asDictionary.
							data := self dataFrom: result.
							self
								deny: (self resultIndicatesError: result)
								description: (self summaryFrom: result).
							self
								assert: data keys asSet
								equals:
									#( changedPackageNames commitDescription commitId headDescription )
										asSet.
							self
								assert: (data at: #changedPackageNames)
								equals: { packageName }.
							self assert: (data at: #commitId) notEmpty.
							self
								assert: (data at: #commitDescription)
								equals: 'Initial commit MCP test'.
							self assert: (data at: #headDescription) notEmpty ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitParsesAndDispatchesToCommitCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolCommitRepository new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#repositoryName -> 'MCP').
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
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestRefusedCommit'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationRefusedCommitClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					self callToolWith: {
							(#action -> 'commit').
							(#repositoryName -> repositoryName).
							(#message -> 'Initial commit from MCP test') }
						asDictionary.
					result := self callToolWith: {
							(#action -> 'commit').
							(#repositoryName -> repositoryName).
							(#message -> 'Second commit from MCP test') }
						asDictionary.
					self assert: (self resultIndicatesError: result).
					self assert:
						((self summaryFrom: result) includesSubstring:
							 'Failed to commit repository') ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitRequestsImageSaveAfterSuccessfulExecution [

	| location packageName repositoryName result server |
	repositoryName := 'MCP Repository Command Commit Save Test'.
	packageName := 'MCPToolRepositoryOperationCommitSavePackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestCommitSave'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationCommitSaveClass'
		do: [
				self
					withCleanRepositoryNamed: repositoryName
					location: location
					do: [
							self callToolWith: {
									(#action -> 'create').
									(#name -> repositoryName).
									(#location -> location pathString).
									(#packageNames -> { packageName }) } asDictionary.
							server := MCPSaveImageRecordingServer new.
							self deny: server didSaveImageSession.
							result := server
								          rpcToolCall: 'repository_commit'
								          withParams: {
										          (#repositoryName -> repositoryName).
										          (#message -> 'Commit and save from MCP test') }
										          asDictionary.
							self
								deny: (self resultIndicatesError: result)
								description: (self summaryFrom: result).
							self assert: server didSaveImageSession ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitUsesFallbackGitIdentityWhenGitSignatureIsUnavailable [

	| data location message packageName repositoryName result |
	repositoryName := 'MCP Repository Command Commit Fallback Identity Test'.
	packageName := 'MCPToolRepositoryOperationCommitFallbackIdentityPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestCommitFallbackIdentity'.
	message := 'Commit with fallback identity from MCP test'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationCommitFallbackIdentityClass'
		do: [
			self
				withCleanRepositoryNamed: repositoryName
				location: location
				do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					self shellCommand:
						'git -C ' , (self shellQuote: location pathString)
						, ' config user.name ' , (self shellQuote: '').
					self shellCommand:
						'git -C ' , (self shellQuote: location pathString)
						, ' config user.email ' , (self shellQuote: '').
					result := self callToolWith: {
							(#action -> 'commit').
							(#repositoryName -> repositoryName).
							(#message -> message) } asDictionary.
					data := self dataFrom: result.
					self assert: (data at: #commitDescription) equals: message.
					self
						assert: (self shellOutput:
								 'git -C ' , (self shellQuote: location pathString)
								 , ' log -1 --format=%an') trimBoth
						equals: 'MCP' ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateBranchReturnsResultReportsErrorsAndRequestsImageSave [

	| data duplicateResult failureResult repository result saveResult server |
	repository := self newTestRepositoryNamed:
		              'MCP Create Branch Test Repository'.
	self withRegisteredRepository: repository do: [
			server := MCPSaveImageRecordingServer new.
			result := self callToolWith: {
					          (#action -> 'createBranch').
					          (#repositoryName -> repository name).
					          (#branchName -> 'feature') } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self
				assert: repository actionLog asArray
				equals: #( 'createBranch:feature' ).
			self
				assert: data keys asSet
				equals:
					#( branchName headDescription previousBranchName
					   previousHeadDescription ) asSet.
			self assert: (data at: #previousBranchName) equals: 'main'.
			self assert: (data at: #branchName) equals: 'feature'.
			self assert: (data at: #previousHeadDescription) equals: 'initial'.
			self assert: (data at: #headDescription) equals: 'branch feature'.
			saveResult := server
				              rpcToolCall: 'repository_branch_create'
				              withParams: {
						              (#repositoryName -> repository name).
						              (#branchName -> 'feature-save') } asDictionary.
			self
				deny: (self resultIndicatesError: saveResult)
				description: (self summaryFrom: saveResult).
			self assert: server didSaveImageSession.
			duplicateResult := self callToolWith: {
					                   (#action -> 'createBranch').
					                   (#repositoryName -> repository name).
					                   (#branchName -> 'feature') } asDictionary.
			self assert: (self resultIndicatesError: duplicateResult).
			self assert:
				((self summaryFrom: duplicateResult) includesSubstring:
					 'Failed to create repository branch').
			self assert:
				((self summaryFrom: duplicateResult) includesSubstring:
					 'Branch already exists') ].
	repository := self newTestRepositoryNamed:
		              'MCP Create Branch Invalid Test Repository'.
	repository failCreateBranch:
		IceGenericError -> 'Invalid branch name test repository'.
	self withRegisteredRepository: repository do: [
			failureResult := self callToolWith: {
					                 (#action -> 'createBranch').
					                 (#repositoryName -> repository name).
					                 (#branchName -> 'bad branch') } asDictionary.
			self assert: (self resultIndicatesError: failureResult).
			self assert: ((self summaryFrom: failureResult) includesSubstring:
					 'Failed to create repository branch').
			self assert: ((self summaryFrom: failureResult) includesSubstring:
					 'Invalid branch name') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateCreatesAndRegistersRepository [

	| location repository repositoryName result |
	repositoryName := 'MCP Repository Command Create Test'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestCreate'.
	self
		withCleanRepositoryNamed: repositoryName
		location: location
		do: [
				result := self callToolWith: {
						          (#action -> 'create').
						          (#name -> repositoryName).
						          (#location -> location pathString).
						          (#subdirectory -> 'src').
						          (#packageNames -> #( 'MCP' 'MCP-Tests' )) }
						          asDictionary.
				repository := IceRepository repositories detect: [ :each |
					              each name asString = repositoryName ].
				self
					deny: (self resultIndicatesError: result)
					description: (self summaryFrom: result).
				self
					assert: repository location pathString
					equals: location pathString.
				self assert: repository subdirectory equals: 'src'.
				self
					assert: (self packageNamesIn: repository)
					equals: #( 'MCP' 'MCP-Tests' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffCanReportImageModifiedPackagesWithoutWorkingCopyDiff [

	| data repository result |
	repository := self newTestRepositoryNamed:
		              'MCP Diff Package Only Test Repository'.
	repository modifiedPackageNames: #( 'MCP-Test-Dirty' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
				          (#action -> 'diff').
				          (#repositoryName -> repository name) } asDictionary.
			data := self dataFrom: result.
			self deny: (result at: #isError ifAbsent: false).
			self assert: (data at: #isEmpty) equals: false.
			self assert: (data at: #changeCount) equals: 1.
			self
				assert: (data at: #changedPackageNames)
				equals: #( 'MCP-Test-Dirty' ).
			self deny: (data includesKey: #modifiedPaths) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffDoesNotRequestImageSaveAfterSuccessfulExecution [

	| location packageName repositoryName result server |
	repositoryName := 'MCP Repository Command Diff Save Test'.
	packageName := 'MCPToolRepositoryOperationDiffSavePackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestDiffSave'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationDiffSaveClass'
		do: [
				self
					withCleanRepositoryNamed: repositoryName
					location: location
					do: [
							self callToolWith: {
									(#action -> 'create').
									(#name -> repositoryName).
									(#location -> location pathString).
									(#packageNames -> { packageName }) } asDictionary.
							server := MCPSaveImageRecordingServer new.
							result := server
								          rpcToolCall: 'repository_change_list'
								          withParams:
								          { (#repositoryName -> repositoryName) } asDictionary.
							self
								deny: (self resultIndicatesError: result)
								description: (self summaryFrom: result).
							self deny: server didSaveImageSession ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffParsesAndDispatchesToDiffCommand [

	| command parsedRequest rawRequest tool |
	tool := MCPToolListRepositoryChanges new.
	rawRequest := tool requestFromToolCallArguments:
		              { (#repositoryName -> 'MCP') } asDictionary.
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
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestDiff'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationDiffClass'
		do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packageNames -> { packageName }) } asDictionary.
					repository := IceRepository repositories detect: [ :each |
						              each name asString = repositoryName ].
					self assert: repository index isEmpty.
					result := self callToolWith: {
						          (#action -> 'diff').
						          (#repositoryName -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					childNames := self directChildNamesOf: location.
					self deny: (result at: #isError ifAbsent: false).
					self
						assert: data keys asSet
						equals: #( changeCount changedPackageNames isEmpty ) asSet.
					self assert: (data at: #isEmpty) equals: false.
					self assert: (data at: #changeCount) > 0.
					self assert: (data at: #changedPackageNames) equals: { packageName }.
					self deny: (data includesKey: #modifiedPaths).
					self deny: (childNames anySatisfy: [ :each |
							 each includesSubstring: packageName ]) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportUpdatesDiskAndIndexWithoutCommitting [

	| childNames data location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Export Test'.
	packageName := 'MCPToolRepositoryOperationExportPackage'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestExport'.
	self
		withExportPackageNamed: packageName
		className: 'MCPToolRepositoryOperationExportClass'
		do: [
				self
					withCleanRepositoryNamed: repositoryName
					location: location
					do: [
							self callToolWith: {
									(#action -> 'create').
									(#name -> repositoryName).
									(#location -> location pathString).
									(#packageNames -> { packageName }) } asDictionary.
							result := self callToolWith: {
									          (#action -> 'export').
									          (#repositoryName -> repositoryName) } asDictionary.
							data := self dataFrom: result.
							childNames := self directChildNamesOf: location.
							self
								deny: (self resultIndicatesError: result)
								description: (self summaryFrom: result).
							self
								assert: data keys asSet
								equals: #( changedPackageNames didChange modifiedPaths ) asSet.
							self assert: (data at: #didChange) equals: true.
							self
								assert: (data at: #changedPackageNames)
								equals: { packageName }.
							self assert: (data at: #modifiedPaths) notEmpty.
							self assert:
								(childNames anySatisfy: [ :each |
									 each includesSubstring: packageName ]) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testFetchReturnsResultShapeAndReportsErrors [

	| data errorResult repository result |
	repository := self newTestRepositoryNamed:
		              'MCP Fetch Test Repository'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'fetch').
					          (#repositoryName -> repository name) } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self
				assert: repository actionLog asArray
				equals: #( 'fetch:origin' ).
			self
				assert: data keys asSet
				equals: #( branchName headDescription ) asSet.
			self assert: (data at: #branchName) equals: 'main'.
			self assert: (data at: #headDescription) equals: 'initial' ].
	repository := self newTestRepositoryNamed:
		              'MCP Fetch Error Test Repository'.
	repository failFetch: true.
	self withRegisteredRepository: repository do: [
			errorResult := self callToolWith: {
					               (#action -> 'fetch').
					               (#repositoryName -> repository name) }
					               asDictionary.
			self assert: (self resultIndicatesError: errorResult).
			self assert: ((self summaryFrom: errorResult) includesSubstring:
					 'Failed to fetch repository') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testGitCommandFailureSignalsStructuredCommandError [

	| command error |
	command := MCPPushRepositoryCommand
		           tool: MCPToolPushRepository new
		           request: nil.
	error := [
		         command
			         signalGitCommandFailed: {
				         (#status -> 128).
				         (#output -> 'fatal: no upstream') } asDictionary
			         action: 'push'.
		         nil ]
		         on: MCPCommandError
		         do: [ :caught | caught ].
	self assert: error errorCode equals: 'pushGitCommandFailed'.
	self assert: error messageText equals: 'fatal: no upstream'.
	self assert: (error details at: #exitStatus) equals: 128.
	self assert: (error details at: #output) equals: 'fatal: no upstream'
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testLinkedWorktreeAttachReportsGitMetadataAndExportsOnLinkedBranch [

	| repositoryName packageName initialClassName exportedClassName location linkedLocation branchName createResult exportResult commitResult repository headCommitId attachResult searchResult searchData entry exportedClassFile |
	repositoryName := 'MCP Repository Command Linked Worktree Contract Test'.
	packageName := 'MCPToolRepositoryOperationLinkedWorktreePackage'.
	initialClassName := 'MCPToolRepositoryOperationLinkedWorktreeClass'.
	exportedClassName := 'MCPToolRepositoryOperationLinkedWorktreeExportClass'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestLinkedWorktreeBase'.
	linkedLocation := self temporaryRepositoryLocationNamed:
		                  'MCPToolRepositoryOperationTestLinkedWorktree'.
	branchName := 'attach-linked-test'.
	exportedClassFile := linkedLocation / 'src' / packageName
	                     / (exportedClassName , '.class.st').
	self
		withExportPackageNamed: packageName
		className: initialClassName
		do: [
				self
					withCleanRepositoryNamed: repositoryName
					location: location
					do: [
							linkedLocation exists ifTrue: [ linkedLocation deleteAll ].
							createResult := self callToolWith: {
									                (#action -> 'create').
									                (#name -> repositoryName).
									                (#location -> location pathString).
									                (#subdirectory -> 'src').
									                (#packageNames -> { packageName }) }
									                asDictionary.
							self
								deny: (self resultIndicatesError: createResult)
								description: (self summaryFrom: createResult).
							exportResult := self callToolWith: {
									                (#action -> 'export').
									                (#repositoryName -> repositoryName) }
									                asDictionary.
							self
								deny: (self resultIndicatesError: exportResult)
								description: (self summaryFrom: exportResult).
							commitResult := self callToolWith: {
									                (#action -> 'commit').
									                (#repositoryName -> repositoryName).
									                (#message
									                 -> 'Prepare linked checkout contract test') }
									                asDictionary.
							self
								deny: (self resultIndicatesError: commitResult)
								description: (self summaryFrom: commitResult).
							repository := IceRepository registry detect: [ :each |
								              each name = repositoryName ].
							headCommitId := MCPIcebergCommitInfo idStringFrom:
								                repository headCommit.
							self shellCommand:
								'git -C ' , (self shellQuote: location pathString)
								, ' remote add origin https://example.com/worktree.git'.
							self shellCommand:
								'git -C ' , (self shellQuote: location pathString)
								, ' worktree add -b ' , branchName , ' '
								, (self shellQuote: linkedLocation pathString).
							[
								self shellCommand:
									'git -C ' , (self shellQuote: linkedLocation pathString)
									, ' config branch.' , branchName , '.remote origin'.
								self shellCommand:
									'git -C ' , (self shellQuote: linkedLocation pathString)
									, ' config branch.' , branchName , '.merge refs/heads/'
									, branchName.
								self removeRegisteredRepositoriesNamed: repositoryName.
								attachResult := self callToolWith: {
										                (#action -> 'attach').
										                (#name -> repositoryName).
										                (#location -> linkedLocation pathString).
										                (#subdirectory -> 'src').
										                (#packageNames -> { packageName }) }
										                asDictionary.
								self
									deny: (self resultIndicatesError: attachResult)
									description: (self summaryFrom: attachResult).
								searchResult := self searchRepositoriesWith: {
										                (#repositoryName -> repositoryName).
										                (#filterMode -> 'exact').
										                (#includeDetails -> true) } asDictionary.
								self
									deny: (self resultIndicatesError: searchResult)
									description: (self summaryFrom: searchResult).
								searchData := self dataFrom: searchResult.
								entry := (searchData at: #repositories) anyOne.
								self
									assert: (entry at: #location)
									equals: linkedLocation pathString.
								self assert: (entry at: #branchName) equals: branchName.
								self assert: (entry at: #headCommitId) equals: headCommitId.
								self assert: (entry at: #upstreamRemoteName) equals: 'origin'.
								self
									assert: (entry at: #upstreamBranchName)
									equals: branchName.
								self
									assert: (entry at: #upstreamRemoteUrl)
									equals: 'https://example.com/worktree.git'.
								self
									createClassNamed: exportedClassName
									inPackageNamed: packageName.
								exportResult := self callToolWith: {
										                (#action -> 'export').
										                (#repositoryName -> repositoryName) }
										                asDictionary.
								self
									deny: (self resultIndicatesError: exportResult)
									description: (self summaryFrom: exportResult).
								self assert: exportedClassFile exists ] ensure: [
									self removeClassNamed: exportedClassName.
									self shellCommand:
										'git -C ' , (self shellQuote: location pathString)
										, ' worktree remove --force '
										, (self shellQuote: linkedLocation pathString).
									linkedLocation exists ifTrue: [ linkedLocation deleteAll ] ] ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPullReportsIcebergMergeAndLoadErrors [

	| loadErrorResult mergeErrorResult repository |
	repository := self newTestRepositoryNamed:
		              'MCP Pull Merge Error Test Repository'.
	repository failPull:
		IceMergeAborted -> 'Iceberg merge failed for test repository'.
	self withRegisteredRepository: repository do: [
			mergeErrorResult := self callToolWith: {
					                    (#action -> 'pull').
					                    (#repositoryName -> repository name) }
					                    asDictionary.
			self assert: (self resultIndicatesError: mergeErrorResult).
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
					                   (#action -> 'pull').
					                   (#repositoryName -> repository name) }
					                   asDictionary.
			self assert: (self resultIndicatesError: loadErrorResult).
			self assert:
				((self summaryFrom: loadErrorResult) includesSubstring:
					 'Failed to pull repository').
			self assert:
				((self summaryFrom: loadErrorResult) includesSubstring:
					 'Iceberg load failed') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPullReturnsResultReportsErrorsAndRequestsImageSave [

	| data errorResult repository result saveResult server |
	repository := self newTestRepositoryNamed: 'MCP Pull Test Repository'.
	self withRegisteredRepository: repository do: [
			server := MCPSaveImageRecordingServer new.
			result := self callToolWith: {
					          (#action -> 'pull').
					          (#repositoryName -> repository name) } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self assert: repository actionLog asArray equals: #( 'pull' ).
			self
				assert: data keys asSet
				equals: #( branchName headDescription modifiedPackageNames ) asSet.
			self assert: (data at: #headDescription) equals: 'after pull'.
			self
				assert: (data at: #modifiedPackageNames)
				equals: #( 'MCP-Test-Pulled' ).
			saveResult := server
				              rpcToolCall: 'repository_pull'
				              withParams:
				              { (#repositoryName -> repository name) }
					              asDictionary.
			self
				deny: (self resultIndicatesError: saveResult)
				description: (self summaryFrom: saveResult).
			self assert: server didSaveImageSession ].
	repository := self newTestRepositoryNamed:
		              'MCP Pull Error Test Repository'.
	repository failPull: true.
	self withRegisteredRepository: repository do: [
			errorResult := self callToolWith: {
					               (#action -> 'pull').
					               (#repositoryName -> repository name) }
					               asDictionary.
			self assert: (self resultIndicatesError: errorResult).
			self assert: ((self summaryFrom: errorResult) includesSubstring:
					 'Failed to pull repository') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPushPublishesCurrentBranchUsingRequestedRemoteName [

	| bareLocation branchName commitAfter location remoteHead repository repositoryName result upstream |
	repositoryName := 'MCP Push Requested Remote Test Repository'.
	branchName := 'feature/requested-remote'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestGitPushRequestedRemote'.
	bareLocation := self temporaryRepositoryLocationNamed:
		                'MCPToolRepositoryOperationTestGitPushRequestedRemote.git'.
	[
		self deleteDirectoryIfExists: location.
		self deleteDirectoryIfExists: bareLocation.
		location ensureCreateDirectory.
		self shellCommand: 'git init --initial-branch=main '
			, (self shellQuote: location pathString).
		location / 'README.md' writeStreamDo: [ :stream |
			stream nextPutAll: 'initial' ].
		self commitAllIn: location message: 'Initial local commit'.
		self shellCommand: 'git init --bare --initial-branch=main '
			, (self shellQuote: bareLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' remote add backup '
			, (self shellQuote: bareLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' checkout -b ' , (self shellQuote: branchName).
		location / 'feature.txt' writeStreamDo: [ :stream |
			stream nextPutAll: 'feature' ].
		self commitAllIn: location message: 'Feature local commit'.
		commitAfter := (LibC resultOfCommand:
			                'git -C ' , (self shellQuote: location pathString)
			                , ' rev-parse HEAD') trimBoth.
		repository := MCPTestIceRepository
			              named: repositoryName
			              location: location pathString.
		self withRegisteredRepository: repository do: [
				result := self callToolWith: {
						          (#action -> 'push').
						          (#repositoryName -> repositoryName).
						          (#remoteName -> 'backup') } asDictionary.
				self
					deny: (self resultIndicatesError: result)
					description: (self summaryFrom: result).
				remoteHead := (LibC resultOfCommand:
					               'git --git-dir '
					               , (self shellQuote: bareLocation pathString)
					               , ' rev-parse ' , (self shellQuote: branchName))
					              trimBoth.
				self assert: remoteHead equals: commitAfter.
				upstream := (LibC resultOfCommand:
					             'git -C ' , (self shellQuote: location pathString)
					             , ' rev-parse --abbrev-ref --symbolic-full-name '
					             , (self shellQuote: '@{u}')) trimBoth.
				self assert: upstream equals: 'backup/' , branchName ] ] ensure: [
			self deleteDirectoryIfExists: location.
			self deleteDirectoryIfExists: bareLocation ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPushPublishesCurrentBranchWhenUpstreamIsMissing [

	| bareLocation branchName commitAfter location remoteHead repository repositoryName result upstream |
	repositoryName := 'MCP Push Missing Upstream Test Repository'.
	branchName := 'feature/publish-upstream'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestGitPushMissingUpstream'.
	bareLocation := self temporaryRepositoryLocationNamed:
		                'MCPToolRepositoryOperationTestGitPushMissingUpstreamRemote.git'.
	[
		self deleteDirectoryIfExists: location.
		self deleteDirectoryIfExists: bareLocation.
		location ensureCreateDirectory.
		self shellCommand: 'git init --initial-branch=main '
			, (self shellQuote: location pathString).
		location / 'README.md' writeStreamDo: [ :stream |
			stream nextPutAll: 'initial' ].
		self commitAllIn: location message: 'Initial local commit'.
		self shellCommand: 'git init --bare --initial-branch=main '
			, (self shellQuote: bareLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' remote add origin '
			, (self shellQuote: bareLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' checkout -b ' , (self shellQuote: branchName).
		location / 'feature.txt' writeStreamDo: [ :stream |
			stream nextPutAll: 'feature' ].
		self commitAllIn: location message: 'Feature local commit'.
		commitAfter := (LibC resultOfCommand:
			                'git -C ' , (self shellQuote: location pathString)
			                , ' rev-parse HEAD') trimBoth.
		repository := MCPTestIceRepository
			              named: repositoryName
			              location: location pathString.
		self withRegisteredRepository: repository do: [
				result := self callToolWith: {
						          (#action -> 'push').
						          (#repositoryName -> repositoryName) } asDictionary.
				self
					deny: (self resultIndicatesError: result)
					description: (self summaryFrom: result).
				self assert: repository actionLog asArray equals: #(  ).
				remoteHead := (LibC resultOfCommand:
					               'git --git-dir '
					               , (self shellQuote: bareLocation pathString)
					               , ' rev-parse ' , (self shellQuote: branchName))
					              trimBoth.
				self assert: remoteHead equals: commitAfter.
				upstream := (LibC resultOfCommand:
					             'git -C ' , (self shellQuote: location pathString)
					             , ' rev-parse --abbrev-ref --symbolic-full-name '
					             , (self shellQuote: '@{u}')) trimBoth.
				self assert: upstream equals: 'origin/' , branchName ] ] ensure: [
			self deleteDirectoryIfExists: location.
			self deleteDirectoryIfExists: bareLocation ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPushReportsRemoteAndAuthenticationErrors [

	| authErrorResult remoteErrorResult repository |
	repository := self newTestRepositoryNamed:
		              'MCP Push Remote Error Test Repository'.
	repository failPush: IceRemoteNotFoundError
		-> 'Iceberg remote not found for test repository'.
	self withRegisteredRepository: repository do: [
			remoteErrorResult := self callToolWith: {
					                     (#action -> 'push').
					                     (#repositoryName -> repository name) }
					                     asDictionary.
			self assert: (self resultIndicatesError: remoteErrorResult).
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
					                   (#action -> 'push').
					                   (#repositoryName -> repository name) }
					                   asDictionary.
			self assert: (self resultIndicatesError: authErrorResult).
			self assert:
				((self summaryFrom: authErrorResult) includesSubstring:
					 'Failed to push repository').
			self assert:
				((self summaryFrom: authErrorResult) includesSubstring:
					 'Iceberg authentication failed') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPushRequiresRemoteNameWhenMultipleNonOriginRemotesExist [

	| backupLocation branchName forkLocation location repository repositoryName result |
	repositoryName := 'MCP Push Ambiguous Remote Test Repository'.
	branchName := 'feature/ambiguous-remote'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestGitPushAmbiguousRemote'.
	backupLocation := self temporaryRepositoryLocationNamed:
		                  'MCPToolRepositoryOperationTestGitPushBackupRemote.git'.
	forkLocation := self temporaryRepositoryLocationNamed:
		                'MCPToolRepositoryOperationTestGitPushForkRemote.git'.
	[
		self deleteDirectoryIfExists: location.
		self deleteDirectoryIfExists: backupLocation.
		self deleteDirectoryIfExists: forkLocation.
		location ensureCreateDirectory.
		self shellCommand: 'git init --initial-branch=main '
			, (self shellQuote: location pathString).
		location / 'README.md' writeStreamDo: [ :stream |
			stream nextPutAll: 'initial' ].
		self commitAllIn: location message: 'Initial local commit'.
		self shellCommand: 'git init --bare --initial-branch=main '
			, (self shellQuote: backupLocation pathString).
		self shellCommand: 'git init --bare --initial-branch=main '
			, (self shellQuote: forkLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' remote add backup '
			, (self shellQuote: backupLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' remote add fork ' , (self shellQuote: forkLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' checkout -b ' , (self shellQuote: branchName).
		location / 'feature.txt' writeStreamDo: [ :stream |
			stream nextPutAll: 'feature' ].
		self commitAllIn: location message: 'Feature local commit'.
		repository := MCPTestIceRepository
			              named: repositoryName
			              location: location pathString.
		self withRegisteredRepository: repository do: [
				result := self callToolWith: {
						          (#action -> 'push').
						          (#repositoryName -> repositoryName) } asDictionary.
				self assert: (self resultIndicatesError: result).
				self
					assert: ((self errorFrom: result) at: #errorCode)
					equals: 'RepositoryRemoteRequired' ] ] ensure: [
			self deleteDirectoryIfExists: location.
			self deleteDirectoryIfExists: backupLocation.
			self deleteDirectoryIfExists: forkLocation ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPushReturnsResultReportsErrorsAndRequestsImageSave [

	| data errorResult repository result saveResult server |
	repository := self newTestRepositoryNamed: 'MCP Push Test Repository'.
	self withRegisteredRepository: repository do: [
			server := MCPSaveImageRecordingServer new.
			result := self callToolWith: {
					          (#action -> 'push').
					          (#repositoryName -> repository name) } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self assert: repository actionLog asArray equals: #( 'push' ).
			self
				assert: data keys asSet
				equals: #( branchName headDescription ) asSet.
			self assert: (data at: #headDescription) equals: 'after push'.
			saveResult := server
				              rpcToolCall: 'repository_push'
				              withParams:
				              { (#repositoryName -> repository name) }
					              asDictionary.
			self
				deny: (self resultIndicatesError: saveResult)
				description: (self summaryFrom: saveResult).
			self assert: server didSaveImageSession ].
	repository := self newTestRepositoryNamed:
		              'MCP Push Error Test Repository'.
	repository failPush: true.
	self withRegisteredRepository: repository do: [
			errorResult := self callToolWith: {
					               (#action -> 'push').
					               (#repositoryName -> repository name) }
					               asDictionary.
			self assert: (self resultIndicatesError: errorResult).
			self assert: ((self summaryFrom: errorResult) includesSubstring:
					 'Failed to push repository') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPushUsesGitCommandForRealWorktree [

	| bareLocation commitAfter location remoteHead repository repositoryName result |
	repositoryName := 'MCP Push Git Command Test Repository'.
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestGitPush'.
	bareLocation := self temporaryRepositoryLocationNamed:
		                'MCPToolRepositoryOperationTestGitPushRemote.git'.
	[
		self deleteDirectoryIfExists: location.
		self deleteDirectoryIfExists: bareLocation.
		location ensureCreateDirectory.
		self shellCommand:
			'git init --initial-branch=main ' , (self shellQuote: location pathString).
		(location / 'README.md') writeStreamDo: [ :stream |
			stream nextPutAll: 'initial' ].
		self commitAllIn: location message: 'Initial local commit'.
		self shellCommand:
			'git init --bare --initial-branch=main '
			, (self shellQuote: bareLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' remote add origin ' , (self shellQuote: bareLocation pathString).
		self shellCommand:
			'git -C ' , (self shellQuote: location pathString)
			, ' push -u origin main'.
		(location / 'README.md') writeStreamDo: [ :stream |
			stream nextPutAll: 'updated' ].
		self commitAllIn: location message: 'Second local commit'.
		commitAfter := (LibC resultOfCommand:
			                'git -C ' , (self shellQuote: location pathString)
			                , ' rev-parse HEAD') trimBoth.
	repository := MCPTestIceRepository
		              named: repositoryName
		              location: location pathString.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
				          (#action -> 'push').
				          (#repositoryName -> repositoryName) } asDictionary.
			self deny: (result at: #isError ifAbsent: false).
			self assert: repository actionLog asArray equals: #( ).
			remoteHead := (LibC resultOfCommand:
				               'git --git-dir '
				               , (self shellQuote: bareLocation pathString)
				               , ' rev-parse main') trimBoth.
			self assert: remoteHead equals: commitAfter ] ] ensure: [
		self deleteDirectoryIfExists: location.
		self deleteDirectoryIfExists: bareLocation ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testRemoteAndBranchOperationsParseAndDispatch [

	| cases |
	cases := {
		         {
			         (#toolClass -> MCPToolFetchRepository).
			         (#action -> 'fetch').
			         (#requestClass -> MCPRepositoryFetchRequest).
			         (#commandClass -> MCPFetchRepositoryCommand).
			         (#arguments -> { (#repositoryName -> 'MCP') } asDictionary) }
			         asDictionary.
		         {
			         (#toolClass -> MCPToolPullRepository).
			         (#action -> 'pull').
			         (#requestClass -> MCPRepositoryPullRequest).
			         (#commandClass -> MCPPullRepositoryCommand).
			         (#arguments -> { (#repositoryName -> 'MCP') } asDictionary) }
			         asDictionary.
		         {
			         (#toolClass -> MCPToolPushRepository).
			         (#action -> 'push').
			         (#requestClass -> MCPRepositoryPushRequest).
			         (#commandClass -> MCPPushRepositoryCommand).
			         (#arguments -> { (#repositoryName -> 'MCP') } asDictionary) }
			         asDictionary.
		         {
			         (#toolClass -> MCPToolCreateRepositoryBranch).
			         (#action -> 'createBranch').
			         (#requestClass -> MCPRepositoryCreateBranchRequest).
			         (#commandClass -> MCPCreateRepositoryBranchCommand).
			         (#arguments -> {
				          (#repositoryName -> 'MCP').
				          (#branchName -> 'feature') } asDictionary) }
			         asDictionary.
		         {
			         (#toolClass -> MCPToolSwitchRepositoryBranch).
			         (#action -> 'switchBranch').
			         (#requestClass -> MCPRepositorySwitchBranchRequest).
			         (#commandClass -> MCPSwitchRepositoryBranchCommand).
			         (#arguments -> {
				          (#repositoryName -> 'MCP').
				          (#branchName -> 'main') } asDictionary) } asDictionary.
		         {
			         (#toolClass -> MCPToolCheckoutRepositoryBranch).
			         (#action -> 'checkoutBranch').
			         (#requestClass -> MCPRepositoryCheckoutBranchRequest).
			         (#commandClass -> MCPCheckoutRepositoryBranchCommand).
			         (#arguments -> {
				          (#repositoryName -> 'MCP').
				          (#branchName -> 'main') } asDictionary) } asDictionary }.
	cases do: [ :each |
			| command parsedRequest rawRequest tool |
			tool := (each at: #toolClass) new.
			rawRequest := tool requestFromToolCallArguments:
				              (each at: #arguments).
			parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
			command := tool commandForRequest: parsedRequest.
			self assert: parsedRequest class equals: (each at: #requestClass).
			self assert: parsedRequest operation equals: (each at: #action).
			self assert: command class equals: (each at: #commandClass) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testRepositoryErrorDetailsUseActionNotOperation [

	| errorDetails repository result |
	repository := self newTestRepositoryNamed:
		              'MCP Repository Error Action Test Repository'.
	repository failPush: true.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'push').
					          (#repositoryName -> repository name) } asDictionary.
			self assert: (self resultIndicatesError: result).
			errorDetails := self errorFrom: result.
			self assert: (errorDetails at: #action) equals: 'push'.
			self deny: (errorDetails includesKey: #operation).
			self deny: (errorDetails includesKey: #updateAction) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testRestoreOrderOnlyTonelChurnRestoresOriginalFile [

	| command file location packageDirectory repository restored snapshot |
	location := self temporaryRepositoryLocationNamed:
		            'MCPToolRepositoryOperationTestOrderOnly'.
	self deleteDirectoryIfExists: location.
	[
		packageDirectory := location / 'MCP-Order'.
		packageDirectory ensureCreateDirectory.
		file := packageDirectory / 'MCPOrderTestClass.class.st'.
		file writeStreamDo: [ :stream |
				stream nextPutAll:
					(self tonelClassSourceWithMethods: #( 'alpha' 'beta' )) ].
		repository := self
			              newRepositoryNamed: 'MCP Order Only Test'
			              location: location
			              packageNames: #(  ).
		command := MCPExportRepositoryCommand new.
		snapshot := command snapshotTonelFilesFor: repository.
		file writeStreamDo: [ :stream |
				stream nextPutAll:
					(self tonelClassSourceWithMethods: #( 'beta' 'alpha' )) ].
		restored := command
			            restoreOrderOnlyTonelChurnFor: repository
			            fromSnapshot: snapshot.
		self
			assert: restored
			equals: #( 'MCP-Order/MCPOrderTestClass.class.st' ).
		self
			assert: file contents
			equals: (self tonelClassSourceWithMethods: #( 'alpha' 'beta' )) ]
		ensure: [ self deleteDirectoryIfExists: location ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testSwitchBranchReturnsResultReportsErrorsAndRequestsImageSave [

	| data conflictResult loadResult missingResult repository result saveResult server |
	repository := self newTestRepositoryNamed:
		              'MCP Switch Branch Test Repository'.
	repository createBranch: 'feature'.
	repository switchToBranchNamed: 'main'.
	self withRegisteredRepository: repository do: [
			server := MCPSaveImageRecordingServer new.
			result := self callToolWith: {
					          (#action -> 'switchBranch').
					          (#repositoryName -> repository name).
					          (#branchName -> 'feature') } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self
				assert: data keys asSet
				equals:
					#( branchName headDescription previousBranchName
					   previousHeadDescription ) asSet.
			self assert: (data at: #previousBranchName) equals: 'main'.
			self assert: (data at: #branchName) equals: 'feature'.
			self
				assert: (data at: #previousHeadDescription)
				equals: 'branch main'.
			self assert: (data at: #headDescription) equals: 'branch feature'.
			saveResult := server
				              rpcToolCall: 'repository_branch_switch'
				              withParams: {
						              (#repositoryName -> repository name).
						              (#branchName -> 'main') } asDictionary.
			self
				deny: (self resultIndicatesError: saveResult)
				description: (self summaryFrom: saveResult).
			self assert: server didSaveImageSession.
			missingResult := self callToolWith: {
					                 (#action -> 'switchBranch').
					                 (#repositoryName -> repository name).
					                 (#branchName -> 'missing') } asDictionary.
			self assert: (self resultIndicatesError: missingResult).
			self assert: ((self summaryFrom: missingResult) includesSubstring:
					 'Failed to switch repository branch').
			self assert: ((self summaryFrom: missingResult) includesSubstring:
					 'Branch not found') ].
	repository := self newTestRepositoryNamed:
		              'MCP Switch Branch Conflict Test Repository'.
	repository createBranch: 'feature'.
	repository failSwitchBranch: IceCheckoutConflictError
		-> 'Iceberg checkout conflict test repository'.
	self withRegisteredRepository: repository do: [
			conflictResult := self callToolWith: {
					                  (#action -> 'switchBranch').
					                  (#repositoryName -> repository name).
					                  (#branchName -> 'feature') } asDictionary.
			self assert: (self resultIndicatesError: conflictResult).
			self assert:
				((self summaryFrom: conflictResult) includesSubstring:
					 'Failed to switch repository branch').
			self assert:
				((self summaryFrom: conflictResult) includesSubstring:
					 'Iceberg checkout conflict') ].
	repository := self newTestRepositoryNamed:
		              'MCP Switch Branch Load Test Repository'.
	repository createBranch: 'feature'.
	repository failSwitchBranch:
		IceGenericError -> 'Iceberg load failed test repository'.
	self withRegisteredRepository: repository do: [
			loadResult := self callToolWith: {
					              (#action -> 'switchBranch').
					              (#repositoryName -> repository name).
					              (#branchName -> 'feature') } asDictionary.
			self assert: (self resultIndicatesError: loadResult).
			self assert: ((self summaryFrom: loadResult) includesSubstring:
					 'Failed to switch repository branch').
			self assert: ((self summaryFrom: loadResult) includesSubstring:
					 'Iceberg load failed') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testTonelMethodOrderComparisonIgnoresMethodChunkOrder [

	| command original reordered |
	command := MCPExportRepositoryCommand new.
	original := self tonelClassSourceWithMethods: #( 'alpha' 'beta' ).
	reordered := self tonelClassSourceWithMethods: #( 'beta' 'alpha' ).
	self assert:
		(command tonelMethodOrderEquivalent: original to: reordered)
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
	repository := self
		              newRepositoryNamed: 'MCP Repository Command Add Test'
		              location: FileLocator imageDirectory
		              packageNames: #(  ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'update').
					          (#repositoryName -> repository name).
					          (#addPackageNames -> { packageName }) } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self
				assert: (self packageNamesIn: repository)
				equals: { packageName }.
			self
				assert: data keys asSet
				equals: #( addedPackageNames updateActions ) asSet.
			self assert: (data at: #updateActions) equals: #( 'addPackages' ).
			self assert: (data at: #addedPackageNames) equals: { packageName } ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateCanReplacePackageMembership [

	| data repository result |
	repository := self
		              newRepositoryNamed:
		              'MCP Repository Command Replace Test'
		              location: FileLocator imageDirectory
		              packageNames:
		              #( 'MCPToolRepositoryOperationOldA'
		                 'MCPToolRepositoryOperationOldB' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'update').
					          (#repositoryName -> repository name).
					          (#packageNames
					           ->
					           #( 'MCPToolRepositoryOperationNewC'
					              'MCPToolRepositoryOperationOldB' )) } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self
				assert: (self packageNamesIn: repository)
				equals:
				#( 'MCPToolRepositoryOperationNewC'
				   'MCPToolRepositoryOperationOldB' ).
			self
				assert: (data at: #updateActions)
				equals: #( 'replacePackages' ).
			self
				assert: (data at: #addedPackageNames)
				equals: #( 'MCPToolRepositoryOperationNewC' ).
			self
				assert: (data at: #removedPackageNames)
				equals: #( 'MCPToolRepositoryOperationOldA' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateRemovesPackageWithoutUnloading [

	| data packageName repository result |
	packageName := 'MCPToolRepositoryOperationRemovalPackage'.
	self withoutEpiceaDuring: [
		PackageOrganizer default ensurePackage: packageName ].
	[
		repository := self
			              newRepositoryNamed:
			              'MCP Repository Command Remove Test'
			              location: FileLocator imageDirectory
			              packageNames: { packageName }.
		self withRegisteredRepository: repository do: [
				result := self callToolWith: {
						          (#action -> 'update').
						          (#repositoryName -> repository name).
						          (#removePackageNames -> { packageName }) }
						          asDictionary.
				data := self dataFrom: result.
				self
					deny: (self resultIndicatesError: result)
					description: (self summaryFrom: result).
				self assert: (self packageNamesIn: repository) equals: #(  ).
				self assert: (PackageOrganizer default hasPackage: packageName).
				self
					assert: data keys asSet
					equals: #( removedPackageNames updateActions ) asSet.
				self
					assert: (data at: #updateActions)
					equals: #( 'removePackages' ).
				self
					assert: (data at: #removedPackageNames)
					equals: { packageName } ] ] ensure: [
		self removePackageNamed: packageName ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityDoesNotRequestImageSaveAfterSuccessfulExecution [

	| repository result server |
	repository := self newTestRepositoryNamed:
		              'MCP VerifyIdentity Save Test Repository'.
	self withRegisteredRepository: repository do: [
			server := MCPSaveImageRecordingServer new.
			result := server
				          rpcToolCall: 'repository_identity_verify'
				          withParams: {
						          (#repositoryName -> repository name).
						          (#branchName -> 'main') } asDictionary.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self deny: server didSaveImageSession ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityOperationRequiresRepositoryAndParses [

	| command parsedRequest rawRequest tool |
	tool := MCPToolVerifyRepositoryIdentity new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#repositoryName -> 'MCP').
			              (#branchName -> 'main').
			              (#packageNames -> #( 'MCP' )).
			              (#isModified -> false) } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.

	self
		assert: parsedRequest class
		equals: MCPRepositoryVerifyIdentityRequest.
	self assert: parsedRequest operation equals: 'verifyIdentity'.
	self assert: parsedRequest branchName equals: 'main'.
	self assert: parsedRequest isModified equals: false.
	self assert: command class equals: MCPRepositoryVerifyIdentityCommand
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityPassesWhenExpectedIdentityMatches [

	| data repository result |
	repository := self newTestRepositoryNamed:
		              'MCP VerifyIdentity Match Test Repository'.
	repository workingCopy packageNames: #( 'MCP-Tests' 'MCP' ).
	repository modifiedPackageNames: #( 'MCP' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#repositoryName -> repository name).
					          (#location -> repository location).
					          (#branchName -> 'main').
					          (#subdirectory -> '').
					          (#packageNames -> #( 'MCP' 'MCP-Tests' )).
					          (#modifiedPackageNames -> #( 'MCP' )).
					          (#isModified -> true) } asDictionary.
			data := self dataFrom: result.
			self
				deny: (self resultIndicatesError: result)
				description: (self summaryFrom: result).
			self assert: data keys asSet equals: #( matched ) asSet.
			self assert: (data at: #matched).
			self assert: repository actionLog asArray equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityReportsStructuredMismatch [

	| branchMismatch errorDetails mismatchFields repository result |
	repository := self newTestRepositoryNamed:
		              'MCP VerifyIdentity Mismatch Test Repository'.
	repository workingCopy packageNames: #( 'MCP' ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#repositoryName -> repository name).
					          (#branchName -> 'feature').
					          (#packageNames -> #( 'MCP' 'MCP-Tests' )).
					          (#isModified -> true) } asDictionary.
			self assert: (self resultIndicatesError: result).
			self assert: ((self summaryFrom: result) includesSubstring:
					 'Repository identity verification failed').
			errorDetails := self errorFrom: result.
			self
				assert: (errorDetails at: #errorCode)
				equals: 'RepositoryIdentityMismatch'.
			self assert: (errorDetails at: #action) equals: 'verifyIdentity'.
			mismatchFields := (errorDetails at: #mismatches) collect: [ :each |
				                  each at: #field ].
			self
				assert: mismatchFields asArray sort
				equals: #( 'branchName' 'isModified' 'packageNames' ).
			branchMismatch := (errorDetails at: #mismatches) detect: [ :each |
				                  (each at: #field) = 'branchName' ].
			self assert: (branchMismatch at: #expected) equals: 'feature'.
			self assert: (branchMismatch at: #actual) equals: 'main'.
			self assert: repository actionLog asArray equals: #(  ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityReportsWrongLocationAsIdentityMismatch [

	| errorDetails locationMismatch repository result |
	repository := self newTestRepositoryNamed:
		              'MCP VerifyIdentity Location Mismatch Test Repository'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#repositoryName -> repository name).
					          (#location -> 'memory://different-location') }
					          asDictionary.
			self assert: (self resultIndicatesError: result).
			errorDetails := self errorFrom: result.
			self
				assert: (errorDetails at: #errorCode)
				equals: 'RepositoryIdentityMismatch'.
			locationMismatch := (errorDetails at: #mismatches) detect: [ :each |
				                    (each at: #field) = 'location' ].
			self
				assert: (locationMismatch at: #expected)
				equals: 'memory://different-location'.
			self
				assert: (locationMismatch at: #actual)
				equals: repository location ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testVerifyIdentityRequiresExpectedIdentityField [

	| errorDetails repository result |
	repository := self newTestRepositoryNamed:
		              'MCP VerifyIdentity Missing Expected Field Test Repository'.
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'verifyIdentity').
					          (#repositoryName -> repository name) } asDictionary.
			self assert: (self resultIndicatesError: result).
			errorDetails := self errorFrom: result.
			self
				assert: (errorDetails at: #errorCode)
				equals: 'RepositoryIdentityExpectationRequired'.
			self assert: ((self summaryFrom: result) includesSubstring:
					 'requires at least one expected identity field') ]
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
