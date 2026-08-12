"
Concrete repository_commit tool. It creates an Iceberg commit for a registered repository through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolCommitRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCommitRepository class >> toolName [

	^ 'repository_commit'
]

{ #category : 'private - specs' }
MCPToolCommitRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Commit Repository').
		  (#description -> 'Create an Iceberg commit for a registered repository using the provided commit message.').
		  (#action -> 'commit').
		  (#requestClass -> MCPRepositoryCommitRequest).
		  (#commandClass -> MCPCommitRepositoryCommand).
		  (#inputProperties -> { self messageSchemaProperty }).
		  (#requiredProperties -> #( 'repositoryName' 'message' )) } asDictionary
]
