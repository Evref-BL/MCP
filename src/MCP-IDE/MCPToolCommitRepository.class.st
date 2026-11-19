"
Concrete repository_commit tool. It writes the packages of a registered repository to its checkout as repository_export does, then stages and commits every change git sees there, through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolCommitRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCommitRepository class >> toolName [

	^ 'repository_commit'
]

{ #category : 'private - results' }
MCPToolCommitRepository >> dataForPackageNames: packageNames otherFiles: otherFiles [
	"What the commit at HEAD holds, as git show lists its files: the registered packages those files belong to, and the files that belong to none, such as .project or a file written by hand."

	^ self dataKeepingNonEmpty: {
			  (#packages -> packageNames asArray).
			  (#otherFiles -> otherFiles asArray) }
]

{ #category : 'private - errors' }
MCPToolCommitRepository >> failureSummaryPrefixFor: request [

	^ 'Failed to commit repository: '
]

{ #category : 'private - results' }
MCPToolCommitRepository >> keyOrder [

	^ #( packages otherFiles )
]

{ #category : 'private - request' }
MCPToolCommitRepository >> messageIn: request [

	^ (request stringArgumentNamed: 'message') ifNil: [ '' ]
]

{ #category : 'private - execution' }
MCPToolCommitRepository >> mutateWith: request [
	"Write the packages as repository_export does, then stage and commit every change git sees in the checkout."

	| commit repository |
	^ self
		  executeOperationFor: request
		  work: [
				  repository := self repositoryFor: request.
				  commit := MCPCommitRepositoryCommand repository: repository message: (self messageIn: request).
				  commit execute ]
		  successResult: [ :warnings |
				  self
					  successResultText: (self summaryForCommit: commit of: repository)
					  data: (self dataForPackageNames: commit packageNames otherFiles: commit otherFiles)
					  warnings: warnings , (self warningsForCommit: commit of: repository) ]
]

{ #category : 'private - specs' }
MCPToolCommitRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Commit Repository').
		  (#description
		   ->
		   'Write the packages of a registered repository to its checkout as repository_export does, then stage and commit every change git sees there with the given message.').
		  (#action -> 'commit').
		  (#inputProperties -> { self messageSchemaProperty }).
		  (#requiredProperties -> #( 'repository' 'message' )) } asDictionary
]

{ #category : 'private - errors' }
MCPToolCommitRepository >> requestedContextFor: request [

	| context |
	context := (super requestedContextFor: request) copy.
	context at: #message put: (self messageIn: request).
	^ context
]

{ #category : 'private - results' }
MCPToolCommitRepository >> summaryForCommit: aCommit of: aRepository [
	"Name the commit as git log --oneline does, on the branch HEAD is on."

	^ String streamContents: [ :stream |
			  stream << 'Committed repository ' << aRepository name.
			  aCommit branchName
				  ifEmpty: [ stream << ' on detached HEAD: ' ]
				  ifNotEmpty: [ :branch | stream << ' on branch ' << branch << ': ' ].
			  stream << (self shortCommitId: aCommit commitId) << ' ' << aCommit subject ]
]

{ #category : 'private - results' }
MCPToolCommitRepository >> warningsForCommit: aCommit of: aRepository [

	| withoutPackages |
	withoutPackages := aCommit registersNoPackage
		                   ifTrue: [
				                   { (String streamContents: [ :stream |
					                    stream << 'Repository ' << aRepository name
					                    << ' has no packages, so this commit holds only what git saw in its checkout.' ]) } ]
		                   ifFalse: [ #(  ) ].
	^ withoutPackages , (self warningsForUnloadedPackages: aCommit unloadedPackageNames of: aRepository)
]
