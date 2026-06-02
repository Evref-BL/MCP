"
Concrete repository_change_list tool. It inspects the image-side Iceberg working-copy diff through MCPToolRepositoryOperation without writing files.
"
Class {
	#name : 'MCPToolListRepositoryChanges',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolListRepositoryChanges class >> toolName [

	^ 'repository_change_list'
]

{ #category : 'private - specs' }
MCPToolListRepositoryChanges >> repositoryToolSpec [

	^ {
		  (#title -> 'List Repository Changes').
		  (#description
		   ->
		   'Inspect the image-side Iceberg working-copy diff for a registered repository without writing files.').
		  (#action -> 'diff').
		  (#requestClass -> MCPRepositoryDiffRequest).
		  (#commandClass -> MCPRepositoryDiffCommand) } asDictionary
]
