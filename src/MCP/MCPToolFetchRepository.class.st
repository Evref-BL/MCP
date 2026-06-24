"
Concrete repository_fetch tool. It fetches remote refs for a registered Iceberg repository through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolFetchRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolFetchRepository class >> toolName [

	^ 'repository_fetch'
]

{ #category : 'private - specs' }
MCPToolFetchRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Fetch Repository').
		  (#description
		   -> 'Fetch remote refs for a registered Iceberg repository.').
		  (#action -> 'fetch').
		  (#requestClass -> MCPRepositoryFetchRequest).
		  (#commandClass -> MCPFetchRepositoryCommand) } asDictionary
]
