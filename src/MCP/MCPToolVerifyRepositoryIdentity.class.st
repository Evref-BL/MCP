"
Concrete repository_identity_verify tool. It verifies expected Iceberg repository identity fields through MCPToolRepositoryOperation without writing files.
"
Class {
	#name : 'MCPToolVerifyRepositoryIdentity',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolVerifyRepositoryIdentity class >> toolName [

	^ 'repository_identity_verify'
]

{ #category : 'metadata' }
MCPToolVerifyRepositoryIdentity >> additionalKeywords [

	^ super additionalKeywords , #( 'identity' 'guard' )
]

{ #category : 'metadata' }
MCPToolVerifyRepositoryIdentity >> mutability [

	^ 'read'
]

{ #category : 'private - specs' }
MCPToolVerifyRepositoryIdentity >> repositoryToolSpec [

	^ {
		  (#title -> 'Verify Repository Identity').
		  (#description
		   ->
		   'Assert expected Iceberg repository identity fields without writing files. Provide at least one expected field such as location, branchName, subdirectory, packageNames, modifiedPackageNames, or isModified.').
		  (#action -> 'verifyIdentity').
		  (#requestClass -> MCPRepositoryVerifyIdentityRequest).
		  (#commandClass -> MCPRepositoryVerifyIdentityCommand).
		  (#inputProperties -> {
			   self branchNameSchemaProperty.
			   self subdirectorySchemaProperty.
			   self packageNamesSchemaProperty.
			   self modifiedPackageNamesSchemaProperty.
			   self isModifiedSchemaProperty }) } asDictionary
]

{ #category : 'metadata' }
MCPToolVerifyRepositoryIdentity >> risk [

	^ 'low'
]
