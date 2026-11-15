"
Command wrapper for repository_commit. It writes the repository's packages as repository_export does, stages and commits every change git sees in the checkout, and returns an MCPRepositoryCommitResult naming what the commit holds.
"
Class {
	#name : 'MCPCommitRepositoryCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#instVars : [
		'repository',
		'message',
		'commitId',
		'branchName',
		'subject',
		'packageNames',
		'otherFiles',
		'registersNoPackage',
		'unloadedPackageNames'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPCommitRepositoryCommand class >> repository: aRepository message: aString [

	^ self new initializeRepository: aRepository message: aString
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> branchName [

	^ branchName
]

{ #category : 'private - committing' }
MCPCommitRepositoryCommand >> commitChanges [
	"Stage every change git sees in the checkout and commit it with the message."

	(self modifiedPathsFromGitStatusIn: repository) ifEmpty: [ self signalNothingToCommitIn: repository ].
	self
		runGitArguments: #( 'add' '--all' )
		in: repository
		ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'add' ].
	self
		runGitArguments: (self gitCommitArgumentsFor: repository message: message)
		in: repository
		ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'commit' ]
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> commitId [

	^ commitId
]

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

	(self repositoryHasChangesToCommit: repository) ifFalse: [ self signalNothingToCommitIn: repository ].
	self writePackages.
	self commitChanges.
	self readCommit
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

{ #category : 'initialization' }
MCPCommitRepositoryCommand >> initializeRepository: aRepository message: aString [

	repository := aRepository.
	message := aString
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> otherFiles [

	^ otherFiles
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> packageNames [

	^ packageNames
]

{ #category : 'private - committing' }
MCPCommitRepositoryCommand >> readCommit [
	"Adopt the commit as the working copy's reference, then read where it is and what it holds: the branch HEAD is on, the first line of its message as git stored it, and the registered packages and other files it changed."

	| committedPaths |
	commitId := self headCommitIdIn: repository.
	self adoptHeadCommit: (repository lookupCommit: commitId) for: repository.
	branchName := self currentBranchNameIn: repository.
	subject := (self headCommitDescriptionIn: repository) lines ifEmpty: [ '' ] ifNotEmpty: [ :lines | lines first ].
	committedPaths := self committedPathsIn: repository.
	packageNames := self packageNamesForPaths: committedPaths in: repository.
	otherFiles := self pathsOutsidePackages: committedPaths in: repository
]

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> registersNoPackage [

	^ registersNoPackage
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

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> subject [

	^ subject
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

{ #category : 'accessing' }
MCPCommitRepositoryCommand >> unloadedPackageNames [

	^ unloadedPackageNames
]

{ #category : 'private - warnings' }
MCPCommitRepositoryCommand >> warningsForCommitWithoutPackagesIn: aRepository [

	aRepository workingCopy packages ifNotEmpty: [ ^ #(  ) ].
	^ { (String streamContents: [ :stream |
		   stream << 'Repository ' << aRepository name << ' has no packages, so this commit holds only what git saw in its checkout.' ]) }
]

{ #category : 'private - committing' }
MCPCommitRepositoryCommand >> writePackages [
	"Write the packages the image holds as an export does, keeping the files the writer only reordered as they were."

	| snapshot |
	snapshot := self snapshotFilesFor: repository.
	registersNoPackage := repository workingCopy packages isEmpty.
	self exportLoadedPackagesFrom: repository.
	unloadedPackageNames := self unloadedPackageNamesOf: repository.
	self restoreOrderOnlyTonelChurnFor: repository fromSnapshot: snapshot
]
