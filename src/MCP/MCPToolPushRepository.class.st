Class {
	#name : 'MCPToolPushRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolPushRepository >> defaultName [

	^ 'push-repository'
]

{ #category : 'defaults' }
MCPToolPushRepository >> defaultTitle [

	^ 'Push Repository'
]

{ #category : 'defaults' }
MCPToolPushRepository >> operationDescription [

	^ 'Push the current Iceberg repository branch to its upstream.'
]

{ #category : 'defaults' }
MCPToolPushRepository >> repositoryOperation [

	^ 'push'
]

{ #category : 'defaults' }
MCPToolPushRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
