"
Parsed input for repository_push. It resolves the registered Iceberg repository whose current branch should push to its configured remote.
"
Class {
	#name : 'MCPRepositoryPushRequest',
	#superclass : 'MCPRepositoryRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryPushRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryPushRequest >> commandForTool: aTool [

	^ MCPPushRepositoryCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryPushRequest >> operation [

	^ 'push'
]

{ #category : 'accessing' }
MCPRepositoryPushRequest >> repository [

	^ self repositoryReference repository
]
