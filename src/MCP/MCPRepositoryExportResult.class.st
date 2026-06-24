"
Result DTO returned by repository_export. It reports the repository synchronized to disk, changed package names, changed relative paths when Iceberg exposes them, order-only Tonel paths restored after export, and whether the diff contained changes.
"
Class {
	#name : 'MCPRepositoryExportResult',
	#superclass : 'Object',
	#instVars : [
		'repositoryInfo',
		'packageInfos',
		'changedPackageNames',
		'modifiedPaths',
		'didChange',
		'restoredOrderOnlyPaths'
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

	| data |
	data := Dictionary new.
	data at: #didChange put: self didChange.
	self changedPackageNames ifNotEmpty: [ :names |
		data at: #changedPackageNames put: names ].
	self modifiedPaths ifNotEmpty: [ :paths |
		data at: #modifiedPaths put: paths ].
	self restoredOrderOnlyPaths ifNotEmpty: [ :paths |
		data at: #restoredOrderOnlyPaths put: paths ].
	^ data
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
	packages := aRepository workingCopy packages asArray sort: [
		            :left
		            :right | left name asString <= right name asString ].
	packageInfos := packages collect: [ :each |
		                MCPRepositoryPackageInfo fromPackage: each ].
	changedPackageNames := packageNames ifNil: [ #(  ) ].
	modifiedPaths := paths ifNil: [ #(  ) ].
	didChange := changedPackageNames notEmpty or: [
		             modifiedPaths notEmpty ]
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

{ #category : 'accessing' }
MCPRepositoryExportResult >> restoredOrderOnlyPaths [

	^ restoredOrderOnlyPaths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> restoredOrderOnlyPaths: aCollection [

	restoredOrderOnlyPaths := aCollection ifNil: [ #(  ) ]
]
