"
Result DTO returned by edit-repository operation=diff. It reports the repository working-copy diff from the image, including changed package names, relative paths when Iceberg exposes them, a change count, and whether the diff is empty.
"
Class {
	#name : 'MCPRepositoryDiffResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
		'changedPackageNames',
		'modifiedPaths',
		'changeCount',
		'isEmpty'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryDiffResult class >> repository: aRepository changedPackageNames: packageNames modifiedPaths: paths isEmpty: aBoolean [

	^ self new
		  initializeRepository: aRepository
		  changedPackageNames: packageNames
		  modifiedPaths: paths
		  isEmpty: aBoolean
]

{ #category : 'converting' }
MCPRepositoryDiffResult >> asDictionary [

	^ {
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#changedPackageNames -> self changedPackageNames).
		  (#modifiedPaths -> self modifiedPaths).
		  (#changeCount -> self changeCount).
		  (#isEmpty -> self isEmpty).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> changeCount [

	^ changeCount ifNil: [ 0 ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> changeCount: anInteger [

	changeCount := anInteger
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> changedPackageNames [

	^ changedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> changedPackageNames: aCollection [

	changedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'private' }
MCPRepositoryDiffResult >> derivedChangeCount [

	self modifiedPaths notEmpty ifTrue: [ ^ self modifiedPaths size ].
	^ self changedPackageNames size
]

{ #category : 'initialization' }
MCPRepositoryDiffResult >> initializeRepository: aRepository changedPackageNames: packageNames modifiedPaths: paths isEmpty: aBoolean [

	| packages |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	packageInfos := packages collect: [ :each |
		                MCPRepositoryPackageInfo fromPackage: each ].
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	modifiedPaths := paths ifNil: [ #(  ) ].
	isEmpty := aBoolean.
	changeCount := self derivedChangeCount.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> isEmpty [

	^ isEmpty ifNil: [ true ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> isEmpty: aBoolean [

	isEmpty := aBoolean
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> modifiedPaths [

	^ modifiedPaths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> modifiedPaths: aCollection [

	modifiedPaths := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> packageInfos: aCollection [

	packageInfos := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> repositoryInfo [

	^ repositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> repositoryInfo: aRepositoryInfo [

	repositoryInfo := aRepositoryInfo
]
