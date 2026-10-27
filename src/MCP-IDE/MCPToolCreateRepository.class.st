"
Concrete repository_create tool. It creates a new Iceberg repository directory and optional initial package membership through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolCreateRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-IDE-Tools',
	#package : 'MCP-IDE',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCreateRepository class >> toolName [

	^ 'repository_create'
]

{ #category : 'private - specs' }
MCPToolCreateRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Create Repository').
		  (#description
		   ->
		   'Create a new Iceberg repository directory and optionally attach initial packages. When location is omitted, use Iceberg''s default local repository directory.').
		  (#action -> 'create').
		  (#requestClass -> MCPRepositoryCreateRequest).
		  (#commandClass -> MCPCreateRepositoryCommand).
		  (#referenceInputProperties -> #(  )).
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'name' type: 'string' description: 'Repository name for the new repository.').
			   (self
				    schemaPropertyNamed: 'location'
				    type: 'string'
				    description:
				    'Optional filesystem path where the new repository directory is created. Defaults to Iceberg''s local repository directory / repository name.').
			   (self
				    schemaPropertyNamed: 'subdirectory'
				    type: 'string'
				    description: 'Optional source subdirectory for packages managed by this repository.').
			   (self
				    stringArraySchemaNamed: 'packages'
				    description: 'Package names to manage initially in the new repository.'
				    itemDescription: 'A package name.') }).
		  (#requiredProperties -> #( 'name' )) } asDictionary
]
