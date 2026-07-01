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

	| changedPackageNames commit commitArguments modifiedPaths repository result tonelSnapshot |
	^ self
		  executeRepositoryAction: 'commit'
		  work: [
				  repository := self request repository.
				  (self repositoryHasChangesToCommit: repository) ifFalse: [
					  IceNothingToCommit signal ].
				  tonelSnapshot := self snapshotTonelFilesFor: repository.
				  self exportLoadedPackagesFrom: repository.
				  self
					  restoreOrderOnlyTonelChurnFor: repository
					  fromSnapshot: tonelSnapshot.
				  modifiedPaths := self modifiedPathsFromGitStatusIn: repository.
				  modifiedPaths isEmpty ifTrue: [ IceNothingToCommit signal ].
				  changedPackageNames := self
					                         changedPackageNamesForRepository: repository
					                         modifiedPaths: modifiedPaths.
				  self
					  runGitArguments: #( 'add' '--all' )
					  in: repository
					  ifFailed: [ :gitResult |
					  self signalGitCommandFailed: gitResult action: 'add' ].
				  commitArguments := self
					                     gitCommitArgumentsFor: repository
					                     message: self request message.
				  self
					  runGitArguments: commitArguments
					  in: repository
					  ifFailed: [ :gitResult |
					  self signalGitCommandFailed: gitResult action: 'commit' ].
				  commit := repository headCommit.
				  self adoptHeadCommit: commit for: repository.
				  result := MCPRepositoryCommitResult
					            repository: repository
					            changedPackageNames: changedPackageNames
					            commit: commit ]
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
MCPCommitRepositoryCommand >> gitCommitArgumentsFor: aRepository message: aMessage [

	(self repositoryHasDefaultGitSignature: aRepository) ifTrue: [
		^ {
			  'commit'.
			  '-m'.
			  aMessage } ].
	^ {
		  '-c'.
		  'user.name=' , self fallbackGitUserName.
		  '-c'.
		  'user.email=' , self fallbackGitUserEmail.
		  'commit'.
		  '-m'.
		  aMessage }
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

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasChangesToCommit: aRepository [

	(self repositoryHasNoCommit: aRepository) ifTrue: [ ^ true ].
	^ (self repositoryHasModifiedPackages: aRepository) or: [
		  (self modifiedPathsFromGitStatusIn: aRepository) isNotEmpty ]
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
