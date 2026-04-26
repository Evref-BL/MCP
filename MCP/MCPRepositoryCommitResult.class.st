"
Result DTO returned by edit-repository operation=commit. It reports repository state after the commit, changed packages captured before committing, modified packages still reported by Iceberg afterward, and commit/head metadata when available.
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

	^ {
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#changedPackageNames -> self changedPackageNames).
		  (#modifiedPackageNames -> self modifiedPackageNames).
		  (#commitId -> self commitId).
		  (#commitDescription -> self commitDescription).
		  (#headDescription -> self headDescription).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
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

	aCommit ifNil: [ ^ '' ].
	(aCommit respondsTo: #comment) ifTrue: [
		^ aCommit comment ifNil: [ '' ] ].
	^ ''
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

	aCommit ifNil: [ ^ '' ].
	(aCommit respondsTo: #id) ifTrue: [ ^ aCommit id asString ].
	(aCommit respondsTo: #commitId) ifTrue: [
		^ aCommit commitId asString ].
	^ aCommit asString
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

	| packages |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	packageInfos := packages collect: [ :each |
		                MCPRepositoryPackageInfo fromPackage: each ].
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	modifiedPackageNames := repositoryInfo modifiedPackageNames.
	commitId := self commitIdFrom: aCommit.
	commitDescription := self commitDescriptionFrom: aCommit.
	headDescription := repositoryInfo headDescription.
	^ self
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
