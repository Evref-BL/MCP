"
Creates or attaches a repository, for repository_create and repository_attach.

execute starts a repository with no history where nothing is yet: Iceberg's creator makes a location that does not exist; a directory that holds no file gets git init; and that directory, like a Git repository with no commit that holds no file, is then registered as attach registers a checkout, with a source directory made for it. Before writing anything it refuses a relative location, a name or location already registered, a package the image lacks, and any other location.

attach registers an existing Git checkout as it is, without writing to it, after the first two refusals and those of a location that does not exist or is no Git root.

Each adds the requested packages to the repository and answers it.
"
Class {
	#name : 'MCPCreateRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#instVars : [
		'name',
		'location',
		'subdirectory',
		'packageNames',
		'verb',
		'locationState'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPCreateRepositoryCommand class >> name: aName location: aLocation subdirectory: aSubdirectoryOrNil packageNames: packageNames [
	"A repository of that name at that absolute path, holding the packages from the source subdirectory, or from its root when there is none."

	^ self new
		  initializeName: aName
		  location: aLocation
		  subdirectory: aSubdirectoryOrNil
		  packageNames: packageNames
]

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

	packageNames do: [ :each | aRepository workingCopy addPackageNamed: each ]
]

{ #category : 'executing' }
MCPCreateRepositoryCommand >> attach [
	"Register the existing checkout at the location as it is, without writing to it, and give it its packages; answer the repository."

	| repository |
	verb := 'attach'.
	self refuseRelativeLocation.
	self refuseRegisteredNameOrLocation.
	repository := self registerCheckoutAt: self existingCheckoutLocation during: [ :each |
			              subdirectory ifNotNil: [ :value |
					              self setSubdirectory: value on: each.
					              "A checkout without .project had no source directory to read its packages from until now."
					              each workingCopy refreshPackages ] ].
	self addRequestedPackagesTo: repository.
	^ repository
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

	| reference |
	reference := location asFileReference.
	aLocationState = #absent ifTrue: [ ^ self createRepositoryWithIcebergAt: reference ].
	aLocationState = #empty ifTrue: [ self initializeGitAt: reference ].
	^ self registerEmptyCheckoutAt: reference
]

{ #category : 'private - creating' }
MCPCreateRepositoryCommand >> createRepositoryWithIcebergAt: aLocation [

	| creator repository |
	creator := IceRepositoryCreator new.
	creator location: aLocation.
	subdirectory ifNotNil: [ :value | creator subdirectory: value ].
	repository := creator createNewRepositoryNamed: name.
	repository register.
	^ repository
]

{ #category : 'executing' }
MCPCreateRepositoryCommand >> execute [
	"Start the repository, register it and give it its packages, refusing before anything is written what create cannot do; answer the repository."

	| repository |
	verb := 'create'.
	self refuseRelativeLocation.
	self refuseRegisteredNameOrLocation.
	self refusePackagesNotInImage.
	locationState := self locationStateRefusingAnyOther.
	repository := self createRepositoryIn: locationState.
	self addRequestedPackagesTo: repository.
	^ repository
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> existingCheckoutLocation [
	"The checkout attach registers, refused when nothing is there or when it is no Git root."

	| reference |
	reference := location asFileReference.
	reference exists ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationMissing
				message: (String streamContents: [ :stream | stream << self refusalPrefix << reference fullName << ' does not exist.' ])
				details: self requestedDetails ].
	(self isGitCheckoutRoot: reference) ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationNotGitRoot
				message: (String streamContents: [ :stream |
							 stream << self refusalPrefix << reference fullName
							 <<
							 ' is not the root of a Git checkout. repository_create starts a repository there if it holds no file; otherwise run git init there first.' ])
				details: self requestedDetails ].
	^ reference
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

{ #category : 'initialization' }
MCPCreateRepositoryCommand >> initializeName: aName location: aLocation subdirectory: aSubdirectory packageNames: somePackageNames [

	name := aName.
	location := aLocation.
	subdirectory := aSubdirectory.
	packageNames := somePackageNames
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

{ #category : 'accessing' }
MCPCreateRepositoryCommand >> locationState [
	"Where execute found the location: #absent, #empty or #emptyCheckout."

	^ locationState
]

{ #category : 'private - location' }
MCPCreateRepositoryCommand >> locationStateRefusingAnyOther [
	"Where create starts the repository: #absent where nothing exists yet, #empty in a directory that holds no file, #emptyCheckout in a Git repository with no commit that holds no file. Any other location is refused here, before anything is written."

	| files reference |
	reference := location asFileReference.
	reference exists ifFalse: [ ^ #absent ].
	reference isDirectory ifFalse: [ self signalLocationIsAFile: reference ].
	(self isGitCheckoutRoot: reference) ifTrue: [
			((self checkoutHasNoCommit: reference) and: [ (self firstFilesIn: reference ignoringGit: true) isEmpty ]) ifTrue: [
				^ #emptyCheckout ].
			self signalLocationIsACheckout: reference ].
	files := self firstFilesIn: reference ignoringGit: false.
	files ifNotEmpty: [ self signalLocation: reference holdsFiles: files ].
	^ #empty
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> matchingRegisteredRepositories [
	"The registered repositories that already have the requested name or location."

	| locationPath |
	locationPath := location asFileReference pathString.
	^ IceRepository repositories select: [ :each |
		  each name asString = name or: [ (self repositoryLocationStringFor: each) = locationPath ] ]
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> refusalPrefix [

	^ String streamContents: [ :stream | stream << 'Cannot ' << verb << ' repository ' << name << ': ' ]
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> refusePackagesNotInImage [
	"A repository registering a package the image lacks would only leave a registration to repair."

	packageNames
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
		detect: [ :each | each name asString = name ]
		ifFound: [ :repository | self signalNameRegisteredFor: repository among: matches ]
		ifNone: [ self signalLocationRegisteredFor: matches first among: matches ]
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> refuseRelativeLocation [
	"The image would resolve a relative location against its own working directory, which is not the caller's."

	location asFileReference isAbsolute ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #RepositoryLocationNotAbsolute
		message: (String streamContents: [ :stream |
					 stream << self refusalPrefix << 'location ' << location
					 << ' is not an absolute path, and the image would resolve it against its own working directory, '
					 << FileSystem workingDirectory fullName << '. Give the full path.' ])
		details: self requestedDetails
]

{ #category : 'private - creating' }
MCPCreateRepositoryCommand >> registerCheckoutAt: aLocation during: aBlock [
	"Register the Git checkout at aLocation without writing to it, letting aBlock set the repository up before it is announced."

	| repository |
	repository := IceLibgitRepository new
		              name: name;
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
			  self setSubdirectory: (subdirectory ifNil: [ '' ]) on: repository.
			  (self repositorySourceDirectoryFor: repository) ensureCreateDirectory ]
]

{ #category : 'accessing' }
MCPCreateRepositoryCommand >> requestedDetails [
	"What a refusal says of the repository asked for."

	^ {
		  (#name -> name).
		  (#location -> location).
		  (#subdirectory -> (subdirectory ifNil: [ '' ])).
		  (#packages -> packageNames) } asDictionary
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalAlreadyRegistered: aMessage among: matches [

	MCPCommandError signalErrorCode: #RepositoryAlreadyRegistered message: aMessage details: (self requestedDetails copy
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
		details: (self requestedDetails copy
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
		details: self requestedDetails
]

{ #category : 'private - signaling' }
MCPCreateRepositoryCommand >> signalLocationIsAFile: aLocation [

	MCPCommandError
		signalErrorCode: #RepositoryLocationNotDirectory
		message: (String streamContents: [ :stream |
				 stream << self refusalPrefix << aLocation fullName
				 << ' is a file. Give a directory that does not exist yet or holds no file.' ])
		details: self requestedDetails
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

	| registeredLocation |
	registeredLocation := self repositoryLocationStringFor: aRepository.
	self
		signalAlreadyRegistered: (String streamContents: [ :stream |
					 stream << self refusalPrefix << 'a repository of that name is already registered, '.
					 registeredLocation ifEmpty: [ stream << 'with no location' ] ifNotEmpty: [ stream << 'at ' << registeredLocation ].
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
