Class {
	#name : 'MCPToolPullRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolPullRepository >> defaultName [

	^ 'pull-repository'
]

{ #category : 'defaults' }
MCPToolPullRepository >> defaultTitle [

	^ 'Pull Repository'
]

{ #category : 'defaults' }
MCPToolPullRepository >> operationDescription [

	^ 'Pull the current Iceberg repository branch from its upstream.'
]

{ #category : 'defaults' }
MCPToolPullRepository >> repositoryOperation [

	^ 'pull'
]

{ #category : 'defaults' }
MCPToolPullRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
