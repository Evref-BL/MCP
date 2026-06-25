"
Parsed input for repository_change_list. It resolves the registered Iceberg repository whose image working-copy diff should be reported without writing files or updating the git index.
"
Class {
	#name : 'MCPRepositoryDiffRequest',
	#superclass : 'MCPRepositoryRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryDiffRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryDiffRequest >> commandForTool: aTool [

	^ MCPRepositoryDiffCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryDiffRequest >> operation [

	^ 'diff'
]

{ #category : 'accessing' }
MCPRepositoryDiffRequest >> repository [

	^ self repositoryReference repository
]
