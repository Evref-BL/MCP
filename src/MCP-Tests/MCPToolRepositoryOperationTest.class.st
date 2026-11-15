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
MCPToolRepositoryOperationTest >> attachRepositoryNamed: aRepositoryName location: aLocationString packages: packageNames [

	^ self callToolWith: {
			  (#action -> 'attach').
			  (#name -> aRepositoryName).
			  (#location -> aLocationString).
			  (#packages -> packageNames) } asDictionary
]

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

	self shellCommand:
		(String streamContents: [ :stream | stream << 'git -C ' << (self shellQuote: aRepositoryLocation pathString) << ' add .' ]).
	self shellCommand: (String streamContents: [ :stream |
				 stream << 'git -C ' << (self shellQuote: aRepositoryLocation pathString) << ' -c user.name=' << (self shellQuote: 'MCP Test')
				 << ' -c user.email=' << (self shellQuote: 'mcp-test@example.com') << ' commit -m ' << (self shellQuote: aMessage) ])
]

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> commitCheckoutNamed: aRepositoryName at: aLocation holding: aPackageName [
	"A checkout with .project and one commit holding the package under src, left unregistered."

	self
		createRepositoryNamed: aRepositoryName
		location: aLocation
		subdirectory: 'src'
		packages: { aPackageName }.
	self exportRepositoryNamed: aRepositoryName.
	self commitRepositoryNamed: aRepositoryName message: 'Hold the package'.
	self removeRegisteredRepositoriesNamed: aRepositoryName
]

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> commitRepositoryNamed: aRepositoryName message: aMessage [

	^ self callToolWith: {
			  (#action -> 'commit').
			  (#name -> aRepositoryName).
			  (#message -> aMessage) } asDictionary
]

{ #category : 'private - classes' }
MCPToolRepositoryOperationTest >> createClassNamed: aClassName inPackageNamed: aPackageName [

	^ self withoutEpiceaDuring: [
			  | builder |
			  self packageOrganizer ensurePackage: aPackageName.
			  builder := Object << aClassName asSymbol.
			  builder package: aPackageName.
			  builder tag: 'Generated'.
			  builder install ]
]

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> createRepositoryNamed: aRepositoryName location: aLocation subdirectory: aSubdirectory packages: packageNames [
	"Create the repository through the tool and fail the test if it refuses; a nil subdirectory keeps the sources at the root."

	| arguments result |
	arguments := Dictionary new
		             at: #action put: 'create';
		             at: #name put: aRepositoryName;
		             at: #location put: aLocation pathString;
		             at: #packages put: packageNames;
		             yourself.
	aSubdirectory ifNotNil: [ arguments at: #subdirectory put: aSubdirectory ].
	result := self callToolWith: arguments.
	self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
	^ result
]

{ #category : 'private - compatibility' }
MCPToolRepositoryOperationTest >> currentTonelFormatNamesPackages [
	"Tonel 3, the format Pharo writes by default from 12 on, names the package of a class. Pharo 11 writes Tonel 1.0 by default, and Pharo 10 knows no other version, neither of which does."

	^ (TonelWriter class canUnderstand: #defaultVersion) and: [ TonelWriter defaultVersion asNumber >= 3 ]
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

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> exportRepositoryNamed: aRepositoryName [

	^ self callToolWith: {
			  (#action -> 'export').
			  (#name -> aRepositoryName) } asDictionary
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> filePathsIn: aLocation [
	"Every file of the checkout outside .git, from its root, as export names them."

	| root |
	root := aLocation asFileReference.
	^ ((root allFiles collect: [ :each | (each path relativeTo: root path) segments ])
		   reject: [ :segments | segments first = '.git' ]
		   thenCollect: [ :segments | '/' join: segments ]) asArray sort
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> git: arguments in: aLocation [
	"The trimmed output of git run in aLocation; the test fails if git does."

	^ (self shellOutput:
		   (String streamContents: [ :stream | stream << 'git -C ' << (self shellQuote: aLocation pathString) << ' ' << arguments ]))
		  trimBoth
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> isRegistered: aRepositoryName [

	^ IceRepository repositories anySatisfy: [ :each | each name asString = aRepositoryName ]
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

{ #category : 'private - calling' }
MCPToolRepositoryOperationTest >> refusedCreateNamed: aRepositoryName location: aLocationString [
	"Ask create for a repository with no packages, and fail the test unless it refuses."

	| result |
	result := self callToolWith: {
			          (#action -> 'create').
			          (#name -> aRepositoryName).
			          (#location -> aLocationString) } asDictionary.
	self assert: (self resultIndicatesError: result) description: 'create should have refused'.
	^ result
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
	outputFile := FileLocator temp asFileReference
	              / (String streamContents: [ :stream | stream << 'mcp-test-shell-command-' << UUID new asString << '.log' ]).
	command := String streamContents: [ :stream |
		           stream << aCommandString << ' > ' << (self shellQuote: outputFile pathString) << ' 2>&1' ].
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

	^ String streamContents: [ :stream | stream << '''' << (aString copyReplaceAll: '''' with: '''"''"''') << '''' ]
]

{ #category : 'private' }
MCPToolRepositoryOperationTest >> temporaryRepositoryLocationNamed: aName [

	^ FileLocator imageDirectory / aName
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testACreatedRepositoryReattachesWithItsPackages [
	"Once exported and committed, a repository create made is attached again with the packages its files hold, read in Tonel. Once where the location did not exist, once where it was an empty Git repository."

	| location packageName repositoryName |
	repositoryName := 'MCP Create Reattach Test'.
	packageName := 'MCPToolRepositoryOperationReattachPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestReattach'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationReattachClass' do: [
			{
				[ ].
				[ self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString) ] } do: [ :prepareLocation |
					self withCleanRepositoryNamed: repositoryName location: location do: [
							| repository result |
							prepareLocation value.
							self
								createRepositoryNamed: repositoryName
								location: location
								subdirectory: 'src'
								packages: { packageName }.
							result := self exportRepositoryNamed: repositoryName.
							self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
							result := self commitRepositoryNamed: repositoryName message: 'Hold the package'.
							self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
							self removeRegisteredRepositoriesNamed: repositoryName.
							result := self callToolWith: {
									          (#action -> 'attach').
									          (#name -> repositoryName).
									          (#location -> location pathString) } asDictionary.
							self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
							repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
							self assert: (self packageNamesIn: repository) equals: { packageName }.
							self assert: repository properties writerClass id asString equals: 'tonel' ] ] ]
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
				assert: (self summaryFrom: result)
				equals:
				'Repository MCP Adopt Head Test Repository now refers to HEAD head-2 on branch main, and no longer marks MCP, MCP-Tests as modified.'.
			self assert: data keys asSet equals: #( unmarkedPackages ) asSet.
			self assert: (data at: #unmarkedPackages) equals: #( 'MCP' 'MCP-Tests' ) ]
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
			self
				assert: (self summaryFrom: result)
				equals:
				'Repository MCP Adopt Clean Test Repository already referred to HEAD head-1 on branch main, and no longer marks MCP as modified.'.
			self assert: (data at: #unmarkedPackages) equals: #( 'MCP' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAdoptHeadNamesADetachedHead [

	| repository result |
	repository := self newTestRepositoryNamed: 'MCP Adopt Detached Head Test Repository'.
	repository headCommitId: '0123456789abcdef'.
	repository isDetachedHead: true.
	repository workingCopy referenceCommit: (MCPTestRepositoryCommit id: 'head-1').
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'adoptHead').
					          (#name -> repository name) } asDictionary.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self
				assert: (self summaryFrom: result)
				equals: 'Repository MCP Adopt Detached Head Test Repository now refers to its detached HEAD 0123456.'.
			self assert: (self dataFrom: result) isEmpty ]
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
MCPToolRepositoryOperationTest >> testAttachDoesNotWarnOfAPackageTheCheckoutHolds [
	"A package the checkout holds is no name mistyped, even when the image has yet to load it."

	| className location packageName repositoryName result |
	repositoryName := 'MCP Attach Package In Checkout Test'.
	packageName := 'MCPToolRepositoryOperationInCheckoutPackage'.
	className := 'MCPToolRepositoryOperationInCheckoutClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachPackageInCheckout'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self commitCheckoutNamed: repositoryName at: location holding: packageName.
					self removeClassNamed: className.
					self removePackageNamed: packageName.
					result := self attachRepositoryNamed: repositoryName location: location pathString packages: { packageName }.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: (self warningsFrom: result) isEmpty ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachGivesACheckoutWithoutProjectFileItsSubdirectory [

	| location packageName repository repositoryName result |
	repositoryName := 'MCP Attach Without Project File Test'.
	packageName := 'MCPToolRepositoryOperationNoProjectPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachWithoutProjectFile'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationNoProjectClass' do: [
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
					(location / '.project') ensureDelete.
					self commitAllIn: location message: 'Keep the sources without a project file'.
					self removeRegisteredRepositoriesNamed: repositoryName.
					result := self callToolWith: {
							          (#action -> 'attach').
							          (#name -> repositoryName).
							          (#location -> location pathString).
							          (#subdirectory -> 'src').
							          (#packages -> { packageName }) } asDictionary.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self assert: repository subdirectory equals: 'src'.
					self assert: (self packageNamesIn: repository) equals: { packageName }.
					self assert: ((self summaryFrom: result) includesSubstring: '.project').
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					self assert: ((location / '.project') contents includesSubstring: 'src') ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachGivesAnEmptyCheckoutItsSubdirectory [

	| location repository repositoryName result |
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
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
			self assert: repository subdirectory equals: 'src' ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachNamesThePackagesItRegistered [

	| location packageName repositoryName result |
	repositoryName := 'MCP Attach Names Packages Test'.
	packageName := 'MCPToolRepositoryOperationAttachNamesPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachNamesPackages'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationAttachNamesClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self commitCheckoutNamed: repositoryName at: location holding: packageName.
					result := self attachRepositoryNamed: repositoryName location: location pathString packages: #(  ).
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self
						assert: (self summaryFrom: result)
						equals: ('Attached repository {1} at {2}, on branch main, with its sources in src.' format: {
									 repositoryName.
									 location fullName }).
					self assert: ((self dataFrom: result) at: #packages) asArray equals: { packageName }.
					self assert: (self warningsFrom: result) isEmpty ] ]
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
MCPToolRepositoryOperationTest >> testAttachReadsThePackagesOfACheckoutWithoutProjectFile [
	"A checkout with .project has the packages under its source directory registered at attach, so one without it, whose source directory says its format in .properties as Tonel checkouts did before .project, has them too once it is given that directory."

	| location packageName repository repositoryName result |
	repositoryName := 'MCP Attach Reads Packages Without Project File Test'.
	packageName := 'MCPToolRepositoryOperationNoProjectReadPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachReadsWithoutProjectFile'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationNoProjectReadClass' do: [
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
					(location / '.project') ensureDelete.
					location / 'src' / '.properties' writeStreamDo: [ :stream | stream nextPutAll: '{ #format : #tonel }' ].
					self commitAllIn: location message: 'Keep the sources without a project file'.
					self removeRegisteredRepositoriesNamed: repositoryName.
					result := self callToolWith: {
							          (#action -> 'attach').
							          (#name -> repositoryName).
							          (#location -> location pathString).
							          (#subdirectory -> 'src') } asDictionary.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self assert: (self packageNamesIn: repository) equals: { packageName } ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachRefusesADirectoryThatIsNoCheckout [

	| location repositoryName result |
	repositoryName := 'MCP Attach No Checkout Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachNoCheckout'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			location ensureCreateDirectory.
			result := self attachRepositoryNamed: repositoryName location: location pathString packages: #(  ).
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationNotGitRoot'.
			self
				assert: (self summaryFrom: result)
				equals:
					('Cannot attach repository {1}: {2} is not the root of a Git checkout. repository_create starts a repository there if it holds no file; otherwise run git init there first.'
						 format: {
								 repositoryName.
								 location fullName }).
			self deny: (self isRegistered: repositoryName) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachRefusesAMissingLocation [

	| location repositoryName result |
	repositoryName := 'MCP Attach Missing Location Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachMissingLocation'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			result := self attachRepositoryNamed: repositoryName location: location pathString packages: #(  ).
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationMissing'.
			self assert: (self summaryFrom: result) equals: ('Cannot attach repository {1}: {2} does not exist.' format: {
						 repositoryName.
						 location fullName }).
			self deny: (self isRegistered: repositoryName) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachRefusesARelativeLocation [

	| repositoryName result |
	repositoryName := 'MCP Attach Relative Location Test'.
	self removeRegisteredRepositoriesNamed: repositoryName.
	result := self attachRepositoryNamed: repositoryName location: 'notes' packages: #(  ).
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationNotAbsolute'.
	self
		assert: (self summaryFrom: result)
		equals:
			('Cannot attach repository {1}: location notes is not an absolute path, and the image would resolve it against its own working directory, {2}. Give the full path.'
				 format: {
						 repositoryName.
						 FileSystem workingDirectory fullName }).
	self deny: (self isRegistered: repositoryName)
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
						self shellCommand: (String streamContents: [ :stream |
									 stream << 'git -C ' << (self shellQuote: location pathString) << ' worktree add -b attach-linked-test '
									 << (self shellQuote: linkedLocation pathString) ]).
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
									LibC uniqueInstance system: (String streamContents: [ :stream |
												 stream << 'git -C ' << (self shellQuote: location pathString) << ' worktree remove --force '
												 << (self shellQuote: linkedLocation pathString) ]).
									self deleteDirectoryIfExists: linkedLocation ] ] ] ]
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
			self
				assert: (self summaryFrom: result)
				equals:
					('Cannot attach repository {1}: a repository of that name is already registered, at {2}. Choose another name.' format: {
							 repositoryName.
							 location pathString }) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachSaysWhenHeadIsDetached [

	| headId location packageName repositoryName result |
	repositoryName := 'MCP Attach Detached Head Test'.
	packageName := 'MCPToolRepositoryOperationAttachDetachedPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachDetachedHead'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationAttachDetachedClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self commitCheckoutNamed: repositoryName at: location holding: packageName.
					headId := self git: 'rev-parse HEAD' in: location.
					self git: 'checkout -q --detach' in: location.
					result := self attachRepositoryNamed: repositoryName location: location pathString packages: #(  ).
					self
						assert: (self summaryFrom: result)
						equals: ('Attached repository {1} at {2}, on detached HEAD {3}, with its sources in src.' format: {
									 repositoryName.
									 location fullName.
									 (headId first: 7) }) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachWarnsOfAPackageInNeitherTheImageNorTheCheckout [
	"A package asked for that neither the image nor the checkout holds is likely a name mistyped."

	| location packageName repositoryName result |
	repositoryName := 'MCP Attach Package Nowhere Test'.
	packageName := 'MCPToolRepositoryOperationNowherePackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachPackageNowhere'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
			result := self attachRepositoryNamed: repositoryName location: location pathString packages: { packageName }.
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self assert: (self warningsFrom: result) size equals: 1.
			self assert: ((self warningsFrom: result) first beginsWith: packageName , ' is in neither the image nor the checkout.') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testAttachWithoutPackagesWarns [

	| location repositoryName result |
	repositoryName := 'MCP Attach Without Packages Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestAttachWithoutPackages'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
			result := self attachRepositoryNamed: repositoryName location: location pathString packages: #(  ).
			self
				assert: (self summaryFrom: result)
				equals: ('Attached repository {1} at {2}, which has no commit yet, with its sources at its root.' format: {
							 repositoryName.
							 location fullName }).
			self
				assert: (self warningsFrom: result) asArray
				equals: { ('Repository {1} has no packages; repository_update addPackages adds them.' format: { repositoryName }) }.
			self deny: ((self dataFrom: result) includesKey: #packages) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testChangeListSaysWhenNothingIsUncommitted [

	| location packageName repositoryName result |
	repositoryName := 'MCP Change List Nothing Uncommitted Test'.
	packageName := 'MCPToolRepositoryOperationNothingUncommittedPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestChangeListNothingUncommitted'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationNothingUncommittedClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					self commitRepositoryNamed: repositoryName message: 'Hold the package'.
					result := self callToolWith: {
							          (#action -> 'diff').
							          (#name -> repositoryName) } asDictionary.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self
						assert: (self summaryFrom: result)
						equals:
						('Repository {1} has no uncommitted changes: the image matches its files and git sees none.' format: { repositoryName }).
					self assert: (self dataFrom: result) isEmpty ] ]
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
					self shellCommand: (String streamContents: [ :stream |
							 stream << 'git -C ' << (self shellQuote: location pathString) << ' checkout -b ' << (self shellQuote: featureBranch) ]).
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
					self shellCommand: (String streamContents: [ :stream |
							 stream << 'git -C ' << (self shellQuote: location pathString) << ' checkout ' << (self shellQuote: baseBranch) ]).
					checkoutResult := self callToolWith: {
							                  (#action -> 'reload').
							                  (#name -> repositoryName) } asDictionary.
					self deny: (self resultIndicatesError: checkoutResult) description: (self summaryFrom: checkoutResult).
					self deny: ((Smalltalk at: className asSymbol) includesSelector: extraSelector) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitCreatesCommitAndReturnsResult [

	| data location otherFiles packageName repositoryName result |
	repositoryName := 'MCP Repository Command Commit Test'.
	packageName := 'MCPToolRepositoryOperationCommitPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommit'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCommitClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: nil
						packages: { packageName }.
					result := self commitRepositoryNamed: repositoryName message: 'Initial commit MCP test'.
					data := self dataFrom: result.
					self
						assert: (self summaryFrom: result)
						equals: ('Committed repository {1} on branch {2}: {3} Initial commit MCP test' format: {
									 repositoryName.
									 (self git: 'symbolic-ref --short HEAD' in: location).
									 ((self git: 'rev-parse HEAD' in: location) first: 7) }).
					self assert: data keys asSet equals: #( packages otherFiles ) asSet.
					self assert: (data at: #packages) asArray equals: { packageName }.
					otherFiles := OrderedCollection with: '.project'.
					(location / '.properties') exists ifTrue: [ otherFiles add: '.properties' ].
					self assert: (data at: #otherFiles) asArray equals: otherFiles asArray sort ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitMessageLeavesWithLineFeeds [
	"A message arrives as the image keeps text, with carriage returns. Git, outside the image, takes line feeds, or keeps the whole message on one line."

	| location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Commit Line Endings Test'.
	packageName := 'MCPToolRepositoryOperationCommitLineEndingsPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommitLineEndings'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCommitLineEndingsClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: nil
						packages: { packageName }.
					result := self
						          commitRepositoryNamed: repositoryName
						          message: (String streamContents: [ :stream | stream << 'Subject' << String cr << String cr << 'Body' ]).
					self assert: ((self summaryFrom: result) endsWith: ' Subject').
					self
						assert: (self git: 'log -1 --format=%B' in: location)
						equals: (String streamContents: [ :stream | stream << 'Subject' << String lf << String lf << 'Body' ]) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitNamesOnlyRegisteredPackages [
	"With the sources at the root, a directory written by hand is a path, not a package."

	| data location packageName repositoryName result |
	repositoryName := 'MCP Commit Registered Packages Test'.
	packageName := 'MCPToolRepositoryOperationCommitRegisteredPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommitRegisteredPackages'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCommitRegisteredClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: nil
						packages: { packageName }.
					self write: '# Notes' to: location / 'README.md'.
					self write: 'x' to: location / 'Other' / 'x.st'.
					result := self commitRepositoryNamed: repositoryName message: 'Write the package beside other files'.
					data := self dataFrom: result.
					self assert: (data at: #packages) asArray equals: { packageName }.
					self assert: ((data at: #otherFiles) includesAll: #( 'README.md' 'Other/x.st' )).
					self deny: ((data at: #otherFiles) anySatisfy: [ :each | each beginsWith: packageName ]) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitOfARepositoryWithoutPackages [
	"With no package to write, a commit takes what git sees in the checkout, and says so."

	| data location repositoryName result |
	repositoryName := 'MCP Commit Without Packages Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommitWithoutPackages'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			location ensureCreateDirectory.
			self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
			self callToolWith: {
					(#action -> 'attach').
					(#name -> repositoryName).
					(#location -> location pathString) } asDictionary.
			self write: 'a' to: location / 'a.txt'.
			result := self commitRepositoryNamed: repositoryName message: 'Add a file written by hand'.
			data := self dataFrom: result.
			self
				assert: (self warningsFrom: result) asArray
				equals:
				{ ('Repository {1} has no packages, so this commit holds only what git saw in its checkout.' format: { repositoryName }) }.
			self assert: (data at: #otherFiles) asArray equals: #( 'a.txt' ).
			self deny: (data includesKey: #packages).
			self assert: (self git: 'log -1 --format=%s' in: location) equals: 'Add a file written by hand' ]
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
MCPToolRepositoryOperationTest >> testCommitRefusesWhenThereIsNothingToCommit [

	| location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Refused Commit Test'.
	packageName := 'MCPToolRepositoryOperationRefusedCommitPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestRefusedCommit'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationRefusedCommitClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: nil
						packages: { packageName }.
					self commitRepositoryNamed: repositoryName message: 'Initial commit from MCP test'.
					result := self commitRepositoryNamed: repositoryName message: 'Second commit from MCP test'.
					self assert: (self resultIndicatesError: result).
					self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryNothingToCommit'.
					self
						assert: (self summaryFrom: result)
						equals:
							('Repository {1} has nothing to commit: the image matches its files and git sees no change in its checkout.' format:
								 { repositoryName }) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitUsesFallbackGitIdentityWhenGitSignatureIsUnavailable [

	| location message packageName repositoryName result |
	repositoryName := 'MCP Repository Command Commit Fallback Identity Test'.
	packageName := 'MCPToolRepositoryOperationCommitFallbackIdentityPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommitFallbackIdentity'.
	message := 'Commit with fallback identity from MCP test'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCommitFallbackIdentityClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: nil
						packages: { packageName }.
					self shellCommand: (String streamContents: [ :stream |
							 stream << 'git -C ' << (self shellQuote: location pathString) << ' config user.name ' << (self shellQuote: '') ]).
					self shellCommand: (String streamContents: [ :stream |
							 stream << 'git -C ' << (self shellQuote: location pathString) << ' config user.email ' << (self shellQuote: '') ]).
					result := self commitRepositoryNamed: repositoryName message: message.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: ((self summaryFrom: result) endsWith: ' ' , message).
					self assert: (self git: 'log -1 --format=%an' in: location) equals: 'MCP' ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitWarnsOfARegisteredPackageNotInTheImage [

	| absentPackageName location packageName repositoryName result |
	repositoryName := 'MCP Commit Warns Absent Package Test'.
	packageName := 'MCPToolRepositoryOperationCommitWarnsPackage'.
	absentPackageName := 'MCPToolRepositoryOperationCommitWarnsAbsentPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommitWarnsAbsentPackage'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCommitWarnsClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self callToolWith: {
							(#action -> 'update').
							(#name -> repositoryName).
							(#addPackages -> { absentPackageName }) } asDictionary.
					result := self commitRepositoryNamed: repositoryName message: 'Write the package'.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self
						assert: (self warningsFrom: result) asArray
						equals:
							{ ('{1} is registered in repository {2} but not in the image, so export did not write it; its files in the checkout are left as they are. If it no longer belongs to the repository, repository_update removePackages drops it.'
								 format: {
										 absentPackageName.
										 repositoryName }) } ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCommitWritesTheProjectFileAnAttachGave [

	| location packageName repositoryName result |
	repositoryName := 'MCP Commit Pending Project File Test'.
	packageName := 'MCPToolRepositoryOperationPendingProjectPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCommitPendingProjectFile'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationPendingProjectClass' do: [
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
					(location / '.project') ensureDelete.
					self commitAllIn: location message: 'Keep the sources without a project file'.
					self removeRegisteredRepositoriesNamed: repositoryName.
					self callToolWith: {
							(#action -> 'attach').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#subdirectory -> 'src').
							(#packages -> { packageName }) } asDictionary.
					result := self callToolWith: {
							          (#action -> 'commit').
							          (#name -> repositoryName).
							          (#message -> 'Name the source directory') } asDictionary.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: ((location / '.project') contents includesSubstring: 'src') ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateCountsAGitDirectoryThatIsNoRootAsAFile [
	"A .git that makes no Git root is something there create would write over, so it is named as a file."

	| location repositoryName result |
	repositoryName := 'MCP Create Broken Git Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateBrokenGit'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			(location / '.git') ensureCreateDirectory.
			result := self refusedCreateNamed: repositoryName location: location pathString.
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationNotEmpty'.
			self assert: ((self summaryFrom: result) includesSubstring: ' already holds a file, .git. Give ').
			self deny: (self isRegistered: repositoryName) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateCreatesAndRegistersRepository [

	| location packageName repository repositoryName result |
	repositoryName := 'MCP Repository Command Create Test'.
	packageName := 'MCPToolRepositoryOperationCreatePackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreate'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationCreateClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					result := self
						          createRepositoryNamed: repositoryName
						          location: location
						          subdirectory: 'src'
						          packages: { packageName }.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self
						assert: (self summaryFrom: result)
						equals: ('Created repository {1} at {2}, with its sources in src; repository_export writes its packages there.' format: {
									 repositoryName.
									 location fullName }).
					self assert: ((self dataFrom: result) at: #packages) asArray equals: { packageName }.
					self assert: repository location pathString equals: location pathString.
					self assert: repository subdirectory equals: 'src'.
					self assert: (self packageNamesIn: repository) equals: { packageName } ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateNamesTheFirstFilesADirectoryHolds [
	"The files a refusal names are found level by level in name order, and three are as many as it names."

	| location repositoryName |
	repositoryName := 'MCP Create First Files Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateFirstFiles'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self write: 'c' to: location / 'b' / 'c.txt'.
			self write: 'a' to: location / 'a.txt'.
			self write: 'finder' to: location / '.DS_Store'.
			self assert: ((self summaryFrom: (self refusedCreateNamed: repositoryName location: location pathString)) includesSubstring:
					 ' already holds files, such as a.txt and b/c.txt. Give ').
			self write: 'e' to: location / 'e.txt'.
			self write: 'd' to: location / 'd.txt'.
			self assert: ((self summaryFrom: (self refusedCreateNamed: repositoryName location: location pathString)) includesSubstring:
					 ' already holds files, such as a.txt, b/c.txt and d.txt. Give ') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesACheckoutWithCommits [

	| headBefore location repositoryName result |
	repositoryName := 'MCP Create Checkout With Commits Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateCheckoutWithCommits'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
			self write: 'notes' to: location / 'README.md'.
			self commitAllIn: location message: 'Start the notes'.
			headBefore := self git: 'log --format=%H' in: location.
			result := self refusedCreateNamed: repositoryName location: location pathString.
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationIsCheckout'.
			self
				assert: (self summaryFrom: result)
				equals: ('Cannot create repository {1}: {2} is already a Git checkout. Register it with repository_attach instead.' format: {
							 repositoryName.
							 location fullName }).
			self deny: (self isRegistered: repositoryName).
			self assert: (self git: 'log --format=%H' in: location) equals: headBefore ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesADirectoryHoldingFiles [

	| location repositoryName result |
	repositoryName := 'MCP Create Directory Holding Files Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateDirectoryHoldingFiles'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self write: 'a' to: location / 'a.txt'.
			result := self refusedCreateNamed: repositoryName location: location pathString.
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationNotEmpty'.
			self
				assert: (self summaryFrom: result)
				equals:
					('Cannot create repository {1}: {2} already holds a file, a.txt. Give a location that does not exist yet or holds no file; to keep what is there, run git init there and register it with repository_attach.'
						 format: {
								 repositoryName.
								 location fullName }).
			self deny: (location / '.git') exists.
			self deny: (self isRegistered: repositoryName) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesAFile [

	| location repositoryName result |
	repositoryName := 'MCP Create File Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateFile'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self write: 'a file' to: location.
			[
				result := self refusedCreateNamed: repositoryName location: location pathString.
				self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationNotDirectory'.
				self
					assert: (self summaryFrom: result)
					equals: ('Cannot create repository {1}: {2} is a file. Give a directory that does not exist yet or holds no file.' format: {
								 repositoryName.
								 location fullName }).
				self assert: location contents equals: 'a file' ] ensure: [ location ensureDelete ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesAPackageNotInTheImage [
	"A registration naming a package the image lacks would only be one to repair; the refusal names the package meant."

	| location packageName repositoryName result summary typo |
	repositoryName := 'MCP Create Missing Package Test'.
	packageName := 'MCPToolRepositoryOperationTypoPackage'.
	typo := packageName allButLast , 's'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateMissingPackage'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationTypoClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					result := self callToolWith: {
							          (#action -> 'create').
							          (#name -> repositoryName).
							          (#location -> location pathString).
							          (#packages -> {
								           packageName.
								           typo }) } asDictionary.
					self assert: (self resultIndicatesError: result).
					self assert: ((self errorFrom: result) at: #errorCode) equals: 'PackageNotFound'.
					summary := self summaryFrom: result.
					self assert: (summary beginsWith: ('Cannot create repository {1}: package {2} does not exist.' format: {
									  repositoryName.
									  typo })).
					self assert: (summary includesSubstring: ' Did you mean: ').
					self assert: (summary includesSubstring: packageName).
					self assert:
						(summary endsWith: ' Create the package first, or leave it out and add it later with repository_update addPackages.').
					self deny: location exists.
					self deny: (self isRegistered: repositoryName) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesARegisteredLocation [

	| location otherName registered repositoryName result |
	repositoryName := 'MCP Create Registered Location Test'.
	otherName := 'MCP Create Registered Location Other'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateRegisteredLocation'.
	self deleteDirectoryIfExists: location.
	registered := self newRepositoryNamed: otherName location: location packageNames: #(  ).
	self withRegisteredRepository: registered do: [
			result := self refusedCreateNamed: repositoryName location: location pathString.
			self
				assert: (self summaryFrom: result)
				equals:
					('Cannot create repository {1}: repository {2} is already registered at {3}. Use it, or choose another location.' format: {
							 repositoryName.
							 otherName.
							 location pathString }).
			self deny: (self isRegistered: repositoryName).
			self deny: location exists ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesARegisteredName [

	| location registered registeredLocation repositoryName result |
	repositoryName := 'MCP Create Registered Name Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateRegisteredName'.
	registeredLocation := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateRegisteredNameElsewhere'.
	registered := self newRepositoryNamed: repositoryName location: registeredLocation packageNames: #(  ).
	self deleteDirectoryIfExists: location.
	self withRegisteredRepository: registered do: [
			result := self refusedCreateNamed: repositoryName location: location pathString.
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryAlreadyRegistered'.
			self
				assert: (self summaryFrom: result)
				equals:
					('Cannot create repository {1}: a repository of that name is already registered, at {2}. Choose another name.' format: {
							 repositoryName.
							 registeredLocation pathString }).
			self assert: ((self errorFrom: result) at: #matchingRepositories) asArray equals: { repositoryName }.
			self deny: location exists ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesARegisteredNameWithNoLocation [

	| location registered registry repositoryName result |
	repositoryName := 'MCP Create Registered Without Location Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateRegisteredWithoutLocation'.
	self deleteDirectoryIfExists: location.
	registered := IceLibgitRepository new
		              name: repositoryName;
		              yourself.
	registry := IceRepository registry.
	registry add: registered.
	[
		result := self refusedCreateNamed: repositoryName location: location pathString.
		self
			assert: (self summaryFrom: result)
			equals:
				('Cannot create repository {1}: a repository of that name is already registered, with no location. Choose another name.'
					 format: { repositoryName }).
		self deny: location exists ] ensure: [ registry remove: registered ifAbsent: [ ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateRefusesARelativeLocation [
	"The image resolves a relative path against its own working directory, which is not the caller's."

	| relative repositoryName result |
	repositoryName := 'MCP Create Relative Location Test'.
	relative := 'mcp-create-relative'.
	self withCleanRepositoryNamed: repositoryName location: FileSystem workingDirectory / relative do: [
			result := self refusedCreateNamed: repositoryName location: relative.
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryLocationNotAbsolute'.
			self
				assert: (self summaryFrom: result)
				equals:
					('Cannot create repository {1}: location mcp-create-relative is not an absolute path, and the image would resolve it against its own working directory, {2}. Give the full path.'
						 format: {
								 repositoryName.
								 FileSystem workingDirectory fullName }).
			self deny: (FileSystem workingDirectory / relative) exists.
			self deny: (self isRegistered: repositoryName) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateTakesADirectoryHoldingOnlyDsStore [
	"macOS's Finder leaves .DS_Store files behind; they are not files create could lose, and it leaves them where they are."

	| location repositoryName |
	repositoryName := 'MCP Create DS Store Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateDsStore'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self write: 'finder' to: location / '.DS_Store'.
			self write: 'finder' to: location / 'src' / '.DS_Store'.
			self
				createRepositoryNamed: repositoryName
				location: location
				subdirectory: 'src'
				packages: #(  ).
			self assert: (self isRegistered: repositoryName).
			self assert: (location / '.DS_Store') exists.
			self assert: (location / 'src' / '.DS_Store') exists ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateTakesADirectoryHoldingOnlyEmptyDirectories [
	"An agent that makes the source directory first has made nothing create could lose."

	| location repositoryName result |
	repositoryName := 'MCP Create Empty Subdirectories Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateEmptySubdirectories'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			(location / 'src') ensureCreateDirectory.
			result := self
				          createRepositoryNamed: repositoryName
				          location: location
				          subdirectory: nil
				          packages: #(  ).
			self
				assert: (self summaryFrom: result)
				equals:
					('Created repository {1} at {2}, with its sources at its root; repository_export writes its packages there.' format: {
							 repositoryName.
							 location fullName }).
			self assert: (self isRegistered: repositoryName).
			self assert: (location / 'src') isDirectory ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateTakesAnEmptyDirectory [

	| location packageName repositoryName result |
	repositoryName := 'MCP Create Empty Directory Test'.
	packageName := 'MCPToolRepositoryOperationEmptyDirectoryPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateEmptyDirectory'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationEmptyDirectoryClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					location ensureCreateDirectory.
					result := self
						          createRepositoryNamed: repositoryName
						          location: location
						          subdirectory: 'src'
						          packages: { packageName }.
					self
						assert: (self summaryFrom: result)
						equals: ('Created repository {1} at {2}, with its sources in src; repository_export writes its packages there.' format: {
									 repositoryName.
									 location fullName }).
					self assert: (location / '.git') exists.
					self assert: (location / 'src') isDirectory.
					self assert: ((self dataFrom: result) at: #packages) asArray equals: { packageName } ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateTakesAnEmptyGitRepositoryAndKeepsItsConfiguration [
	"git init, perhaps with a remote set, is what an agent runs before create; create registers that repository and touches nothing in .git."

	| location packageName repositoryName result |
	repositoryName := 'MCP Create Empty Git Repository Test'.
	packageName := 'MCPToolRepositoryOperationEmptyGitPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateEmptyGit'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationEmptyGitClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
					self git: 'remote add origin https://example.com/x.git' in: location.
					result := self
						          createRepositoryNamed: repositoryName
						          location: location
						          subdirectory: 'src'
						          packages: { packageName }.
					self
						assert: (self summaryFrom: result)
						equals:
							('Created repository {1} in the empty Git repository at {2}, with its sources in src; repository_export writes its packages there.'
								 format: {
										 repositoryName.
										 location fullName }).
					self assert: ((self dataFrom: result) at: #packages) asArray equals: { packageName }.
					self assert: (self git: 'remote get-url origin' in: location) equals: 'https://example.com/x.git'.
					result := self exportRepositoryNamed: repositoryName.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: ((STON fromString: (location / '.project') contents) at: 'srcDirectory') equals: 'src'.
					self assert: (location / 'src' / packageName) isDirectory ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateWarnsOfAPackageRegisteredElsewhere [
	"Two registrations claiming one package is a hazard, so the second says so."

	| firstLocation firstName location packageName repositoryName result |
	firstName := 'MCP Create Shared Package First Test'.
	repositoryName := 'MCP Create Shared Package Test'.
	packageName := 'MCPToolRepositoryOperationSharedPackage'.
	firstLocation := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateSharedPackageFirst'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateSharedPackage'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationSharedClass' do: [
			self withCleanRepositoryNamed: firstName location: firstLocation do: [
					self withCleanRepositoryNamed: repositoryName location: location do: [
							result := self
								          createRepositoryNamed: firstName
								          location: firstLocation
								          subdirectory: nil
								          packages: { packageName }.
							self assert: (self warningsFrom: result) isEmpty.
							result := self
								          createRepositoryNamed: repositoryName
								          location: location
								          subdirectory: nil
								          packages: { packageName }.
							self assert: (self warningsFrom: result) asArray equals: { ('{1} is also registered in repository {2}.' format: {
										 packageName.
										 firstName }) } ] ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testCreateWithoutPackagesWarns [

	| location repositoryName result |
	repositoryName := 'MCP Create Without Packages Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestCreateWithoutPackages'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			result := self
				          createRepositoryNamed: repositoryName
				          location: location
				          subdirectory: nil
				          packages: #(  ).
			self
				assert: (self warningsFrom: result) asArray
				equals: { ('Repository {1} has no packages yet; repository_update addPackages adds them.' format: { repositoryName }) }.
			self deny: ((self dataFrom: result) includesKey: #packages) ]
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
			self assert: (self summaryFrom: result) equals: 'Repository MCP Diff Package Only Test Repository has uncommitted changes.'.
			self assert: data keys asSet equals: #( imageModifiedPackages ) asSet.
			self assert: (data at: #imageModifiedPackages) equals: #( 'MCP-Test-Dirty' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffLeavesOutAPackageMarkedOverNothing [
	"Iceberg marks a package on any change and clears the mark only when it writes the package, so a method compiled and removed again leaves a mark over nothing. The change list answers what differs from the files, not the mark."

	| class className data location packageName repository repositoryName result |
	repositoryName := 'MCP Repository Command Diff Mark Test'.
	packageName := 'MCPToolRepositoryOperationDiffMarkPackage'.
	className := 'MCPToolRepositoryOperationDiffMarkClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestDiffMark'.
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
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					class := self class environment at: className asSymbol.
					class compile: 'probe ^ 1' classified: 'probing'.
					class removeSelector: #probe.
					self assert: (repository modifiedPackages collect: [ :each | each name ] as: Array) equals: { packageName }.
					result := self callToolWith: {
							          (#action -> 'diff').
							          (#name -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self deny: (data includesKey: #imageModifiedPackages) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiffListsAPackageWhoseImageDiffersFromItsFiles [

	| className data location packageName repositoryName result |
	repositoryName := 'MCP Repository Command Diff Differs Test'.
	packageName := 'MCPToolRepositoryOperationDiffDiffersPackage'.
	className := 'MCPToolRepositoryOperationDiffDiffersClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestDiffDiffers'.
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
					(self class environment at: className asSymbol) compile: 'probe ^ 1' classified: 'probing'.
					result := self callToolWith: {
							          (#action -> 'diff').
							          (#name -> repositoryName) } asDictionary.
					data := self dataFrom: result.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self assert: (data at: #imageModifiedPackages) equals: { packageName } ] ]
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
MCPToolRepositoryOperationTest >> testDiffReportsImageChangesWithoutWriting [
	"A package loaded in the image and never written is what git cannot see, and what the change list exists to report."

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
					self assert: (self summaryFrom: result) equals: ('Repository {1} has uncommitted changes.' format: { repositoryName }).
					self assert: data keys asSet equals: #( imageModifiedPackages ) asSet.
					self assert: (data at: #imageModifiedPackages) equals: { packageName }.
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
			self assert: (self summaryFrom: result) equals: 'Repository MCP Discard Clean Test Repository had no changes to discard.'.
			self assert: data isEmpty.
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
			self assert: (self summaryFrom: result) equals: 'Discarded the changes of repository MCP Discard Package Only Test Repository.'.
			self assert: data keys asSet equals: #( discardedPackages ) asSet.
			self assert: (data at: #discardedPackages) equals: #( 'MCP-Test-Dirty' ).
			self assert: repository modifiedPackages isEmpty.
			self assert: repository actionLog asArray equals: #( 'discard' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testDiscardNamesNoPackageForAnUnregisteredDirectory [
	"A discard reverts the image and writes no file, so files written by hand remain and the call fails. The paths left are named as paths: a directory is never read as a package."

	| details location packageName repositoryName result |
	repositoryName := 'MCP Discard Unregistered Directory Test'.
	packageName := 'MCPToolRepositoryOperationDiscardUnregisteredPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestDiscardUnregisteredDirectory'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationDiscardUnregisteredClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: nil
						packages: { packageName }.
					self commitRepositoryNamed: repositoryName message: 'Write the package'.
					self write: '# Notes' to: location / 'README.md'.
					self write: 'x' to: location / 'src' / 'X' / 'a.st'.
					result := self callToolWith: {
							          (#action -> 'discard').
							          (#name -> repositoryName) } asDictionary.
					self assert: (self resultIndicatesError: result).
					details := self errorFrom: result.
					self assert: (details at: #errorCode) equals: 'RepositoryDiscardIncomplete'.
					self assert: (details at: #remainingPackageNames) isEmpty.
					self assert: ((details at: #remainingPaths) includes: 'README.md') ] ]
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
					self assert: (data at: #packages) asArray equals: { packageName }.
					self assert: ((data at: #written) includes: ('{1}.package/' format: { packageName })).
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
MCPToolRepositoryOperationTest >> testExportDoesNotNameAMarkedButUnchangedPackage [
	"Iceberg marks a package on any change, a method compiled and removed again included. A mark is not a difference: export names what it wrote."

	| class className location packageName repository repositoryName result |
	repositoryName := 'MCP Export Marked Test'.
	packageName := 'MCPToolRepositoryOperationMarkedPackage'.
	className := 'MCPToolRepositoryOperationMarkedClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportMarked'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					self commitRepositoryNamed: repositoryName message: 'Write the package'.
					class := self class environment at: className asSymbol.
					class compile: 'probe ^ 1' classified: 'probing'.
					class removeSelector: #probe.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self assert: (repository modifiedPackages collect: [ :each | each name ] as: Array) equals: { packageName }.
					result := self exportRepositoryNamed: repositoryName.
					self
						assert: (self summaryFrom: result)
						equals: ('Exported repository {1}: nothing to write, its files already hold what the image has.' format: { repositoryName }) ] ]
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
						assert: (sourceFile contents includesSubstring: '#package :') = self currentTonelFormatNamesPackages
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
MCPToolRepositoryOperationTest >> testExportKeepsAnOrderOnlyRewriteOutOfWritten [
	"A committed class file whose methods are not in the writer's order is written back as it was, so export wrote nothing."

	| class className committed file location packageName repositoryName result |
	repositoryName := 'MCP Export Order Only Test'.
	packageName := 'MCPToolRepositoryOperationOrderOnlyPackage'.
	className := 'MCPToolRepositoryOperationOrderOnlyClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportOrderOnly'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					class := self class environment at: className asSymbol.
					class compile: 'alpha ^ 1' classified: 'probing'.
					class compile: 'beta ^ 2' classified: 'probing'.
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					file := location / 'src' / packageName / (className , '.class.st').
					committed := self tonelSource: file contents withFirstTwoMethodsSwapped: true.
					self write: committed to: file.
					self commitAllIn: location message: 'Keep the methods in another order'.
					result := self exportRepositoryNamed: repositoryName.
					self
						assert: (self summaryFrom: result)
						equals: ('Exported repository {1}: nothing to write, its files already hold what the image has.' format: { repositoryName }).
					self assert: file binaryReadStream upToEnd equals: committed utf8Encoded ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportLeavesOutFilesItDidNotWrite [
	"Files written by hand are what git sees, not what export wrote: they are left uncommitted, and no directory is read as a package."

	| data location packageName repositoryName result |
	repositoryName := 'MCP Export Hand Written Test'.
	packageName := 'MCPToolRepositoryOperationHandWrittenPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportHandWritten'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationHandWrittenClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					self commitRepositoryNamed: repositoryName message: 'Write the package'.
					self write: '# Notes' to: location / 'README.md'.
					self write: 'x' to: location / 'src' / 'Other' / 'x.st'.
					result := self exportRepositoryNamed: repositoryName.
					data := self dataFrom: result.
					self
						assert: (self summaryFrom: result)
						equals: ('Exported repository {1}: nothing to write, its files already hold what the image has.' format: { repositoryName }).
					self assert: (data at: #alsoUncommitted) asArray equals: #( 'README.md' 'src/Other/x.st' ).
					self deny: (data includesKey: #packages) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportNamesTheFilesItDeleted [
	"The writer writes a package's directory again from what the image holds, so the file of a class the image no longer has is deleted, and export names it."

	| data location packageName removedClassName repositoryName result |
	repositoryName := 'MCP Export Deleted Test'.
	packageName := 'MCPToolRepositoryOperationDeletedPackage'.
	removedClassName := 'MCPToolRepositoryOperationDeletedLaterClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportDeleted'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationDeletedClass' do: [
			[
				self createClassNamed: removedClassName inPackageNamed: packageName.
				self withCleanRepositoryNamed: repositoryName location: location do: [
						self
							createRepositoryNamed: repositoryName
							location: location
							subdirectory: 'src'
							packages: { packageName }.
						self exportRepositoryNamed: repositoryName.
						self commitRepositoryNamed: repositoryName message: 'Write the package'.
						self removeClassNamed: removedClassName.
						result := self exportRepositoryNamed: repositoryName.
						data := self dataFrom: result.
						self assert: (data at: #deleted) asArray equals: { ('src/{1}/{2}.class.st' format: {
									 packageName.
									 removedClassName }) }.
						self assert: (data at: #packages) asArray equals: { packageName }.
						self deny: (data includesKey: #written) ] ] ensure: [ self removeClassNamed: removedClassName ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportNamesTheFilesItWrote [
	"Export compares the files it may write before and after writing them. A package directory it creates is named once, as git names an untracked directory, and every path counts from the checkout root."

	| data location packageName repositoryName result written |
	repositoryName := 'MCP Repository Command Export Test'.
	packageName := 'MCPToolRepositoryOperationExportPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExport'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationExportClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					result := self exportRepositoryNamed: repositoryName.
					data := self dataFrom: result.
					self assert: (self summaryFrom: result) equals: ('Exported repository {1}: wrote {2}, not committed yet.' format: {
								 repositoryName.
								 packageName }).
					written := OrderedCollection with: '.project' with: ('src/{1}/' format: { packageName }).
					(location / 'src' / '.properties') exists ifTrue: [ written add: 'src/.properties' ].
					self assert: (data at: #written) asArray equals: written asArray sort.
					self assert: (data at: #packages) asArray equals: { packageName }.
					self assert: data keys asSet equals: #( packages written ) asSet ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportOfAnUnchangedRepositoryWritesNothing [
	"Writing what the files already hold changes no byte, so the second export names nothing it wrote, and what the first wrote is left uncommitted, file by file."

	| data location packageName repositoryName result |
	repositoryName := 'MCP Export Unchanged Test'.
	packageName := 'MCPToolRepositoryOperationUnchangedPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportUnchanged'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationUnchangedClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					result := self exportRepositoryNamed: repositoryName.
					data := self dataFrom: result.
					self
						assert: (self summaryFrom: result)
						equals: ('Exported repository {1}: nothing to write, its files already hold what the image has.' format: { repositoryName }).
					self deny: (data includesKey: #written).
					self deny: (data includesKey: #packages).
					self assert:
						((data at: #alsoUncommitted) includes: ('src/{1}/MCPToolRepositoryOperationUnchangedClass.class.st' format: { packageName })).
					self assert: (data at: #alsoUncommitted) asArray equals: (self filePathsIn: location) ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportRefusesARepositoryWithoutPackages [
	"A repository that registers no package gives export nothing to write. It refuses before writing, so neither the files nor what git sees change."

	| file location repositoryName result statusBefore |
	repositoryName := 'MCP Export Without Packages Test'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportWithoutPackages'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			location ensureCreateDirectory.
			self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
			self callToolWith: {
					(#action -> 'attach').
					(#name -> repositoryName).
					(#location -> location pathString) } asDictionary.
			file := location / 'src' / 'X' / 'a.st'.
			self write: 'x' to: file.
			statusBefore := self git: 'status --porcelain=v1 --untracked-files=all' in: location.
			result := self exportRepositoryNamed: repositoryName.
			self assert: (self resultIndicatesError: result).
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryHasNoPackages'.
			self
				assert: (self summaryFrom: result)
				equals:
					('Repository {1} has no packages, so export has nothing to write. Add them with repository_update addPackages, then export again.'
						 format: { repositoryName }).
			self assert: (self git: 'status --porcelain=v1 --untracked-files=all' in: location) equals: statusBefore.
			self assert: (self filePathsIn: location) equals: #( 'src/X/a.st' ).
			self assert: file contents equals: 'x' ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportRefusesWhenNoRegisteredPackageIsInTheImage [

	| absentPackageName location repositoryName result |
	repositoryName := 'MCP Export Absent Packages Test'.
	absentPackageName := 'MCPToolRepositoryOperationAbsentPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportAbsentPackages'.
	self withCleanRepositoryNamed: repositoryName location: location do: [
			self
				createRepositoryNamed: repositoryName
				location: location
				subdirectory: 'src'
				packages: #(  ).
			self callToolWith: {
					(#action -> 'update').
					(#name -> repositoryName).
					(#addPackages -> { absentPackageName }) } asDictionary.
			result := self exportRepositoryNamed: repositoryName.
			self assert: (self resultIndicatesError: result).
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'RepositoryPackagesNotInImage'.
			self
				assert: (self summaryFrom: result)
				equals:
					('None of the packages repository {1} registers is in the image: {2}. Export has nothing to write; repository_update removePackages and addPackages correct the list.'
						 format: {
								 repositoryName.
								 absentPackageName }) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportRewritesAShorterProjectFileWhole [

	| location packageName repositoryName |
	repositoryName := 'MCP Export Shorter Project File Test'.
	packageName := 'MCPToolRepositoryOperationShorterProjectPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportShorterProjectFile'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationShorterProjectClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self callToolWith: {
							(#action -> 'create').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#subdirectory -> 'repository').
							(#packages -> { packageName }) } asDictionary.
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					self callToolWith: {
							(#action -> 'update').
							(#name -> repositoryName).
							(#subdirectory -> 'src') } asDictionary.
					self callToolWith: {
							(#action -> 'export').
							(#name -> repositoryName) } asDictionary.
					self assert: ((STON fromString: (location / '.project') contents) at: 'srcDirectory') equals: 'src'.
					self assert: ((location / '.project') contents occurrencesOf: $}) equals: 1 ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testExportWarnsOfARegisteredPackageNotInTheImage [
	"Export writes the packages the image holds and says which registered ones it left alone."

	| absentPackageName data location packageName repositoryName result |
	repositoryName := 'MCP Export Warns Absent Package Test'.
	packageName := 'MCPToolRepositoryOperationWarnsPackage'.
	absentPackageName := 'MCPToolRepositoryOperationWarnsAbsentPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportWarnsAbsentPackage'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationWarnsClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self callToolWith: {
							(#action -> 'update').
							(#name -> repositoryName).
							(#addPackages -> { absentPackageName }) } asDictionary.
					result := self exportRepositoryNamed: repositoryName.
					data := self dataFrom: result.
					self
						assert: (self warningsFrom: result) asArray
						equals:
							{ ('{1} is registered in repository {2} but not in the image, so export did not write it; its files in the checkout are left as they are. If it no longer belongs to the repository, repository_update removePackages drops it.'
								 format: {
										 absentPackageName.
										 repositoryName }) }.
					self assert: (data at: #written) asArray equals: {
							'.project'.
							('src/{1}/' format: { packageName }) }.
					self assert: (data at: #packages) asArray equals: { packageName } ] ]
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
					self shellCommand: (String streamContents: [ :stream |
							 stream << 'git -C ' << (self shellQuote: location pathString) << ' remote add origin https://example.com/worktree.git' ]).
					self shellCommand: (String streamContents: [ :stream |
								 stream << 'git -C ' << (self shellQuote: location pathString) << ' worktree add -b ' << branchName << ' '
								 << (self shellQuote: linkedLocation pathString) ]).
					[
						self shellCommand: (String streamContents: [ :stream |
								 stream << 'git -C ' << (self shellQuote: linkedLocation pathString) << ' config branch.' << branchName
								 << '.remote origin' ]).
						self shellCommand: (String streamContents: [ :stream |
									 stream << 'git -C ' << (self shellQuote: linkedLocation pathString) << ' config branch.' << branchName
									 << '.merge refs/heads/' << branchName ]).
						self removeRegisteredRepositoriesNamed: repositoryName.
						attachResult := self callToolWith: {
								                (#action -> 'attach').
								                (#name -> repositoryName).
								                (#location -> linkedLocation pathString).
								                (#subdirectory -> 'src').
								                (#packages -> { packageName }) } asDictionary.
						self deny: (self resultIndicatesError: attachResult) description: (self summaryFrom: attachResult).
						searchResult := self searchRepositoriesWith: { (#name -> repositoryName) } asDictionary.
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
							self shellCommand: (String streamContents: [ :stream |
										 stream << 'git -C ' << (self shellQuote: location pathString) << ' worktree remove --force '
										 << (self shellQuote: linkedLocation pathString) ]).
							linkedLocation exists ifTrue: [ linkedLocation deleteAll ] ] ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testOrderOnlyRestoreWritesTheOldFileWhole [
	"A committed file with its methods in another order and one blank line fewer than the writer writes is shorter than what the writer wrote over it. Writing it back must leave nothing of the longer file past its end."

	| class className file location packageName repositoryName |
	repositoryName := 'MCP Export Order Only Shorter Test'.
	packageName := 'MCPToolRepositoryOperationOrderOnlyShorterPackage'.
	className := 'MCPToolRepositoryOperationOrderOnlyShorterClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestExportOrderOnlyShorter'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					class := self class environment at: className asSymbol.
					class compile: 'alpha ^ 1' classified: 'probing'.
					class compile: 'beta ^ 2' classified: 'probing'.
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					file := location / 'src' / packageName / (className , '.class.st').
					self write: (self tonelSource: file contents withFirstTwoMethodsSwapped: false) to: file.
					self commitAllIn: location message: 'Keep the methods in another order, closer together'.
					self exportRepositoryNamed: repositoryName.
					self git: 'diff --exit-code' in: location ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testPathRuleNamesTheRegisteredPackagesOfAPath [

	| absentPackageName className command location packageName repository repositoryName |
	repositoryName := 'MCP Path Rule Test'.
	packageName := 'MCPToolRepositoryOperationPathRulePackage'.
	absentPackageName := 'MCPToolRepositoryOperationPathRuleAbsentPackage'.
	className := 'MCPToolRepositoryOperationPathRuleClass'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestPathRule'.
	self withExportPackageNamed: packageName className: className do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					self callToolWith: {
							(#action -> 'update').
							(#name -> repositoryName).
							(#addPackages -> { absentPackageName }) } asDictionary.
					self write: 'a' to: location / 'src' / absentPackageName / 'a.st'.
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					command := MCPExportRepositoryCommand new.
					{
						('src/{1}/{2}.class.st' format: {
								 packageName.
								 className }).
						('src/{1}' format: { packageName }).
						('src/{1}/' format: { packageName }) } do: [ :path |
						self assert: (command packageNamesForPaths: { path } in: repository) equals: { packageName } ].
					self assert: (command packageNamesForPaths: #( 'src/' ) in: repository) equals: {
							absentPackageName.
							packageName } sort.
					#( 'src/Other/x.st' 'src/Other/' 'README.md' ) do: [ :path |
						self assert: (command packageNamesForPaths: { path } in: repository) isEmpty ] ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testReloadAnswersBranchAndPackages [

	| location packageName repositoryName result |
	repositoryName := 'MCP Reload Answers Test'.
	packageName := 'MCPToolRepositoryOperationReloadAnswersPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestReloadAnswers'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationReloadAnswersClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					self
						createRepositoryNamed: repositoryName
						location: location
						subdirectory: 'src'
						packages: { packageName }.
					self exportRepositoryNamed: repositoryName.
					self commitRepositoryNamed: repositoryName message: 'Hold the package'.
					result := self callToolWith: {
							          (#action -> 'reload').
							          (#name -> repositoryName) } asDictionary.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					self
						assert: (self summaryFrom: result)
						equals: ('Reloaded repository {1} from its files, on branch main.' format: { repositoryName }).
					self assert: (self dataFrom: result) keys asArray equals: #( packages ).
					self assert: ((self dataFrom: result) at: #packages) asArray equals: { packageName } ] ]
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
	"The snapshot holds each file's bytes by path from the checkout root."

	| command file location original repository restored snapshot |
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestOrderOnly'.
	self deleteDirectoryIfExists: location.
	[
		file := location / 'MCP-Order' / 'MCPOrderTestClass.class.st'.
		original := self tonelClassSourceWithMethods: #( 'alpha' 'beta' ).
		self write: (self tonelClassSourceWithMethods: #( 'beta' 'alpha' )) to: file.
		repository := self newRepositoryNamed: 'MCP Order Only Test' location: location packageNames: #(  ).
		command := MCPExportRepositoryCommand new.
		snapshot := Dictionary new.
		snapshot at: 'MCP-Order/MCPOrderTestClass.class.st' put: original utf8Encoded.
		restored := command restoreOrderOnlyTonelChurnFor: repository fromSnapshot: snapshot.
		self assert: restored equals: #( 'MCP-Order/MCPOrderTestClass.class.st' ).
		self assert: file contents equals: original ] ensure: [ self deleteDirectoryIfExists: location ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testSourceFormatChoosesItsOwnReaderAndWriter [

	| command |
	command := MCPRepositoryCommand new.
	self assert: (command sourceRepositoryClassForWriter: IceLibgitTonelWriter) equals: TonelRepository.
	self assert: (command sourceRepositoryClassForWriter: IceLibgitFiletreeWriter) equals: MCFileTreeRepository
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testSourceFormatSupportsEveryFormatIcebergWrites [

	| command icebergFormats |
	command := MCPRepositoryCommand new.
	icebergFormats := (TIceRepositoryWriter users collect: [ :each | each id asString ] as: Array) sort.
	self assert: command supportedSourceFormatIds = icebergFormats description: (String streamContents: [ :stream |
				 stream << 'Every format Iceberg writes must be one this reads back, but it writes ' << icebergFormats printString
				 << ' and this reads ' << command supportedSourceFormatIds printString ]).
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
			self assert: data keys asSet equals: #( addedPackages ) asSet.
			self assert: (data at: #addedPackages) equals: { packageName }.
			self assert: (self warningsFrom: result) size equals: 1.
			self assert: ((self warningsFrom: result) first beginsWith: packageName , ' is in neither the image nor the checkout.') ]
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
			self assert: data keys asSet equals: #( addedPackages removedPackages ) asSet.
			self assert: (data at: #addedPackages) equals: #( 'MCPToolRepositoryOperationNewC' ).
			self assert: (data at: #removedPackages) equals: #( 'MCPToolRepositoryOperationOldA' ) ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateGivesAnEmptyCheckoutItsSubdirectory [

	| location repository repositoryName result |
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
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
			self assert: repository subdirectory equals: 'src'.
			self assert: ((self summaryFrom: result) includesSubstring: '.project') ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateKeepsThePackagesOfACheckoutItGivesASubdirectory [

	| location packageName repository repositoryName result |
	repositoryName := 'MCP Update Keeps Packages Test'.
	packageName := 'MCPToolRepositoryOperationKeptPackage'.
	location := self temporaryRepositoryLocationNamed: 'MCPToolRepositoryOperationTestUpdateKeepsPackages'.
	self withExportPackageNamed: packageName className: 'MCPToolRepositoryOperationKeptClass' do: [
			self withCleanRepositoryNamed: repositoryName location: location do: [
					location ensureCreateDirectory.
					self shellCommand: 'git init --initial-branch=main ' , (self shellQuote: location pathString).
					self callToolWith: {
							(#action -> 'attach').
							(#name -> repositoryName).
							(#location -> location pathString).
							(#packages -> { packageName }) } asDictionary.
					result := self callToolWith: {
							          (#action -> 'update').
							          (#name -> repositoryName).
							          (#subdirectory -> 'src') } asDictionary.
					self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
					repository := IceRepository repositories detect: [ :each | each name asString = repositoryName ].
					self assert: (self packageNamesIn: repository) equals: { packageName } ] ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateRemovesPackageWithoutUnloading [

	| data packageName repository result |
	packageName := 'MCPToolRepositoryOperationRemovalPackage'.
	self withoutEpiceaDuring: [ self packageOrganizer ensurePackage: packageName ].
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
				self assert: (self packageOrganizer hasPackage: packageName).
				self assert: data keys asSet equals: #( removedPackages ) asSet.
				self assert: (data at: #removedPackages) equals: { packageName } ] ] ensure: [ self removePackageNamed: packageName ]
]

{ #category : 'tests' }
MCPToolRepositoryOperationTest >> testUpdateWithNothingToDoNamesItsArguments [

	| repository result |
	repository := self
		              newRepositoryNamed: 'MCP Repository Command Nothing To Do Test'
		              location: FileLocator imageDirectory
		              packageNames: #(  ).
	self withRegisteredRepository: repository do: [
			result := self callToolWith: {
					          (#action -> 'update').
					          (#name -> repository name) } asDictionary.
			self assert: (self resultIndicatesError: result).
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'NoRepositoryUpdateRequested'.
			self
				assert: (self summaryFrom: result)
				equals: 'repository_update needs at least one of subdirectory, packages, addPackages or removePackages.' ]
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

	| repository result |
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
			self deny: (self resultIndicatesError: result) description: (self summaryFrom: result).
			self
				assert: (self summaryFrom: result)
				equals:
				'Verified repository MCP VerifyIdentity Match Test Repository: location, branch, subdirectory, packages, modifiedPackages, isModified as expected.'.
			self assert: (self dataFrom: result) isEmpty.
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
			self assert: (contentText includesSubstring: 'packages: expected [MCP, MCP-Tests], actual [MCP]') ]
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
				nextPutAll: (String streamContents: [ :stream | stream << String tab << '^ #' << selector ]);
				nextPut: Character lf;
				nextPutAll: ']';
				nextPut: Character lf ].
	^ stream contents
]

{ #category : 'private - fixtures' }
MCPToolRepositoryOperationTest >> tonelSource: aString withFirstTwoMethodsSwapped: keepsBlankLine [
	"The Tonel source with its first two methods in the other order, which the writer would put back. Without the blank line, the source also has one blank line fewer between them than the writer writes."

	| first second |
	first := aString findString: '{ #category'.
	second := aString findString: '{ #category' startingAt: first + 1.
	^ String streamContents: [ :stream |
			  stream << (aString copyFrom: 1 to: first - 1) << (aString copyFrom: second to: aString size).
			  keepsBlankLine ifTrue: [ stream nextPut: Character lf ].
			  stream << (aString copyFrom: first to: second - 2) ]
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

{ #category : 'private' }
MCPToolRepositoryOperationTest >> write: aString to: aFileReference [

	aFileReference parent ensureCreateDirectory.
	aFileReference ensureDelete.
	aFileReference writeStreamDo: [ :stream | stream nextPutAll: aString ]
]
