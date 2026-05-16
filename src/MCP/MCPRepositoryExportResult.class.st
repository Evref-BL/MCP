"
Result DTO returned by edit-repository operation=export. It reports the repository synchronized to disk, changed package names, changed relative paths when Iceberg exposes them, and whether the diff contained changes.
"
Class {
	#name : 'MCPRepositoryExportResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
		'changedPackageNames',
		'modifiedPaths',
		'didChange'
	],
	#category : 'MCP-Results',
	#package : 'MCP',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryExportResult class >> repository: aRepository changedPackageNames: packageNames modifiedPaths: paths [

	^ self new
		  initializeRepository: aRepository
		  changedPackageNames: packageNames
		  modifiedPaths: paths
]

{ #category : 'converting' }
MCPRepositoryExportResult >> asDictionary [

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
		  (#didChange -> self didChange).
		  (#repositoryLocation -> self repositoryInfo location) }
		  asDictionary
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> changedPackageNames [

	^ changedPackageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> changedPackageNames: aCollection [

	changedPackageNames := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> didChange [

	^ didChange ifNil: [ false ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> didChange: aBoolean [

	didChange := aBoolean
]

{ #category : 'initialization' }
MCPRepositoryExportResult >> initializeRepository: aRepository changedPackageNames: packageNames modifiedPaths: paths [

	| packages |
	repositoryInfo := MCPRepositoryInfo fromRepository: aRepository.
	packages := aRepository workingCopy packages asArray
		            asSortedCollection: [ :left :right |
		            left name asString <= right name asString ].
	packageInfos := packages collect: [ :each |
		                MCPRepositoryPackageInfo fromPackage: each ].
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	modifiedPaths := paths ifNil: [ #(  ) ].
	didChange := changedPackageNames notEmpty or: [
		             modifiedPaths notEmpty ].
	^ self
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> modifiedPaths [

	^ modifiedPaths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> modifiedPaths: aCollection [

	modifiedPaths := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> packageInfos [

	^ packageInfos ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> packageInfos: aCollection [

	packageInfos := aCollection ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> repositoryInfo [

	^ repositoryInfo
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> repositoryInfo: aRepositoryInfo [

	repositoryInfo := aRepositoryInfo
]
