"
Result DTO returned by edit-repository operation=fetch. It reports repository metadata before and after fetching, remote names, and branch/head state after the fetch.
"
Class {
	#name : 'MCPRepositoryFetchResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfoBefore',
		'repositoryInfoAfter',
		'packageInfos',
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

	^ {
		  (#repositoryBefore -> self repositoryInfoBefore asDictionary).
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#remoteNames -> self remoteNames).
		  (#branchName -> self branchName).
		  (#headDescription -> self headDescription).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
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

	repositoryInfoBefore := beforeInfo.
	repositoryInfoAfter := MCPRepositoryInfo fromRepository: aRepository.
	packageInfos := self packageInfosFromRepository: aRepository.
	remoteNames := repositoryInfoAfter remoteNames.
	branchName := repositoryInfoAfter branchName.
	headDescription := repositoryInfoAfter headDescription.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryFetchResult >> packageInfosFromRepository: aRepository [

	| packages |
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	^ packages collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> remoteNames [

	^ remoteNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> repositoryInfo [

	^ self repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> repositoryInfoAfter [

	^ repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryFetchResult >> repositoryInfoBefore [

	^ repositoryInfoBefore
]
