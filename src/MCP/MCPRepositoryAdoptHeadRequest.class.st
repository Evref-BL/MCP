"
Parsed input for repository_head_adopt. It resolves the registered Iceberg repository whose image working copy should adopt the repository HEAD commit, with an optional expected branch guard.
"
Class {
	#name : 'MCPRepositoryAdoptHeadRequest',
	#superclass : 'MCPRepositoryBranchRequest',
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryAdoptHeadRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryAdoptHeadRequest >> commandForTool: aTool [

	^ MCPAdoptRepositoryHeadCommand tool: aTool request: self
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadRequest >> operation [

	^ 'adoptHead'
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'converting' }
MCPRepositoryAdoptHeadRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	self branchName ifNotEmpty: [ :expectedBranchName | context at: #branchName put: expectedBranchName ].
	^ context
]
