Class {
	#name : 'MCPToolCreateRepositoryBranch',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCreateRepositoryBranch >> defaultName [

	^ 'create-repository-branch'
]

{ #category : 'defaults' }
MCPToolCreateRepositoryBranch >> defaultTitle [

	^ 'Create Repository Branch'
]

{ #category : 'defaults' }
MCPToolCreateRepositoryBranch >> operationDescription [

	^ 'Create and switch to a new branch in an Iceberg repository.'
]

{ #category : 'defaults' }
MCPToolCreateRepositoryBranch >> repositoryOperation [

	^ 'createBranch'
]

{ #category : 'defaults' }
MCPToolCreateRepositoryBranch >> requiredInputPropertyNames [

	^ #( 'repositoryName' 'branchName' )
]
