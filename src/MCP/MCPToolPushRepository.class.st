"
Concrete repository_push tool. It pushes local commits for a registered Iceberg repository through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolPushRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolPushRepository class >> toolName [

	^ 'repository_push'
]

{ #category : 'private - specs' }
MCPToolPushRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Push Repository').
		  (#description
		   -> 'Push local commits for a registered Iceberg repository.').
		  (#action -> 'push').
		  (#requestClass -> MCPRepositoryPushRequest).
		  (#commandClass -> MCPPushRepositoryCommand) } asDictionary
]
