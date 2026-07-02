"
Request for repository remote-management operations on one registered Iceberg repository.
"
Class {
	#name : 'MCPRepositoryRemoteRequest',
	#superclass : 'MCPRepositoryRequest',
	#instVars : [
		'remoteName',
		'remoteUrl',
		'newRemoteName',
		'operation'
	],
	#category : 'MCP-Requests',
	#package : 'MCP',
	#tag : 'Requests'
}

{ #category : 'instance creation' }
MCPRepositoryRemoteRequest class >> fromRequest: request tool: aTool [

	^ self new
		  operation: (aTool repositoryToolSpec at: #action);
		  initializeFromRequest: request
]

{ #category : 'initialization' }
MCPRepositoryRemoteRequest >> initializeFromRequest: request [

	super initializeFromRequest: request.
	remoteName := request stringArgumentNamed: 'remoteName'.
	remoteUrl := request stringArgumentNamed: 'remoteUrl'.
	newRemoteName := request stringArgumentNamed: 'newRemoteName'
]

{ #category : 'accessing' }
MCPRepositoryRemoteRequest >> newRemoteName [

	^ newRemoteName
]

{ #category : 'accessing' }
MCPRepositoryRemoteRequest >> operation [

	^ operation
]

{ #category : 'accessing' }
MCPRepositoryRemoteRequest >> operation: aString [

	operation := aString
]

{ #category : 'accessing' }
MCPRepositoryRemoteRequest >> remoteName [

	^ remoteName
]

{ #category : 'accessing' }
MCPRepositoryRemoteRequest >> remoteUrl [

	^ remoteUrl
]

{ #category : 'accessing' }
MCPRepositoryRemoteRequest >> repository [

	^ self repositoryReference repository
]
