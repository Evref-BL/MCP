"
Result DTO returned by repository branch tools. It reports repository metadata before and after the operation plus previous and current branch/head descriptions.
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

	| data |
	data := Dictionary new.
	self previousBranchName ifNotEmpty: [ :name |
		data at: #previousBranchName put: name ].
	self branchName ifNotEmpty: [ :name | data at: #branchName put: name ].
	self previousHeadDescription ifNotEmpty: [ :description |
		data at: #previousHeadDescription put: description ].
	self headDescription ifNotEmpty: [ :description |
		data at: #headDescription put: description ].
	^ data
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
	headDescription := afterInfo headDescription
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryBranchResult >> packageInfosFromRepository: aRepository [

	| packages |
	packages := aRepository workingCopy packages asArray
		            sort: [ :left :right |
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
