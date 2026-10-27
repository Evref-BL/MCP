"
Abstract base for repository command objects. It owns the shared tool/request state and construction protocol used by repository tools; subclasses implement the repository operation itself.
"
Class {
	#name : 'MCPRepositoryCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPRepositoryCommand class >> isAbstract [

	^ self = MCPRepositoryCommand
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> adoptHeadCommit: headCommit for: aRepository [

	self adoptHeadCommit: headCommit for: aRepository markLoadedPackagesClean: true
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> adoptHeadCommit: headCommit for: aRepository markLoadedPackagesClean: shouldMarkClean [

	| workingCopy |
	workingCopy := aRepository workingCopy.
	(self commit: workingCopy referenceCommit equals: headCommit) ifFalse: [ workingCopy referenceCommit: headCommit ].
	shouldMarkClean
		ifTrue: [ self markLoadedPackagesCleanIn: workingCopy ]
		ifFalse: [ self markLoadedPackagesDirtyIn: workingCopy ]
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> commit: leftCommit equals: rightCommit [

	leftCommit ifNil: [ ^ rightCommit isNil ].
	rightCommit ifNil: [ ^ false ].
	^ (self commitIdFrom: leftCommit) = (self commitIdFrom: rightCommit)
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> commitIdFrom: aCommit [

	^ MCPIcebergCommitInfo idStringFrom: aCommit
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> declaredSourceFormatFor: aRepository [
	"The format id the checkout writes in its .properties, or nil when it names
	none and when the repository cannot be asked at all."

	^ [ aRepository properties at: #format ]
		  on: Error
		  do: [ nil ]
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> definitionsAbsentFrom: expectedSnapshot inPackage: aPackage [

	| expectedDefinitions |
	expectedDefinitions := expectedSnapshot definitions asSet.
	^ aPackage snapshot definitions reject: [ :definition | expectedDefinitions includes: definition ]
]

{ #category : 'private - execution' }
MCPRepositoryCommand >> executeRepositoryAction: actionName work: workBlock successResult: successBlock failureSummary: failureBlock [

	^ self tool
		  executeMutationAction: actionName
		  force: false
		  requestedContext: self request requestedContext
		  work: workBlock
		  successResult: successBlock
		  failureSummary: failureBlock
]

{ #category : 'private - export' }
MCPRepositoryCommand >> exportProjectFileFor: aRepository [

	| project projectFile |
	project := aRepository workingCopy project.
	project ifNil: [ ^ self ].
	project isUnborn ifTrue: [ ^ self ].
	projectFile := aRepository location asFileReference / '.project'.
	projectFile binaryWriteStreamDo: [ :stream | stream nextPutAll: project contentsString ]
]

{ #category : 'private - git' }
MCPRepositoryCommand >> gitCommandStringFor: arguments in: aRepository outputFile: outputFile [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: 'git -C ';
				  nextPutAll: (self shellQuote: (self repositoryLocationStringFor: aRepository)).
			  arguments do: [ :argument |
					  stream
						  space;
						  nextPutAll: (self shellQuote: argument asString) ].
			  stream
				  space;
				  nextPut: $>;
				  space;
				  nextPutAll: (self shellQuote: outputFile pathString);
				  space;
				  nextPutAll: '2>&1' ]
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> loadLoadedPackagesFrom: headCommit in: aRepository [

	| loadedPackageNames workingCopy |
	workingCopy := aRepository workingCopy.
	loadedPackageNames := workingCopy loadedPackages collect: [ :package | package name ].
	workingCopy loadPackagesNamed: loadedPackageNames fromCommit: headCommit.
	self adoptHeadCommit: headCommit for: aRepository
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> loadLoadedPackagesFromDiskIn: aRepository [

	| writerClass |
	writerClass := self sourceWriterClassFor: aRepository.
	self withoutLeavingFiletreeMarkerIn: (self repositorySourceDirectoryFor: aRepository) do: [
		self
			loadLoadedPackagesFromSource: (self sourceRepositoryFor: aRepository writer: writerClass)
			in: aRepository
			writer: writerClass ]
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> loadLoadedPackagesFromSource: sourceRepository in: aRepository writer: aWriterClass [

	| missing versionsByName |
	versionsByName := OrderedDictionary new.
	aRepository workingCopy loadedPackages do: [ :package |
		versionsByName at: package name put: (self versionIn: sourceRepository for: package writer: aWriterClass) ].
	missing := versionsByName associations select: [ :each | each value isNil ] thenCollect: [ :each | each key ].
	missing ifNotEmpty: [ self signalMissingSourceForPackageNames: missing asArray in: aRepository writer: aWriterClass ].
	self loadVersionsReplacingImageChanges: versionsByName values asArray.
	self adoptHeadCommit: aRepository headCommit for: aRepository
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> loadVersionsReplacingImageChanges: versions [

	| loader |
	versions ifEmpty: [ ^ self ].
	loader := versions size > 1
		          ifTrue: [ MCMultiPackageLoader new ]
		          ifFalse: [ MCPackageLoader new ].
	versions do: [ :version | loader updatePackage: version package withSnapshot: version snapshot ].
	loader load.
	self unloadDefinitionsAbsentFromLoadedVersions: versions.
	versions do: [ :version | version workingCopy loaded: version ]
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> markLoadedPackagesCleanIn: aWorkingCopy [

	aWorkingCopy loadedPackages do: [ :package | package beDirty: false ]
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> markLoadedPackagesDirtyIn: aWorkingCopy [

	aWorkingCopy loadedPackages do: [ :package | package beDirty: true ]
]

{ #category : 'private - git' }
MCPRepositoryCommand >> normalizedSystemStatusFrom: anInteger [

	(anInteger isInteger and: [ anInteger > 255 ]) ifTrue: [ ^ anInteger bitShift: -8 ].
	^ anInteger
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> packageNameFromDirectoryName: aName writer: aWriterClass [
	"Each format names a package directory its own way: Tonel after the package
	itself, filetree with a .package extension. The writer the checkout declares
	knows which, so a changed path reports the package and not its directory."

	^ (aWriterClass packageNameFromDirectory: aName asFileReference) asString
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> referenceCommitFor: aRepository [

	^ aRepository workingCopy referenceCommit
]

{ #category : 'private - git' }
MCPRepositoryCommand >> repositoryHasGitWorkTree: aRepository [

	| result |
	result := self runGitArguments: #( 'rev-parse' '--is-inside-work-tree' ) in: aRepository.
	^ (result at: #status) = 0 and: [ (result at: #output) trimBoth = 'true' ]
]

{ #category : 'private - git' }
MCPRepositoryCommand >> repositoryLocationStringFor: aRepository [

	^ aRepository location ifNil: [ '' ] ifNotNil: [ :repositoryLocation | repositoryLocation mcpRepositoryLocationString ]
]

{ #category : 'private - export' }
MCPRepositoryCommand >> repositorySourceDirectoryFor: aRepository [

	| location subdirectory |
	location := aRepository location asFileReference.
	subdirectory := aRepository subdirectory.
	subdirectory ifNil: [ ^ location ].
	subdirectory asString isEmpty ifTrue: [ ^ location ].
	^ location / subdirectory asString
]

{ #category : 'private - git' }
MCPRepositoryCommand >> runGitArguments: arguments in: aRepository [

	| command output outputFile status |
	outputFile := FileLocator temp asFileReference / ('mcp-git-command-' , UUID new asString , '.log').
	command := self gitCommandStringFor: arguments in: aRepository outputFile: outputFile.
	status := self normalizedSystemStatusFrom: (LibC uniqueInstance system: command).
	output := outputFile exists
		          ifTrue: [ outputFile contents ]
		          ifFalse: [ '' ].
	outputFile exists ifTrue: [ outputFile delete ].
	^ {
		  (#status -> status).
		  (#output -> output) } asDictionary
]

{ #category : 'private - git' }
MCPRepositoryCommand >> runGitArguments: arguments in: aRepository ifFailed: failureBlock [

	| result status |
	result := self runGitArguments: arguments in: aRepository.
	status := result at: #status.
	status = 0 ifTrue: [ ^ result ].
	^ failureBlock cull: result
]

{ #category : 'private - git' }
MCPRepositoryCommand >> shellQuote: aString [

	| quote |
	quote := Character value: 39.
	^ String streamContents: [ :stream |
			  stream nextPut: quote.
			  aString do: [ :each |
					  each = quote
						  ifTrue: [
								  stream
									  nextPut: quote;
									  nextPut: $";
									  nextPut: quote;
									  nextPut: $";
									  nextPut: quote ]
						  ifFalse: [ stream nextPut: each ] ].
			  stream nextPut: quote ]
]

{ #category : 'private - git' }
MCPRepositoryCommand >> signalGitCommandFailed: gitResult action: actionName [

	| output status |
	status := gitResult at: #status.
	output := (gitResult at: #output) trimBoth.
	output isEmpty ifTrue: [ output := 'git ' , actionName , ' failed with status ' , status asString ].
	MCPCommandError signalErrorCode: actionName , 'GitCommandFailed' message: output details: {
			(#exitStatus -> status).
			(#output -> output) } asDictionary
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> signalMissingSourceForPackageNames: packageNames in: aRepository writer: aWriterClass [

	MCPCommandError
		signalErrorCode: #RepositorySourceMissing
		message: 'Repository ' , aRepository name , ' has no source on disk for ' , (', ' join: packageNames)
			, '. Reloading would drop what the image holds without restoring anything in its place.'
		details: {
				(#repository -> aRepository name).
				(#packages -> packageNames).
				(#format -> aWriterClass id asString) } asDictionary
]

{ #category : 'private - validation' }
MCPRepositoryCommand >> signalSubdirectoryRequiresHeadFor: aRepository [

	MCPCommandError
		signalErrorCode: #RepositorySubdirectoryRequiresHead
		message:
		'Repository subdirectory is not supported before the repository has an initial commit. Attach without subdirectory, commit or adopt the initial head, then update the repository subdirectory.'
		details: {
				(#name -> aRepository name asString).
				(#subdirectory -> self request subdirectory) } asDictionary
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> signalUnsupportedSourceFormat: formatId for: aRepository [

	MCPCommandError
		signalErrorCode: #RepositorySourceFormatUnsupported
		message:
		'Repository ' , aRepository name , ' keeps its source as ' , formatId asString , ', which this neither reads nor writes.'
		details: {
				(#repository -> aRepository name).
				(#format -> formatId asString).
				(#supportedFormats -> self supportedSourceFormatIds) } asDictionary
]

{ #category : 'private' }
MCPRepositoryCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet asArray sort
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> sourceRepositoryClassForWriter: aWriterClass [
	"Monticello reads each format with its own repository class, and Iceberg has
	no reader that answers Monticello versions, so the pairing is made here. A
	writer nothing here reads back answers nil."

	aWriterClass id = #tonel ifTrue: [ ^ TonelRepository ].
	aWriterClass id = #filetree ifTrue: [ ^ Smalltalk globals at: #MCFileTreeRepository ifAbsent: [ nil ] ].
	^ nil
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> sourceRepositoryFor: aRepository writer: aWriterClass [

	| readerClass |
	readerClass := (self sourceRepositoryClassForWriter: aWriterClass) ifNil: [
		               self signalUnsupportedSourceFormat: aWriterClass id for: aRepository ].
	^ readerClass new
		  directory: (self repositorySourceDirectoryFor: aRepository);
		  yourself
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> sourceWriterClassFor: aRepository [
	"Iceberg names the writer for the format the checkout declares, and picks its
	own default when the checkout declares none. It cannot answer for a format no
	writer implements, and that is the one case reported here by name."

	^ [ aRepository properties writerClass ]
		  on: Error
		  do: [
				  (self declaredSourceFormatFor: aRepository)
					  ifNil: [ IceLibgitTonelWriter ]
					  ifNotNil: [ :formatId | self signalUnsupportedSourceFormat: formatId for: aRepository ] ]
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> supportedSourceFormatIds [
	"Every format Iceberg writes and this reads back, asked of Iceberg rather than
	listed here, so a format it gains is either supported or named in a refusal."

	^ (TIceRepositoryWriter users
		   select: [ :each | (self sourceRepositoryClassForWriter: each) isNotNil ]
		   thenCollect: [ :each | each id asString ]) asArray sort
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> unloadDefinitionsAbsentFromLoadedVersions: versions [

	| loader staleDefinitions |
	staleDefinitions := OrderedCollection new.
	versions do: [ :version | staleDefinitions addAll: (self definitionsAbsentFrom: version snapshot inPackage: version package) ].
	staleDefinitions ifEmpty: [ ^ self ].
	loader := MCPackageLoader new.
	staleDefinitions do: [ :definition | loader removeDefinition: definition ].
	loader load
]

{ #category : 'private - validation' }
MCPRepositoryCommand >> validateSubdirectorySupportedFor: aRepository [

	self request subdirectory ifNil: [ ^ self ].
	aRepository project isUnborn ifTrue: [ self signalSubdirectoryRequiresHeadFor: aRepository ]
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> versionIn: sourceRepository for: anIcePackage writer: aWriterClass [
	"Each format names the package's directory its own way, and every Monticello
	directory repository reads a version from that name. The checkout answers nil
	when it does not hold the package."

	| directoryName |
	directoryName := (aWriterClass directoryNameFor: anIcePackage) asString.
	^ (sourceRepository directory / directoryName) exists
		  ifTrue: [ sourceRepository versionFromFileNamed: directoryName ]
		  ifFalse: [ nil ]
]

{ #category : 'private - source format' }
MCPRepositoryCommand >> withoutLeavingFiletreeMarkerIn: aDirectory do: aBlock [
	"Monticello's filetree reader writes a .filetree configuration file into any
	directory that has none, even when it only reads. Iceberg keeps that file
	inside each package rather than at the root of the checkout, so reading the
	source must not leave one behind."

	| marker existed |
	marker := aDirectory / '.filetree'.
	existed := marker exists.
	^ aBlock ensure: [ existed ifFalse: [ marker ensureDelete ] ]
]
