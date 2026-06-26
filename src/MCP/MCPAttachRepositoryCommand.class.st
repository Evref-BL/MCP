"
Command wrapper for repository_attach. It registers an existing Git checkout through IceRepositoryCreator, attaches requested packages to the working copy, and returns an MCPRepositoryCreateResult-shaped payload.
"
Class {
	#name : 'MCPAttachRepositoryCommand',
	#superclass : 'MCPCreateRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private' }
MCPAttachRepositoryCommand >> createRepository [

	| repository |
	self signalDuplicateRepositoryIfNeeded.
	repository := IceLibgitRepository new
		              name: self request name;
		              location: self locationReference;
		              yourself.
	repository pluginManager repositoryWillBeCreated: repository.
	repository workingCopy initializePackagesFromRepository.
	self request subdirectory ifNotNil: [ :value |
		repository subdirectory: value ].
	repository pluginManager repositoryWasCreated: repository.
	repository register.
	^ repository
]

{ #category : 'executing' }
MCPAttachRepositoryCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'attach'
		  work: [
				  repository := self createRepository.
				  self addRequestedPackagesTo: repository.
				  result := MCPRepositoryCreateResult fromRepository: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Attached repository ' , self request name , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to attach repository ' , self request name , ': '
				  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'private' }
MCPAttachRepositoryCommand >> gitDirectoryReferenceFor: gitDirPath relativeTo: aLocation [

	| reference |
	reference := gitDirPath asFileReference.
	^ reference isAbsolute
		  ifTrue: [ reference ]
		  ifFalse: [ aLocation / gitDirPath ]
]

{ #category : 'private' }
MCPAttachRepositoryCommand >> isGitCheckoutRoot: aLocation [

	^ (IceRepositoryCreator isGitRoot: aLocation) or: [
		  self isLinkedGitWorktreeRoot: aLocation ]
]

{ #category : 'private' }
MCPAttachRepositoryCommand >> isLinkedGitWorktreeRoot: aLocation [

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
	^ (self
		   gitDirectoryReferenceFor: gitDirectoryPath
		   relativeTo: aLocation) exists
]

{ #category : 'private' }
MCPAttachRepositoryCommand >> locationReference [

	| location |
	location := self request location asFileReference.
	location exists ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationMissing
				message: 'repository_attach requires location to exist.'
				details: self request requestedContext ].
	(self isGitCheckoutRoot: location) ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationNotGitRoot
				message:
				'repository_attach requires location to be an existing Git repository root.'
				details: self request requestedContext ].
	^ location
]

{ #category : 'private' }
MCPAttachRepositoryCommand >> matchingRegisteredRepositories [

	| locationPath |
	locationPath := self request location asFileReference pathString.
	^ IceRepository repositories select: [ :each |
			  each name asString = self request name or: [
				  (self repositoryLocationPathFor: each) = locationPath ] ]
]

{ #category : 'private' }
MCPAttachRepositoryCommand >> repositoryLocationPathFor: aRepository [

	^ aRepository location
		  ifNil: [ '' ]
		  ifNotNil: [ :repositoryLocation |
			  repositoryLocation mcpRepositoryLocationString ]
]

{ #category : 'private - signaling' }
MCPAttachRepositoryCommand >> signalDuplicateRepositoryIfNeeded [

	| matchingRepositoryNames matches |
	matches := self matchingRegisteredRepositories.
	matches isEmpty ifTrue: [ ^ self ].
	matchingRepositoryNames := (matches
		                            collect: [ :each | each name asString ]
		                            as: Array) sort.
	MCPCommandError
		signalErrorCode: #RepositoryAlreadyRegistered
		message:
		'Repository name or location is already registered in Iceberg.'
		details: (self request requestedContext copy
				 at: #matchingRepositoryNames put: matchingRepositoryNames;
				 yourself)
]
