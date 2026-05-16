"
Command wrapper for edit-repository operation=diff. It calculates IceRepository>>workingCopyDiff and returns an MCPRepositoryDiffResult without writing the disk working copy or updating the repository index.
"
Class {
	#name : 'MCPRepositoryDiffCommand',
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
MCPRepositoryDiffCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private - diff' }
MCPRepositoryDiffCommand >> addModifiedPathsFromNode: aNode to: paths [

	(aNode hasChanges and: [ aNode path segments notEmpty ]) ifTrue: [
		paths add: aNode path pathString ].
	aNode children do: [ :each |
		self addModifiedPathsFromNode: each to: paths ]
]

{ #category : 'private - diff' }
MCPRepositoryDiffCommand >> changedPackageNamesFromDiff: aDiff [

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
MCPRepositoryDiffCommand >> execute [

	| changedPackageNames diff modifiedPaths repository result |
	^ self tool
		  executeEditOperation: 'diff'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self request repository.
			  diff := repository workingCopyDiff.
			  changedPackageNames := self changedPackageNamesFromDiff: diff.
			  modifiedPaths := self modifiedPathsFromDiff: diff.
			  result := MCPRepositoryDiffResult
				            repository: repository
				            changedPackageNames: changedPackageNames
				            modifiedPaths: modifiedPaths
				            isEmpty: diff isEmpty ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Computed repository diff for ' , result repositoryInfo name
				  , '.'
				  data: (self tool dataForRepositoryDiffResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to compute repository diff: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPRepositoryDiffCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - diff' }
MCPRepositoryDiffCommand >> modifiedPathsFromDiff: aDiff [

	| paths |
	paths := OrderedCollection new.
	[ self addModifiedPathsFromNode: aDiff tree to: paths ]
		on: Error
		do: [ :ignored | ^ #(  ) ].
	^ self sortedStringsFrom: paths
]

{ #category : 'private - diff' }
MCPRepositoryDiffCommand >> packageNameFromDiffPackageNode: aNode [

	| definition |
	definition := aNode definition.
	(definition respondsTo: #packageName) ifFalse: [ ^ nil ].
	^ definition packageName asString
]

{ #category : 'accessing' }
MCPRepositoryDiffCommand >> request [

	^ request
]

{ #category : 'private' }
MCPRepositoryDiffCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet
		  asSortedCollection asArray
]

{ #category : 'accessing' }
MCPRepositoryDiffCommand >> tool [

	^ tool
]
