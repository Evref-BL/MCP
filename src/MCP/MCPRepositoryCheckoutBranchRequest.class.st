"
Parsed input for repository_branch_checkout. It resolves the registered Iceberg repository and carries the required branch name to check out.
"
Class {
	#name : 'MCPRepositoryCheckoutBranchRequest',
	#superclass : 'MCPRepositoryBranchRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryCheckoutBranchRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryCheckoutBranchRequest >> commandForTool: aTool [

	^ MCPCheckoutRepositoryBranchCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryCheckoutBranchRequest >> operation [

	^ 'checkoutBranch'
]

{ #category : 'accessing' }
MCPRepositoryCheckoutBranchRequest >> repository [

	^ self repositoryReference repository
]
