"
Concrete repository_push tool. It pushes local commits for a registered Iceberg repository through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolPushRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolPushRepository class >> toolName [

	^ 'repository_push'
]

{ #category : 'spec' }
MCPToolPushRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Push Repository').
		  (#description -> 'Push local commits for a registered Iceberg repository.').
		  (#action -> 'push').
		  (#requestClass -> MCPRepositoryPushRequest).
		  (#commandClass -> MCPPushRepositoryCommand).
		  (#inputProperties
		   ->
		   { (self
			    schemaPropertyNamed: 'remoteName'
			    type: 'string'
			    description: 'Remote to use when publishing a branch without upstream.') }) } asDictionary
]
