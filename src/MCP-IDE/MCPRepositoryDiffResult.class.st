"
Result DTO returned by repository_change_list.

It names the two layers apart: imageModifiedPackages, the packages whose contents in the image differ from the checkout's files, which is what an export would change; and modifiedPaths, the files git sees changed in the checkout.
"
Class {
	#name : 'MCPRepositoryDiffResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'modifiedPaths',
		'imageModifiedPackageNames'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryDiffResult class >> repository: aRepository imageModifiedPackages: imagePackageNames modifiedPaths: paths [

	^ self new initializeRepository: aRepository imageModifiedPackages: imagePackageNames modifiedPaths: paths
]

{ #category : 'converting' }
MCPRepositoryDiffResult >> asDictionary [

	| data |
	data := Dictionary new.
	self imageModifiedPackageNames ifNotEmpty: [ :names | data at: #imageModifiedPackages put: names ].
	self modifiedPaths ifNotEmpty: [ :paths | data at: #modifiedPaths put: paths ].
	^ data
]

{ #category : 'testing' }
MCPRepositoryDiffResult >> hasChanges [
	"Whether either side holds something its last commit does not."

	^ self imageModifiedPackageNames isNotEmpty or: [ self modifiedPaths isNotEmpty ]
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
MCPRepositoryDiffResult >> initializeRepository: aRepository imageModifiedPackages: imagePackageNames modifiedPaths: paths [

	self initializeSnapshotFromRepository: aRepository.
	imageModifiedPackageNames := imagePackageNames ifNil: [ #(  ) ].
	modifiedPaths := paths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> modifiedPaths [

	^ modifiedPaths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryDiffResult >> modifiedPaths: aCollection [

	modifiedPaths := aCollection ifNil: [ #(  ) ]
]
