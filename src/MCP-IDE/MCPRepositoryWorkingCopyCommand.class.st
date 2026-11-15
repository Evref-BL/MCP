"
Abstract base for repository commands that read or write the checkout's files: repository_change_list, repository_change_discard, repository_export and repository_commit.

It writes the loaded packages, reads the bytes of the files export may write, answers which registered packages a path belongs to, and reads what git sees in the checkout. Every path counts from the checkout root, its segments joined with a slash.
"
Class {
	#name : 'MCPRepositoryWorkingCopyCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPRepositoryWorkingCopyCommand class >> isAbstract [

	^ self = MCPRepositoryWorkingCopyCommand
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> addModifiedPathsFromNode: aNode to: paths [

	(aNode hasChanges and: [ aNode path segments isNotEmpty ]) ifTrue: [ paths add: aNode path pathString ].
	aNode children do: [ :each | self addModifiedPathsFromNode: each to: paths ]
]

{ #category : 'private - files' }
MCPRepositoryWorkingCopyCommand >> alsoUncommittedFrom: uncommittedPaths written: written deleted: deleted [
	"What git sees besides what export wrote or deleted, in full: every uncommitted path but those export names and those under a directory it names."

	^ uncommittedPaths reject: [ :path |
			  (deleted includes: path) or: [
				  written anySatisfy: [ :each | path = each or: [ (each endsWith: '/') and: [ path beginsWith: each ] ] ] ] ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> assertRepositoryCleanAfterDiscard: aRepository [

	| remainingPackageNames remainingPaths |
	remainingPaths := self modifiedPathsFromGitStatusIn: aRepository.
	remainingPackageNames := self changedPackageNamesForRepository: aRepository modifiedPaths: remainingPaths.
	(remainingPackageNames isEmpty and: [ remainingPaths isEmpty ]) ifFalse: [
			MCPCommandError signalErrorCode: 'RepositoryDiscardIncomplete' message: 'Repository changes remain after discard.' details: {
					(#remainingPackageNames -> remainingPackageNames).
					(#remainingPaths -> remainingPaths) } asDictionary ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> byteForGitEscape: aCharacter [

	^ {
		  ($a -> 7).
		  ($b -> 8).
		  ($t -> 9).
		  ($n -> 10).
		  ($v -> 11).
		  ($f -> 12).
		  ($r -> 13) } asDictionary at: aCharacter ifAbsent: [ aCharacter asInteger ]
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> bytes: beforeBytes differOnlyInMethodOrderFrom: afterBytes [
	"Both are read as UTF-8, which Tonel writes; bytes that are not UTF-8 are never taken for the same file."

	| after before |
	beforeBytes = afterBytes ifTrue: [ ^ false ].
	before := [ beforeBytes utf8Decoded ]
		          on: Error
		          do: [ ^ false ].
	after := [ afterBytes utf8Decoded ]
		         on: Error
		         do: [ ^ false ].
	^ self tonelMethodOrderEquivalent: before to: after
]

{ #category : 'private - files' }
MCPRepositoryWorkingCopyCommand >> bytesOf: aFileReference [

	^ aFileReference binaryReadStreamDo: [ :stream | stream upToEnd ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> changedPackageNamesForRepository: aRepository modifiedPaths: paths [
	"The packages Iceberg marks and those the paths belong to."

	^ self sortedStringsFrom: (self imageModifiedPackageNamesFor: aRepository) , (self packageNamesForPaths: paths in: aRepository)
]

{ #category : 'private - files' }
MCPRepositoryWorkingCopyCommand >> deletedPathsFrom: before to: after [

	^ self sortedStringsFrom: (before keys reject: [ :each | after includesKey: each ])
]

{ #category : 'private - files' }
MCPRepositoryWorkingCopyCommand >> existingLoadedPackageDirectoryPathsFor: aRepository [

	^ ((self loadedPackageDirectoriesFor: aRepository)
		   select: [ :each | each isDirectory ]
		   thenCollect: [ :each | self pathFromRoot: each in: aRepository ]) asSet
]

{ #category : 'private - export' }
MCPRepositoryWorkingCopyCommand >> exportLoadedPackagesFrom: aRepository [
	"Write .project and each loaded package, and answer the warning that names the registered packages the image lacks, whose files are left as they are."

	| sourceDirectory writerClass |
	writerClass := self sourceWriterClassFor: aRepository.
	self exportProjectFileFor: aRepository.
	sourceDirectory := self repositorySourceDirectoryFor: aRepository.
	sourceDirectory ensureCreateDirectory.
	aRepository workingCopy loadedPackages do: [ :package | self exportPackage: package in: aRepository through: writerClass ].
	^ self warningsForPackagesNotInImageOf: aRepository
]

{ #category : 'private - export' }
MCPRepositoryWorkingCopyCommand >> exportPackage: anIcePackage in: aRepository through: aWriterClass [
	"Iceberg's internal store writes the package where the checkout keeps it, in
	the format the writer stands for and at the version the checkout pins: a
	Tonel checkout gets Tonel files, a filetree one a Name.package directory."

	| mcPackage |
	mcPackage := anIcePackage mcPackage.
	aWriterClass
		forInternalStoreFileOut: (MCVersion package: mcPackage info: (IceMCVersionInfo package: mcPackage message: ''))
		on: aRepository
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> gitStatusLinesFor: aRepository [

	| output |
	output := (self
		           runGitArguments: #( 'status' '--porcelain=v1' )
		           in: aRepository
		           ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'status' ]) at: #output.
	^ output lines
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> imageDifferingPackageNamesFor: aRepository [
	"The packages Iceberg marks modified whose contents in the image differ from the checkout's files. Iceberg marks a package on any change and clears the mark only when it writes the package, so an edit undone, or a test that compiles a method and removes it, leaves a mark over nothing. When the files cannot be read at all, the marks are all there is to answer with."

	| modifiedPackages writerClass |
	modifiedPackages := aRepository modifiedPackages.
	modifiedPackages ifEmpty: [ ^ #(  ) ].
	^ self withoutLeavingFiletreeMarkerIn: (self repositorySourceDirectoryFor: aRepository) do: [
			  | sourceRepository |
			  sourceRepository := [
				                      writerClass := self sourceWriterClassFor: aRepository.
				                      self sourceRepositoryFor: aRepository writer: writerClass ]
				                      on: Error
				                      do: [ ^ self imageModifiedPackageNamesFor: aRepository ].
			  self sortedStringsFrom: (modifiedPackages
					   select: [ :each | self package: each differsIn: sourceRepository writer: writerClass ]
					   thenCollect: [ :each | each name ]) ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> imageModifiedPackageNamesFor: aRepository [

	^ self sortedStringsFrom: (aRepository modifiedPackages collect: [ :each | each name ])
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> isTonelMethodOrderFile: aFileReference [

	| basename |
	basename := aFileReference basename.
	^ (basename endsWith: '.class.st') or: [ basename endsWith: '.extension.st' ]
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

{ #category : 'private - files' }
MCPRepositoryWorkingCopyCommand >> loadedPackageDirectoriesFor: aRepository [
	"The directory export writes each loaded package to."

	| writerClass |
	writerClass := self sourceWriterClassFor: aRepository.
	^ aRepository workingCopy loadedPackages collect: [ :each | self directoryOfPackage: each in: aRepository writer: writerClass ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> modifiedPathsFromGitStatusIn: aRepository [

	(self repositoryHasGitWorkTree: aRepository) ifFalse: [ ^ #(  ) ].
	^ self sortedStringsFrom:
		  ((self gitStatusLinesFor: aRepository)
			   collect: [ :line | self pathFromGitStatusLine: line ]
			   thenSelect: [ :path | path isNotEmpty ])
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> package: anIcePackage differsIn: sourceRepository writer: aWriterClass [
	"Answer whether the image holds anIcePackage otherwise than the checkout's files do. A package the files lack differs, and so does one that cannot be read or compared: nothing showed it equal."

	^ [
		  (self versionIn: sourceRepository for: anIcePackage writer: aWriterClass)
			  ifNil: [ true ]
			  ifNotNil: [ :version | ((MCPackage named: anIcePackage name) snapshot patchRelativeToBase: version snapshot) isEmpty not ] ]
		  on: Error
		  do: [ true ]
]

{ #category : 'private - paths' }
MCPRepositoryWorkingCopyCommand >> packageDirectoryPathsFor: aRepository [
	"The directory of each package the repository registers, loaded or not, as a path from the checkout root, by package name. The format the checkout declares names the directory."

	| packages paths writerClass |
	paths := Dictionary new.
	packages := aRepository workingCopy packages.
	packages ifEmpty: [ ^ paths ].
	writerClass := self sourceWriterClassFor: aRepository.
	packages do: [ :each |
			paths
				at: each name asString
				put: (self pathFromRoot: (self directoryOfPackage: each in: aRepository writer: writerClass) in: aRepository) ].
	^ paths
]

{ #category : 'private - paths' }
MCPRepositoryWorkingCopyCommand >> packageNamesForPath: aPath among: packageDirectories in: aRepository [
	"The packages aPath belongs to, given each registered package's directory from the checkout root; packageNamesForPaths:in: says when it does."

	| names |
	names := OrderedCollection new.
	packageDirectories keysAndValuesDo: [ :name :directory |
			((self path: aPath isOrLiesUnder: directory) or: [ self path: aPath foldsExistingDirectory: directory in: aRepository ])
				ifTrue: [ names add: name ] ].
	^ names
]

{ #category : 'private - paths' }
MCPRepositoryWorkingCopyCommand >> packageNamesForPaths: paths in: aRepository [
	"The packages the repository registers, loaded or not, that the paths belong to, sorted. A path belongs to a package when it is the package's directory, with or without a trailing slash, or lies under it. A path ending in a slash that holds package directories, as git folds a wholly untracked tree, belongs to each package whose directory lies under it and exists. A directory's name is never read as a package's: a path that belongs to no package stays a path."

	| directories |
	paths ifEmpty: [ ^ #(  ) ].
	directories := self packageDirectoryPathsFor: aRepository.
	^ self sortedStringsFrom: (paths flatCollect: [ :each | self packageNamesForPath: each among: directories in: aRepository ])
]

{ #category : 'private - paths' }
MCPRepositoryWorkingCopyCommand >> path: aPath foldsExistingDirectory: aDirectoryPath in: aRepository [
	"Git names a wholly untracked tree by its top directory and a trailing slash; such a path holds every package directory under it that exists."

	^ (aPath endsWith: '/') and: [
		  (aDirectoryPath beginsWith: aPath) and: [ (aRepository location asFileReference resolveString: aDirectoryPath) isDirectory ] ]
]

{ #category : 'private - paths' }
MCPRepositoryWorkingCopyCommand >> path: aPath isOrLiesUnder: aDirectoryPath [

	^ aPath = aDirectoryPath or: [ aPath beginsWith: aDirectoryPath , '/' ]
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> pathFromGitStatusLine: aLine [

	| arrow path |
	aLine size < 4 ifTrue: [ ^ '' ].
	path := (aLine allButFirst: 3) trimBoth.
	arrow := path findString: ' -> '.
	arrow isZero ifFalse: [ path := (path allButFirst: arrow + 3) trimBoth ].
	^ self unquotedGitPath: path
]

{ #category : 'private - paths' }
MCPRepositoryWorkingCopyCommand >> pathFromRoot: aFileReference in: aRepository [
	"The path of aFileReference from the checkout root, the repository's location, which attach and create require to be the Git root: its segments joined with a slash on every platform, as git writes a path."

	^ '/' join: (aFileReference path relativeTo: aRepository location asFileReference path) segments
]

{ #category : 'private - paths' }
MCPRepositoryWorkingCopyCommand >> pathsOutsidePackages: paths in: aRepository [
	"The paths that belong to no package the repository registers, as packageNamesForPaths:in: reads them."

	| directories |
	directories := self packageDirectoryPathsFor: aRepository.
	^ paths select: [ :each | (self packageNamesForPath: each among: directories in: aRepository) isEmpty ]
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> restoreOrderOnlyTonelChurnFor: aRepository fromSnapshot: aSnapshot [
	"Write back whole, from the snapshot, each Tonel class or extension file the writer changed only by putting its methods in another order, and answer their paths from the checkout root. The file is deleted first: a write stream on an existing file would keep whatever a shorter contents leaves past its end."

	| location restored |
	restored := OrderedCollection new.
	location := aRepository location asFileReference.
	aSnapshot keysAndValuesDo: [ :path :beforeBytes |
			| file |
			file := location resolveString: path.
			((self isTonelMethodOrderFile: file) and: [
				 file isFile and: [ self bytes: beforeBytes differOnlyInMethodOrderFrom: (self bytesOf: file) ] ]) ifTrue: [
					file ensureDelete.
					file binaryWriteStreamDo: [ :stream | stream nextPutAll: beforeBytes ].
					restored add: path ] ].
	^ self sortedStringsFrom: restored
]

{ #category : 'private - files' }
MCPRepositoryWorkingCopyCommand >> snapshotFilesFor: aRepository [
	"The bytes of every file export may write, by path from the checkout root: every file under each loaded package's directory, every file directly in the source directory, and .project. Only export runs between this reading and the next, so what differs between them is what it wrote."

	| files projectFile snapshot sourceDirectory |
	files := OrderedCollection new.
	(self loadedPackageDirectoriesFor: aRepository) do: [ :each | each isDirectory ifTrue: [ files addAll: each allFiles ] ].
	sourceDirectory := self repositorySourceDirectoryFor: aRepository.
	sourceDirectory isDirectory ifTrue: [ files addAll: sourceDirectory files ].
	projectFile := aRepository location asFileReference / '.project'.
	projectFile isFile ifTrue: [ files add: projectFile ].
	snapshot := Dictionary new.
	files do: [ :each | snapshot at: (self pathFromRoot: each in: aRepository) put: (self bytesOf: each) ].
	^ snapshot
]

{ #category : 'private - tonel order' }
MCPRepositoryWorkingCopyCommand >> tonelMethodOrderEquivalent: beforeContents to: afterContents [

	^ (self tonelMethodOrderSignatureFor: beforeContents) = (self tonelMethodOrderSignatureFor: afterContents)
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
						currentChunk ifNotNil: [ chunks add: currentChunk contents trimBoth ].
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

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> uncommittedPathsIn: aRepository [
	"Every path git sees changed or untracked in the checkout, file by file: what repository_commit would take."

	| output |
	(self repositoryHasGitWorkTree: aRepository) ifFalse: [ ^ #(  ) ].
	output := (self
		           runGitArguments: #( '-c' 'core.quotePath=false' 'status' '--porcelain=v1' '--untracked-files=all' )
		           in: aRepository
		           ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'status' ]) at: #output.
	^ self sortedStringsFrom:
		  (output lines collect: [ :line | self pathFromGitStatusLine: line ] thenSelect: [ :path | path isNotEmpty ])
]

{ #category : 'private - export' }
MCPRepositoryWorkingCopyCommand >> unloadedPackageNamesOf: aRepository [
	"The packages the repository registers and the image does not hold, sorted. Export leaves their files as they are."

	^ self sortedStringsFrom: (aRepository workingCopy packages reject: [ :each | each isLoaded ] thenCollect: [ :each | each name ])
]

{ #category : 'private - diff' }
MCPRepositoryWorkingCopyCommand >> unquotedGitPath: aString [
	"Git writes between double quotes a path that holds a double quote, a backslash, a control character or, in a status, a space, with C escapes, and each byte outside ASCII as an octal escape unless core.quotePath is false."

	| bytes index |
	(aString size >= 2 and: [ aString first = $" and: [ aString last = $" ] ]) ifFalse: [ ^ aString ].
	bytes := WriteStream on: ByteArray new.
	index := 2.
	[ index < aString size ] whileTrue: [
			| character |
			character := aString at: index.
			character = $\
				ifFalse: [
						bytes nextPutAll: character asString utf8Encoded.
						index := index + 1 ]
				ifTrue: [
						(aString at: index + 1) isDigit
							ifTrue: [
									bytes nextPut: ((aString copyFrom: index + 1 to: index + 3) inject: 0 into: [ :sum :digit | sum * 8 + digit digitValue ]).
									index := index + 4 ]
							ifFalse: [
									bytes nextPut: (self byteForGitEscape: (aString at: index + 1)).
									index := index + 2 ] ] ].
	^ bytes contents utf8Decoded
]

{ #category : 'private - export' }
MCPRepositoryWorkingCopyCommand >> warningsForPackagesNotInImageOf: aRepository [

	| names |
	names := self sortedStringsFrom:
		         (aRepository workingCopy packages reject: [ :each | each isLoaded ] thenCollect: [ :each | each name ]).
	names ifEmpty: [ ^ #(  ) ].
	^ { (String streamContents: [ :stream |
			   names size = 1
				   ifTrue: [
						   stream << names first << ' is registered in repository ' << aRepository name
						   <<
						   ' but not in the image, so export did not write it; its files in the checkout are left as they are. If it no longer belongs to the repository, repository_update removePackages drops it.' ]
				   ifFalse: [
						   stream << (', ' join: names) << ' are registered in repository ' << aRepository name
						   <<
						   ' but not in the image, so export did not write them; their files in the checkout are left as they are. If they no longer belong to the repository, repository_update removePackages drops them.' ] ]) }
]

{ #category : 'private - execution' }
MCPRepositoryWorkingCopyCommand >> withNonInteractiveAuthorDuring: aBlock [

	^ aBlock value
]

{ #category : 'private - files' }
MCPRepositoryWorkingCopyCommand >> writtenPathsFrom: before to: after newDirectories: directoryPaths [
	"Each file created or changed between the two readings. A package directory that did not exist before is named once, with a trailing slash, as git names an untracked directory; in one that existed, files are named one by one, which a filetree package, a file per method, needs."

	| written |
	written := OrderedCollection new.
	directoryPaths do: [ :each | written add: each , '/' ].
	after keysAndValuesDo: [ :path :bytes |
			((directoryPaths anySatisfy: [ :each | path beginsWith: each , '/' ]) or: [ (before at: path ifAbsent: [ nil ]) = bytes ])
				ifFalse: [ written add: path ] ].
	^ self sortedStringsFrom: written
]
