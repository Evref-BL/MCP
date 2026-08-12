"
MCP tool that removes one remote from a registered repository.
"
Class {
	#name : 'MCPToolRemoveRepositoryRemote',
	#superclass : 'MCPToolRepositoryRemoteOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolRemoveRepositoryRemote class >> toolName [

	^ 'repository_remote_remove'
]

{ #category : 'private - specs' }
MCPToolRemoveRepositoryRemote >> repositoryToolSpec [

	^ {
		  (#title -> 'Remove Repository Remote').
		  (#description -> 'Remove one remote from a registered repository.').
		  (#action -> 'remoteRemove').
		  (#requestClass -> MCPRepositoryRemoteRequest).
		  (#commandClass -> MCPRemoveRepositoryRemoteCommand).
		  (#inputProperties -> { self remoteNameSchemaProperty }).
		  (#requiredProperties -> #( 'repositoryName' 'remoteName' )) } asDictionary
]
