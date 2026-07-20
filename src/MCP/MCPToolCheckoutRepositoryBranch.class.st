"
Concrete repository_branch_checkout tool. It checks out an existing Iceberg branch and loads changes for packages already managed by the repository.
"
Class {
	#name : 'MCPToolCheckoutRepositoryBranch',
	#superclass : 'MCPToolRepositoryOperation',
	#category : 'MCP-Tools',
	#package : 'MCP',
	#tag : 'Tools'
}

{ #category : 'metadata' }
MCPToolCheckoutRepositoryBranch class >> toolName [

	^ 'repository_branch_checkout'
]

{ #category : 'metadata' }
MCPToolCheckoutRepositoryBranch >> additionalKeywords [

	^ super additionalKeywords , #( 'checkout' 'reload' 'stale' 'verification' )
]

{ #category : 'private - specs' }
MCPToolCheckoutRepositoryBranch >> repositoryToolSpec [

	^ {
		  (#title -> 'Checkout Repository Branch').
		  (#description
		   ->
		   'Check out a registered Iceberg repository branch and load changes for packages already loaded in the image. Use repository_branch_switch when only the repository head should move.').
		  (#action -> 'checkoutBranch').
		  (#requestClass -> MCPRepositoryCheckoutBranchRequest).
		  (#commandClass -> MCPCheckoutRepositoryBranchCommand).
		  (#inputProperties -> { self branchNameSchemaProperty }).
		  (#requiredProperties -> #( 'repositoryName' 'branchName' )) }
		  asDictionary
]
