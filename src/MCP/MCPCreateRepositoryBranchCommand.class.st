"
Command wrapper for edit-repository operation=createBranch. It calls IceRepository>>createBranch: and returns an MCPRepositoryBranchResult.
"
Class {
	#name : 'MCPCreateRepositoryBranchCommand',
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
MCPCreateRepositoryBranchCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPCreateRepositoryBranchCommand >> execute [

	| beforeInfo repository result |
	^ self tool
		  executeEditOperation: 'createBranch'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self request repository.
			  beforeInfo := MCPRepositoryInfo fromRepository: repository.
			  repository createBranch: self request branchName.
			  result := MCPRepositoryBranchResult
				            repositoryBefore: beforeInfo
				            after: repository ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Created branch ' , self request branchName , ' in repository '
					  , result repositoryInfo name , '.'
				  data: (self tool dataForRepositoryCreateBranchResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to create repository branch: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPCreateRepositoryBranchCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPCreateRepositoryBranchCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPCreateRepositoryBranchCommand >> tool [

	^ tool
]
