"
Result DTO returned by repository_change_list.

It names the two layers apart: imageModifiedPackages, the packages whose contents in the image differ from the checkout's files, which is what an export would change; and modifiedPaths, the files git sees changed in the checkout. changedPackages is the union of both, which is why it can name a package whose files are untouched.
"
Class {
	#name : 'MCPRepositoryDiffResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'changedPackageNames',
		'modifiedPaths',
		'changeCount',
		'isEmpty',
		'imageModifiedPackageNames'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryDiffResult class >> repository: aRepository changedPackageNames: packageNames imageModifiedPackages: imagePackageNames modifiedPaths: paths [

	^ self new
		  initializeRepository: aRepository
		  changedPackageNames: packageNames
		  imageModifiedPackages: imagePackageNames
		  modifiedPaths: paths
]

{ #category : 'converting' }
MCPRepositoryDiffResult >> asDictionary [

	| data |
	data := Dictionary new.
	data
		at: #changeCount put: self changeCount;
		at: #isEmpty put: self isEmpty.
	self changedPackageNames ifNotEmpty: [ :names | data at: #changedPackages put: names ].
	self imageModifiedPackageNames ifNotEmpty: [ :names | data at: #imageModifiedPackages put: names ].
	self modifiedPaths ifNotEmpty: [ :paths | data at: #modifiedPaths put: paths ].
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

	self modifiedPaths isNotEmpty ifTrue: [ ^ self modifiedPaths size ].
	^ self changedPackageNames size
]

{ #category : 'private' }
MCPRepositoryDiffResult >> derivedIsEmpty [

	^ self changedPackageNames isEmpty and: [ self modifiedPaths isEmpty ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> imageModifiedPackageNames [
	"The packages whose contents in the image differ from the checkout's files. They are what an export would change, and what git cannot see."

	^ imageModifiedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> imageModifiedPackageNames: aCollection [

	imageModifiedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'initialization' }
MCPRepositoryDiffResult >> initializeRepository: aRepository changedPackageNames: packageNames imageModifiedPackages: imagePackageNames modifiedPaths: paths [

	self initializeSnapshotFromRepository: aRepository.
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	imageModifiedPackageNames := imagePackageNames ifNil: [ #(  ) ].
	modifiedPaths := paths ifNil: [ #(  ) ].
	isEmpty := self derivedIsEmpty.
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
