"
Lets the image continue from a commit or fast-forward git made outside it.
"
Class {
	#name : 'MCPToolAdoptRepositoryHead',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolAdoptRepositoryHead class >> toolName [

	^ 'repository_head_adopt'
]

{ #category : 'private - validation' }
MCPToolAdoptRepositoryHead >> checkBranchOf: aRepository for: request [
	"The branch argument is a guard: the call fails when the repository is on another branch, and never switches."

	| actualBranchName expectedBranchName |
	expectedBranchName := self expectedBranchNameIn: request.
	expectedBranchName ifEmpty: [ ^ self ].
	actualBranchName := aRepository branchName asString.
	actualBranchName = expectedBranchName ifTrue: [ ^ self ].
	MCPCommandError
		signalErrorCode: #RepositoryBranchMismatch
		message: (String streamContents: [ :stream |
				 stream << 'Repository branch mismatch. Expected ' << expectedBranchName << ' but found ' << actualBranchName << '.' ])
		details: ((self requestedContextFor: request) copy
				 at: #actualBranch put: actualBranchName;
				 at: #expectedBranch put: expectedBranchName;
				 yourself)
]

{ #category : 'private - validation' }
MCPToolAdoptRepositoryHead >> checkHeadCommit: headCommit of: aRepository for: request [

	(headCommit isNil or: [ MCPIcebergCommitInfo isNoCommit: headCommit ]) ifFalse: [ ^ self ].
	MCPCommandError
		signalErrorCode: #RepositoryHeadCommitRequired
		message: 'Cannot adopt repository HEAD because the repository has no head commit.'
		details: ((self requestedContextFor: request) copy
				 at: #name put: aRepository name asString;
				 yourself)
]

{ #category : 'private - results' }
MCPToolAdoptRepositoryHead >> dataForUnmarkedPackageNames: unmarkedNames modifiedPackageNames: modifiedNames [

	^ self dataKeepingNonEmpty: {
			  (#unmarkedPackages -> unmarkedNames).
			  (#modifiedPackages -> modifiedNames) }
]

{ #category : 'private - errors' }
MCPToolAdoptRepositoryHead >> failureSummaryPrefixFor: request [

	^ 'Failed to adopt repository HEAD: '
]

{ #category : 'private - results' }
MCPToolAdoptRepositoryHead >> keysStatedInSummary [

	^ #( unmarkedPackages modifiedPackages )
]

{ #category : 'private - execution' }
MCPToolAdoptRepositoryHead >> mutateWith: request [
	"Make the HEAD commit the working copy's reference, and mark the loaded packages whose image differs from it: a mark clears where the image holds what HEAD holds, and stays on the changes HEAD lacks."

	| afterInfo beforeInfo didAdopt headCommit |
	^ self
		  executeOperationFor: request
		  work: [
				  | repository steps |
				  repository := self repositoryFor: request.
				  self checkBranchOf: repository for: request.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  headCommit := repository headCommit.
				  self checkHeadCommit: headCommit of: repository for: request.
				  steps := MCPRepositoryCommand new.
				  didAdopt := (steps commit: (steps referenceCommitFor: repository) equals: headCommit) not.
				  steps adoptHeadCommit: headCommit for: repository.
				  afterInfo := MCPRepositoryInfo fromRepository: repository ]
		  successResult: [ :warnings |
				  | unmarked |
				  unmarked := self packageNamesMarkedIn: beforeInfo andNotIn: afterInfo.
				  self
					  successResultText: (self
							   summaryForAdopting: (MCPIcebergCommitInfo idStringFrom: headCommit)
							   in: afterInfo
							   moved: didAdopt
							   unmarking: unmarked)
					  data: (self dataForUnmarkedPackageNames: unmarked modifiedPackageNames: afterInfo modifiedPackageNames)
					  warnings: warnings ]
]

{ #category : 'private - results' }
MCPToolAdoptRepositoryHead >> packageNamesMarkedIn: beforeInfo andNotIn: afterInfo [
	"The packages adopting no longer marks modified: those whose image holds what HEAD holds."

	| stillMarked |
	stillMarked := afterInfo modifiedPackageNames.
	^ (beforeInfo modifiedPackageNames reject: [ :each | stillMarked includes: each ]) asArray
]

{ #category : 'private - results' }
MCPToolAdoptRepositoryHead >> summaryForAdopting: aCommitId in: anInfo moved: didAdopt unmarking: packageNames [

	^ String streamContents: [ :stream |
			  stream << 'Repository ' << anInfo name << (didAdopt
				   ifTrue: [ ' now refers to ' ]
				   ifFalse: [ ' already referred to ' ]).
			  anInfo isDetachedHead
				  ifTrue: [ stream << 'its detached HEAD ' << (self shortCommitId: aCommitId) ]
				  ifFalse: [ stream << 'HEAD ' << (self shortCommitId: aCommitId) << ' on branch ' << anInfo branchName ].
			  packageNames
				  ifEmpty: [ stream << '.' ]
				  ifNotEmpty: [ :names | stream << ', and no longer marks ' << (', ' join: names) << ' as modified.' ].
			  anInfo modifiedPackageNames ifNotEmpty: [ :names |
				  stream << ' It marks ' << (', ' join: names) << ' as modified: the image differs from HEAD there.' ] ]
]

{ #category : 'private - specs' }
MCPToolAdoptRepositoryHead >> toolSpec [

	^ {
		  (#title -> 'Adopt Repository Head').
		  (#description -> 'Align the image working-copy reference with the repository HEAD commit.').
		  (#action -> 'adoptHead').
		  (#inputProperties -> { self branchNameSchemaProperty }).
		  (#requiredProperties -> #( 'repository' )) } asDictionary
]
