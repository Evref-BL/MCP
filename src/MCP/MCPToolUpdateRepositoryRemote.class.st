"
MCP tool that updates the URL for one repository remote.
"
Class {
	#name : 'MCPToolUpdateRepositoryRemote',
	#superclass : 'MCPToolRepositoryRemoteOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateRepositoryRemote class >> toolName [

	^ 'repository_remote_update'
]

{ #category : 'private - specs' }
MCPToolUpdateRepositoryRemote >> repositoryToolSpec [

	^ {
		  (#title -> 'Update Repository Remote').
		  (#description -> 'Update the URL configured for one repository remote.').
		  (#action -> 'remoteUpdate').
		  (#requestClass -> MCPRepositoryRemoteRequest).
		  (#commandClass -> MCPUpdateRepositoryRemoteCommand).
		  (#inputProperties -> {
			   self remoteNameSchemaProperty.
			   self remoteUrlSchemaProperty }).
		  (#requiredProperties -> #( 'name' 'remoteName' 'remoteUrl' )) } asDictionary
]
