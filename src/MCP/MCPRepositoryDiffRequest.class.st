"
Parsed input for edit-repository operation=diff. It resolves the registered Iceberg repository whose image working-copy diff should be reported without writing files or updating the git index.
"
Class {
	#name : 'MCPRepositoryDiffRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryDiffRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'initialization' }
MCPRepositoryDiffRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryDiffRequest >> operation [

	^ 'diff'
]

{ #category : 'accessing' }
MCPRepositoryDiffRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryDiffRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryDiffRequest >> requestedContext [

	^ self repositoryReference requestedContext
]
