Class {
	#name : 'MCPToolFindRepositoryChanges',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindRepositoryChanges class >> toolName [

	^ 'find-repository-changes'
]

{ #category : 'private - operations' }
MCPToolFindRepositoryChanges >> repositoryOperationSpec [

	^ {
		  (#title -> 'Find Repository Changes').
		  (#description
		   ->
		   'Inspect the image-side Iceberg working-copy diff for a registered repository without writing files.').
		  (#operation -> 'diff').
		  (#requestClass -> MCPRepositoryDiffRequest).
		  (#commandClass -> MCPRepositoryDiffCommand) } asDictionary
]
