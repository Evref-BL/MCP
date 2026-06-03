"
Command wrapper for repository_branch_checkout. It asks Iceberg to check out the target branch so the repository head and loaded package snapshot move together.
"
Class {
	#name : 'MCPCheckoutRepositoryBranchCommand',
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
MCPCheckoutRepositoryBranchCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPCheckoutRepositoryBranchCommand >> execute [

	| beforeInfo branch repository result |
	^ self tool
		  executeMutationAction: 'checkoutBranch'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
				  repository := self request repository.
				  beforeInfo := MCPRepositoryInfo fromRepository: repository.
				  branch := repository branchNamed: self request branchName.
				  branch checkout.
				  result := MCPRepositoryBranchResult
					            repositoryBefore: beforeInfo
					            after: repository ]
		  successResult: [ :warningMessages |
				  self tool
					  successResultText:
						  'Checked out repository ' , result repositoryInfo name
						  , ' to branch ' , self request branchName , '.'
					  data: (self tool dataForRepositoryCheckoutBranchResult: result)
					  warnings: warningMessages ]
		  failureSummary: [ :error |
				  'Failed to check out repository branch: '
				  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPCheckoutRepositoryBranchCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest
]

{ #category : 'accessing' }
MCPCheckoutRepositoryBranchCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPCheckoutRepositoryBranchCommand >> tool [

	^ tool
]
