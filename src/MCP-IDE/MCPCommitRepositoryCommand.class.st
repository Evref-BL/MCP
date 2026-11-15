"
Command wrapper for repository_commit. It writes the repository's packages as repository_export does, stages and commits every change git sees in the checkout, and returns an MCPRepositoryCommitResult naming what the commit holds.
"
Class {
	#name : 'MCPCommitRepositoryCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> committedPathsIn: aRepository [
	"The paths the commit at HEAD changed, from the checkout root."

	| output |
	output := (self
		           runGitArguments: #( '-c' 'core.quotePath=false' 'show' '--name-only' '--format=' 'HEAD' )
		           in: aRepository
		           ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'show' ]) at: #output.
	^ self sortedStringsFrom: (output lines reject: [ :each | each isEmpty ] thenCollect: [ :each | self unquotedGitPath: each ])
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> currentBranchNameIn: aRepository [
	"The branch HEAD is on, or an empty string when HEAD is detached."

	| gitResult |
	gitResult := self runGitArguments: #( 'symbolic-ref' '--short' '-q' 'HEAD' ) in: aRepository.
	(gitResult at: #status) = 0 ifFalse: [ ^ '' ].
	^ (gitResult at: #output) trimBoth
]

{ #category : 'executing' }
MCPCommitRepositoryCommand >> execute [

	| commitId commitWarnings committedPaths repository result snapshot summary |
	^ self
		  executeRepositoryAction: 'commit'
		  work: [
				  repository := self request repository.
				  (self repositoryHasChangesToCommit: repository) ifFalse: [ self signalNothingToCommitIn: repository ].
				  snapshot := self snapshotFilesFor: repository.
				  commitWarnings := (self warningsForCommitWithoutPackagesIn: repository) , (self exportLoadedPackagesFrom: repository).
				  self restoreOrderOnlyTonelChurnFor: repository fromSnapshot: snapshot.
				  (self modifiedPathsFromGitStatusIn: repository) ifEmpty: [ self signalNothingToCommitIn: repository ].
				  self
					  runGitArguments: #( 'add' '--all' )
					  in: repository
					  ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'add' ].
				  self
					  runGitArguments: (self gitCommitArgumentsFor: repository message: self request message)
					  in: repository
					  ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'commit' ].
				  commitId := self headCommitIdIn: repository.
				  self adoptHeadCommit: (repository lookupCommit: commitId) for: repository.
				  summary := self summaryForCommit: commitId in: repository.
				  committedPaths := self committedPathsIn: repository.
				  result := MCPRepositoryCommitResult repository: repository.
				  result
					  packageNames: (self packageNamesForPaths: committedPaths in: repository);
					  otherFiles: (self pathsOutsidePackages: committedPaths in: repository) ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText: summary
				  data: (self tool dataForRepositoryResult: result)
				  warnings: warningMessages , commitWarnings ]
		  failureSummary: [ :error | 'Failed to commit repository: ' , (error messageText ifNil: [ error asString ]) ]
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
		  ('user.name=' , self fallbackGitUserName).
		  '-c'.
		  ('user.email=' , self fallbackGitUserEmail).
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
	(gitResult at: #status) = 0 ifTrue: [ ^ (gitResult at: #output) trimBoth ].
	(gitResult at: #status) = 1 ifTrue: [ ^ '' ].
	self signalGitCommandFailed: gitResult action: 'config'
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> headCommitDescriptionIn: aRepository [

	^ self trimmedGitOutputFor: #( 'log' '-1' '--format=%B' ) in: aRepository action: 'log'
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> headCommitIdIn: aRepository [

	^ self trimmedGitOutputFor: #( 'rev-parse' 'HEAD' ) in: aRepository action: 'rev-parse'
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasChangesToCommit: aRepository [

	(self repositoryHasNoCommit: aRepository) ifTrue: [ ^ true ].
	^ (self repositoryHasModifiedPackages: aRepository) or: [ (self modifiedPathsFromGitStatusIn: aRepository) isNotEmpty ]
]

{ #category : 'private - git identity' }
MCPCommitRepositoryCommand >> repositoryHasConfiguredGitIdentity: aRepository [

	^ (self gitConfigValueAt: 'user.name' in: aRepository) isNotEmpty and: [
		  (self gitConfigValueAt: 'user.email' in: aRepository) isNotEmpty ]
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasModifiedPackages: aRepository [

	^ aRepository modifiedPackages isNotEmpty
]

{ #category : 'private - diff' }
MCPCommitRepositoryCommand >> repositoryHasNoCommit: aRepository [

	^ MCPIcebergCommitInfo isNoCommit: aRepository headCommit
]

{ #category : 'private - signaling' }
MCPCommitRepositoryCommand >> signalNothingToCommitIn: aRepository [

	MCPCommandError
		signalErrorCode: #RepositoryNothingToCommit
		message: (String streamContents: [ :stream |
					 stream << 'Repository ' << aRepository name
					 << ' has nothing to commit: the image matches its files and git sees no change in its checkout.' ])
		details: { (#repository -> aRepository name) } asDictionary
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> summaryForCommit: aCommitId in: aRepository [
	"Name the commit as git log --oneline does, on the branch HEAD is on; the subject is the first line of the message as git stored it."

	| branch subject |
	branch := self currentBranchNameIn: aRepository.
	subject := (self headCommitDescriptionIn: aRepository) lines ifEmpty: [ '' ] ifNotEmpty: [ :lines | lines first ].
	^ String streamContents: [ :stream |
			  stream << 'Committed repository ' << aRepository name.
			  branch ifEmpty: [ stream << ' on detached HEAD: ' ] ifNotEmpty: [ stream << ' on branch ' << branch << ': ' ].
			  stream << (self shortCommitId: aCommitId) << ' ' << subject ]
]

{ #category : 'private - git' }
MCPCommitRepositoryCommand >> trimmedGitOutputFor: arguments in: aRepository action: actionName [

	| gitResult |
	gitResult := self
		             runGitArguments: arguments
		             in: aRepository
		             ifFailed: [ :failedResult | self signalGitCommandFailed: failedResult action: actionName ].
	^ (gitResult at: #output) trimBoth
]

{ #category : 'private - warnings' }
MCPCommitRepositoryCommand >> warningsForCommitWithoutPackagesIn: aRepository [

	aRepository workingCopy packages ifNotEmpty: [ ^ #(  ) ].
	^ { (String streamContents: [ :stream |
		   stream << 'Repository ' << aRepository name << ' has no packages, so this commit holds only what git saw in its checkout.' ]) }
]
