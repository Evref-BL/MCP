Class {
	#name : 'MCPToolCommitRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCommitRepository >> defaultName [

	^ 'commit-repository'
]

{ #category : 'defaults' }
MCPToolCommitRepository >> defaultTitle [

	^ 'Commit Repository'
]

{ #category : 'defaults' }
MCPToolCommitRepository >> operationDescription [

	^ 'Create an Iceberg commit from current repository changes.'
]

{ #category : 'defaults' }
MCPToolCommitRepository >> repositoryOperation [

	^ 'commit'
]

{ #category : 'defaults' }
MCPToolCommitRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' 'message' )
]
