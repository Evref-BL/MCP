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

{ #category : 'private - export' }
MCPRepositoryWorkingCopyCommand >> exportLoadedPackagesFrom: aRepository [

	| sourceDirectory |
	self exportProjectFileFor: aRepository.
	sourceDirectory := self repositorySourceDirectoryFor: aRepository.
	sourceDirectory ensureCreateDirectory.
	aRepository workingCopy loadedPackages do: [ :package |
		self exportPackage: package to: sourceDirectory ]
]

{ #category : 'private - export' }
MCPRepositoryWorkingCopyCommand >> exportPackage: anIcePackage to: sourceDirectory [

	| versionInfo |
	versionInfo := MCVersionInfo
		               name: anIcePackage packageName
		               id: UUID new
		               message: ''
		               date: Date today
		               time: Time now
		               ancestors: #(  )
		               stepChildren: #(  ).
	TonelWriter
		fileOut: (MCVersion package: anIcePackage mcPackage info: versionInfo)
		on: sourceDirectory
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

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> isTonelMethodOrderFile: aFileReference [

	| basename |
	basename := aFileReference basename.
	^ (basename endsWith: '.class.st') or: [
		  basename endsWith: '.extension.st' ]
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> isTonelMethodStartAt: anIndex in: lines [

	| line nextLine |
	anIndex >= lines size ifTrue: [ ^ false ].
	line := lines at: anIndex.
	(line beginsWith: '{ #category') ifFalse: [ ^ false ].
	nextLine := lines at: anIndex + 1.
	^ nextLine includesSubstring: ' >> '
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

	| packageName segments subdirectory subdirectorySegments |
	pathString isEmpty ifTrue: [ ^ '' ].
	segments := pathString substrings: '/'.
	segments isEmpty ifTrue: [ ^ '' ].
	subdirectory := aRepository subdirectory ifNil: [ '' ].
	packageName := subdirectory isEmpty
		               ifTrue: [ segments first ]
		               ifFalse: [
			               subdirectorySegments := subdirectory substrings: '/'.
			               segments size <= subdirectorySegments size ifTrue: [ ^ '' ].
			               (segments first: subdirectorySegments size)
			               = subdirectorySegments ifFalse: [ ^ '' ].
			               segments at: subdirectorySegments size + 1 ].
	(packageName beginsWith: '.') ifTrue: [ ^ '' ].
	^ packageName
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

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> relativePathFor: aFileReference under: aDirectory [

	| directoryPath filePath relative |
	directoryPath := aDirectory pathString.
	filePath := aFileReference pathString.
	relative := (filePath beginsWith: directoryPath)
		            ifTrue: [ filePath allButFirst: directoryPath size ]
		            ifFalse: [ aFileReference basename ].
	(relative beginsWith: '/') ifTrue: [ relative := relative allButFirst ].
	^ relative
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> restoreOrderOnlyTonelChurnFor: aRepository fromSnapshot: aSnapshot [

	| restored sourceDirectory |
	restored := OrderedCollection new.
	sourceDirectory := self repositorySourceDirectoryFor: aRepository.
	aSnapshot keysAndValuesDo: [ :relativePath :beforeContents |
		| afterContents file |
		file := sourceDirectory / relativePath.
		file exists ifTrue: [
			afterContents := file contents.
			(beforeContents ~= afterContents and: [
				 self
					 tonelMethodOrderEquivalent: beforeContents
					 to: afterContents ]) ifTrue: [
				file writeStreamDo: [ :stream |
					stream nextPutAll: beforeContents ].
				restored add: relativePath ] ] ].
	^ self sortedStringsFrom: restored
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> snapshotTonelFilesFor: aRepository [

	| snapshot sourceDirectory |
	snapshot := Dictionary new.
	sourceDirectory := self repositorySourceDirectoryFor: aRepository.
	(sourceDirectory exists and: [ sourceDirectory isDirectory ])
		ifFalse: [ ^ snapshot ].
	self tonelFilesIn: sourceDirectory do: [ :file |
		snapshot
			at: (self relativePathFor: file under: sourceDirectory)
			put: file contents ].
	^ snapshot
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> tonelFilesIn: aDirectory do: aBlock [

	aDirectory children do: [ :child |
		child isDirectory
			ifTrue: [ self tonelFilesIn: child do: aBlock ]
			ifFalse: [
				(self isTonelMethodOrderFile: child) ifTrue: [
					aBlock value: child ] ] ]
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> tonelMethodOrderEquivalent: beforeContents to: afterContents [

	^ (self tonelMethodOrderSignatureFor: beforeContents)
	  = (self tonelMethodOrderSignatureFor: afterContents)
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> tonelMethodOrderSignatureFor: contents [

	| chunks currentChunk lines normalizedContents preamble |
	normalizedContents := contents withLineEndings: String lf.
	lines := OrderedCollection new.
	normalizedContents linesDo: [ :line | lines add: line ].
	preamble := WriteStream on: String new.
	chunks := OrderedCollection new.
	1 to: lines size do: [ :index |
			| line |
			line := lines at: index.
			(self isTonelMethodStartAt: index in: lines)
				ifTrue: [
						currentChunk ifNotNil: [
							chunks add: currentChunk contents trimBoth ].
						currentChunk := WriteStream on: String new.
						currentChunk
							nextPutAll: line;
							nextPut: Character lf ]
				ifFalse: [
						currentChunk
							ifNil: [
									preamble
										nextPutAll: line;
										nextPut: Character lf ]
							ifNotNil: [
									currentChunk
										nextPutAll: line;
										nextPut: Character lf ] ] ].
	currentChunk ifNotNil: [ chunks add: currentChunk contents trimBoth ].
	^ {
		  (#preamble -> preamble contents trimBoth).
		  (#methods -> chunks asArray sort) } asDictionary
]

{ #category : 'private - execution' }
MCPRepositoryWorkingCopyCommand >> withNonInteractiveAuthorDuring: aBlock [

	^ PharoCompatibility
		  withNonInteractiveAuthorNamed: 'MCP'
		  during: aBlock
]
