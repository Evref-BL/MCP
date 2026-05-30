Class {
	#name : 'MCPToolFindRepositoryChanges',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolFindRepositoryChanges class >> toolName [

	^ 'repository_change_list'
]

{ #category : 'private - operations' }
MCPToolFindRepositoryChanges >> repositoryOperationSpec [

	^ {
		  (#title -> 'List Repository Changes').
		  (#description
		   ->
		   'Inspect the image-side Iceberg working-copy diff for a registered repository without writing files.').
		  (#operation -> 'diff').
		  (#requestClass -> MCPRepositoryDiffRequest).
		  (#commandClass -> MCPRepositoryDiffCommand) } asDictionary
]
