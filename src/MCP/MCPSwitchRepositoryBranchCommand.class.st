"
Command wrapper for edit-repository operation=switchBranch. It calls IceRepository>>switchToBranchNamed: and returns an MCPRepositoryBranchResult.
"
Class {
	#name : 'MCPSwitchRepositoryBranchCommand',
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
MCPSwitchRepositoryBranchCommand class >> tool: aTool request: aRequest [

	^ self new initializeTool: aTool request: aRequest
]

{ #category : 'executing' }
MCPSwitchRepositoryBranchCommand >> execute [

	| beforeInfo repository result |
	^ self tool
		  executeEditOperation: 'switchBranch'
		  force: false
		  requestedContext: self request requestedContext
		  work: [
			  repository := self request repository.
			  beforeInfo := MCPRepositoryInfo fromRepository: repository.
			  repository switchToBranchNamed: self request branchName.
			  result := MCPRepositoryBranchResult
				            repositoryBefore: beforeInfo
				            after: repository ]
		  successResult: [ :warningMessages |
			  self tool
				  successResultText:
					  'Switched repository ' , result repositoryInfo name
					  , ' to branch ' , self request branchName , '.'
				  data: (self tool dataForRepositorySwitchBranchResult: result)
				  warnings: warningMessages ]
		  failureSummary: [ :error |
			  'Failed to switch repository branch: '
			  , (error messageText ifNil: [ error asString ]) ]
]

{ #category : 'initialization' }
MCPSwitchRepositoryBranchCommand >> initializeTool: aTool request: aRequest [

	tool := aTool.
	request := aRequest.
	^ self
]

{ #category : 'accessing' }
MCPSwitchRepositoryBranchCommand >> request [

	^ request
]

{ #category : 'accessing' }
MCPSwitchRepositoryBranchCommand >> tool [

	^ tool
]
