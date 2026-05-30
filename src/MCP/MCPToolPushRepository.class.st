Class {
	#name : 'MCPToolPushRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolPushRepository class >> toolName [

	^ 'repository_push'
]

{ #category : 'private - operations' }
MCPToolPushRepository >> repositoryOperationSpec [

	^ {
		  (#title -> 'Push Repository').
		  (#description
		   -> 'Push local commits for a registered Iceberg repository.').
		  (#operation -> 'push').
		  (#requestClass -> MCPRepositoryPushRequest).
		  (#commandClass -> MCPPushRepositoryCommand) } asDictionary
]
