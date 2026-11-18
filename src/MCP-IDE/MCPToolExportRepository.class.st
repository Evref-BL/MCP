"
Concrete repository_export tool. It writes the packages of a registered repository to its checkout, in the format the checkout declares, through MCPToolRepositoryOperation, and names the packages and files it wrote, without staging or committing anything.

It refuses a repository that registers no package, or none the image holds. Otherwise it reads the files export may write, writes each loaded package and .project, puts back the files the writer only reordered, and reads the same files again: what differs is what it wrote or deleted, and the packages those files belong to are the ones it wrote. What git sees besides is named as left uncommitted, and the registered packages the image lacks, whose files it leaves as they are, get a warning.
"
Class {
	#name : 'MCPToolExportRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolExportRepository class >> toolName [

	^ 'repository_export'
]

{ #category : 'private - results' }
MCPToolExportRepository >> dataForPackageNames: packageNames writtenPaths: writtenPaths deletedPaths: deletedPaths alsoUncommittedPaths: alsoUncommittedPaths [
	"What export wrote and nothing else: the packages, the files it created or changed, a package directory that did not exist before as one path ending in a slash, the files it deleted, and what git sees besides in the checkout, every path from the checkout root."

	^ self dataKeepingNonEmpty: {
			  (#packages -> packageNames asArray).
			  (#written -> writtenPaths asArray).
			  (#deleted -> deletedPaths asArray).
			  (#alsoUncommitted -> alsoUncommittedPaths asArray) }
]

{ #category : 'metadata' }
MCPToolExportRepository >> defaultExposure [

	^ 'static'
]

{ #category : 'private - errors' }
MCPToolExportRepository >> failureSummaryPrefixFor: request [

	^ 'Failed to export repository: '
]

{ #category : 'private - export' }
MCPToolExportRepository >> filesExportChangedIn: aRepository since: before directories: directoriesBefore with: steps [
	"Read the files again. What differs from before is what export wrote or deleted, and the packages they belong to are those it wrote; what git sees besides is left uncommitted."

	| after deleted newDirectories written |
	newDirectories := (steps existingLoadedPackageDirectoryPathsFor: aRepository) reject: [ :each | directoriesBefore includes: each ].
	after := steps snapshotFilesFor: aRepository.
	written := steps writtenPathsFrom: before to: after newDirectories: newDirectories.
	deleted := steps deletedPathsFrom: before to: after.
	^ {
		  (#packages -> (steps packageNamesForPaths: written , deleted in: aRepository)).
		  (#written -> written).
		  (#deleted -> deleted).
		  (#alsoUncommitted -> (steps alsoUncommittedFrom: (steps uncommittedPathsIn: aRepository) written: written deleted: deleted)) }
		  asDictionary
]

{ #category : 'private - results' }
MCPToolExportRepository >> keyOrder [

	^ #( written deleted alsoUncommitted )
]

{ #category : 'private - results' }
MCPToolExportRepository >> keysStatedInSummary [

	^ #( packages )
]

{ #category : 'private - execution' }
MCPToolExportRepository >> mutateWith: request [
	"Write the packages the image holds and .project to the checkout, put back the files the writer only reordered, and name what was written, staging and committing nothing."

	| files repository unloadedPackageNames |
	^ self
		  executeOperationFor: request
		  work: [
				  | before directoriesBefore steps |
				  repository := self repositoryFor: request.
				  steps := MCPRepositoryWorkingCopyCommand new.
				  self refuseExportWithNothingToWriteFor: repository.
				  directoriesBefore := steps existingLoadedPackageDirectoryPathsFor: repository.
				  before := steps snapshotFilesFor: repository.
				  steps withNonInteractiveAuthorDuring: [
						  steps exportLoadedPackagesFrom: repository.
						  unloadedPackageNames := steps unloadedPackageNamesOf: repository.
						  steps restoreOrderOnlyTonelChurnFor: repository fromSnapshot: before ].
				  files := self
					           filesExportChangedIn: repository
					           since: before
					           directories: directoriesBefore
					           with: steps.
				  steps markLoadedPackagesCleanIn: repository workingCopy ]
		  successResult: [ :warnings |
				  self
					  successResultText: (self summaryForExportOf: repository files: files)
					  data: (self
							   dataForPackageNames: (files at: #packages)
							   writtenPaths: (files at: #written)
							   deletedPaths: (files at: #deleted)
							   alsoUncommittedPaths: (files at: #alsoUncommitted))
					  warnings: warnings , (self warningsForUnloadedPackages: unloadedPackageNames of: repository) ]
]

{ #category : 'private - export' }
MCPToolExportRepository >> refuseExportWithNothingToWriteFor: aRepository [
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
	names := MCPRepositoryCommand new sortedStringsFrom: (packages collect: [ :each | each name ]).
	MCPCommandError
		signalErrorCode: #RepositoryPackagesNotInImage
		message: (String streamContents: [ :stream |
					 stream << 'None of the packages repository ' << aRepository name << ' registers is in the image: ' << (', ' join: names)
					 << '. Export has nothing to write; repository_update removePackages and addPackages correct the list.' ])
		details: {
				(#repository -> aRepository name).
				(#packages -> names) } asDictionary
]

{ #category : 'private - specs' }
MCPToolExportRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Export Repository').
		  (#description
		   ->
		   'Write the packages of a registered repository to its checkout, in the format the checkout declares. It names the files written. Nothing is staged or committed.').
		  (#action -> 'export') } asDictionary
]

{ #category : 'private - results' }
MCPToolExportRepository >> summaryForExportOf: aRepository files: files [
	"Name the packages export wrote; when it wrote no package file, the files it wrote outside every package, such as .project; and otherwise that there was nothing to write."

	| changedPaths |
	changedPaths := (files at: #written) , (files at: #deleted).
	^ String streamContents: [ :stream |
			  stream << 'Exported repository ' << aRepository name << ': '.
			  (files at: #packages) ifNotEmpty: [ :names | stream << 'wrote ' << (', ' join: names) << ', not committed yet.' ] ifEmpty: [
					  changedPaths
						  ifNotEmpty: [ stream << 'wrote ' << (', ' join: changedPaths asArray sort) << ', not committed yet.' ]
						  ifEmpty: [ stream << 'nothing to write, its files already hold what the image has.' ] ] ]
]
