"
Result DTO returned by edit-repository branch operations. It reports repository metadata before and after the operation plus previous and current branch/head descriptions.
"
Class {
	#name : 'MCPRepositoryBranchResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfoBefore',
		'repositoryInfoAfter',
		'packageInfos',
		'previousBranchName',
		'branchName',
		'previousHeadDescription',
		'headDescription'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryBranchResult class >> repositoryBefore: beforeInfo after: aRepository [

	^ self new initializeRepositoryBefore: beforeInfo after: aRepository
]

{ #category : 'converting' }
MCPRepositoryBranchResult >> asDictionary [

	^ {
		  (#repositoryBefore -> self repositoryInfoBefore asDictionary).
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#previousBranchName -> self previousBranchName).
		  (#branchName -> self branchName).
		  (#previousHeadDescription -> self previousHeadDescription).
		  (#headDescription -> self headDescription).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryBranchResult >> initializeRepositoryBefore: beforeInfo after: aRepository [

	| afterInfo |
	repositoryInfoBefore := beforeInfo.
	afterInfo := MCPRepositoryInfo fromRepository: aRepository.
	repositoryInfoAfter := afterInfo.
	packageInfos := self packageInfosFromRepository: aRepository.
	previousBranchName := beforeInfo branchName.
	branchName := afterInfo branchName.
	previousHeadDescription := beforeInfo headDescription.
	headDescription := afterInfo headDescription.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryBranchResult >> packageInfosFromRepository: aRepository [

	| packages |
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	^ packages collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> previousBranchName [

	^ previousBranchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> previousHeadDescription [

	^ previousHeadDescription ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> repositoryInfo [

	^ self repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> repositoryInfoAfter [

	^ repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> repositoryInfoBefore [

	^ repositoryInfoBefore
]
