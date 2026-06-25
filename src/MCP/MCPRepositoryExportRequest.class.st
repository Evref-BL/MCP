"
Parsed input for repository_export. It resolves the registered Iceberg repository that should be synchronized from the image working copy to files.
"
Class {
	#name : 'MCPRepositoryExportRequest',
	#superclass : 'MCPRepositoryRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryExportRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryExportRequest >> commandForTool: aTool [

	^ MCPExportRepositoryCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryExportRequest >> operation [

	^ 'export'
]

{ #category : 'accessing' }
MCPRepositoryExportRequest >> repository [

	^ self repositoryReference repository
]
