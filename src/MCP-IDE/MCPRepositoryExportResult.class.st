"
Result DTO returned by repository_export. It names what export wrote and nothing else: the packages it wrote, the files it created or changed (a package directory that did not exist before as one path ending in a slash), the files it deleted, and what git sees besides in the checkout, every path counted from the checkout root.
"
Class {
	#name : 'MCPRepositoryExportResult',
	#superclass : 'MCPRepositorySnapshotResult',
	#instVars : [
		'packageNames',
		'writtenPaths',
		'deletedPaths',
		'alsoUncommittedPaths'
	],
	#category : 'MCP-IDE-Results',
	#package : 'MCP-IDE',
	#tag : 'Results'
}

{ #category : 'instance creation' }
MCPRepositoryExportResult class >> repository: aRepository [

	^ self new
		  initializeSnapshotFromRepository: aRepository;
		  yourself
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> alsoUncommittedPaths [

	^ alsoUncommittedPaths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> alsoUncommittedPaths: aCollection [

	alsoUncommittedPaths := aCollection asArray
]

{ #category : 'converting' }
MCPRepositoryExportResult >> asDictionary [

	| data |
	data := Dictionary new.
	self packageNames ifNotEmpty: [ :names | data at: #packages put: names ].
	self writtenPaths ifNotEmpty: [ :paths | data at: #written put: paths ].
	self deletedPaths ifNotEmpty: [ :paths | data at: #deleted put: paths ].
	self alsoUncommittedPaths ifNotEmpty: [ :paths | data at: #alsoUncommitted put: paths ].
	^ data
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> deletedPaths [

	^ deletedPaths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> deletedPaths: aCollection [

	deletedPaths := aCollection asArray
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> packageNames [

	^ packageNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> packageNames: aCollection [

	packageNames := aCollection asArray
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> writtenPaths [

	^ writtenPaths ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRepositoryExportResult >> writtenPaths: aCollection [

	writtenPaths := aCollection asArray
]
