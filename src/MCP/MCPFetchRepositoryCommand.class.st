"
Command wrapper for repository_fetch. It calls IceRepository>>fetch and returns an MCPRepositoryFetchResult.
"
Class {
	#name : 'MCPFetchRepositoryCommand',
	#superclass : 'MCPRepositoryCommand',
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'executing' }
MCPFetchRepositoryCommand >> execute [

	| beforeInfo repository result |
	^ self
		  executeRepositoryAction: 'fetch'
		  work: [
				  repository := self request repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  repository fetch.
				  result := MCPRepositoryFetchResult
					            repositoryBefore: beforeInfo
					            after: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
					  'Fetched repository ' , result repositoryInfo name , '.'
					  data: (self tool dataForRepositoryFetchResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to fetch repository: '
				  , (error messageText ifNil: [ error asString ]) ]
]
