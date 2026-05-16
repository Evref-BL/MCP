"
Result DTO returned by edit-repository operation=update. It reports the repository after applying package membership or repository metadata changes, plus the package names added and removed during the update.
"
Class {
	#name : 'MCPRepositoryUpdateResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
		'updateActions',
		'addedPackageNames',
		'removedPackageNames'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryUpdateResult class >> repository: aRepository updateActions: actionNames addedPackageNames: addedNames removedPackageNames: removedNames [

	^ self new
		  initializeRepository: aRepository
		  updateActions: actionNames
		  addedPackageNames: addedNames
		  removedPackageNames: removedNames
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> addedPackageNames [

	^ addedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> addedPackageNames: aCollection [

	addedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'converting' }
MCPRepositoryUpdateResult >> asDictionary [

	^ {
		  (#repository -> self repositoryInfo asDictionary).
		  (#packages
		   ->
		   (self packageInfos
			    collect: [ :each | each asDictionary ]
			    as: Array)).
		  (#packageNames -> self repositoryInfo packageNames).
		  (#updateActions -> self updateActions).
		  (#addedPackageNames -> self addedPackageNames).
		  (#removedPackageNames -> self removedPackageNames) } asDictionary
]

{ #category : 'initialization' }
MCPRepositoryUpdateResult >> initializeRepository: aRepository updateActions: actionNames addedPackageNames: addedNames removedPackageNames: removedNames [

	| packages |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	packageInfos := packages collect: [ :each |
		                MCPRepositoryPackageInfo fromPackage: each ].
	updateActions := actionNames ifNil: [ #(  ) ].
	addedPackageNames := addedNames ifNil: [ #(  ) ].
	removedPackageNames := removedNames ifNil: [ #(  ) ].
	^ self
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> packageInfos: aCollection [

	packageInfos := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> removedPackageNames [

	^ removedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> removedPackageNames: aCollection [

	removedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> repositoryInfo [

	^ repositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> repositoryInfo: aRepositoryInfo [

	repositoryInfo := aRepositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> updateActions [

	^ updateActions ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryUpdateResult >> updateActions: aCollection [

	updateActions := aCollection ifNil: [ #(  ) ]
]
