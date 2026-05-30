Class {
	#name : 'MCPToolSwitchRepositoryBranch',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolSwitchRepositoryBranch class >> toolName [

	^ 'repository_branch_switch'
]

{ #category : 'private - operations' }
MCPToolSwitchRepositoryBranch >> repositoryOperationSpec [

	^ {
		  (#title -> 'Switch Repository Branch').
		  (#description
		   ->
		   'Switch a registered Iceberg repository to an existing branch.').
		  (#operation -> 'switchBranch').
		  (#requestClass -> MCPRepositorySwitchBranchRequest).
		  (#commandClass -> MCPSwitchRepositoryBranchCommand).
		  (#inputProperties -> { self branchNameSchemaProperty }).
		  (#requiredProperties -> #( 'repositoryName' 'branchName' )) }
		  asDictionary
]
