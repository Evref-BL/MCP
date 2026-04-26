"
Command wrapper for edit-repository operation=pull. It calls IceRepository>>pull and returns an MCPRepositoryPullResult.
"
Class {
	#name : 'MCPPullRepositoryCommand',
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
MCPPullRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPPullRepositoryCommand >> execute [

	| beforeInfo repository result |
	^ self tool
		  executeEditOperation: 'pull'
		  force: false
		  requestedContext: self request requestedContext
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
				  data: (self tool dataForRepositoryPullResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to pull repository: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPPullRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPPullRepositoryCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPPullRepositoryCommand >> tool [

	^ tool
]
