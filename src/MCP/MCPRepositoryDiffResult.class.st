"
Result DTO returned by repository_change_list. It reports the repository working-copy diff from the image, including changed package names, relative paths when Iceberg exposes them, a change count, and whether the diff is empty.
"
Class {
	#name : 'MCPRepositoryDiffResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
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

	| data |
	data := Dictionary new.
	data
		at: #changeCount put: self changeCount;
		at: #isEmpty put: self isEmpty.
	self changedPackageNames ifNotEmpty: [ :names |
		data at: #changedPackageNames put: names ].
	self modifiedPaths ifNotEmpty: [ :paths |
		data at: #modifiedPaths put: paths ].
	^ data
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

	self initializeSnapshotFromRepository: aRepository.
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	modifiedPaths := paths ifNil: [ #(  ) ].
	isEmpty := aBoolean.
	changeCount := self derivedChangeCount
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
