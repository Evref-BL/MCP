"
Command wrapper for edit-repository operation=export. It calculates the repository working copy diff, updates the disk working copy and git index from that diff, and returns an MCPRepositoryExportResult.
"
Class {
	#name : 'MCPExportRepositoryCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPExportRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - diff' }
MCPExportRepositoryCommand >> addModifiedPathsFromNode: aNode to: paths [

	(aNode hasChanges and: [ aNode path segments notEmpty ]) ifTrue: [
		paths add: aNode path pathString ].
	aNode children do: [ :each |
		self addModifiedPathsFromNode: each to: paths ]
]

{ #category : 'private - diff' }
MCPExportRepositoryCommand >> changedPackageNamesFromDiff: aDiff [

	| names |
	names := [
	         aDiff packages collect: [ :each |
		         self packageNameFromDiffPackageNode: each ] ]
		         on: Error
		         do: [ :ignored | #(  ) ].
	^ self sortedStringsFrom:
		  (names select: [ :each | each notNil and: [ each isEmpty not ] ])
]

{ #category : 'executing' }
MCPExportRepositoryCommand >> execute [

	| changedPackageNames diff modifiedPaths repository result |
	^ self tool
		  executeEditOperation: 'export'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self request repository.
			  diff := repository workingCopyDiff.
			  changedPackageNames := self changedPackageNamesFromDiff: diff.
			  modifiedPaths := self modifiedPathsFromDiff: diff.
			  self withNonInteractiveAuthorDuring: [
				  repository index
					  updateDiskWorkingCopy: diff;
					  updateIndex: diff ].
			  result := (MCPRepositoryExportResult
				             repository: repository
				             changedPackageNames: changedPackageNames
				             modifiedPaths: modifiedPaths)
				            didChange: diff isEmpty not;
				            yourself ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Exported repository ' , result repositoryInfo name , '.'
				  data: (self tool dataForRepositoryExportResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to export repository: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPExportRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - diff' }
MCPExportRepositoryCommand >> modifiedPathsFromDiff: aDiff [

	| paths |
	paths := OrderedCollection new.
	[ self addModifiedPathsFromNode: aDiff tree to: paths ]
		on: Error
		do: [ :ignored | ^ #(  ) ].
	^ self sortedStringsFrom: paths
]

{ #category : 'private - diff' }
MCPExportRepositoryCommand >> packageNameFromDiffPackageNode: aNode [

	| definition |
	definition := aNode definition.
	(definition respondsTo: #packageName) ifFalse: [ ^ nil ].
	^ definition packageName asString
]

{ #category : 'accessing' }
MCPExportRepositoryCommand >> request [

	^ request
]

{ #category : 'private' }
MCPExportRepositoryCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet
		  asSortedCollection asArray
]

{ #category : 'accessing' }
MCPExportRepositoryCommand >> tool [

	^ tool
]

{ #category : 'private - execution' }
MCPExportRepositoryCommand >> withNonInteractiveAuthorDuring: aBlock [

	^ Author fullNamePerSe isEmptyOrNil
		  ifTrue: [ Author useAuthor: 'MCP' during: aBlock ]
		  ifFalse: [ aBlock value ]
]
