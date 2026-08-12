"
Concrete repository_attach tool. It registers an existing Git checkout and optional package membership through MCPToolRepositoryOperation.
"
Class {
	#name : 'MCPToolAttachRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolAttachRepository class >> toolName [

	^ 'repository_attach'
]

{ #category : 'private - specs' }
MCPToolAttachRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Attach Repository').
		  (#description -> 'Register an existing Git checkout without creating repository files, and optionally attach packages.').
		  (#action -> 'attach').
		  (#requestClass -> MCPRepositoryAttachRequest).
		  (#commandClass -> MCPAttachRepositoryCommand).
		  (#referenceInputProperties -> #(  )).
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'name' type: 'string' description: 'Repository name to register in the image.').
			   (self
				    schemaPropertyNamed: 'location'
				    type: 'string'
				    description: 'Filesystem path of the existing Git checkout to register.').
			   (self
				    schemaPropertyNamed: 'subdirectory'
				    type: 'string'
				    description: 'Optional source subdirectory for packages managed by this repository.').
			   (self
				    stringArraySchemaNamed: 'packageNames'
				    description: 'Package names to manage initially from the attached checkout.'
				    itemDescription: 'A package name.') }).
		  (#requiredProperties -> #( 'name' 'location' )) } asDictionary
]
