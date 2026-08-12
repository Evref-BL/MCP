"
Concrete repository_head_adopt tool. It aligns the Iceberg working-copy reference with the repository HEAD commit through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolAdoptRepositoryHead',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolAdoptRepositoryHead class >> toolName [

	^ 'repository_head_adopt'
]

{ #category : 'private - specs' }
MCPToolAdoptRepositoryHead >> repositoryToolSpec [

	^ {
		  (#title -> 'Adopt Repository Head').
		  (#description -> 'Align the image working-copy reference with the repository HEAD commit.').
		  (#action -> 'adoptHead').
		  (#requestClass -> MCPRepositoryAdoptHeadRequest).
		  (#commandClass -> MCPAdoptRepositoryHeadCommand).
		  (#inputProperties -> { self branchNameSchemaProperty }) } asDictionary
]
