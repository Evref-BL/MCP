"
Parsed input for repository_reload. It resolves the registered Iceberg repository whose files should be loaded back into the image.
"
Class {
	#name : 'MCPRepositoryReloadRequest',
	#superclass : 'MCPRepositoryRequest',
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryReloadRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryReloadRequest >> commandForTool: aTool [

	^ MCPReloadRepositoryCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryReloadRequest >> operation [

	^ 'reload'
]

{ #category : 'accessing' }
MCPRepositoryReloadRequest >> repository [

	^ self repositoryReference repository
]
