"
Command wrapper for repository_export. It refuses a repository that registers no package, or none the image holds. Otherwise it reads the files export may write, writes each loaded package and .project, puts back the files the writer only reordered, and reads the same files again: what differs is what it wrote or deleted. What git sees besides is answered as left uncommitted. Nothing is staged or committed.
"
Class {
	#name : 'MCPExportRepositoryCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPExportRepositoryCommand >> execute [

	| before directoriesBefore exportWarnings repository result |
	^ self
		  executeRepositoryAction: 'export'
		  work: [
				  repository := self request repository.
				  self refuseExportWithNothingToWriteFor: repository.
				  directoriesBefore := self existingLoadedPackageDirectoryPathsFor: repository.
				  before := self snapshotFilesFor: repository.
				  self withNonInteractiveAuthorDuring: [
						  exportWarnings := self exportLoadedPackagesFrom: repository.
						  self restoreOrderOnlyTonelChurnFor: repository fromSnapshot: before ].
				  result := MCPRepositoryExportResult repository: repository.
				  self
					  record: result
					  filesWrittenSince: before
					  directories: directoriesBefore
					  in: repository.
				  self markLoadedPackagesCleanIn: repository workingCopy ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (self tool summaryForExportResult: result)
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages , exportWarnings ]
		  failureSummary: [ :error | 'Failed to export repository: ' , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'private - export' }
MCPExportRepositoryCommand >> record: anExportResult filesWrittenSince: before directories: directoriesBefore in: aRepository [
	"Read the files again. What differs from before is what export wrote or deleted, and the packages they belong to are those it wrote; what git sees besides is left uncommitted."

	| after deleted newDirectories written |
	newDirectories := (self existingLoadedPackageDirectoryPathsFor: aRepository) reject: [ :each | directoriesBefore includes: each ].
	after := self snapshotFilesFor: aRepository.
	written := self writtenPathsFrom: before to: after newDirectories: newDirectories.
	deleted := self deletedPathsFrom: before to: after.
	anExportResult
		packageNames: (self packageNamesForPaths: written , deleted in: aRepository);
		writtenPaths: written;
		deletedPaths: deleted;
		alsoUncommittedPaths: (self alsoUncommittedFrom: (self uncommittedPathsIn: aRepository) written: written deleted: deleted)
]

{ #category : 'private - export' }
MCPExportRepositoryCommand >> refuseExportWithNothingToWriteFor: aRepository [
	"Export writes the packages the image holds, so a repository that registers none, or none the image holds, gets a refusal before anything is read or written."

	| names packages |
	packages := aRepository workingCopy packages.
	packages ifEmpty: [
			MCPCommandError
				signalErrorCode: #RepositoryHasNoPackages
				message: (String streamContents: [ :stream |
							 stream << 'Repository ' << aRepository name
							 << ' has no packages, so export has nothing to write. Add them with repository_update addPackages, then export again.' ])
				details: { (#repository -> aRepository name) } asDictionary ].
	(packages anySatisfy: [ :each | each isLoaded ]) ifTrue: [ ^ self ].
	names := self sortedStringsFrom: (packages collect: [ :each | each name ]).
	MCPCommandError
		signalErrorCode: #RepositoryPackagesNotInImage
		message: (String streamContents: [ :stream |
					 stream << 'None of the packages repository ' << aRepository name << ' registers is in the image: ' << (', ' join: names)
					 << '. Export has nothing to write; repository_update removePackages and addPackages correct the list.' ])
		details: {
				(#repository -> aRepository name).
				(#packages -> names) } asDictionary
]
