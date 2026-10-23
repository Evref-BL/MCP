"
Result DTO returned by repository_reload. It reports the branch and head the image was on before the reload and the ones it holds after.
"
Class {
	#name : 'MCPRepositoryReloadResult',
	#superclass : 'MCPRepositoryTransitionResult',
	#instVars : [
		'previousHeadDescription',
		'headDescription'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryReloadResult class >> repositoryBefore: beforeInfo after: aRepository [

	^ self new initializeRepositoryBefore: beforeInfo after: aRepository
]

{ #category : 'converting' }
MCPRepositoryReloadResult >> asDictionary [

	| data |
	data := Dictionary new.
	data at: #branch put: self repositoryInfoAfter branchName.
	self previousHeadDescription ifNotEmpty: [ :description | data at: #previousHeadDescription put: description ].
	self headDescription ifNotEmpty: [ :description | data at: #headDescription put: description ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryReloadResult >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryReloadResult >> initializeRepositoryBefore: beforeInfo after: aRepository [

	super initializeRepositoryBefore: beforeInfo after: aRepository.
	previousHeadDescription := beforeInfo headDescription.
	headDescription := repositoryInfoAfter headDescription
]

{ #category : 'accessing' }
MCPRepositoryReloadResult >> previousHeadDescription [

	^ previousHeadDescription ifNil: [ '' ]
]
