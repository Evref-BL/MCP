"
Command wrapper for repository_change_list.

It reads the image's modified packages and the checkout's git status, and returns an MCPRepositoryDiffResult without writing the disk working copy or updating the repository index.
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
				  imagePackageNames := self imageModifiedPackageNamesFor: repository.
				  modifiedPaths := self modifiedPathsFromGitStatusIn: repository.
				  changedPackageNames := self changedPackageNamesForRepository: repository modifiedPaths: modifiedPaths.
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
