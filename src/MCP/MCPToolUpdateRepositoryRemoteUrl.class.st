"
MCP tool that updates the URL for one repository remote.
"
Class {
	#name : 'MCPToolUpdateRepositoryRemoteUrl',
	#superclass : 'MCPToolRepositoryRemoteOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateRepositoryRemoteUrl class >> toolName [

	^ 'repository_remote_url_update'
]

{ #category : 'private - specs' }
MCPToolUpdateRepositoryRemoteUrl >> repositoryToolSpec [

	^ {
		  (#title -> 'Update Repository Remote URL').
		  (#description
		   -> 'Update the URL configured for one repository remote.').
		  (#action -> 'remoteUrlUpdate').
		  (#requestClass -> MCPRepositoryRemoteRequest).
		  (#commandClass -> MCPUpdateRepositoryRemoteUrlCommand).
		  (#inputProperties -> {
			   self remoteNameSchemaProperty.
			   self remoteUrlSchemaProperty }).
		  (#requiredProperties
		   -> #( 'repositoryName' 'remoteName' 'remoteUrl' )) } asDictionary
]
