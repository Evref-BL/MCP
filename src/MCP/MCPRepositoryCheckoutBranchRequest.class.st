"
Parsed input for repository_branch_checkout. It resolves the registered Iceberg repository and carries the required branch name to check out.
"
Class {
	#name : 'MCPRepositoryCheckoutBranchRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference',
		'branchName'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryCheckoutBranchRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPRepositoryCheckoutBranchRequest >> branchName [

	^ branchName
]

{ #category : 'converting' }
MCPRepositoryCheckoutBranchRequest >> commandForTool: aTool [

	^ MCPCheckoutRepositoryBranchCommand tool: aTool request: self
]

{ #category : 'initialization' }
MCPRepositoryCheckoutBranchRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	branchName := request stringArgumentNamed: 'branchName'
]

{ #category : 'accessing' }
MCPRepositoryCheckoutBranchRequest >> operation [

	^ 'checkoutBranch'
]

{ #category : 'accessing' }
MCPRepositoryCheckoutBranchRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryCheckoutBranchRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryCheckoutBranchRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	context at: #branchName put: self branchName.
	^ context
]
