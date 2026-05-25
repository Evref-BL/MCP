Class {
	#name : 'MCPToolAttachRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolAttachRepository >> defaultName [

	^ 'attach-repository'
]

{ #category : 'defaults' }
MCPToolAttachRepository >> defaultTitle [

	^ 'Attach Repository'
]

{ #category : 'defaults' }
MCPToolAttachRepository >> operationDescription [

	^ 'Register an existing Git checkout as an Iceberg repository and optionally attach packages.'
]

{ #category : 'defaults' }
MCPToolAttachRepository >> repositoryOperation [

	^ 'attach'
]

{ #category : 'defaults' }
MCPToolAttachRepository >> requiredInputPropertyNames [

	^ #( 'name' 'location' )
]
