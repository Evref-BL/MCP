Class {
	#name : 'MCPToolDiffRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolDiffRepository >> defaultName [

	^ 'diff-repository'
]

{ #category : 'defaults' }
MCPToolDiffRepository >> defaultTitle [

	^ 'Diff Repository'
]

{ #category : 'defaults' }
MCPToolDiffRepository >> operationDescription [

	^ 'Inspect Iceberg working-copy differences without writing package files.'
]

{ #category : 'defaults' }
MCPToolDiffRepository >> repositoryOperation [

	^ 'diff'
]

{ #category : 'defaults' }
MCPToolDiffRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
