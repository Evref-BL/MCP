"
Command wrapper for repository_push. It calls IceRepository>>push and returns an MCPRepositoryPushResult.
"
Class {
	#name : 'MCPPushRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPPushRepositoryCommand >> execute [

	| repository result |
	^ self
		  executeRepositoryAction: 'push'
		  work: [
				  repository := self request repository.
				  repository push.
				  result := MCPRepositoryPushResult repository: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Pushed repository ' , result repositoryInfo name , '.'
					  data: (self tool dataForRepositoryResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to push repository: '
				  , (error messageText ifNil: [ error asString ]) ]
]
