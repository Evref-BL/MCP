"
MCP tool for discarding all current changes from one registered Iceberg repository working copy.
"
Class {
	#name : 'MCPToolDiscardRepositoryChanges',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolDiscardRepositoryChanges class >> toolName [

	^ 'repository_change_discard'
]

{ #category : 'private - errors' }
MCPToolDiscardRepositoryChanges >> failureSummaryPrefixFor: request [

	^ 'Failed to discard repository changes: '
]

{ #category : 'private - execution' }
MCPToolDiscardRepositoryChanges >> mutateWith: request [
	"Discard what git sees changed and what Iceberg marks modified, then check that nothing is left."

	| discardedPackageNames discardedPaths repository |
	^ self
		  executeOperationFor: request
		  work: [
				  | steps |
				  repository := self repositoryFor: request.
				  steps := MCPRepositoryWorkingCopyCommand new.
				  discardedPaths := steps modifiedPathsFromGitStatusIn: repository.
				  discardedPackageNames := steps changedPackageNamesForRepository: repository modifiedPaths: discardedPaths.
				  (discardedPackageNames isNotEmpty or: [ discardedPaths isNotEmpty ]) ifTrue: [ repository discardChanges ].
				  steps assertRepositoryCleanAfterDiscard: repository ]
		  successResult: [ :warnings |
				  self
					  successResultText: (String streamContents: [ :stream |
								   (discardedPackageNames isNotEmpty or: [ discardedPaths isNotEmpty ])
									   ifTrue: [ stream << 'Discarded the changes of repository ' << repository name << '.' ]
									   ifFalse: [ stream << 'Repository ' << repository name << ' had no changes to discard.' ] ])
					  data: (self dataKeepingNonEmpty: {
								   (#discardedPackages -> discardedPackageNames).
								   (#discardedPaths -> discardedPaths) })
					  warnings: warnings ]
]

{ #category : 'private - specs' }
MCPToolDiscardRepositoryChanges >> toolSpec [

	^ {
		  (#title -> 'Discard Repository Changes').
		  (#description
		   -> 'Discard all current changes in one registered Iceberg repository working copy. Use only when abandoning local changes.').
		  (#action -> 'discard').
		  (#requiredProperties -> #( 'repository' )) } asDictionary
]
