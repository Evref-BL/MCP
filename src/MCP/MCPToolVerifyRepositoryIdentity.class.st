Class {
	#name : 'MCPToolVerifyRepositoryIdentity',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'defaults' }
MCPToolVerifyRepositoryIdentity class >> toolName [

	^ 'repository_identity_verify'
]

{ #category : 'private - operations' }
MCPToolVerifyRepositoryIdentity >> repositoryOperationSpec [

	^ {
		  (#title -> 'Verify Repository Identity').
		  (#description
		   ->
		   'Assert expected Iceberg repository identity fields without writing files. Provide at least one expected field such as location, branchName, subdirectory, packageNames, modifiedPackageNames, or isModified.').
		  (#operation -> 'verifyIdentity').
		  (#requestClass -> MCPRepositoryVerifyIdentityRequest).
		  (#commandClass -> MCPRepositoryVerifyIdentityCommand).
		  (#inputProperties -> {
			   self branchNameSchemaProperty.
			   self subdirectorySchemaProperty.
			   self packageNamesSchemaProperty.
			   self modifiedPackageNamesSchemaProperty.
			   self isModifiedSchemaProperty }) } asDictionary
]
