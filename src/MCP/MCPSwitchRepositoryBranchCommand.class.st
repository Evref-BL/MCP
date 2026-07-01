"
Command wrapper for repository_branch_switch. It calls IceRepository>>switchToBranchNamed: and returns an MCPRepositoryBranchResult.
"
Class {
	#name : 'MCPSwitchRepositoryBranchCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPSwitchRepositoryBranchCommand >> execute [

	| beforeInfo headCommit repository result |
	^ self
		 executeRepositoryAction: 'switchBranch'
		 work: [
				 repository := self request repository.
				 beforeInfo := MCPRepositoryInfo fromRepository: repository.
				 (self repositorySupportsExternalGitOperations: repository)
					 ifTrue: [
						 self
							 runGitArguments: { 'switch'. self request branchName }
							 in: repository
							 ifFailed: [ :gitResult |
							 self signalGitCommandFailed: gitResult action: 'switch' ].
						 headCommit := repository headCommit.
						 self
							 adoptHeadCommit: headCommit
							 for: repository
							 markLoadedPackagesClean: false ]
					 ifFalse: [ repository switchToBranchNamed: self request branchName ].
				 result := MCPRepositoryBranchResult
					 repositoryBefore: beforeInfo
					 after: repository ]
		 successResult: [ :warningMessages |
				 self tool
					 successResultText:
						 'Switched repository ' , result repositoryInfo name
						 , ' branch ' , self request branchName , '.'
					 data: (self tool dataForRepositoryResult: result)
					 warnings: warningMessages ]
		 failureSummary: [ :error |
				 'Failed to switch repository branch: '
				 , (error messageText ifNil: [ error asString ]) ]
]
