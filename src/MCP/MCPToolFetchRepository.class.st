Class {
	#name : 'MCPToolFetchRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFetchRepository class >> toolName [

	^ 'fetch-repository'
]

{ #category : 'private - operations' }
MCPToolFetchRepository >> repositoryOperationSpec [

	^ {
		  (#title -> 'Fetch Repository').
		  (#description
		   -> 'Fetch remote refs for a registered Iceberg repository.').
		  (#operation -> 'fetch').
		  (#requestClass -> MCPRepositoryFetchRequest).
		  (#commandClass -> MCPFetchRepositoryCommand) } asDictionary
]
