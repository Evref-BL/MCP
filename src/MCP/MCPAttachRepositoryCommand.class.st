"
Command wrapper for edit-repository operation=attach. It registers an existing Git checkout through IceRepositoryCreator, attaches requested packages to the working copy, and returns an MCPRepositoryCreateResult-shaped payload.
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

	| creator repository |
	self signalDuplicateRepositoryIfNeeded.
	creator := IceRepositoryCreator new.
	creator
		repository: (IceLibgitRepository new
				 name: self request name;
				 yourself);
		location: self locationReference.
	repository := creator createRepository.
	self request subdirectory ifNotNil: [ :value |
		repository subdirectory: value ].
	repository register.
	^ repository
]

{ #category : 'executing' }
MCPAttachRepositoryCommand >> execute [

	| repository result |
	^ self tool
		  executeEditOperation: 'attach'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
				  repository := self createRepository.
				  self addRequestedPackagesTo: repository.
				  result := MCPRepositoryCreateResult fromRepository: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Attached repository ' , self request name , '.'
					  data: (self tool dataForRepositoryAttachResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to attach repository ' , self request name , ': '
				  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'private' }
MCPAttachRepositoryCommand >> locationReference [

	| location |
	location := self request location asFileReference.
	location exists ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationMissing
				message: 'operation=attach requires location to exist.'
				details: self request requestedContext ].
	(IceRepositoryCreator isGitRoot: location) ifFalse: [
			MCPCommandError
				signalErrorCode: #RepositoryLocationNotGitRoot
				message:
				'operation=attach requires location to be an existing Git repository root.'
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

	^ [
		  (aRepository respondsTo: #location)
			  ifTrue: [ aRepository location pathString ]
			  ifFalse: [ '' ] ]
		  on: Error
		  do: [ :ignored | '' ]
]

{ #category : 'private - signaling' }
MCPAttachRepositoryCommand >> signalDuplicateRepositoryIfNeeded [

	| matches |
	matches := self matchingRegisteredRepositories.
	matches isEmpty ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #RepositoryAlreadyRegistered
		message:
		'Repository name or location is already registered in Iceberg.'
		details: (self request requestedContext copy
				 at: #matchingRepositoryNames
				 put: (matches collect: [ :each | each name asString ]) asArray
						 asSortedCollection asArray;
				 yourself)
]
