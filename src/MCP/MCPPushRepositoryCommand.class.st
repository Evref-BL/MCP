"
Command wrapper for repository_push. It calls IceRepository>>push and returns an MCPRepositoryPushResult.
"
Class {
	#name : 'MCPPushRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - git' }
MCPPushRepositoryCommand >> currentBranchNameFor: aRepository [

	^ self gitOutputFrom:
		  (self
			   runGitArguments: #( 'branch' '--show-current' )
			   in: aRepository)
]

{ #category : 'executing' }
MCPPushRepositoryCommand >> execute [

	| repository result |
	^ self
		executeRepositoryAction: 'push'
		work: [
			repository := self request repository.
			(self repositorySupportsExternalGitOperations: repository)
				ifTrue: [
					self
						runGitArguments: (self pushArgumentsFor: repository)
						in: repository
						ifFailed: [ :gitResult |
							self signalGitCommandFailed: gitResult action: 'push' ] ]
				ifFalse: [ repository branch push ].
			result := MCPRepositoryPushResult repository: repository ]
		successResult: [ :warningMessages |
			self tool
				successResultText:
				'Pushed repository ' , result repositoryInfo name , '.'
				data: (self tool dataForRepositoryResult: result)
				warnings: warningMessages ]
		failureSummary: [ :error |
			'Failed to push repository: '
			, (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'private - git' }
MCPPushRepositoryCommand >> gitOutputFrom: gitResult [

	^ (gitResult at: #output ifAbsent: [ '' ]) trimBoth
]

{ #category : 'private - git' }
MCPPushRepositoryCommand >> pushArgumentsFor: aRepository [

	| branchName remoteName |
	(self repositoryHasUpstream: aRepository) ifTrue: [ ^ #( 'push' ) ].
	branchName := self currentBranchNameFor: aRepository.
	branchName isEmpty ifTrue: [ ^ #( 'push' ) ].
	remoteName := self pushRemoteNameFor: aRepository.
	remoteName ifNil: [ ^ #( 'push' ) ].
	^ {
		'push'.
		'--set-upstream'.
		remoteName.
		branchName }
]

{ #category : 'private - git' }
MCPPushRepositoryCommand >> pushRemoteNameFor: aRepository [

	| remoteNames requestedRemoteName |
	remoteNames := self remoteNamesFor: aRepository.
	requestedRemoteName := self request remoteName.
	requestedRemoteName isEmpty ifFalse: [
		(remoteNames includes: requestedRemoteName) ifFalse: [
			self signalRemoteName: requestedRemoteName missingFrom: remoteNames ].
		^ requestedRemoteName ].
	(remoteNames includes: 'origin') ifTrue: [ ^ 'origin' ].
	remoteNames size = 1 ifTrue: [ ^ remoteNames first ].
	self signalRemoteSelectionRequiredFor: remoteNames
]

{ #category : 'private - git' }
MCPPushRepositoryCommand >> remoteNamesFor: aRepository [

	| output |
	output := self gitOutputFrom:
		          (self runGitArguments: #( 'remote' ) in: aRepository).
	^ Array streamContents: [ :stream |
		  output linesDo: [ :line |
			  | remoteName |
			  remoteName := line trimBoth.
			  remoteName isEmpty ifFalse: [ stream nextPut: remoteName ] ] ]
]

{ #category : 'private - git' }
MCPPushRepositoryCommand >> repositoryHasUpstream: aRepository [

	| result |
	result := self
		runGitArguments: #( 'rev-parse' '--abbrev-ref' '--symbolic-full-name' '@{u}' )
		in: aRepository.
	^ (result at: #status) = 0
]

{ #category : 'private - errors' }
MCPPushRepositoryCommand >> signalRemoteName: remoteName missingFrom: remoteNames [

	MCPCommandError
		signalErrorCode: #RepositoryRemoteNotFound
		message: 'Repository remote ' , remoteName , ' does not exist.'
		details: {
			(#remoteName -> remoteName).
			(#remoteNames -> remoteNames) } asDictionary
]

{ #category : 'private - errors' }
MCPPushRepositoryCommand >> signalRemoteSelectionRequiredFor: remoteNames [

	| message |
	message := remoteNames isEmpty
		ifTrue: [ 'Repository has no configured remote.' ]
		ifFalse: [ 'Repository has multiple remotes and no origin; provide remoteName.' ].
	MCPCommandError
		signalErrorCode: #RepositoryRemoteRequired
		message: message
		details: { (#remoteNames -> remoteNames) } asDictionary
]
