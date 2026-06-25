"
Parsed input for repository_branch_create. It resolves the registered Iceberg repository and carries the required branch name to create.
"
Class {
	#name : 'MCPRepositoryCreateBranchRequest',
	#superclass : 'MCPRepositoryBranchRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryCreateBranchRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryCreateBranchRequest >> commandForTool: aTool [

	^ MCPCreateRepositoryBranchCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryCreateBranchRequest >> operation [

	^ 'createBranch'
]

{ #category : 'accessing' }
MCPRepositoryCreateBranchRequest >> repository [

	^ self repositoryReference repository
]
