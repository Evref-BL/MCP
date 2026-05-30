Class {
	#name : 'MCPToolAdoptRepositoryHead',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolAdoptRepositoryHead class >> toolName [

	^ 'repository_head_adopt'
]

{ #category : 'private - operations' }
MCPToolAdoptRepositoryHead >> repositoryOperationSpec [

	^ {
		  (#title -> 'Adopt Repository Head').
		  (#description
		   ->
		   'Align the image working-copy reference with the repository HEAD commit.').
		  (#operation -> 'adoptHead').
		  (#requestClass -> MCPRepositoryAdoptHeadRequest).
		  (#commandClass -> MCPAdoptRepositoryHeadCommand).
		  (#inputProperties -> { self branchNameSchemaProperty }) }
		  asDictionary
]
