"
Command wrapper for repository_head_adopt. It asks the Iceberg working copy to adopt the repository head commit so same-image work can continue cleanly after Git commits or fast-forwards.
"
Class {
	#name : 'MCPAdoptRepositoryHeadCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPAdoptRepositoryHeadCommand >> execute [

	| beforeInfo didAdopt headCommit repository result |
	^ self
		  executeRepositoryAction: 'adoptHead'
		  work: [
				  repository := self request repository.
				  self validateExpectedBranchFor: repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  headCommit := repository headCommit.
				  self validateHeadCommit: headCommit for: repository.
				  didAdopt := (self commit: (self referenceCommitFor: repository) equals: headCommit) not.
				  self adoptHeadCommit: headCommit for: repository.
				  result := MCPRepositoryAdoptHeadResult
					            repositoryBefore: beforeInfo
					            after: repository
					            adoptedCommit: headCommit
					            didAdopt: didAdopt ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: (self summaryForAdoptHeadResult: result)
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed to adopt repository HEAD: ' , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'private - validation' }
MCPAdoptRepositoryHeadCommand >> signalMissingHeadCommitFor: aRepository [

	MCPCommandError
		signalErrorCode: #RepositoryHeadCommitRequired
		message: 'Cannot adopt repository HEAD because the repository has no head commit.'
		details: (self request requestedContext copy
				 at: #name put: aRepository name asString;
				 yourself)
]

{ #category : 'private - results' }
MCPAdoptRepositoryHeadCommand >> summaryForAdoptHeadResult: anAdoptHeadResult [

	^ String streamContents: [ :stream |
			  stream << 'Repository ' << anAdoptHeadResult repositoryInfo name << (anAdoptHeadResult didAdopt
				   ifTrue: [ ' now refers to ' ]
				   ifFalse: [ ' already referred to ' ]).
			  anAdoptHeadResult isDetachedHead
				  ifTrue: [ stream << 'its detached HEAD ' << (self shortCommitId: anAdoptHeadResult adoptedCommitId) ]
				  ifFalse: [
				  stream << 'HEAD ' << (self shortCommitId: anAdoptHeadResult adoptedCommitId) << ' on branch '
				  << anAdoptHeadResult branchName ].
			  anAdoptHeadResult unmarkedPackageNames
				  ifEmpty: [ stream << '.' ]
				  ifNotEmpty: [ :names | stream << ', and no longer marks ' << (', ' join: names) << ' as modified.' ] ]
]

{ #category : 'private - validation' }
MCPAdoptRepositoryHeadCommand >> validateExpectedBranchFor: aRepository [

	| actualBranchName expectedBranchName |
	expectedBranchName := self request branchName.
	expectedBranchName ifEmpty: [ ^ self ].
	actualBranchName := aRepository branchName asString.
	actualBranchName = expectedBranchName ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #RepositoryBranchMismatch
		message: (String streamContents: [ :stream |
				 stream << 'Repository branch mismatch. Expected ' << expectedBranchName << ' but found ' << actualBranchName << '.' ])
		details: (self request requestedContext copy
				 at: #actualBranch put: actualBranchName;
				 at: #expectedBranch put: expectedBranchName;
				 yourself)
]

{ #category : 'private - validation' }
MCPAdoptRepositoryHeadCommand >> validateHeadCommit: headCommit for: aRepository [

	headCommit ifNil: [ ^ self signalMissingHeadCommitFor: aRepository ].
	(MCPIcebergCommitInfo isNoCommit: headCommit) ifTrue: [ ^ self signalMissingHeadCommitFor: aRepository ].
	^ self
]
