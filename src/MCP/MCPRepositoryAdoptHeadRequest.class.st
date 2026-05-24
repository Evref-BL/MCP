"
Parsed input for edit-repository operation=adoptHead. It resolves the registered Iceberg repository whose image working copy should adopt the repository HEAD commit, with an optional expected branch guard.
"
Class {
	#name : 'MCPRepositoryAdoptHeadRequest',
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
MCPRepositoryAdoptHeadRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadRequest >> branchName [

	^ branchName ifNil: [ '' ]
]

{ #category : 'initialization' }
MCPRepositoryAdoptHeadRequest >> initializeFromRequest: request [

	repositoryReference := MCPRepositoryReferenceSpec fromRequest:
		                       request.
	branchName := request stringArgumentNamed: 'branchName'.
	^ self
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadRequest >> operation [

	^ 'adoptHead'
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'accessing' }
MCPRepositoryAdoptHeadRequest >> repositoryReference [

	^ repositoryReference
]

{ #category : 'converting' }
MCPRepositoryAdoptHeadRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	self branchName ifNotEmpty: [ :expectedBranchName |
		context at: #branchName put: expectedBranchName ].
	^ context
]
