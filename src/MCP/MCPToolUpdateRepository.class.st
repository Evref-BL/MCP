Class {
	#name : 'MCPToolUpdateRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolUpdateRepository >> defaultName [

	^ 'update-repository'
]

{ #category : 'defaults' }
MCPToolUpdateRepository >> defaultTitle [

	^ 'Update Repository'
]

{ #category : 'defaults' }
MCPToolUpdateRepository >> operationDescription [

	^ 'Change image-side Iceberg repository metadata or package membership without writing packages to disk.'
]

{ #category : 'defaults' }
MCPToolUpdateRepository >> repositoryOperation [

	^ 'update'
]

{ #category : 'defaults' }
MCPToolUpdateRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
