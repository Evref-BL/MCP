Class {
	#name : 'MCPToolPullRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolPullRepository class >> toolName [

	^ 'pull-repository'
]

{ #category : 'private - operations' }
MCPToolPullRepository >> repositoryOperationSpec [

	^ {
		  (#title -> 'Pull Repository').
		  (#description
		   -> 'Pull remote changes for a registered Iceberg repository.').
		  (#operation -> 'pull').
		  (#requestClass -> MCPRepositoryPullRequest).
		  (#commandClass -> MCPPullRepositoryCommand) } asDictionary
]
