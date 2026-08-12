"
MCP tool that adds one remote to a registered repository.
"
Class {
	#name : 'MCPToolAddRepositoryRemote',
	#superclass : 'MCPToolRepositoryRemoteOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolAddRepositoryRemote class >> toolName [

	^ 'repository_remote_add'
]

{ #category : 'private - specs' }
MCPToolAddRepositoryRemote >> repositoryToolSpec [

	^ {
		  (#title -> 'Add Repository Remote').
		  (#description -> 'Add one remote to a registered repository.').
		  (#action -> 'remoteAdd').
		  (#requestClass -> MCPRepositoryRemoteRequest).
		  (#commandClass -> MCPAddRepositoryRemoteCommand).
		  (#inputProperties -> {
			   self remoteNameSchemaProperty.
			   self remoteUrlSchemaProperty }).
		  (#requiredProperties -> #( 'repositoryName' 'remoteName' 'remoteUrl' )) } asDictionary
]
