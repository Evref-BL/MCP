"
Command wrapper for edit-repository operation=fetch. It calls IceRepository>>fetch and returns an MCPRepositoryFetchResult.
"
Class {
	#name : 'MCPFetchRepositoryCommand',
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
MCPFetchRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPFetchRepositoryCommand >> execute [

	| beforeInfo repository result |
	^ self tool
		  executeEditOperation: 'fetch'
		  force: false
		  requestedContext: self request requestedContext
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

{ #category : 'initialization' }
MCPFetchRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPFetchRepositoryCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPFetchRepositoryCommand >> tool [

	^ tool
]
