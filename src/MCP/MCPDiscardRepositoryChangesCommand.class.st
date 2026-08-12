"
Command that discards all current changes in one registered Iceberg repository working copy.
"
Class {
	#name : 'MCPDiscardRepositoryChangesCommand',
	#superclass : 'MCPRepositoryWorkingCopyCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'private - validation' }
MCPDiscardRepositoryChangesCommand >> assertRepositoryCleanAfterDiscard: aRepository [

	| remainingPackageNames remainingPaths |
	remainingPaths := self modifiedPathsFromGitStatusIn: aRepository.
	remainingPackageNames := self changedPackageNamesForRepository: aRepository modifiedPaths: remainingPaths.
	(remainingPackageNames isEmpty and: [ remainingPaths isEmpty ]) ifFalse: [
			MCPCommandError signalErrorCode: 'RepositoryDiscardIncomplete' message: 'Repository changes remain after discard.' details: {
					(#remainingPackageNames -> remainingPackageNames).
					(#remainingPaths -> remainingPaths) } asDictionary ]
]

{ #category : 'executing' }
MCPDiscardRepositoryChangesCommand >> execute [

	| discardedPackageNames discardedPaths repository result |
	^ self
		  executeRepositoryAction: 'discard'
		  work: [
				  repository := self request repository.
				  discardedPaths := self modifiedPathsFromGitStatusIn: repository.
				  discardedPackageNames := self changedPackageNamesForRepository: repository modifiedPaths: discardedPaths.
				  (discardedPackageNames isNotEmpty or: [ discardedPaths isNotEmpty ]) ifTrue: [ repository discardChanges ].
				  result := MCPRepositoryDiscardResult discardedPackageNames: discardedPackageNames discardedPaths: discardedPaths.
				  self assertRepositoryCleanAfterDiscard: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: 'Discarded repository changes for ' , repository name , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed repository discard: ' , (error messageText ifNil: [ error asString ]) ]
]
