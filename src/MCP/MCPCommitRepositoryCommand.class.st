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

	| changedPackageNames commit commitArguments commitDescription commitId modifiedPaths repository result tonelSnapshot |
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
				  commitId := self headCommitIdIn: repository.
				  commitDescription := self headCommitDescriptionIn: repository.
				  commit := repository lookupCommit: commitId.
				  self adoptHeadCommit: commit for: repository.
				  result := MCPRepositoryCommitResult
					            repository: repository
					            changedPackageNames: changedPackageNames
					            commitId: commitId
					            commitDescription: commitDescription ]
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

	(self repositoryHasConfiguredGitIdentity: aRepository) ifTrue: [
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
MCPCommitRepositoryCommand >> gitConfigValueAt: key in: aRepository [

	| gitResult |
	gitResult := self
		             runGitArguments: {
			             'config'.
			             '--get'.
			             key }
		             in: aRepository.
	(gitResult at: #status) = 0 ifTrue: [
		^ (gitResult at: #output) trimBoth ].
	(gitResult at: #status) = 1 ifTrue: [ ^ '' ].
	self signalGitCommandFailed: gitResult action: 'config'
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> headCommitDescriptionIn: aRepository [

	^ self
		  trimmedGitOutputFor: #( 'log' '-1' '--format=%B' )
		  in: aRepository
		  action: 'log'
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> headCommitIdIn: aRepository [

	^ self
		  trimmedGitOutputFor: #( 'rev-parse' 'HEAD' )
		  in: aRepository
		  action: 'rev-parse'
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasChangesToCommit: aRepository [

	(self repositoryHasNoCommit: aRepository) ifTrue: [ ^ true ].
	^ (self repositoryHasModifiedPackages: aRepository) or: [
		  (self modifiedPathsFromGitStatusIn: aRepository) isNotEmpty ]
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> repositoryHasConfiguredGitIdentity: aRepository [

	^ ((self gitConfigValueAt: 'user.name' in: aRepository) isNotEmpty and: [
		   (self gitConfigValueAt: 'user.email' in: aRepository) isNotEmpty ])
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasModifiedPackages: aRepository [

	^ aRepository modifiedPackages notEmpty
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasNoCommit: aRepository [

	^ MCPIcebergCommitInfo isNoCommit: aRepository headCommit
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> trimmedGitOutputFor: arguments in: aRepository action: actionName [

	| gitResult |
	gitResult := self
		             runGitArguments: arguments
		             in: aRepository
		             ifFailed: [ :failedResult |
		             self signalGitCommandFailed: failedResult action: actionName ].
	^ (gitResult at: #output) trimBoth
]
