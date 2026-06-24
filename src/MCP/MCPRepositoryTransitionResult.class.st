"
Abstract base for repository result DTOs that report a repository transition. It owns the before snapshot, after snapshot, and package summary shared by branch, fetch, pull, and adopt-head operations.
"
Class {
	#name : 'MCPRepositoryTransitionResult',
	#superclass : 'MCPRepositoryResult',
	#instVars : [
		'repositoryInfoBefore',
		'repositoryInfoAfter',
		'packageInfos'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
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

{ #category : 'accessing' }
MCPRepositoryTransitionResult >> repositoryInfoBefore [

	^ repositoryInfoBefore
]
