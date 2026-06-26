"
Abstract base for repository result DTOs that represent one repository snapshot. Subclasses add operation-specific fields while this class owns the common repository and package summary state.
"
Class {
	#name : 'MCPRepositorySnapshotResult',
	#superclass : 'MCPRepositoryResult',
	#instVars : [
		'repositoryInfo',
		'packageInfos'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'testing' }
MCPRepositorySnapshotResult class >> isAbstract [

	^ self = MCPRepositorySnapshotResult
]

{ #category : 'initialization' }
MCPRepositorySnapshotResult >> initializeFromRepository: aRepository [

	self initializeSnapshotFromRepository: aRepository
]

{ #category : 'initialization' }
MCPRepositorySnapshotResult >> initializeSnapshotFromRepository: aRepository [

	repositoryInfo := self repositoryInfoFromRepository: aRepository.
	packageInfos := self packageInfosFromRepository: aRepository
]

{ #category : 'accessing' }
MCPRepositorySnapshotResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositorySnapshotResult >> packageInfos: aCollection [

	packageInfos := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositorySnapshotResult >> repositoryInfo [

	^ repositoryInfo
]

{ #category : 'accessing' }
MCPRepositorySnapshotResult >> repositoryInfo: aRepositoryInfo [

	repositoryInfo := aRepositoryInfo
]
