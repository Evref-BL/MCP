Class {
	#name : 'MCPToolFetchRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFetchRepository >> defaultName [

	^ 'fetch-repository'
]

{ #category : 'defaults' }
MCPToolFetchRepository >> defaultTitle [

	^ 'Fetch Repository'
]

{ #category : 'defaults' }
MCPToolFetchRepository >> operationDescription [

	^ 'Fetch configured remotes for an Iceberg repository.'
]

{ #category : 'defaults' }
MCPToolFetchRepository >> repositoryOperation [

	^ 'fetch'
]

{ #category : 'defaults' }
MCPToolFetchRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
