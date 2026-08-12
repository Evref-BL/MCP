"
Command wrapper for repository_pull. It calls IceRepository>>pull and returns an MCPRepositoryPullResult.
"
Class {
	#name : 'MCPPullRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPPullRepositoryCommand >> execute [

	| beforeInfo repository result |
	^ self
		  executeRepositoryAction: 'pull'
		  work: [
				  repository := self request repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  (self repositorySupportsExternalGitOperations: repository)
					  ifTrue: [
							  self
								  runGitArguments: #( 'pull' '--ff-only' )
								  in: repository
								  ifFailed: [ :gitResult | self signalGitCommandFailed: gitResult action: 'pull' ].
							  self loadLoadedPackagesFromDiskIn: repository ]
					  ifFalse: [ repository branch pull ].
				  result := MCPRepositoryPullResult repositoryBefore: beforeInfo after: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText: 'Pulled repository ' , result repositoryInfo name , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error | 'Failed to pull repository: ' , (error messageText ifNil: [ error asString ]) ]
]
