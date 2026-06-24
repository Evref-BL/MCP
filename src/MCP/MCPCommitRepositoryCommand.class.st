"
Command wrapper for repository_commit. It captures the current IceRepository working-copy diff, commits it, and returns an MCPRepositoryCommitResult.
"
Class {
	#name : 'MCPCommitRepositoryCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPCommitRepositoryCommand >> execute [

	| changedPackageNames diff repository result |
	^ self
		  executeRepositoryAction: 'commit'
		  work: [
				  repository := self request repository.
				  (self repositoryHasChangesToCommit: repository) ifFalse: [
					  IceNothingToCommit signal ].
				  diff := repository workingCopyDiff.
				  changedPackageNames := self changedPackageNamesFromDiff: diff.
				  result := self
					            withNonInteractiveGitIdentityFor: repository
					            during: [
							            | commit |
							            commit := self withNonInteractiveAuthorDuring: [
									                      repository workingCopy
										                      commitChanges: diff
										                      withMessage: self request message ].
							            MCPRepositoryCommitResult
								            repository: repository
								            changedPackageNames: changedPackageNames
								            commit: commit ] ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Committed repository ' , result repositoryInfo name , '.'
					  data: (self tool dataForRepositoryResult: result)
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

	^ config
		  getString: key
		  ifPresent: [ :value | value isEmptyOrNil ]
		  ifAbsent: [ true ]
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

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> removeGitConfigKey: key from: config [

	config
		getString: key
		ifPresent: [ :ignored | config unset: key ]
		ifAbsent: [ ]
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> removeTemporaryGitConfigKey: key from: config [

	"Pharo 13 libgit2 can crash while deleting freshly-created repository config entries."
	PharoCompatibility isPharo13OrLater ifTrue: [ ^ self ].
	self removeGitConfigKey: key from: config
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasChangesToCommit: aRepository [

	(self repositoryHasNoCommit: aRepository) ifTrue: [ ^ true ].
	^ self repositoryHasModifiedPackages: aRepository
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

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasModifiedPackages: aRepository [

	^ aRepository modifiedPackages notEmpty
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasNoCommit: aRepository [

	^ MCPIcebergCommitInfo isNoCommit: aRepository headCommit
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
