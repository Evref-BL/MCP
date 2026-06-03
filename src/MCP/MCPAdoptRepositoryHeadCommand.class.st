"
Command wrapper for repository_head_adopt. It asks the Iceberg working copy to adopt the repository head commit so same-image work can continue cleanly after Git commits or fast-forwards.
"
Class {
	#name : 'MCPAdoptRepositoryHeadCommand',
	#superclass : 'Object',
	#instVars : [
		'tool',
		'request'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPAdoptRepositoryHeadCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'private' }
MCPAdoptRepositoryHeadCommand >> commit: leftCommit equals: rightCommit [

	leftCommit ifNil: [ ^ rightCommit isNil ].
	rightCommit ifNil: [ ^ false ].
	^ (self commitIdFrom: leftCommit) = (self commitIdFrom: rightCommit)
]

{ #category : 'private' }
MCPAdoptRepositoryHeadCommand >> commitIdFrom: aCommit [

	^ MCPIcebergCommitInfo idStringFrom: aCommit
]

{ #category : 'executing' }
MCPAdoptRepositoryHeadCommand >> execute [

	| beforeInfo didAdopt headCommit previousReferenceCommit repository result |
	^ self tool
		  executeMutationAction: 'adoptHead'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
				  repository := self request repository.
				  self validateExpectedBranchFor: repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  headCommit := repository headCommit.
				  self validateHeadCommit: headCommit for: repository.
				  previousReferenceCommit := self referenceCommitFor: repository.
				  didAdopt := (self
					               commit: previousReferenceCommit
					               equals: headCommit) not.
				  repository workingCopy adoptCommit: headCommit.
				  result := MCPRepositoryAdoptHeadResult
					            repositoryBefore: beforeInfo
					            after: repository
					            previousReferenceCommit: previousReferenceCommit
					            adoptedCommit: headCommit
					            didAdopt: didAdopt ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Adopted repository HEAD for ' , result repositoryInfo name
					  , '.'
					  data: (self tool dataForRepositoryAdoptHeadResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to adopt repository HEAD: '
				  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPAdoptRepositoryHeadCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'private' }
MCPAdoptRepositoryHeadCommand >> referenceCommitFor: aRepository [

	^ aRepository workingCopy referenceCommit
]

{ #category : 'accessing' }
MCPAdoptRepositoryHeadCommand >> request [

	^ request
]

{ #category : 'private - validation' }
MCPAdoptRepositoryHeadCommand >> signalMissingHeadCommitFor: aRepository [

	MCPCommandError
		signalErrorCode: #RepositoryHeadCommitRequired
		message:
		'Cannot adopt repository HEAD because the repository has no head commit.'
		details: (self request requestedContext copy
				 at: #repositoryName put: aRepository name asString;
				 yourself)
]

{ #category : 'accessing' }
MCPAdoptRepositoryHeadCommand >> tool [

	^ tool
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
		message:
			'Repository branch mismatch. Expected ' , expectedBranchName
			, ' but found ' , actualBranchName , '.'
		details: (self request requestedContext copy
				 at: #actualBranchName put: actualBranchName;
				 at: #expectedBranchName put: expectedBranchName;
				 yourself)
]

{ #category : 'private - validation' }
MCPAdoptRepositoryHeadCommand >> validateHeadCommit: headCommit for: aRepository [

	headCommit ifNil: [ ^ self signalMissingHeadCommitFor: aRepository ].
	(MCPIcebergCommitInfo isNoCommit: headCommit) ifTrue: [
		^ self signalMissingHeadCommitFor: aRepository ].
	^ self
]
