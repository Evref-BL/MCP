Class {
	#name : 'MCPToolSwitchRepositoryBranch',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolSwitchRepositoryBranch >> defaultName [

	^ 'switch-repository-branch'
]

{ #category : 'defaults' }
MCPToolSwitchRepositoryBranch >> defaultTitle [

	^ 'Switch Repository Branch'
]

{ #category : 'defaults' }
MCPToolSwitchRepositoryBranch >> operationDescription [

	^ 'Switch an Iceberg repository to an existing branch.'
]

{ #category : 'defaults' }
MCPToolSwitchRepositoryBranch >> repositoryOperation [

	^ 'switchBranch'
]

{ #category : 'defaults' }
MCPToolSwitchRepositoryBranch >> requiredInputPropertyNames [

	^ #( 'repositoryName' 'branchName' )
]
