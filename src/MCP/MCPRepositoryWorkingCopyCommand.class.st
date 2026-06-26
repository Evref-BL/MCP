"
Abstract base for repository commands that read the Iceberg working-copy diff.

It centralizes shared tool/request plumbing and diff summarization helpers used by repository_change_list, repository_export, and repository_commit commands.
"
Class {
	#name : 'MCPRepositoryWorkingCopyCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPRepositoryWorkingCopyCommand class >> isAbstract [

	^ self = MCPRepositoryWorkingCopyCommand
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> addModifiedPathsFromNode: aNode to: paths [

	(aNode hasChanges and: [ aNode path segments notEmpty ]) ifTrue: [
		paths add: aNode path pathString ].
	aNode children do: [ :each |
		self addModifiedPathsFromNode: each to: paths ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> changedPackageNamesForRepository: aRepository modifiedPaths: paths [

	^ self sortedStringsFrom:
		  (self imageModifiedPackageNamesFor: aRepository)
		  , (self packageNamesFromModifiedPaths: paths in: aRepository)
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> changedPackageNamesFromDiff: aDiff [

	| names |
	names := OrderedCollection new.
	aDiff packages do: [ :each |
			(self packageNameFromDiffPackageNode: each) ifNotNil: [ :name |
				name isEmpty ifFalse: [ names add: name ] ] ].
	^ self sortedStringsFrom: names
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> gitStatusLinesFor: aRepository [

	| output |
	output := (self
		           runGitArguments: #( 'status' '--porcelain=v1' )
		           in: aRepository
		           ifFailed: [ :gitResult |
			           self signalGitCommandFailed: gitResult action: 'status' ])
		          at: #output.
	^ output lines
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> imageModifiedPackageNamesFor: aRepository [

	^ self sortedStringsFrom:
		  (aRepository modifiedPackages collect: [ :each | each name ])
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
MCPRepositoryWorkingCopyCommand >> modifiedPathsFromGitStatusIn: aRepository [

	(self repositoryHasGitWorkTree: aRepository) ifFalse: [ ^ #( ) ].
	^ self sortedStringsFrom:
		  ((self gitStatusLinesFor: aRepository)
			   collect: [ :line | self pathFromGitStatusLine: line ]
			   thenSelect: [ :path | path notEmpty ])
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> packageNameFromDiffPackageNode: aNode [

	^ aNode mcpDiffPackageName
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> packageNameFromPath: pathString in: aRepository [

	| segments subdirectory subdirectorySegments |
	pathString isEmpty ifTrue: [ ^ '' ].
	segments := pathString substrings: '/'.
	segments isEmpty ifTrue: [ ^ '' ].
	subdirectory := aRepository subdirectory ifNil: [ '' ].
	subdirectory isEmpty ifTrue: [ ^ segments first ].
	subdirectorySegments := subdirectory substrings: '/'.
	segments size <= subdirectorySegments size ifTrue: [ ^ '' ].
	(segments first: subdirectorySegments size) = subdirectorySegments
		ifFalse: [ ^ '' ].
	^ segments at: subdirectorySegments size + 1
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> packageNamesFromModifiedPaths: paths in: aRepository [

	^ self sortedStringsFrom:
		  (paths collect: [ :path | self packageNameFromPath: path in: aRepository ]
		         thenSelect: [ :name | name notEmpty ])
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> pathFromGitStatusLine: aLine [

	| arrow path |
	aLine size < 4 ifTrue: [ ^ '' ].
	path := (aLine allButFirst: 3) trimBoth.
	arrow := path findString: ' -> '.
	arrow isZero ifFalse: [ path := (path allButFirst: arrow + 3) trimBoth ].
	^ path
]

{ #category : 'private - execution' }
MCPRepositoryWorkingCopyCommand >> withNonInteractiveAuthorDuring: aBlock [

	^ PharoCompatibility
		  withNonInteractiveAuthorNamed: 'MCP'
		  during: aBlock
]
