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
MCPToolVerifyRepositoryIdentity >> annotations [

	^ MCPStructureToolAnnotations readOnly
]

{ #category : 'private - results' }
MCPToolVerifyRepositoryIdentity >> keysStatedInSummary [
	"The summary already says whether verification passed."

	^ #( matched )
]

{ #category : 'private - specs' }
MCPToolVerifyRepositoryIdentity >> repositoryToolSpec [

	^ {
		  (#title -> 'Verify Repository Identity').
		  (#description
		   ->
		   'Assert what the image believes about a registered repository, without writing files. Give at least one expectation beside the repository reference: location, branch, subdirectory, packages, modifiedPackages or isModified. The call fails when one of them does not hold.').
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
