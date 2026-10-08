"
Concrete repository_branch_switch tool. It switches a registered Iceberg repository to an existing branch through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolSwitchRepositoryBranch',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolSwitchRepositoryBranch class >> toolName [

	^ 'repository_branch_switch'
]

{ #category : 'private - specs' }
MCPToolSwitchRepositoryBranch >> repositoryToolSpec [

	^ {
		  (#title -> 'Switch Repository Branch').
		  (#description -> 'Switch a registered Iceberg repository to an existing branch.').
		  (#action -> 'switchBranch').
		  (#requestClass -> MCPRepositorySwitchBranchRequest).
		  (#commandClass -> MCPSwitchRepositoryBranchCommand).
		  (#inputProperties -> { self branchNameSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'branchName' )) } asDictionary
]
