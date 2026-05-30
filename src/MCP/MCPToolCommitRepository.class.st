Class {
	#name : 'MCPToolCommitRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCommitRepository class >> toolName [

	^ 'repository_commit'
]

{ #category : 'private - operations' }
MCPToolCommitRepository >> repositoryOperationSpec [

	^ {
		  (#title -> 'Commit Repository').
		  (#description
		   ->
		   'Create an Iceberg commit for a registered repository using the provided commit message.').
		  (#operation -> 'commit').
		  (#requestClass -> MCPRepositoryCommitRequest).
		  (#commandClass -> MCPCommitRepositoryCommand).
		  (#inputProperties -> { self messageSchemaProperty }).
		  (#requiredProperties -> #( 'repositoryName' 'message' )) }
		  asDictionary
]
