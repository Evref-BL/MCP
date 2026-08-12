"
Result DTO returned by repository branch tools. It reports repository metadata before and after the operation plus previous and current branch/head descriptions.
"
Class {
	#name : 'MCPRepositoryBranchResult',
	#superclass : 'MCPRepositoryTransitionResult',
	#instVars : [
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
	self previousBranchName ifNotEmpty: [ :name | data at: #previousBranchName put: name ].
	self branchName ifNotEmpty: [ :name | data at: #branchName put: name ].
	self previousHeadDescription ifNotEmpty: [ :description | data at: #previousHeadDescription put: description ].
	self headDescription ifNotEmpty: [ :description | data at: #headDescription put: description ].
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

	super initializeRepositoryBefore: beforeInfo after: aRepository.
	previousBranchName := beforeInfo branchName.
	branchName := repositoryInfoAfter branchName.
	previousHeadDescription := beforeInfo headDescription.
	headDescription := repositoryInfoAfter headDescription
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> previousBranchName [

	^ previousBranchName ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryBranchResult >> previousHeadDescription [

	^ previousHeadDescription ifNil: [ '' ]
]
