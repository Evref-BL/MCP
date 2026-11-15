"
Concrete repository_commit tool. It creates an Iceberg commit for a registered repository through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolCommitRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCommitRepository class >> toolName [

	^ 'repository_commit'
]

{ #category : 'private - results' }
MCPToolCommitRepository >> keyOrder [

	^ #( packages otherFiles )
]

{ #category : 'private - specs' }
MCPToolCommitRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Commit Repository').
		  (#description
		   ->
		   'Write the packages of a registered repository to its checkout as repository_export does, then stage and commit every change git sees there with the given message.').
		  (#action -> 'commit').
		  (#requestClass -> MCPRepositoryCommitRequest).
		  (#commandClass -> MCPCommitRepositoryCommand).
		  (#inputProperties -> { self messageSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'message' )) } asDictionary
]
