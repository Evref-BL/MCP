"
Request for discarding all current image-side repository changes for one registered Iceberg repository.
"
Class {
	#name : 'MCPRepositoryDiscardRequest',
	#superclass : 'MCPRepositoryRequest',
	#category : 'MCP-IDE-Requests',
	#package : 'MCP-IDE',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryDiscardRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPRepositoryDiscardRequest >> operation [

	^ 'discard'
]

{ #category : 'accessing' }
MCPRepositoryDiscardRequest >> repository [

	^ self repositoryReference repository
]
