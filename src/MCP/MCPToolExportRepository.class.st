Class {
	#name : 'MCPToolExportRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolExportRepository >> defaultName [

	^ 'export-repository'
]

{ #category : 'defaults' }
MCPToolExportRepository >> defaultTitle [

	^ 'Export Repository'
]

{ #category : 'defaults' }
MCPToolExportRepository >> operationDescription [

	^ 'Write image package changes to the repository working tree and update the Iceberg index without committing.'
]

{ #category : 'defaults' }
MCPToolExportRepository >> repositoryOperation [

	^ 'export'
]

{ #category : 'defaults' }
MCPToolExportRepository >> requiredInputPropertyNames [

	^ #( 'repositoryName' )
]
