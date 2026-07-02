"
MCP tool that renames one repository remote.
"
Class {
	#name : 'MCPToolUpdateRepositoryRemoteName',
	#superclass : 'MCPToolRepositoryRemoteOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateRepositoryRemoteName class >> toolName [

	^ 'repository_remote_name_update'
]

{ #category : 'private - specs' }
MCPToolUpdateRepositoryRemoteName >> repositoryToolSpec [

	^ {
		  (#title -> 'Update Repository Remote Name').
		  (#description -> 'Rename one repository remote.').
		  (#action -> 'remoteNameUpdate').
		  (#requestClass -> MCPRepositoryRemoteRequest).
		  (#commandClass -> MCPUpdateRepositoryRemoteNameCommand).
		  (#inputProperties -> {
			   self remoteNameSchemaProperty.
			   self newRemoteNameSchemaProperty }).
		  (#requiredProperties
		   -> #( 'repositoryName' 'remoteName' 'newRemoteName' )) }
		  asDictionary
]
