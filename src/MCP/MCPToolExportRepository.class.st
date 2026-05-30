Class {
	#name : 'MCPToolExportRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolExportRepository class >> toolName [

	^ 'repository_export'
]

{ #category : 'private - operations' }
MCPToolExportRepository >> repositoryOperationSpec [

	^ {
		  (#title -> 'Export Repository').
		  (#description
		   ->
		   'Materialize image-side repository changes to Tonel files through Iceberg without staging or committing Git changes.').
		  (#operation -> 'export').
		  (#requestClass -> MCPRepositoryExportRequest).
		  (#commandClass -> MCPExportRepositoryCommand) } asDictionary
]
