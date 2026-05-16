"
Parsed input for edit-repository operation=switchBranch. It resolves the registered Iceberg repository and carries the required branch name to switch to.
"
Class {
	#name : 'MCPRepositorySwitchBranchRequest',
	#superclass : 'Object',
	#instVars : [
		'repositoryReference',
		'branchName'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositorySwitchBranchRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPRepositorySwitchBranchRequest >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositorySwitchBranchRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	branchName := request stringArgumentNamed: 'branchName'.
	^ self
]

{ #category : 'accessing' }
MCPRepositorySwitchBranchRequest >> operation [

	^ 'switchBranch'
]

{ #category : 'accessing' }
MCPRepositorySwitchBranchRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositorySwitchBranchRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositorySwitchBranchRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	context at: #branchName put: self branchName.
	^ context
]
