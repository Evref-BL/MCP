"
Result DTO returned by repository_update. It names the packages the update added to the repository and those it removed.
"
Class {
	#name : 'MCPRepositoryUpdateResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'addedPackageNames',
		'removedPackageNames'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryUpdateResult class >> repository: aRepository addedPackageNames: addedNames removedPackageNames: removedNames [

	^ self new initializeRepository: aRepository addedPackageNames: addedNames removedPackageNames: removedNames
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> addedPackageNames [

	^ addedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'converting' }
MCPRepositoryUpdateResult >> asDictionary [

	| data |
	data := Dictionary new.
	self addedPackageNames ifNotEmpty: [ :names | data at: #addedPackages put: names ].
	self removedPackageNames ifNotEmpty: [ :names | data at: #removedPackages put: names ].
	^ data
]

{ #category : 'initialization' }
MCPRepositoryUpdateResult >> initializeRepository: aRepository addedPackageNames: addedNames removedPackageNames: removedNames [

	self initializeSnapshotFromRepository: aRepository.
	addedPackageNames := addedNames ifNil: [ #(  ) ].
	removedPackageNames := removedNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> removedPackageNames [

	^ removedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> removedPackageNames: aCollection [

	removedPackageNames := aCollection ifNil: [ #(  ) ]
]
