Class {
	#name : 'MCPToolCreateRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolCreateRepository class >> toolName [

	^ 'repository_create'
]

{ #category : 'private - operations' }
MCPToolCreateRepository >> repositoryOperationSpec [

	^ {
		  (#title -> 'Create Repository').
		  (#description
		   ->
		   'Create a new Iceberg repository directory and optionally attach initial packages.').
		  (#operation -> 'create').
		  (#requestClass -> MCPRepositoryCreateRequest).
		  (#commandClass -> MCPCreateRepositoryCommand).
		  (#referenceInputProperties -> #(  )).
		  (#inputProperties -> {
			   (self
				    schemaPropertyNamed: 'name'
				    type: 'string'
				    description: 'Repository name for the new repository.').
			   (self
				    schemaPropertyNamed: 'location'
				    type: 'string'
				    description:
				    'Filesystem path where the new repository directory is created.').
			   (self
				    schemaPropertyNamed: 'subdirectory'
				    type: 'string'
				    description:
				    'Optional source subdirectory for packages managed by this repository.').
			   (self
				    stringArraySchemaNamed: 'packageNames'
				    description:
				    'Package names to manage initially in the new repository.'
				    itemDescription: 'A package name.') }).
		  (#requiredProperties -> #( 'name' 'location' )) } asDictionary
]
