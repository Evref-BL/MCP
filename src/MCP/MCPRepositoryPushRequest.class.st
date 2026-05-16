"
Parsed input for edit-repository operation=push. It resolves the registered Iceberg repository whose current branch should push to its configured remote.
"
Class {
	#name : 'MCPRepositoryPushRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryPushRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'initialization' }
MCPRepositoryPushRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryPushRequest >> operation [

	^ 'push'
]

{ #category : 'accessing' }
MCPRepositoryPushRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryPushRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryPushRequest >> requestedContext [

	^ self repositoryReference requestedContext
]
