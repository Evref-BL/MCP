"
Abstract base for repository command objects. It owns the shared tool/request state and construction protocol used by repository tools; subclasses implement the repository operation itself.
"
Class {
	#name : 'MCPRepositoryCommand',
	#superclass : 'MCPToolRequestCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
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
	(self commit: workingCopy referenceCommit equals: headCommit) ifFalse: [
		workingCopy referenceCommit: headCommit ].
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
	projectFile binaryWriteStreamDo: [ :stream |
		stream nextPutAll: project contentsString ]
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
	loadedPackageNames := workingCopy loadedPackages collect: [ :package |
		package name ].
	workingCopy loadPackagesNamed: loadedPackageNames fromCommit: headCommit.
	self adoptHeadCommit: headCommit for: aRepository
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> loadLoadedPackagesFromDiskIn: aRepository [

	| sourceRepository versions workingCopy |
	workingCopy := aRepository workingCopy.
	sourceRepository := TonelRepository new
		                    directory: (self repositorySourceDirectoryFor: aRepository);
		                    yourself.
	versions := workingCopy loadedPackages
		            collect: [ :package | sourceRepository versionFrom: package name ]
		            thenSelect: [ :version | version notNil ].
	self loadVersionsReplacingImageChanges: versions.
	self adoptHeadCommit: aRepository headCommit for: aRepository
]

{ #category : 'private - loading' }
MCPRepositoryCommand >> loadVersionsReplacingImageChanges: versions [

	| loader |
	versions ifEmpty: [ ^ self ].
	loader := versions size > 1
		          ifTrue: [ MCMultiPackageLoader new ]
		          ifFalse: [ MCPackageLoader new ].
	versions do: [ :version |
		loader updatePackage: version package withSnapshot: version snapshot ].
	loader load.
	versions do: [ :version | version workingCopy loaded: version ]
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> markLoadedPackagesCleanIn: aWorkingCopy [

	aWorkingCopy loadedPackages do: [ :package |
		package beDirty: false ]
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> markLoadedPackagesDirtyIn: aWorkingCopy [

	aWorkingCopy loadedPackages do: [ :package |
		package beDirty: true ]
]

{ #category : 'private - iceberg state' }
MCPRepositoryCommand >> referenceCommitFor: aRepository [

	^ aRepository workingCopy referenceCommit
]

{ #category : 'private - git' }
MCPRepositoryCommand >> repositoryHasGitWorkTree: aRepository [

	| result |
	result := self
		          runGitArguments: #( 'rev-parse' '--is-inside-work-tree' )
		          in: aRepository.
	^ (result at: #status) = 0 and: [
		  (result at: #output) trimBoth = 'true' ]
]

{ #category : 'private - git' }
MCPRepositoryCommand >> repositoryLocationStringFor: aRepository [

	^ aRepository location
		  ifNil: [ '' ]
		  ifNotNil: [ :repositoryLocation |
		  repositoryLocation mcpRepositoryLocationString ]
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
MCPRepositoryCommand >> repositorySupportsExternalGitOperations: aRepository [

	| result |
	(self repositoryHasGitWorkTree: aRepository) ifFalse: [ ^ false ].
	result := self
		          runGitArguments: #( 'rev-parse' '--verify' 'HEAD' )
		          in: aRepository.
	^ (result at: #status) = 0
]

{ #category : 'private - git' }
MCPRepositoryCommand >> runGitArguments: arguments in: aRepository [

	| command output outputFile status |
	outputFile := FileLocator temp asFileReference
	              / ('mcp-git-command-' , UUID new asString , '.log').
	command := self
		           gitCommandStringFor: arguments
		           in: aRepository
		           outputFile: outputFile.
	status := LibC uniqueInstance system: command.
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
	output isEmpty ifTrue: [
		output := 'git ' , actionName , ' failed with status '
		          , status asString ].
	MCPCommandError
		signalErrorCode: actionName , 'GitCommandFailed'
		message: output
		details: {
				(#exitStatus -> status).
				(#output -> output) } asDictionary
]

{ #category : 'private' }
MCPRepositoryCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet asArray sort
]
