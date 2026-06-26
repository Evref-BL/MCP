"
Result DTO returned by repository_create or repository_attach. It reports the registered repository and the packages managed by its working copy after creation or attachment.
"
Class {
	#name : 'MCPRepositoryCreateResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryCreateResult class >> fromRepository: aRepository [

	^ self new initializeFromRepository: aRepository
]

{ #category : 'converting' }
MCPRepositoryCreateResult >> asDictionary [

	^ Dictionary new
]
