"
Abstract base for repository result DTOs that report a change of a repository's state. It keeps the repository as it was before the change and as it is after, and the packages of its working copy after.
"
Class {
	#name : 'MCPRepositoryTransitionResult',
	#superclass : 'MCPRepositoryResult',
	#instVars : [
		'repositoryInfoBefore',
		'repositoryInfoAfter',
		'packageInfos'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'testing' }
MCPRepositoryTransitionResult class >> isAbstract [

	^ self = MCPRepositoryTransitionResult
]

{ #category : 'initialization' }
MCPRepositoryTransitionResult >> initializeRepositoryBefore: beforeInfo after: aRepository [

	repositoryInfoBefore := beforeInfo.
	repositoryInfoAfter := self repositoryInfoFromRepository: aRepository.
	packageInfos := self packageInfosFromRepository: aRepository
]

{ #category : 'accessing' }
MCPRepositoryTransitionResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryTransitionResult >> repositoryInfo [

	^ self repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryTransitionResult >> repositoryInfoAfter [

	^ repositoryInfoAfter
]
