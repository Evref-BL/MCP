"
Command wrapper for repository_create. It starts a repository with no history where nothing is yet: Iceberg's creator makes a location that does not exist; a directory that holds no file gets git init; and that directory, like a Git repository with no commit that holds no file, is then registered as repository_attach registers a checkout, with a source directory made for it. Before writing anything it refuses a relative location, a name or location already registered, a package the image lacks, and any other location. It answers an MCPRepositoryCreateResult naming the repository's packages, and warns when it has none or when another repository registers them too. repository_attach shares the first two refusals.
"
Class {
	#name : 'MCPCreateRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> addFilesIn: aDirectory under: aPrefix to: files ignoringGit: ignoresGit [
	"Three files are as many as a refusal names."

	(aDirectory children asArray sort: [ :left :right | left basename <= right basename ]) do: [ :each |
			| path |
			files size >= 3 ifTrue: [ ^ self ].
			path := aPrefix , each basename.
			(aPrefix isEmpty and: [ each basename = '.git' ])
				ifTrue: [ ignoresGit ifFalse: [ files add: path ] ]
				ifFalse: [
						(each isDirectory and: [ each isSymlink not ])
							ifTrue: [
									self
										addFilesIn: each
										under: path , '/'
										to: files
										ignoringGit: ignoresGit ]
							ifFalse: [ each basename = '.DS_Store' ifFalse: [ files add: path ] ] ] ]
]

