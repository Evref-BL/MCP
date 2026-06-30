"
Tests for repository tools split from the broad repository operation surface.
"
Class {
	#name : 'MCPToolRepositoryToolsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRepositoryToolsTest >> inputPropertyNamesFor: aTool [

	^ aTool inputSchema properties collect: [ :each | each name ]
]

{ #category : 'private' }
MCPToolRepositoryToolsTest >> metadataByNameForRepositoryTools [

	| result |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#group -> 'repositories') } asDictionary.
	^ (((self dataFrom: result) at: #tools) collect: [ :each |
		   (each at: #name) -> each ]) asDictionary
]

{ #category : 'private' }
MCPToolRepositoryToolsTest >> repositoryToolSpecifications [

	^ {
		  {
			  (#toolClass -> MCPToolVerifyRepositoryIdentity).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#action -> 'verifyIdentity').
			  (#requestClass -> MCPRepositoryVerifyIdentityRequest).
			  (#commandClass -> MCPRepositoryVerifyIdentityCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolListRepositoryChanges).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#action -> 'diff').
			  (#requestClass -> MCPRepositoryDiffRequest).
			  (#commandClass -> MCPRepositoryDiffCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepository).
			  (#arguments -> {
				   (#name -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#action -> 'create').
			  (#requestClass -> MCPRepositoryCreateRequest).
			  (#commandClass -> MCPCreateRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolAttachRepository).
			  (#arguments -> {
				   (#name -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#action -> 'attach').
			  (#requestClass -> MCPRepositoryAttachRequest).
			  (#commandClass -> MCPAttachRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateRepository).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#addPackageNames -> #( 'MCP' )) } asDictionary).
			  (#action -> 'update').
			  (#requestClass -> MCPRepositoryUpdateRequest).
			  (#commandClass -> MCPUpdateRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolExportRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#action -> 'export').
			  (#requestClass -> MCPRepositoryExportRequest).
			  (#commandClass -> MCPExportRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCommitRepository).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#message -> 'Commit from test') } asDictionary).
			  (#action -> 'commit').
			  (#requestClass -> MCPRepositoryCommitRequest).
			  (#commandClass -> MCPCommitRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFetchRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#action -> 'fetch').
			  (#requestClass -> MCPRepositoryFetchRequest).
			  (#commandClass -> MCPFetchRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPullRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#action -> 'pull').
			  (#requestClass -> MCPRepositoryPullRequest).
			  (#commandClass -> MCPPullRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPushRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#action -> 'push').
			  (#requestClass -> MCPRepositoryPushRequest).
			  (#commandClass -> MCPPushRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'feature') } asDictionary).
			  (#action -> 'createBranch').
			  (#requestClass -> MCPRepositoryCreateBranchRequest).
			  (#commandClass -> MCPCreateRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolSwitchRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#action -> 'switchBranch').
			  (#requestClass -> MCPRepositorySwitchBranchRequest).
			  (#commandClass -> MCPSwitchRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolCheckoutRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#action -> 'checkoutBranch').
			  (#requestClass -> MCPRepositoryCheckoutBranchRequest).
			  (#commandClass -> MCPCheckoutRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#action -> 'adoptHead').
			  (#requestClass -> MCPRepositoryAdoptHeadRequest).
			  (#commandClass -> MCPAdoptRepositoryHeadCommand) } asDictionary }
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsAreDiscoverableWithExpectedRisk [

	| metadataByName |
	metadataByName := self metadataByNameForRepositoryTools.
	#( 'repository_identity_verify' 'repository_change_list'
	   'repository_create' 'repository_attach' 'repository_update'
	   'repository_export' 'repository_commit' 'repository_fetch'
	   'repository_pull' 'repository_push' 'repository_branch_create'
	   'repository_branch_switch' 'repository_branch_checkout'
	   'repository_head_adopt' ) do: [ :toolName |
			| metadata tool |
			metadata := metadataByName at: toolName.
			tool := MCPToolRegistry
				        toolNamed: toolName
				        ifAbsent: [ self fail: 'Missing tool ' , toolName ].
			self
				assert: (MCPToolRegistry exposureForTool: tool)
				equals: 'discoverable'.
			self
				assert: metadata keys asSet
				equals: #( name description schemaInspectionRequired ) asSet.
			self assert: (metadata at: #schemaInspectionRequired) ].
	self assert: (metadataByName includesKey: 'repository_load')
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsRequiredInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity
		                 -> #( 'repositoryName' )).
		                (MCPToolListRepositoryChanges
		                 -> #( 'repositoryName' )).
		                (MCPToolCreateRepository -> #( 'name' 'location' )).
		                (MCPToolAttachRepository -> #( 'name' 'location' )).
		                (MCPToolUpdateRepository -> #( 'repositoryName' )).
		                (MCPToolExportRepository -> #( 'repositoryName' )).
		                (MCPToolCommitRepository
		                 -> #( 'repositoryName' 'message' )).
		                (MCPToolFetchRepository -> #( 'repositoryName' )).
		                (MCPToolPullRepository -> #( 'repositoryName' )).
		                (MCPToolPushRepository -> #( 'repositoryName' )).
		                (MCPToolCreateRepositoryBranch
		                 -> #( 'repositoryName' 'branchName' )).
		                (MCPToolSwitchRepositoryBranch
		                 -> #( 'repositoryName' 'branchName' )).
		                (MCPToolCheckoutRepositoryBranch
		                 -> #( 'repositoryName' 'branchName' )).
		                (MCPToolAdoptRepositoryHead -> #( 'repositoryName' )) }.
	expectations do: [ :association |
			self
				assert: association key new inputSchema required asArray
				equals: association value ]
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsRouteToRepositoryCommands [

	self repositoryToolSpecifications do: [ :specification |
			| command parsedRequest rawRequest tool |
			tool := (specification at: #toolClass) new.
			rawRequest := tool requestFromToolCallArguments:
				              (specification at: #arguments).
			parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
			command := tool commandForRequest: parsedRequest.
			self
				assert: parsedRequest class
				equals: (specification at: #requestClass).
			self
				assert: parsedRequest operation
				equals: (specification at: #action).
			self
				assert: command class
				equals: (specification at: #commandClass) ]
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsUseDedicatedInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity
		                 ->
			                 #( 'repositoryName' 'location' 'branchName'
			                    'subdirectory' 'packageNames' 'modifiedPackageNames'
			                    'isModified' )).
		                (MCPToolListRepositoryChanges
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolCreateRepository
		                 ->
		                 #( 'name' 'location' 'subdirectory' 'packageNames' )).
		                (MCPToolAttachRepository
		                 ->
		                 #( 'name' 'location' 'subdirectory' 'packageNames' )).
		                (MCPToolUpdateRepository
		                 ->
			                 #( 'repositoryName' 'location' 'subdirectory'
			                    'packageNames' 'addPackageNames'
			                    'removePackageNames' )).
		                (MCPToolExportRepository
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolCommitRepository
		                 -> #( 'repositoryName' 'location' 'message' )).
		                (MCPToolFetchRepository
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolPullRepository
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolPushRepository
		                 -> #( 'repositoryName' 'location' 'remoteName' )).
		                (MCPToolCreateRepositoryBranch
		                 -> #( 'repositoryName' 'location' 'branchName' )).
		                (MCPToolSwitchRepositoryBranch
		                 -> #( 'repositoryName' 'location' 'branchName' )).
		                (MCPToolCheckoutRepositoryBranch
		                 -> #( 'repositoryName' 'location' 'branchName' )).
		                (MCPToolAdoptRepositoryHead
		                 -> #( 'repositoryName' 'location' 'branchName' )) }.
	expectations do: [ :association |
			| propertyNames |
			propertyNames := self inputPropertyNamesFor: association key new.
			self assert: propertyNames asArray equals: association value ]
]
