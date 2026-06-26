"
Parsed input for repository_branch_switch. It resolves the registered Iceberg repository and carries the required branch name to switch to.
"
Class {
	#name : 'MCPRepositorySwitchBranchRequest',
	#superclass : 'MCPRepositoryBranchRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositorySwitchBranchRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositorySwitchBranchRequest >> commandForTool: aTool [

	^ MCPSwitchRepositoryBranchCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositorySwitchBranchRequest >> operation [

	^ 'switchBranch'
]

{ #category : 'accessing' }
MCPRepositorySwitchBranchRequest >> repository [

	^ self repositoryReference repository
]
