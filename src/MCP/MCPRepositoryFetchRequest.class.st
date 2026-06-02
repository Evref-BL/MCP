"
Parsed input for repository_fetch. It resolves the registered Iceberg repository whose remotes should be fetched.
"
Class {
	#name : 'MCPRepositoryFetchRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference'
	],
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

{ #category : 'initialization' }
MCPRepositoryFetchRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryFetchRequest >> operation [

	^ 'fetch'
]

{ #category : 'accessing' }
MCPRepositoryFetchRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryFetchRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryFetchRequest >> requestedContext [

	^ self repositoryReference requestedContext
]
