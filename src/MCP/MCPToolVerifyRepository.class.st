Class {
	#name : 'MCPToolVerifyRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolVerifyRepository >> defaultName [

	^ 'verify-repository'
]

{ #category : 'defaults' }
MCPToolVerifyRepository >> defaultTitle [

	^ 'Verify Repository'
]

{ #category : 'defaults' }
MCPToolVerifyRepository >> operationDescription [

	^ 'Assert read-only repository identity fields before a later repository edit or export.'
]

{ #category : 'defaults' }
MCPToolVerifyRepository >> repositoryOperation [

	^ 'verifyIdentity'
]

{ #category : 'defaults' }
MCPToolVerifyRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
