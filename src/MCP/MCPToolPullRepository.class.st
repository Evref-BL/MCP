"
Concrete repository_pull tool. It pulls remote changes for a registered Iceberg repository through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolPullRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolPullRepository class >> toolName [

	^ 'repository_pull'
]

{ #category : 'private - specs' }
MCPToolPullRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Pull Repository').
		  (#description
		   -> 'Pull remote changes for a registered Iceberg repository.').
		  (#action -> 'pull').
		  (#requestClass -> MCPRepositoryPullRequest).
		  (#commandClass -> MCPPullRepositoryCommand) } asDictionary
]
