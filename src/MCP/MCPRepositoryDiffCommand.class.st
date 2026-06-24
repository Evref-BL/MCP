"
Command wrapper for repository_change_list. It calculates IceRepository>>workingCopyDiff and returns an MCPRepositoryDiffResult without writing the disk working copy or updating the repository index.
"
Class {
	#name : 'MCPRepositoryDiffCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPRepositoryDiffCommand >> execute [

	| changedPackageNames diff modifiedPaths repository result |
	^ self
		  executeRepositoryAction: 'diff'
		  work: [
				  repository := self request repository.
				  diff := repository workingCopyDiff.
				  changedPackageNames := self changedPackageNamesFromDiff: diff.
				  modifiedPaths := self modifiedPathsFromDiff: diff.
				  result := MCPRepositoryDiffResult
					            repository: repository
					            changedPackageNames: changedPackageNames
					            modifiedPaths: modifiedPaths
					            isEmpty: diff isEmpty ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Computed repository diff for ' , result repositoryInfo name
					  , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed repository diff: '
				  , (error messageText ifNil: [ error asString ]) ]
]
