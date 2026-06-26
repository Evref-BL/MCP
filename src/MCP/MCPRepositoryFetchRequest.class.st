"
Parsed input for repository_fetch. It resolves the registered Iceberg repository whose remotes should be fetched.
"
Class {
	#name : 'MCPRepositoryFetchRequest',
	#superclass : 'MCPRepositoryRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryFetchRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryFetchRequest >> commandForTool: aTool [

	^ MCPFetchRepositoryCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryFetchRequest >> operation [

	^ 'fetch'
]

{ #category : 'accessing' }
MCPRepositoryFetchRequest >> repository [

	^ self repositoryReference repository
]
