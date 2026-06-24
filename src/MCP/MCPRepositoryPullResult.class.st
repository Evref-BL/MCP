"
Result DTO returned by repository_pull. It reports repository metadata before and after pulling, branch/head state after the pull, and modified packages afterward.
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

	| data |
	data := Dictionary new.
	self branchName ifNotEmpty: [ :name | data at: #branchName put: name ].
	self headDescription ifNotEmpty: [ :description |
		data at: #headDescription put: description ].
	self modifiedPackageNames ifNotEmpty: [ :names |
		data at: #modifiedPackageNames put: names ].
	^ data
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
	modifiedPackageNames := repositoryInfoAfter modifiedPackageNames
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
		            sort: [ :left :right |
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
