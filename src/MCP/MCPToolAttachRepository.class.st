Class {
	#name : 'MCPToolAttachRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolAttachRepository class >> toolName [

	^ 'repository_attach'
]

{ #category : 'private - operations' }
MCPToolAttachRepository >> repositoryOperationSpec [

	^ {
		  (#title -> 'Attach Repository').
		  (#description
		   ->
		   'Register an existing Git checkout without creating repository files, and optionally attach packages.').
		  (#operation -> 'attach').
		  (#requestClass -> MCPRepositoryAttachRequest).
		  (#commandClass -> MCPAttachRepositoryCommand).
		  (#referenceInputProperties -> #(  )).
		  (#inputProperties -> {
			   (self
				    schemaPropertyNamed: 'name'
				    type: 'string'
				    description: 'Repository name to register in the image.').
			   (self
				    schemaPropertyNamed: 'location'
				    type: 'string'
				    description:
				    'Filesystem path of the existing Git checkout to register.').
			   (self
				    schemaPropertyNamed: 'subdirectory'
				    type: 'string'
				    description:
				    'Optional source subdirectory for packages managed by this repository.').
			   (self
				    stringArraySchemaNamed: 'packageNames'
				    description:
				    'Package names to manage initially from the attached checkout.'
				    itemDescription: 'A package name.') }).
		  (#requiredProperties -> #( 'name' 'location' )) } asDictionary
]
