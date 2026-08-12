"
Result DTO returned by repository_pull. It reports repository metadata before and after pulling, branch/head state after the pull, and modified packages afterward.
"
Class {
	#name : 'MCPRepositoryPullResult',
	#superclass : 'MCPRepositoryTransitionResult',
	#instVars : [
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
	self headDescription ifNotEmpty: [ :description | data at: #headDescription put: description ].
	self modifiedPackageNames ifNotEmpty: [ :names | data at: #modifiedPackageNames put: names ].
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

	super initializeRepositoryBefore: beforeInfo after: aRepository.
	branchName := repositoryInfoAfter branchName.
	headDescription := repositoryInfoAfter headDescription.
	modifiedPackageNames := repositoryInfoAfter modifiedPackageNames
]

{ #category : 'accessing' }
MCPRepositoryPullResult >> modifiedPackageNames [

	^ modifiedPackageNames ifNil: [ #(  ) ]
]
