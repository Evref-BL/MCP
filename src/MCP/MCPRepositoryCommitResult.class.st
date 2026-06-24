"
Result DTO returned by repository_commit. It reports repository state after the commit, changed packages captured before committing, modified packages still reported by Iceberg afterward, and commit/head metadata when available.
"
Class {
	#name : 'MCPRepositoryCommitResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
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

	^ MCPIcebergCommitInfo commentStringFrom: aCommit
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

	| packages repositoryPackageNames |
	packages := aRepository workingCopy packages asArray sort: [
		            :left
		            :right | left name asString <= right name asString ].
	packageInfos := packages collect: [ :each |
		                MCPRepositoryPackageInfo fromPackage: each ].
	repositoryPackageNames := (packages collect: [ :each |
		                           each name asString ]) asArray.
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

{ #category : 'accessing' }
MCPRepositoryCommitResult >> modifiedPackageNames [

	^ modifiedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> modifiedPackageNames: aCollection [

	modifiedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> packageInfos: aCollection [

	packageInfos := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> repositoryInfo [

	^ repositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryCommitResult >> repositoryInfo: aRepositoryInfo [

	repositoryInfo := aRepositoryInfo
]
