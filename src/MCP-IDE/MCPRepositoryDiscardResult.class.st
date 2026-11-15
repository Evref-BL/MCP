"
Result describing what a discard found before it ran: the packages Iceberg marked or the changed paths belong to, and the paths git saw changed.
"
Class {
	#name : 'MCPRepositoryDiscardResult',
	#superclass : 'MCPResult',
	#instVars : [
		'discardedPackageNames',
		'discardedPaths'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryDiscardResult class >> discardedPackageNames: packageNames discardedPaths: paths [

	^ self new initializeDiscardedPackageNames: packageNames discardedPaths: paths
]

{ #category : 'converting' }
MCPRepositoryDiscardResult >> asDictionary [

	| data |
	data := Dictionary new.
	self discardedPackageNames ifNotEmpty: [ :names | data at: #discardedPackages put: names ].
	self discardedPaths ifNotEmpty: [ :paths | data at: #discardedPaths put: paths ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> discardedPackageNames [

	^ discardedPackageNames
]

{ #category : 'accessing' }
MCPRepositoryDiscardResult >> discardedPaths [

	^ discardedPaths
]

{ #category : 'initialization' }
MCPRepositoryDiscardResult >> initializeDiscardedPackageNames: packageNames discardedPaths: paths [

	discardedPackageNames := packageNames ifNil: [ #(  ) ].
	discardedPaths := paths ifNil: [ #(  ) ]
]
