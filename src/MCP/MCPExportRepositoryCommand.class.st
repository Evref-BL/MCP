"
Command wrapper for repository_export. It calculates the repository working copy diff, updates the disk working copy and git index from that diff, and returns an MCPRepositoryExportResult.
"
Class {
	#name : 'MCPExportRepositoryCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPExportRepositoryCommand >> execute [

	| changedPackageNames diff modifiedPaths repository result restoredOrderOnlyPaths tonelSnapshot |
	^ self tool
		  executeMutationAction: 'export'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
				  repository := self request repository.
				  diff := repository workingCopyDiff.
				  changedPackageNames := self changedPackageNamesFromDiff: diff.
				  modifiedPaths := self modifiedPathsFromDiff: diff.
				  tonelSnapshot := self snapshotTonelFilesFor: repository.
				  self withNonInteractiveAuthorDuring: [
						  repository index updateDiskWorkingCopy: diff.
						  restoredOrderOnlyPaths := self
							                            restoreOrderOnlyTonelChurnFor:
							                            repository
							                            fromSnapshot: tonelSnapshot.
						  repository index updateIndex: diff ].
				  result := (MCPRepositoryExportResult
					             repository: repository
					             changedPackageNames: changedPackageNames
					             modifiedPaths: modifiedPaths)
					            restoredOrderOnlyPaths: restoredOrderOnlyPaths;
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

{ #category : 'private - tonel order' }
MCPExportRepositoryCommand >> isTonelMethodOrderFile: aFileReference [

	| basename |
	basename := aFileReference basename.
	^ (basename endsWith: '.class.st') or: [
		  basename endsWith: '.extension.st' ]
]

{ #category : 'private - tonel order' }
MCPExportRepositoryCommand >> isTonelMethodStartAt: anIndex in: lines [

	| line nextLine |
	anIndex >= lines size ifTrue: [ ^ false ].
	line := lines at: anIndex.
	(line beginsWith: '{ #category') ifFalse: [ ^ false ].
	nextLine := lines at: anIndex + 1.
	^ nextLine includesSubstring: ' >> '
]

{ #category : 'private - tonel order' }
MCPExportRepositoryCommand >> relativePathFor: aFileReference under: aDirectory [

	| directoryPath filePath relative |
	directoryPath := aDirectory pathString.
	filePath := aFileReference pathString.
	relative := (filePath beginsWith: directoryPath)
		            ifTrue: [ filePath allButFirst: directoryPath size ]
		            ifFalse: [ aFileReference basename ].
	(relative beginsWith: '/') ifTrue: [
		relative := relative allButFirst ].
	^ relative
]

{ #category : 'private - tonel order' }
MCPExportRepositoryCommand >> repositorySourceDirectoryFor: aRepository [

	| location subdirectory |
	location := aRepository location asFileReference.
	subdirectory := aRepository subdirectory.
	subdirectory ifNil: [ ^ location ].
	subdirectory asString isEmpty ifTrue: [ ^ location ].
	^ location / subdirectory asString
]

{ #category : 'private - tonel order' }
MCPExportRepositoryCommand >> restoreOrderOnlyTonelChurnFor: aRepository fromSnapshot: aSnapshot [

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
MCPExportRepositoryCommand >> snapshotTonelFilesFor: aRepository [

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
MCPExportRepositoryCommand >> tonelFilesIn: aDirectory do: aBlock [

	aDirectory children do: [ :child |
			child isDirectory
				ifTrue: [ self tonelFilesIn: child do: aBlock ]
				ifFalse: [
					(self isTonelMethodOrderFile: child) ifTrue: [
						aBlock value: child ] ] ]
]

{ #category : 'private - tonel order' }
MCPExportRepositoryCommand >> tonelMethodOrderEquivalent: beforeContents to: afterContents [

	^ (self tonelMethodOrderSignatureFor: beforeContents)
	  = (self tonelMethodOrderSignatureFor: afterContents)
]

{ #category : 'private - tonel order' }
MCPExportRepositoryCommand >> tonelMethodOrderSignatureFor: contents [

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
		  (#methods -> chunks asSortedCollection asArray) } asDictionary
]
