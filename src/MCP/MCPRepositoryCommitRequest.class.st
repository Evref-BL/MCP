"
Parsed input for repository_commit. It resolves the registered Iceberg repository to commit and carries the required commit message.
"
Class {
	#name : 'MCPRepositoryCommitRequest',
	#superclass : 'MCPRepositoryRequest',
	#instVars : [
		'message'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryCommitRequest class >> fromRequest: request tool: aTool [

	^ self new initializeFromRequest: request
]

{ #category : 'converting' }
MCPRepositoryCommitRequest >> commandForTool: aTool [

	^ MCPCommitRepositoryCommand tool: aTool request: self
]

{ #category : 'initialization' }
MCPRepositoryCommitRequest >> initializeFromRequest: request [

	super initializeFromRequest: request.
	message := request stringArgumentNamed: 'message'
]

{ #category : 'accessing' }
MCPRepositoryCommitRequest >> message [

	^ message ifNil: [ '' ]
]

{ #category : 'accessing' }
MCPRepositoryCommitRequest >> operation [

	^ 'commit'
]

{ #category : 'accessing' }
MCPRepositoryCommitRequest >> repository [

	^ self repositoryReference repository
]

{ #category : 'converting' }
MCPRepositoryCommitRequest >> requestedContext [

	| context |
	context := self repositoryReference requestedContext copy.
	context at: #message put: self message.
	^ context
]
