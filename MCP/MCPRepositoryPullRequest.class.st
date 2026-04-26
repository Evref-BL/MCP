"
Parsed input for edit-repository operation=pull. It resolves the registered Iceberg repository whose current branch should pull from its configured remote.
"
Class {
	#name : 'MCPRepositoryPullRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryPullRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'initialization' }
MCPRepositoryPullRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryPullRequest >> operation [

	^ 'pull'
]

{ #category : 'accessing' }
MCPRepositoryPullRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryPullRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryPullRequest >> requestedContext [

	^ self repositoryReference requestedContext
]
