"
Result DTO returned by repository_fetch. It reports repository metadata before and after fetching, remote names, and branch/head state after the fetch.
"
Class {
	#name : 'MCPRepositoryFetchResult',
	#superclass : 'MCPRepositoryTransitionResult',
	#instVars : [
		'remoteNames',
		'branchName',
		'headDescription'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryFetchResult class >> repositoryBefore: beforeInfo after: aRepository [

	^ self new initializeRepositoryBefore: beforeInfo after: aRepository
]

{ #category : 'converting' }
MCPRepositoryFetchResult >> asDictionary [

	^ self branchHeadDictionary
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryFetchResult >> initializeRepositoryBefore: beforeInfo after: aRepository [

	super initializeRepositoryBefore: beforeInfo after: aRepository.
	remoteNames := repositoryInfoAfter remoteNames.
	branchName := repositoryInfoAfter branchName.
	headDescription := repositoryInfoAfter headDescription
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> remoteNames [

	^ remoteNames ifNil: [ #(  ) ]
]
