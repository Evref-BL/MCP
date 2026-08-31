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
	result := self callToolNamed: 'tool_search' withArguments: { (#query -> 'repository') } asDictionary.
	^ (((self dataFrom: result) at: #tools) collect: [ :each | (each at: #name) -> each ]) asDictionary
]

{ #category : 'private' }
MCPToolRepositoryToolsTest >> repositoryToolSpecifications [

	^ {
		  {
			  (#toolClass -> MCPToolVerifyRepositoryIdentity).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#action -> 'verifyIdentity').
			  (#requestClass -> MCPRepositoryVerifyIdentityRequest).
			  (#commandClass -> MCPRepositoryVerifyIdentityCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolListRepositoryChanges).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
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
				   (#name -> 'MCP').
				   (#addPackageNames -> #( 'MCP' )) } asDictionary).
			  (#action -> 'update').
			  (#requestClass -> MCPRepositoryUpdateRequest).
			  (#commandClass -> MCPUpdateRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolExportRepository).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'export').
			  (#requestClass -> MCPRepositoryExportRequest).
			  (#commandClass -> MCPExportRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCommitRepository).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#message -> 'Commit from test') } asDictionary).
			  (#action -> 'commit').
			  (#requestClass -> MCPRepositoryCommitRequest).
			  (#commandClass -> MCPCommitRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFetchRepository).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'fetch').
			  (#requestClass -> MCPRepositoryFetchRequest).
			  (#commandClass -> MCPFetchRepositoryCommand) } asDictionary.

		  {
			  (#toolClass -> MCPToolAddRepositoryRemote).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#remoteName -> 'origin').
				   (#remoteUrl -> 'git@example.com:mcp.git') } asDictionary).
			  (#action -> 'remoteAdd').
			  (#requestClass -> MCPRepositoryRemoteRequest).
			  (#commandClass -> MCPAddRepositoryRemoteCommand) } asDictionary.

		  {
			  (#toolClass -> MCPToolRemoveRepositoryRemote).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#remoteName -> 'origin') } asDictionary).
			  (#action -> 'remoteRemove').
			  (#requestClass -> MCPRepositoryRemoteRequest).
			  (#commandClass -> MCPRemoveRepositoryRemoteCommand) } asDictionary.

		  {
			  (#toolClass -> MCPToolUpdateRepositoryRemote).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#remoteName -> 'origin').
				   (#remoteUrl -> 'git@example.com:mcp.git') } asDictionary).
			  (#action -> 'remoteUpdate').
			  (#requestClass -> MCPRepositoryRemoteRequest).
			  (#commandClass -> MCPUpdateRepositoryRemoteCommand) } asDictionary.



		  {
			  (#toolClass -> MCPToolPullRepository).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'pull').
			  (#requestClass -> MCPRepositoryPullRequest).
			  (#commandClass -> MCPPullRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPushRepository).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'push').
			  (#requestClass -> MCPRepositoryPushRequest).
			  (#commandClass -> MCPPushRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepositoryBranch).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#branchName -> 'feature') } asDictionary).
			  (#action -> 'createBranch').
			  (#requestClass -> MCPRepositoryCreateBranchRequest).
			  (#commandClass -> MCPCreateRepositoryBranchCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSwitchRepositoryBranch).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#action -> 'switchBranch').
			  (#requestClass -> MCPRepositorySwitchBranchRequest).
			  (#commandClass -> MCPSwitchRepositoryBranchCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCheckoutRepositoryBranch).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#action -> 'checkoutBranch').
			  (#requestClass -> MCPRepositoryCheckoutBranchRequest).
			  (#commandClass -> MCPCheckoutRepositoryBranchCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'adoptHead').
			  (#requestClass -> MCPRepositoryAdoptHeadRequest).
			  (#commandClass -> MCPAdoptRepositoryHeadCommand) } asDictionary }
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsAreDiscoverableWithExpectedMetadata [

	| metadataByName |
	metadataByName := self metadataByNameForRepositoryTools.
	#( 'repository_identity_verify' 'repository_change_list' 'repository_create' 'repository_attach' 'repository_update'
	   'repository_remote_add' 'repository_remote_remove' 'repository_remote_update' 'repository_export' 'repository_commit'
	   'repository_fetch' 'repository_pull' 'repository_push' 'repository_branch_create' 'repository_branch_switch'
	   'repository_branch_checkout' 'repository_head_adopt' ) do: [ :toolName |
			| metadata tool |
			metadata := metadataByName at: toolName.
			tool := self toolRegistry toolNamed: toolName ifAbsent: [ self fail: 'Missing tool ' , toolName ].
			self assert: tool defaultExposure equals: 'discoverable'.
			self assert: metadata keys asSet equals: #( name description ) asSet ].
	self assert: (metadataByName includesKey: 'repository_load')
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsRequiredInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity -> #( 'name' )).
		                (MCPToolListRepositoryChanges -> #( 'name' )).
		                (MCPToolCreateRepository -> #( 'name' 'location' )).
		                (MCPToolAttachRepository -> #( 'name' 'location' )).
		                (MCPToolUpdateRepository -> #( 'name' )).
		                (MCPToolAddRepositoryRemote -> #( 'name' 'remoteName' 'remoteUrl' )).
		                (MCPToolRemoveRepositoryRemote -> #( 'name' 'remoteName' )).
		                (MCPToolUpdateRepositoryRemote -> #( 'name' 'remoteName' 'remoteUrl' )).
		                (MCPToolExportRepository -> #( 'name' )).
		                (MCPToolCommitRepository -> #( 'name' 'message' )).
		                (MCPToolFetchRepository -> #( 'name' )).
		                (MCPToolPullRepository -> #( 'name' )).
		                (MCPToolPushRepository -> #( 'name' )).
		                (MCPToolCreateRepositoryBranch -> #( 'name' 'branchName' )).
		                (MCPToolSwitchRepositoryBranch -> #( 'name' 'branchName' )).
		                (MCPToolCheckoutRepositoryBranch -> #( 'name' 'branchName' )).
		                (MCPToolAdoptRepositoryHead -> #( 'name' )) }.
	expectations do: [ :association | self assert: association key new inputSchema required asArray equals: association value ]
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsRouteToRepositoryCommands [

	self repositoryToolSpecifications do: [ :specification |
			| command parsedRequest rawRequest tool |
			tool := (specification at: #toolClass) new.
			rawRequest := tool requestFromToolCallArguments: (specification at: #arguments).
			parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
			command := tool commandForRequest: parsedRequest.
			self assert: parsedRequest class equals: (specification at: #requestClass).
			self assert: parsedRequest operation equals: (specification at: #action).
			self assert: command class equals: (specification at: #commandClass) ]
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsUseDedicatedInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity
		                 ->
		                 #( 'name' 'location' 'branchName' 'subdirectory' 'packageNames' 'modifiedPackageNames'
		                    'isModified' )).
		                (MCPToolListRepositoryChanges -> #( 'name' 'location' )).
		                (MCPToolCreateRepository -> #( 'name' 'location' 'subdirectory' 'packageNames' )).
		                (MCPToolAttachRepository -> #( 'name' 'location' 'subdirectory' 'packageNames' )).
		                (MCPToolUpdateRepository
		                 -> #( 'name' 'location' 'subdirectory' 'packageNames' 'addPackageNames' 'removePackageNames' )).
		                (MCPToolAddRepositoryRemote -> #( 'name' 'location' 'remoteName' 'remoteUrl' )).
		                (MCPToolRemoveRepositoryRemote -> #( 'name' 'location' 'remoteName' )).
		                (MCPToolUpdateRepositoryRemote -> #( 'name' 'location' 'remoteName' 'remoteUrl' )).
		                (MCPToolExportRepository -> #( 'name' 'location' )).
		                (MCPToolCommitRepository -> #( 'name' 'location' 'message' )).
		                (MCPToolFetchRepository -> #( 'name' 'location' )).
		                (MCPToolPullRepository -> #( 'name' 'location' )).
		                (MCPToolPushRepository -> #( 'name' 'location' 'remoteName' )).
		                (MCPToolCreateRepositoryBranch -> #( 'name' 'location' 'branchName' )).
		                (MCPToolSwitchRepositoryBranch -> #( 'name' 'location' 'branchName' )).
		                (MCPToolCheckoutRepositoryBranch -> #( 'name' 'location' 'branchName' )).
		                (MCPToolAdoptRepositoryHead -> #( 'name' 'location' 'branchName' )) }.
	expectations do: [ :association |
			| propertyNames |
			propertyNames := self inputPropertyNamesFor: association key new.
			self assert: propertyNames asArray equals: association value ]
]
