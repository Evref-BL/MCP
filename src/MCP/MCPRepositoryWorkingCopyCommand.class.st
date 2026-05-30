"
Abstract base for repository commands that read the Iceberg working-copy diff.

It centralizes shared tool/request plumbing and diff summarization helpers used by repository_change_list, repository_export, and repository_commit commands.
"
Class {
	#name : 'MCPRepositoryWorkingCopyCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPRepositoryWorkingCopyCommand class >> isAbstract [

	^ self = MCPRepositoryWorkingCopyCommand
]

{ #category : 'instance creation' }
MCPRepositoryWorkingCopyCommand class >> tool: aTool request: aRequest [

	^ self new
		  initializeTool: aTool request: aRequest;
		  yourself
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> addModifiedPathsFromNode: aNode to: paths [

	(aNode hasChanges and: [ aNode path segments notEmpty ]) ifTrue: [
		paths add: aNode path pathString ].
	aNode children do: [ :each |
		self addModifiedPathsFromNode: each to: paths ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> changedPackageNamesFromDiff: aDiff [

	| names |
	names := [
		         aDiff packages collect: [ :each |
			         self packageNameFromDiffPackageNode: each ] ]
		         on: Error
		         do: [ :ignored | #(  ) ].
	^ self sortedStringsFrom:
		  (names select: [ :each | each notNil and: [ each isEmpty not ] ])
]

{ #category : 'initialization' }
MCPRepositoryWorkingCopyCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> modifiedPathsFromDiff: aDiff [

	| paths |
	paths := OrderedCollection new.
	[ self addModifiedPathsFromNode: aDiff tree to: paths ]
		on: Error
		do: [ :ignored | ^ #(  ) ].
	^ self sortedStringsFrom: paths
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> packageNameFromDiffPackageNode: aNode [

	| definition |
	definition := aNode definition.
	(definition respondsTo: #packageName) ifFalse: [ ^ nil ].
	^ definition packageName asString
]

{ #category : 'accessing' }
MCPRepositoryWorkingCopyCommand >> request [

	^ request
]

{ #category : 'private' }
MCPRepositoryWorkingCopyCommand >> sortedStringsFrom: aCollection [

	^ (aCollection collect: [ :each | each asString ]) asSet
		  asSortedCollection asArray
]

{ #category : 'accessing' }
MCPRepositoryWorkingCopyCommand >> tool [

	^ tool
]

{ #category : 'private - execution' }
MCPRepositoryWorkingCopyCommand >> withNonInteractiveAuthorDuring: aBlock [

	^ PharoCompatibility
		  withNonInteractiveAuthorNamed: 'MCP'
		  during: aBlock
]
