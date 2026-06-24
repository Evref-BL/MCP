"
Command wrapper for repository_branch_create. It calls IceRepository>>createBranch: and returns an MCPRepositoryBranchResult.
"
Class {
	#name : 'MCPCreateRepositoryBranchCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPCreateRepositoryBranchCommand >> execute [

	| beforeInfo repository result |
	^ self
		  executeRepositoryAction: 'createBranch'
		  work: [
				  repository := self request repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  repository createBranch: self request branchName.
				  result := MCPRepositoryBranchResult
					            repositoryBefore: beforeInfo
					            after: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
						  'Created branch ' , self request branchName
						  , ' in repository ' , result repositoryInfo name , '.'
					  data: (self tool dataForRepositoryCreateBranchResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to create repository branch: '
				  , (error messageText ifNil: [ error asString ]) ]
]
