Class {
	#name : 'MCPToolCreateRepositoryBranch',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCreateRepositoryBranch class >> toolName [

	^ 'repository_branch_create'
]

{ #category : 'private - operations' }
MCPToolCreateRepositoryBranch >> repositoryOperationSpec [

	^ {
		  (#title -> 'Create Repository Branch').
		  (#description
		   ->
		   'Create a branch from the current Iceberg repository head and switch to it.').
		  (#operation -> 'createBranch').
		  (#requestClass -> MCPRepositoryCreateBranchRequest).
		  (#commandClass -> MCPCreateRepositoryBranchCommand).
		  (#inputProperties -> { self branchNameSchemaProperty }).
		  (#requiredProperties -> #( 'repositoryName' 'branchName' )) }
		  asDictionary
]
