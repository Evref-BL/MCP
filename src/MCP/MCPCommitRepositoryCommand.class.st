"
Command wrapper for edit-repository operation=commit. It captures the current IceRepository working-copy diff, commits it with IceRepository>>commitWithMessage:, and returns an MCPRepositoryCommitResult.
"
Class {
	#name : 'MCPCommitRepositoryCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPCommitRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> changedPackageNamesFromDiff: aDiff [

	| names |
	names := [
	         aDiff packages collect: [ :each |
		         self packageNameFromDiffPackageNode: each ] ]
		         on: Error
		         do: [ :ignored | #(  ) ].
	^ self sortedStringsFrom:
		  (names select: [ :each | each notNil and: [ each isEmpty not ] ])
]

{ #category : 'executing' }
MCPCommitRepositoryCommand >> execute [

	| changedPackageNames diff repository result |
	^ self tool
		  executeEditOperation: 'commit'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self request repository.
			  diff := repository workingCopyDiff.
			  changedPackageNames := self changedPackageNamesFromDiff: diff.
			  result := self
				            withNonInteractiveGitIdentityFor: repository
				            during: [
					            | commit |
					            commit := self withNonInteractiveAuthorDuring: [
						                      repository commitWithMessage:
							                      self request message ].
					            MCPRepositoryCommitResult
						            repository: repository
						            changedPackageNames: changedPackageNames
						            commit: commit ] ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Committed repository ' , result repositoryInfo name , '.'
				  data: (self tool dataForRepositoryCommitResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to commit repository: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> fallbackGitUserEmail [

	^ 'mcp@example.invalid'
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> fallbackGitUserName [

	^ 'MCP'
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> gitConfigValueMissingOrEmpty: key in: config [

	^ [
	  config
		  getString: key
		  ifPresent: [ :value | value isEmptyOrNil ]
		  ifAbsent: [ true ] ]
		  on: Error
		  do: [ :ignored | true ]
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> gitSignatureMissingFor: anError [

	| message |
	message := anError messageText ifNil: [ '' ].
	message := message asLowercase.
	^ message = 'config value ''user.name'' was not found' or: [
		  message = 'config value ''user.email'' was not found' or: [
			  message
			  =
			  'failed to parse signature - signature cannot have an empty name or email' ] ]
]

{ #category : 'initialization' }
MCPCommitRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> packageNameFromDiffPackageNode: aNode [

	| definition |
	definition := aNode definition.
	(definition respondsTo: #packageName) ifFalse: [ ^ nil ].
	^ definition packageName asString
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> removeGitConfigKey: key from: config [

	[ config unset: key ]
		on: Error
		do: [ :ignored | nil ]
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> removeTemporaryGitConfigKey: key from: config [

	"Pharo 13 libgit2 can crash while deleting freshly-created repository config entries."
	PharoCompatibility isPharo13OrLater ifTrue: [ ^ self ].
	self removeGitConfigKey: key from: config
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> repositoryHasDefaultGitSignature: aRepository [

	^ [
	  aRepository repositoryHandle defaultSignature.
	  true ]
		  on: LGit_GIT_ENOTFOUND , LGit_GIT_ERROR
		  do: [ :error |
			  (self gitSignatureMissingFor: error)
				  ifTrue: [ false ]
				  ifFalse: [ error pass ] ]
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> request [

	^ request
]

{ #category : 'private' }
MCPCommitRepositoryCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet
		  asSortedCollection asArray
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> tool [

	^ tool
]

{ #category : 'private - execution' }
MCPCommitRepositoryCommand >> withNonInteractiveAuthorDuring: aBlock [

	^ PharoCompatibility
		  withNonInteractiveAuthorNamed: 'MCP'
		  during: aBlock
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> withNonInteractiveGitIdentityFor: aRepository during: aBlock [

	| config shouldSetEmail shouldSetName |
	config := aRepository repositoryHandle config.
	shouldSetName := self
		                 gitConfigValueMissingOrEmpty: 'user.name'
		                 in: config.
	shouldSetEmail := self
		                  gitConfigValueMissingOrEmpty: 'user.email'
		                  in: config.
	(shouldSetName or: [ shouldSetEmail ]) ifFalse: [ ^ aBlock value ].
	shouldSetName ifTrue: [ config username: self fallbackGitUserName ].
	shouldSetEmail ifTrue: [ config email: self fallbackGitUserEmail ].
	^ [ aBlock value ] ensure: [
		  shouldSetName ifTrue: [
			  self removeTemporaryGitConfigKey: 'user.name' from: config ].
		  shouldSetEmail ifTrue: [
			  self removeTemporaryGitConfigKey: 'user.email' from: config ] ]
]
