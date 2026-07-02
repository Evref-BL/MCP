"
Result describing repository changes that were present before a discard operation ran.
"
Class {
	#name : 'MCPRepositoryDiscardResult',
	#superclass : 'MCPResult',
	#instVars : [
		'discardedPackageNames',
		'discardedPaths',
		'changeCount',
		'isEmpty'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryDiscardResult class >> discardedPackageNames: packageNames discardedPaths: paths [

	^ self new
		  initializeDiscardedPackageNames: packageNames
		  discardedPaths: paths
]

{ #category : 'converting' }
MCPRepositoryDiscardResult >> asDictionary [

	| data |
	data := Dictionary new.
	data
		at: #changeCount put: self changeCount;
		at: #isEmpty put: self isEmpty.
	self discardedPackageNames ifNotEmpty: [ :names |
		data at: #discardedPackageNames put: names ].
	self discardedPaths ifNotEmpty: [ :paths |
		data at: #discardedPaths put: paths ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> changeCount [

	^ changeCount
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> changeCount: anInteger [

	changeCount := anInteger
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> discardedPackageNames [

	^ discardedPackageNames
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> discardedPackageNames: packageNames [

	discardedPackageNames := packageNames
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> discardedPaths [

	^ discardedPaths
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> discardedPaths: paths [

	discardedPaths := paths
]

{ #category : 'initialization' }
MCPRepositoryDiscardResult >> initializeDiscardedPackageNames: packageNames discardedPaths: paths [

	discardedPackageNames := packageNames ifNil: [ #(  ) ].
	discardedPaths := paths ifNil: [ #(  ) ].
	changeCount := discardedPackageNames size + discardedPaths size.
	isEmpty := changeCount = 0
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> isEmpty [

	^ isEmpty
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> isEmpty: aBoolean [

	isEmpty := aBoolean
]
