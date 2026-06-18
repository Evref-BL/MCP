"
Result DTO returned by repository_head_adopt. It reports repository metadata before and after adopting the head commit, before/after modified package names, the previous and adopted working-copy reference commit ids, and whether the working copy reference changed.
"
Class {
	#name : 'MCPRepositoryAdoptHeadResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfoBefore',
		'repositoryInfoAfter',
		'packageInfos',
		'modifiedPackageNamesBefore',
		'modifiedPackageNamesAfter',
		'previousReferenceCommitId',
		'referenceCommitId',
		'adoptedCommitId',
		'didAdopt',
		'branchName',
		'headDescription'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryAdoptHeadResult class >> repositoryBefore: beforeInfo after: aRepository previousReferenceCommit: previousCommit adoptedCommit: headCommit didAdopt: aBoolean [

	^ self new
		  initializeRepositoryBefore: beforeInfo
		  after: aRepository
		  previousReferenceCommit: previousCommit
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
	data at: #didAdopt put: self didAdopt.
	self previousReferenceCommitId ifNotEmpty: [ :id |
		data at: #previousReferenceCommitId put: id ].
	self referenceCommitId ifNotEmpty: [ :id |
		data at: #referenceCommitId put: id ].
	self adoptedCommitId ifNotEmpty: [ :id |
		data at: #adoptedCommitId put: id ].
	self modifiedPackageNamesBefore ifNotEmpty: [ :names |
		data at: #modifiedPackageNamesBefore put: names ].
	self modifiedPackageNamesAfter ifNotEmpty: [ :names |
		data at: #modifiedPackageNamesAfter put: names ].
	self branchName ifNotEmpty: [ :name | data at: #branchName put: name ].
	self headDescription ifNotEmpty: [ :description |
		data at: #headDescription put: description ].
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

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryAdoptHeadResult >> initializeRepositoryBefore: beforeInfo after: aRepository previousReferenceCommit: previousCommit adoptedCommit: headCommit didAdopt: aBoolean [

	repositoryInfoBefore := beforeInfo.
	repositoryInfoAfter := MCPRepositoryInfo fromRepository: aRepository.
	packageInfos := self packageInfosFromRepository: aRepository.
	modifiedPackageNamesBefore := beforeInfo modifiedPackageNames.
	modifiedPackageNamesAfter := repositoryInfoAfter modifiedPackageNames.
	previousReferenceCommitId := self commitIdFrom: previousCommit.
	referenceCommitId := self referenceCommitIdForRepository: aRepository.
	adoptedCommitId := self commitIdFrom: headCommit.
	didAdopt := aBoolean.
	branchName := repositoryInfoAfter branchName.
	headDescription := repositoryInfoAfter headDescription.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> modifiedPackageNamesAfter [

	^ modifiedPackageNamesAfter ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> modifiedPackageNamesBefore [

	^ modifiedPackageNamesBefore ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryAdoptHeadResult >> packageInfosFromRepository: aRepository [

	| packages |
	packages := aRepository workingCopy packages asArray
		            sort: [ :left :right |
		            left name asString <= right name asString ].
	^ packages collect: [ :each |
		  MCPRepositoryPackageInfo fromPackage: each ]
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> previousReferenceCommitId [

	^ previousReferenceCommitId ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> referenceCommitId [

	^ referenceCommitId ifNil: [ '' ]
]

{ #category : 'private' }
MCPRepositoryAdoptHeadResult >> referenceCommitIdForRepository: aRepository [

	^ self commitIdFrom: aRepository workingCopy referenceCommit
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> repositoryInfo [

	^ self repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> repositoryInfoAfter [

	^ repositoryInfoAfter
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadResult >> repositoryInfoBefore [

	^ repositoryInfoBefore
]
