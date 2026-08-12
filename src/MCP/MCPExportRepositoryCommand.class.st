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

	| changedPackageNames modifiedPaths repository result restoredOrderOnlyPaths tonelSnapshot |
	^ self
		  executeRepositoryAction: 'export'
		  work: [
				  repository := self request repository.
				  tonelSnapshot := self snapshotTonelFilesFor: repository.
				  self withNonInteractiveAuthorDuring: [
						  self exportLoadedPackagesFrom: repository.
						  restoredOrderOnlyPaths := self restoreOrderOnlyTonelChurnFor: repository fromSnapshot: tonelSnapshot ].
				  modifiedPaths := self modifiedPathsFromGitStatusIn: repository.
				  changedPackageNames := self changedPackageNamesForRepository: repository modifiedPaths: modifiedPaths.
				  self markLoadedPackagesCleanIn: repository workingCopy.
				  result := (MCPRepositoryExportResult
					             repository: repository
					             changedPackageNames: changedPackageNames
					             modifiedPaths: modifiedPaths)
					            restoredOrderOnlyPaths: restoredOrderOnlyPaths;
					            didChange: (changedPackageNames isNotEmpty or: [ modifiedPaths isNotEmpty ]);
					            yourself ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: 'Exported repository ' , result repositoryInfo name , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed to export repository: ' , (error messageText ifNil: [ error asString ]) ]
]