{ #category : 'private' }
MCPCreateRepositoryCommand >> addRequestedPackagesTo: aRepository [

	self request packageNames do: [ :each | aRepository workingCopy addPackageNamed: each ]
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> checkoutHasNoCommit: aLocation [
	"Asked of a repository made for the question and never registered."

	^ MCPIcebergCommitInfo isNoCommit: (IceLibgitRepository new
			   location: aLocation;
			   yourself) headCommit
]

{ #category : 'private - creating' }
MCPCreateRepositoryCommand >> createRepositoryIn: aLocationState [
	"Iceberg's creator makes a location that does not exist; an empty directory gets git init and is then registered as an empty Git repository is."

	| location |
	location := self request location asFileReference.
	aLocationState = #absent ifTrue: [ ^ self createRepositoryWithIcebergAt: location ].
	aLocationState = #empty ifTrue: [ self initializeGitAt: location ].
	^ self registerEmptyCheckoutAt: location
]

{ #category : 'private - creating' }
MCPCreateRepositoryCommand >> createRepositoryWithIcebergAt: aLocation [

	| creator repository |
	creator := IceRepositoryCreator new.
	creator location: aLocation.
	self request subdirectory ifNotNil: [ :value | creator subdirectory: value ].
	repository := creator createNewRepositoryNamed: self request name.
	repository register.
	^ repository
]

{ #category : 'executing' }
MCPCreateRepositoryCommand >> execute [

	| locationState packageWarnings repository result summary |
	^ self
		  executeRepositoryAction: 'create'
		  work: [
				  self refuseRelativeLocation.
				  self refuseRegisteredNameOrLocation.
				  self refusePackagesNotInImage.
				  locationState := self locationStateRefusingAnyOther.
				  repository := self createRepositoryIn: locationState.
				  self addRequestedPackagesTo: repository.
				  result := MCPRepositoryCreateResult fromRepository: repository.
				  summary := self summaryForRepository: repository createdIn: locationState.
				  packageWarnings := self packageWarningsFor: repository ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: summary
				  data: (self tool dataForRepositoryResult: result)
				  warnings: warningMessages , packageWarnings ]
		  failureSummary: [ :error |
				  String streamContents: [ :stream |
					  stream << 'Failed to create repository ' << self request name << ': ' << (error messageText ifNil: [ error asString ]) ] ]
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> firstFilesIn: aLocation ignoringGit: ignoresGit [
	"Up to three files aLocation holds, as paths from it with their segments joined by a slash, found by walking every level in name order. A .DS_Store, which macOS's Finder leaves, is no file. A .git at the top is passed over when ignoresGit, and is otherwise named as a file: only a Git root's .git is not one."

	| files |
	files := OrderedCollection new.
	self
		addFilesIn: aLocation
		under: ''
		to: files
		ignoringGit: ignoresGit.
	^ files asArray
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> gitDirectoryReferenceFor: gitDirPath relativeTo: aLocation [

	| reference |
	reference := gitDirPath asFileReference.
	^ reference isAbsolute
		  ifTrue: [ reference ]
		  ifFalse: [ aLocation / gitDirPath ]
]

{ #category : 'private - creating' }
MCPCreateRepositoryCommand >> initializeGitAt: aLocation [
	"git init, as Iceberg's creator runs it."

	(IceLibgitRepository new
		 location: aLocation;
		 yourself) init
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> isGitCheckoutRoot: aLocation [

	^ (IceRepositoryCreator isGitRoot: aLocation) or: [ self isLinkedGitWorktreeRoot: aLocation ]
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> isLinkedGitWorktreeRoot: aLocation [

	| contents gitDirectoryPath gitFile |
	aLocation isDirectory ifFalse: [ ^ false ].
	gitFile := aLocation / '.git'.
	(gitFile exists and: [ gitFile isFile ]) ifFalse: [ ^ false ].
	contents := [ gitFile contents trimBoth ]
		            on: Error
		            do: [ :ignored | ^ false ].
	(contents beginsWith: 'gitdir:') ifFalse: [ ^ false ].
	gitDirectoryPath := (contents allButFirst: 'gitdir:' size) trimBoth.
	gitDirectoryPath isEmpty ifTrue: [ ^ false ].
	^ (self gitDirectoryReferenceFor: gitDirectoryPath relativeTo: aLocation) exists
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> locationStateRefusingAnyOther [
	"Where create starts the repository: #absent where nothing exists yet, #empty in a directory that holds no file, #emptyCheckout in a Git repository with no commit that holds no file. Any other location is refused here, before anything is written."

	| files location |
	location := self request location asFileReference.
	location exists ifFalse: [ ^ #absent ].
	location isDirectory ifFalse: [ self signalLocationIsAFile: location ].
	(self isGitCheckoutRoot: location) ifTrue: [
			((self checkoutHasNoCommit: location) and: [ (self firstFilesIn: location ignoringGit: true) isEmpty ]) ifTrue: [
				^ #emptyCheckout ].
			self signalLocationIsACheckout: location ].
	files := self firstFilesIn: location ignoringGit: false.
	files ifNotEmpty: [ self signalLocation: location holdsFiles: files ].
	^ #empty
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> matchingRegisteredRepositories [
	"The registered repositories that already have the requested name or location."

	| locationPath |
	locationPath := self request location asFileReference pathString.
	^ IceRepository repositories select: [ :each |
		  each name asString = self request name or: [ (self repositoryLocationStringFor: each) = locationPath ] ]
]

{ #category : 'private - results' }
MCPCreateRepositoryCommand >> noPackagesWarningFor: aRepository [

	^ String streamContents: [ :stream |
		  stream << 'Repository ' << aRepository name << ' has no packages yet; repository_update addPackages adds them.' ]
]

{ #category : 'private - results' }
MCPCreateRepositoryCommand >> packageNamesRegisteredIn: aRepository [
	"A registration whose working copy cannot be read registers nothing this can name."

	^ [ aRepository workingCopy packageNames collect: [ :each | each asString ] ]
		  on: Error
		  do: [ #(  ) ]
]

{ #category : 'private - results' }
MCPCreateRepositoryCommand >> packageWarningsFor: aRepository [
	"Say when the repository has no packages, and name every other repository that registers some of them: two registrations claiming one package is a hazard."

	| packageNames |
	packageNames := self sortedStringsFrom: aRepository workingCopy packageNames.
	packageNames ifEmpty: [ ^ { (self noPackagesWarningFor: aRepository) } ].
	^ self warningsForPackages: packageNames alsoRegisteredBesides: aRepository
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> refusalPrefix [

	^ String streamContents: [ :stream |
		  stream << 'Cannot ' << self request operation << ' repository ' << self request name << ': ' ]
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> refusePackagesNotInImage [
	"A repository registering a package the image lacks would only leave a registration to repair."

	self request packageNames
		detect: [ :each | (self packageOrganizer hasPackage: each) not ]
		ifFound: [ :packageName | self signalPackageNotInImageNamed: packageName ]
		ifNone: [ ]
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> refuseRegisteredNameOrLocation [
	"One name, or one location, would name two repositories."

	| matches |
	matches := self matchingRegisteredRepositories.
	matches ifEmpty: [ ^ self ].
	matches
		detect: [ :each | each name asString = self request name ]
		ifFound: [ :repository | self signalNameRegisteredFor: repository among: matches ]
		ifNone: [ self signalLocationRegisteredFor: matches first among: matches ]
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> refuseRelativeLocation [
	"The image would resolve a relative location against its own working directory, which is not the caller's."

	self request location asFileReference isAbsolute ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #RepositoryLocationNotAbsolute
		message: (String streamContents: [ :stream |
					 stream << self refusalPrefix << 'location ' << self request location
					 << ' is not an absolute path, and the image would resolve it against its own working directory, '
					 << FileSystem workingDirectory fullName << '. Give the full path.' ])
		details: self request requestedContext
]

{ #category : 'private - creating' }
MCPCreateRepositoryCommand >> registerCheckoutAt: aLocation during: aBlock [
	"Register the Git checkout at aLocation without writing to it, letting aBlock set the repository up before it is announced."

	| repository |
	repository := IceLibgitRepository new
		              name: self request name;
		              location: aLocation;
		              yourself.
	repository pluginManager repositoryWillBeCreated: repository.
	repository workingCopy initializePackagesFromRepository.
	aBlock value: repository.
	repository pluginManager repositoryWasCreated: repository.
	repository register.
	^ repository
]

{ #category : 'private - creating' }
MCPCreateRepositoryCommand >> registerEmptyCheckoutAt: aLocation [
	"Its project is unborn: give it a source directory, as Iceberg's creator does, and make that directory. Nothing in .git is touched, so a remote set there before is kept."

	^ self registerCheckoutAt: aLocation during: [ :repository |
			  self setSubdirectory: (self request subdirectory ifNil: [ '' ]) on: repository.
			  (self repositorySourceDirectoryFor: repository) ensureCreateDirectory ]
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalAlreadyRegistered: aMessage among: matches [

	MCPCommandError signalErrorCode: #RepositoryAlreadyRegistered message: aMessage details: (self request requestedContext copy
			 at: #matchingRepositories put: (matches collect: [ :each | each name asString ] as: Array) sort;
			 yourself)
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalLocation: aLocation holdsFiles: filePaths [

	MCPCommandError
		signalErrorCode: #RepositoryLocationNotEmpty
		message: (String streamContents: [ :stream |
					 stream << self refusalPrefix << aLocation fullName << ' already holds '.
					 filePaths size = 1
						 ifTrue: [ stream << 'a file, ' << filePaths first ]
						 ifFalse: [ stream << 'files, such as ' << (MCPScopeQuery listPhraseFor: filePaths) ].
					 stream
					 <<
					 '. Give a location that does not exist yet or holds no file; to keep what is there, run git init there and register it with repository_attach.' ])
		details: (self request requestedContext copy
				 at: #files put: filePaths;
				 yourself)
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalLocationIsACheckout: aLocation [

	MCPCommandError
		signalErrorCode: #RepositoryLocationIsCheckout
		message: (String streamContents: [ :stream |
				 stream << self refusalPrefix << aLocation fullName
				 << ' is already a Git checkout. Register it with repository_attach instead.' ])
		details: self request requestedContext
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalLocationIsAFile: aLocation [

	MCPCommandError
		signalErrorCode: #RepositoryLocationNotDirectory
		message: (String streamContents: [ :stream |
				 stream << self refusalPrefix << aLocation fullName
				 << ' is a file. Give a directory that does not exist yet or holds no file.' ])
		details: self request requestedContext
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalLocationRegisteredFor: aRepository among: matches [

	self
		signalAlreadyRegistered: (String streamContents: [ :stream |
					 stream << self refusalPrefix << 'repository ' << aRepository name << ' is already registered at '
					 << (self repositoryLocationStringFor: aRepository) << '. Use it, or choose another location.' ])
		among: matches
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalNameRegisteredFor: aRepository among: matches [

	| location |
	location := self repositoryLocationStringFor: aRepository.
	self
		signalAlreadyRegistered: (String streamContents: [ :stream |
					 stream << self refusalPrefix << 'a repository of that name is already registered, '.
					 location ifEmpty: [ stream << 'with no location' ] ifNotEmpty: [ stream << 'at ' << location ].
					 stream << '. Choose another name.' ])
		among: matches
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalPackageNotInImageNamed: aPackageName [

	| suggestions |
	suggestions := MCPScopeNameSuggester packageSuggestionsFor: aPackageName.
	MCPCommandError
		signalErrorCode: #PackageNotFound
		message: (String streamContents: [ :stream |
					 stream << self refusalPrefix << 'package ' << aPackageName << ' does not exist.'.
					 suggestions ifNotEmpty: [ stream << ' Did you mean: ' << (', ' join: suggestions) << '.' ].
					 stream << ' Create the package first, or leave it out and add it later with repository_update addPackages.' ])
		details: {
				(#package -> aPackageName).
				(#suggestions -> suggestions) } asDictionary
]

{ #category : 'private - results' }
MCPCreateRepositoryCommand >> sourcesPhraseFor: aRepository [

	| subdirectory |
	subdirectory := (aRepository subdirectory ifNil: [ '' ]) asString.
	subdirectory isEmpty ifTrue: [ ^ 'with its sources at its root' ].
	^ 'with its sources in ' , subdirectory
]

{ #category : 'private - results' }
MCPCreateRepositoryCommand >> summaryForRepository: aRepository createdIn: aLocationState [

	^ String streamContents: [ :stream |
			  stream << 'Created repository ' << aRepository name << (aLocationState = #emptyCheckout
				   ifTrue: [ ' in the empty Git repository at ' ]
				   ifFalse: [ ' at ' ]) << aRepository location fullName << ', ' << (self sourcesPhraseFor: aRepository)
			  << '; repository_export writes its packages there.' ]
]

{ #category : 'private - results' }
MCPCreateRepositoryCommand >> warningsForPackages: packageNames alsoRegisteredBesides: aRepository [
	"One warning per other registered repository that registers some of these packages, in the order of their names."

	| others |
	others := (IceRepository repositories reject: [ :each | each == aRepository ]) asArray sort: [ :left :right |
		          left name asString <= right name asString ].
	^ Array streamContents: [ :stream |
			  others do: [ :other |
					  | shared |
					  shared := self sortedStringsFrom: ((self packageNamesRegisteredIn: other) select: [ :each | packageNames includes: each ]).
					  shared ifNotEmpty: [
							  stream nextPut: (String streamContents: [ :text |
										   text << (', ' join: shared) << (shared size = 1
											    ifTrue: [ ' is' ]
											    ifFalse: [ ' are' ]) << ' also registered in repository ' << other name << '.' ]) ] ] ]
]
