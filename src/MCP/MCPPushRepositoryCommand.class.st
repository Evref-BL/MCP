"
Command wrapper for edit-repository operation=push. It calls IceRepository>>push and returns an MCPRepositoryPushResult.
"
Class {
	#name : 'MCPPushRepositoryCommand',
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
MCPPushRepositoryCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPPushRepositoryCommand >> execute [

	| repository result |
	^ self tool
		  executeEditOperation: 'push'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self request repository.
			  repository push.
			  result := MCPRepositoryPushResult repository: repository ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
				  'Pushed repository ' , result repositoryInfo name , '.'
				  data: (self tool dataForRepositoryPushResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to push repository: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPPushRepositoryCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPPushRepositoryCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPPushRepositoryCommand >> tool [

	^ tool
]
