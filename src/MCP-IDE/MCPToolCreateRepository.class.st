"
Concrete repository_create tool. It starts a Git repository with no history at a location that does not exist yet or holds no file, registers it and gives it packages from the image, through MCPToolRepositoryOperation. An existing checkout is registered with repository_attach instead.
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
		   'Start a Git repository with no history at a location that does not exist yet or holds no file, register it, and give it packages from the image. An existing checkout is registered with repository_attach. Without a location, the repository goes in Iceberg''s own directory of repositories, under its name.').
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
				    'Absolute path of the new repository: a directory that does not exist yet, one that holds no file, or a Git repository with no commit.').
			   (self
				    schemaPropertyNamed: 'subdirectory'
				    type: 'string'
				    description: 'Directory inside the repository for the package sources, such as src. Defaults to its root.').
			   (self
				    stringArraySchemaNamed: 'packages'
				    description: 'Packages of the image the repository holds.'
				    itemDescription: 'A package name.') }).
		  (#requiredProperties -> #( 'name' )) } asDictionary
]
