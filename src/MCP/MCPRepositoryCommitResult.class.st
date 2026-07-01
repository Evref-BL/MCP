"
Result DTO returned by repository_commit. It reports repository state after the commit, changed packages captured before committing, modified packages still reported by Iceberg afterward, and commit/head metadata when available.
"
Class {
	#name : 'MCPRepositoryCommitResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'changedPackageNames',
		'modifiedPackageNames',
		'commitId',
		'headDescription',
		'commitDescription'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryCommitResult class >> repository: aRepository changedPackageNames: packageNames commit: aCommit [

	^ self new
		  initializeRepository: aRepository
		  changedPackageNames: packageNames
		  commit: aCommit
]

{ #category : 'instance creation' }
MCPRepositoryCommitResult class >> repository: aRepository changedPackageNames: packageNames commitId: commitId commitDescription: commitDescription [

	^ self new
		  initializeRepository: aRepository
		  changedPackageNames: packageNames
		  commitId: commitId
		  commitDescription: commitDescription
]

{ #category : 'converting' }
MCPRepositoryCommitResult >> asDictionary [

	| data |
	data := Dictionary new.
	self commitId ifNotEmpty: [ :id | data at: #commitId put: id ].
	self commitDescription ifNotEmpty: [ :description |
		data at: #commitDescription put: description ].
	self headDescription ifNotEmpty: [ :description |
		data at: #headDescription put: description ].
	self changedPackageNames ifNotEmpty: [ :names |
		data at: #changedPackageNames put: names ].
	self modifiedPackageNames ifNotEmpty: [ :names |
		data at: #modifiedPackageNames put: names ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> changedPackageNames [

	^ changedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> changedPackageNames: aCollection [

	changedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> commitDescription [

	^ commitDescription ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> commitDescription: aString [

	commitDescription := aString ifNil: [ '' ]
]

{ #category : 'private' }
MCPRepositoryCommitResult >> commitDescriptionFrom: aCommit [

	^ (MCPIcebergCommitInfo commentStringFrom: aCommit) trimBoth
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> commitId [

	^ commitId ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> commitId: aString [

	commitId := aString ifNil: [ '' ]
]

{ #category : 'private' }
MCPRepositoryCommitResult >> commitIdFrom: aCommit [

	^ MCPIcebergCommitInfo idStringFrom: aCommit
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> headDescription [

	^ headDescription ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> headDescription: aString [

	headDescription := aString ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryCommitResult >> initializeRepository: aRepository changedPackageNames: packageNames commit: aCommit [

	| repositoryPackageNames |
	packageInfos := self packageInfosFromRepository: aRepository.
	repositoryPackageNames := packageInfos collect: [ :each | each name ].
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	modifiedPackageNames := #(  ).
	commitId := self commitIdFrom: aCommit.
	commitDescription := self commitDescriptionFrom: aCommit.
	headDescription := commitId.
	repositoryInfo := MCPRepositoryInfo
		                  commitResultRepository: aRepository
		                  packageNames: repositoryPackageNames
		                  modifiedPackageNames: modifiedPackageNames
		                  headCommitId: commitId
		                  headDescription: headDescription
]

{ #category : 'initialization' }
MCPRepositoryCommitResult >> initializeRepository: aRepository changedPackageNames: packageNames commitId: aCommitId commitDescription: aCommitDescription [

	| repositoryPackageNames |
	packageInfos := self packageInfosFromRepository: aRepository.
	repositoryPackageNames := packageInfos collect: [ :each | each name ].
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	modifiedPackageNames := #(  ).
	commitId := aCommitId ifNil: [ '' ].
	commitDescription := aCommitDescription ifNil: [ '' ].
	headDescription := commitId.
	repositoryInfo := MCPRepositoryInfo
		                  commitResultRepository: aRepository
		                  packageNames: repositoryPackageNames
		                  modifiedPackageNames: modifiedPackageNames
		                  headCommitId: commitId
		                  headDescription: headDescription
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> modifiedPackageNames [

	^ modifiedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> modifiedPackageNames: aCollection [

	modifiedPackageNames := aCollection ifNil: [ #(  ) ]
]
