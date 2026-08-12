"
Concrete repository_export tool. It materializes image-side repository changes to Tonel files through MCPToolRepositoryOperation without staging or committing Git changes.
"
Class {
	#name : 'MCPToolExportRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolExportRepository class >> toolName [

	^ 'repository_export'
]

{ #category : 'private - specs' }
MCPToolExportRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Export Repository').
		  (#description
		   -> 'Materialize image-side repository changes to Tonel files through Iceberg without staging or committing Git changes.').
		  (#action -> 'export').
		  (#requestClass -> MCPRepositoryExportRequest).
		  (#commandClass -> MCPExportRepositoryCommand) } asDictionary
]
