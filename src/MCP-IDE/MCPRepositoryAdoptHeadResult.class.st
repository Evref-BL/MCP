"
Result DTO returned by repository_head_adopt. Its data names the packages Iceberg marked modified before the adoption and no longer marks, since adopting clears every loaded package's mark. It keeps for the summary the commit adopted, the branch it is on or that HEAD is detached, and whether the working copy's reference moved.
"
Class {
	#name : 'MCPRepositoryAdoptHeadResult',
	#superclass : 'MCPRepositoryTransitionResult',
	#instVars : [
		'unmarkedPackageNames',
		'adoptedCommitId',
		'didAdopt',
		'branchName',
		'isDetachedHead'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryAdoptHeadResult class >> repositoryBefore: beforeInfo after: aRepository adoptedCommit: headCommit didAdopt: aBoolean [

	^ self new
		  initializeRepositoryBefore: beforeInfo
		  after: aRepository
		  adoptedCommit: headCommit
		  didAdopt: aBoolean
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> adoptedCommitId [

	^ adoptedCommitId ifNil: [ '' ]
]

{ #category : 'converting' }
MCPRepositoryAdoptHeadResult >> asDictionary [

	| data |
	data := Dictionary new.
	self unmarkedPackageNames ifNotEmpty: [ :names | data at: #unmarkedPackages put: names ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'private' }
MCPRepositoryAdoptHeadResult >> commitIdFrom: aCommit [

	^ MCPIcebergCommitInfo idStringFrom: aCommit
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> didAdopt [

	^ didAdopt ifNil: [ false ]
]

{ #category : 'initialization' }
MCPRepositoryAdoptHeadResult >> initializeRepositoryBefore: beforeInfo after: aRepository adoptedCommit: headCommit didAdopt: aBoolean [

	| stillMarked |
	super initializeRepositoryBefore: beforeInfo after: aRepository.
	stillMarked := repositoryInfoAfter modifiedPackageNames.
	unmarkedPackageNames := (beforeInfo modifiedPackageNames reject: [ :each | stillMarked includes: each ]) asArray.
	adoptedCommitId := self commitIdFrom: headCommit.
	didAdopt := aBoolean.
	branchName := repositoryInfoAfter branchName.
	isDetachedHead := repositoryInfoAfter isDetachedHead
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> isDetachedHead [

	^ isDetachedHead ifNil: [ false ]
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> unmarkedPackageNames [
	"The packages Iceberg marked modified before the adoption and no longer marks."

	^ unmarkedPackageNames ifNil: [ #(  ) ]
]
