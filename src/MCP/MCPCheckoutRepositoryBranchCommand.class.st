"
Command wrapper for repository_branch_checkout. It asks Iceberg to check out the target branch so the repository head and loaded package snapshot move together.
"
Class {
	#name : 'MCPCheckoutRepositoryBranchCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPCheckoutRepositoryBranchCommand >> execute [

	| beforeInfo repository result |
	^ self
		  executeRepositoryAction: 'checkoutBranch'
		  work: [
				  repository := self request repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  (self repositorySupportsExternalGitOperations: repository)
					  ifTrue: [
							  self
								  runGitArguments: {
										  'switch'.
										  self request branchName }
								  in: repository
								  ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'checkoutBranch' ].
							  self loadLoadedPackagesFromDiskIn: repository ]
					  ifFalse: [ (repository branchNamed: self request branchName) checkout ].
				  result := MCPRepositoryBranchResult repositoryBefore: beforeInfo after: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: 'Checked out repository ' , result repositoryInfo name , ' branch ' , self request branchName , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed check out repository branch: ' , (error messageText ifNil: [ error asString ]) ]
]
