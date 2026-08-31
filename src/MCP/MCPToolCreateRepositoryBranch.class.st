"
Concrete repository_branch_create tool. It creates a branch from the current Iceberg head and switches to it through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolCreateRepositoryBranch',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCreateRepositoryBranch class >> toolName [

	^ 'repository_branch_create'
]

{ #category : 'private - specs' }
MCPToolCreateRepositoryBranch >> repositoryToolSpec [

	^ {
		  (#title -> 'Create Repository Branch').
		  (#description -> 'Create a branch from the current Iceberg repository head and switch to it.').
		  (#action -> 'createBranch').
		  (#requestClass -> MCPRepositoryCreateBranchRequest).
		  (#commandClass -> MCPCreateRepositoryBranchCommand).
		  (#inputProperties -> { self branchNameSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'branchName' )) } asDictionary
]
