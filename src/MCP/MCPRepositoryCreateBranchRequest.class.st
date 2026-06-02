"
Parsed input for repository_branch_create. It resolves the registered Iceberg repository and carries the required branch name to create.
"
Class {
	#name : 'MCPRepositoryCreateBranchRequest',
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
MCPRepositoryCreateBranchRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPRepositoryCreateBranchRequest >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'converting' }
MCPRepositoryCreateBranchRequest >> commandForTool: aTool [

	^ MCPCreateRepositoryBranchCommand tool: aTool request: self
]

{ #category : 'initialization' }
MCPRepositoryCreateBranchRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	branchName := request stringArgumentNamed: 'branchName'.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryCreateBranchRequest >> operation [

	^ 'createBranch'
]

{ #category : 'accessing' }
MCPRepositoryCreateBranchRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryCreateBranchRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryCreateBranchRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	context at: #branchName put: self branchName.
	^ context
]
