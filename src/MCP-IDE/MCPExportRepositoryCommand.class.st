"
Command wrapper for repository_export. It refuses a repository that registers no package, or none the image holds. Otherwise it reads the files export may write, writes each loaded package and .project, puts back the files the writer only reordered, and reads the same files again: what differs is what it wrote or deleted. What git sees besides is answered as left uncommitted. Nothing is staged or committed.
"
Class {
	#name : 'MCPExportRepositoryCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#instVars : [
		'repository',
		'packageNames',
		'writtenPaths',
		'deletedPaths',
		'alsoUncommittedPaths',
		'unloadedPackageNames'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPExportRepositoryCommand class >> repository: aRepository [

	^ self new initializeRepository: aRepository
]

{ #category : 'accessing' }
MCPExportRepositoryCommand >> alsoUncommittedPaths [

	^ alsoUncommittedPaths
]

{ #category : 'accessing' }
MCPExportRepositoryCommand >> deletedPaths [

	^ deletedPaths
]

{ #category : 'executing' }
MCPExportRepositoryCommand >> execute [
	"Write the packages the image holds and .project to the checkout, put back the files the writer only reordered, and read back what changed."

	| before directoriesBefore |
	self refuseExportWithNothingToWriteFor: repository.
	directoriesBefore := self existingLoadedPackageDirectoryPathsFor: repository.
	before := self snapshotFilesFor: repository.
	self withNonInteractiveAuthorDuring: [
			self exportLoadedPackagesFrom: repository.
			unloadedPackageNames := self unloadedPackageNamesOf: repository.
			self restoreOrderOnlyTonelChurnFor: repository fromSnapshot: before ].
	self recordFilesWrittenSince: before directories: directoriesBefore.
	self markLoadedPackagesCleanIn: repository workingCopy
]

{ #category : 'initialization' }
MCPExportRepositoryCommand >> initializeRepository: aRepository [

	repository := aRepository
]

{ #category : 'accessing' }
MCPExportRepositoryCommand >> packageNames [

	^ packageNames
]

{ #category : 'private - export' }
MCPExportRepositoryCommand >> recordFilesWrittenSince: before directories: directoriesBefore [
	"Read the files again. What differs from before is what export wrote or deleted, and the packages they belong to are those it wrote; what git sees besides is left uncommitted."

	| after newDirectories |
	newDirectories := (self existingLoadedPackageDirectoryPathsFor: repository) reject: [ :each | directoriesBefore includes: each ].
	after := self snapshotFilesFor: repository.
	writtenPaths := self writtenPathsFrom: before to: after newDirectories: newDirectories.
	deletedPaths := self deletedPathsFrom: before to: after.
	packageNames := self packageNamesForPaths: writtenPaths , deletedPaths in: repository.
	alsoUncommittedPaths := self
		                        alsoUncommittedFrom: (self uncommittedPathsIn: repository)
		                        written: writtenPaths
		                        deleted: deletedPaths
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

{ #category : 'accessing' }
MCPExportRepositoryCommand >> unloadedPackageNames [

	^ unloadedPackageNames
]

{ #category : 'accessing' }
MCPExportRepositoryCommand >> writtenPaths [

	^ writtenPaths
]
