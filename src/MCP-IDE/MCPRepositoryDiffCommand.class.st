"
Command wrapper for repository_change_list.

It compares each package Iceberg marks modified with the checkout's files, keeping those that differ, reads the checkout's git status, and returns an MCPRepositoryDiffResult without writing the disk working copy or updating the repository index.
"
Class {
	#name : 'MCPRepositoryDiffCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPRepositoryDiffCommand >> execute [

	| changedPackageNames imagePackageNames modifiedPaths repository result |
	^ self
		  executeRepositoryAction: 'diff'
		  work: [
				  repository := self request repository.
				  imagePackageNames := self imageDifferingPackageNamesFor: repository.
				  modifiedPaths := self modifiedPathsFromGitStatusIn: repository.
				  changedPackageNames := self sortedStringsFrom:
					                         imagePackageNames , (self packageNamesFromModifiedPaths: modifiedPaths in: repository).
				  result := MCPRepositoryDiffResult
					            repository: repository
					            changedPackageNames: changedPackageNames
					            imageModifiedPackages: imagePackageNames
					            modifiedPaths: modifiedPaths ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  (String streamContents: [ :stream | stream << 'Computed repository diff for ' << result repositoryInfo name << '.' ])
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed repository diff: ' , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'private - comparing' }
MCPRepositoryDiffCommand >> imageDifferingPackageNamesFor: aRepository [
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

{ #category : 'private - comparing' }
MCPRepositoryDiffCommand >> package: anIcePackage differsIn: sourceRepository writer: aWriterClass [
	"Answer whether the image holds anIcePackage otherwise than the checkout's files do. A package the files lack differs, and so does one that cannot be read or compared: nothing showed it equal."

	^ [
		  (self versionIn: sourceRepository for: anIcePackage writer: aWriterClass)
			  ifNil: [ true ]
			  ifNotNil: [ :version | ((MCPackage named: anIcePackage name) snapshot patchRelativeToBase: version snapshot) isEmpty not ] ]
		  on: Error
		  do: [ true ]
]
