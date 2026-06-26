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
				  repository pull.
				  result := MCPRepositoryPullResult
					            repositoryBefore: beforeInfo
					            after: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Pulled repository ' , result repositoryInfo name , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to pull repository: '
				  , (error messageText ifNil: [ error asString ]) ]
]
