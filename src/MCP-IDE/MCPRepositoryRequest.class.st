"
Abstract request DTO for repository operations that target an existing repository reference.
"
Class {
	#name : 'MCPRepositoryRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference'
	],
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'testing' }
MCPRepositoryRequest class >> isAbstract [

	^ self == MCPRepositoryRequest
]

{ #category : 'initialization' }
MCPRepositoryRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest: request
]

{ #category : 'accessing' }
MCPRepositoryRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryRequest >> requestedContext [

	^ self repositoryReference requestedContext
]
