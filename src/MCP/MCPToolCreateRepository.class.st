Class {
	#name : 'MCPToolCreateRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCreateRepository >> defaultName [

	^ 'create-repository'
]

{ #category : 'defaults' }
MCPToolCreateRepository >> defaultTitle [

	^ 'Create Repository'
]

{ #category : 'defaults' }
MCPToolCreateRepository >> operationDescription [

	^ 'Create a new Iceberg repository directory and optionally attach initial packages.'
]

{ #category : 'defaults' }
MCPToolCreateRepository >> repositoryOperation [

	^ 'create'
]

{ #category : 'defaults' }
MCPToolCreateRepository >> requiredInputPropertyNames [

	^ #( 'name' 'location' )
]
