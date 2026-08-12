"
Concrete repository_update tool. It changes image-side repository subdirectory or package membership through MCPToolRepositoryOperation without writing packages to files.
"
Class {
	#name : 'MCPToolUpdateRepository',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolUpdateRepository class >> toolName [

	^ 'repository_update'
]

{ #category : 'private - specs' }
MCPToolUpdateRepository >> repositoryToolSpec [

	^ {
		  (#title -> 'Update Repository').
		  (#description -> 'Change image-side repository subdirectory or package membership without writing packages to files.').
		  (#action -> 'update').
		  (#requestClass -> MCPRepositoryUpdateRequest).
		  (#commandClass -> MCPUpdateRepositoryCommand).
		  (#inputProperties -> {
			   (self schemaPropertyNamed: 'subdirectory' type: 'string' description: 'Set the repository source subdirectory in the image.').
			   (self
				    stringArraySchemaNamed: 'packageNames'
				    description:
				    'Replace the full managed package list by adding and removing repository package membership without unloading packages or writing files.'
				    itemDescription: 'A package name.').
			   (self
				    stringArraySchemaNamed: 'addPackageNames'
				    description: 'Package names to add to the repository working copy without writing packages to files.'
				    itemDescription: 'A package name to add.').
			   (self
				    stringArraySchemaNamed: 'removePackageNames'
				    description: 'Package names to remove from repository membership without unloading packages from the image.'
				    itemDescription: 'A package name to remove.') }) } asDictionary
]
