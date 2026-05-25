Class {
	#name : 'MCPToolAdoptRepositoryHead',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolAdoptRepositoryHead >> defaultName [

	^ 'adopt-repository-head'
]

{ #category : 'defaults' }
MCPToolAdoptRepositoryHead >> defaultTitle [

	^ 'Adopt Repository HEAD'
]

{ #category : 'defaults' }
MCPToolAdoptRepositoryHead >> operationDescription [

	^ 'Refresh the image working-copy reference to the repository HEAD for same-image continuation after commits or fast-forwards.'
]

{ #category : 'defaults' }
MCPToolAdoptRepositoryHead >> repositoryOperation [

	^ 'adoptHead'
]

{ #category : 'defaults' }
MCPToolAdoptRepositoryHead >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
