"
Result DTO returned by edit-repository operation=pull. It reports repository metadata before and after pulling, branch/head state after the pull, and modified packages afterward.
"
Class {
	#name : 'MCPRepositoryPullResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfoBefore',
		'repositoryInfoAfter',
		'packageInfos',
		'branchName',
		'headDescription',
		'modifiedPackageNames'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryPullResult class >> repositoryBefore: beforeInfo after: aRepository [

	^ self new initializeRepositoryBefore: beforeInfo after: aRepository
]

{ #category : 'converting' }
MCPRepositoryPullResult >> asDictionary [

	^ {
		  (#repositoryBefore -> self repositoryInfoBefore asDictionary).
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#modifiedPackageNames -> self modifiedPackageNames).
		  (#branchName -> self branchName).
		  (#headDescription -> self headDescription).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryPullResult >> initializeRepositoryBefore: beforeInfo after: aRepository [

	repositoryInfoBefore := beforeInfo.
	repositoryInfoAfter := MCPRepositoryInfo fromRepository: aRepository.
	packageInfos := self packageInfosFromRepository: aRepository.
	branchName := repositoryInfoAfter branchName.
	headDescription := repositoryInfoAfter headDescription.
	modifiedPackageNames := repositoryInfoAfter modifiedPackageNames.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> modifiedPackageNames [

	^ modifiedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryPullResult >> packageInfosFromRepository: aRepository [

	| packages |
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	^ packages collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> repositoryInfo [

	^ self repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> repositoryInfoAfter [

	^ repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> repositoryInfoBefore [

	^ repositoryInfoBefore
]
