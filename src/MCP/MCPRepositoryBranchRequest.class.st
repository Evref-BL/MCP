"
Abstract request DTO for repository operations that target an existing repository and branch.
"
Class {
	#name : 'MCPRepositoryBranchRequest',
	#superclass : 'MCPRepositoryRequest',
	#instVars : [
		'branchName'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'testing' }
MCPRepositoryBranchRequest class >> isAbstract [

	^ self == MCPRepositoryBranchRequest
]

{ #category : 'accessing' }
MCPRepositoryBranchRequest >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryBranchRequest >> initializeFromRequest: request [

	super initializeFromRequest: request.
	branchName := request stringArgumentNamed: 'branchName'
]

{ #category : 'converting' }
MCPRepositoryBranchRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	context at: #branchName put: self branchName.
	^ context
]
