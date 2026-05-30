"
Tests for focused repository tools split from the broad repository_edit surface.
"
Class {
	#name : 'MCPToolFocusedRepositoryTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolFocusedRepositoryTest >> focusedToolSpecifications [

	^ {
		  {
			  (#toolClass -> MCPToolVerifyRepositoryIdentity).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#operation -> 'verifyIdentity').
			  (#requestClass -> MCPRepositoryVerifyIdentityRequest).
			  (#commandClass -> MCPRepositoryVerifyIdentityCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolFindRepositoryChanges).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#operation -> 'diff').
			  (#requestClass -> MCPRepositoryDiffRequest).
			  (#commandClass -> MCPRepositoryDiffCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolExportRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#operation -> 'export').
			  (#requestClass -> MCPRepositoryExportRequest).
			  (#commandClass -> MCPExportRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCommitRepository).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#message -> 'Commit from test') } asDictionary).
			  (#operation -> 'commit').
			  (#requestClass -> MCPRepositoryCommitRequest).
			  (#commandClass -> MCPCommitRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFetchRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#operation -> 'fetch').
			  (#requestClass -> MCPRepositoryFetchRequest).
			  (#commandClass -> MCPFetchRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPullRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#operation -> 'pull').
			  (#requestClass -> MCPRepositoryPullRequest).
			  (#commandClass -> MCPPullRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPushRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#operation -> 'push').
			  (#requestClass -> MCPRepositoryPushRequest).
			  (#commandClass -> MCPPushRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'feature') } asDictionary).
			  (#operation -> 'createBranch').
			  (#requestClass -> MCPRepositoryCreateBranchRequest).
			  (#commandClass -> MCPCreateRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolSwitchRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#operation -> 'switchBranch').
			  (#requestClass -> MCPRepositorySwitchBranchRequest).
			  (#commandClass -> MCPSwitchRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#operation -> 'adoptHead').
			  (#requestClass -> MCPRepositoryAdoptHeadRequest).
			  (#commandClass -> MCPAdoptRepositoryHeadCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolFocusedRepositoryTest >> inputPropertyNamesFor: aTool [

	^ aTool inputSchema properties collect: [ :each | each name ]
]

{ #category : 'private' }
MCPToolFocusedRepositoryTest >> metadataByNameForRepositoryTools [

	| result |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#group -> 'repositories') } asDictionary.
	^ (((self dataFrom: result) at: #tools) collect: [ :each |
		   (each at: #name) -> each ]) asDictionary
]

{ #category : 'tests' }
MCPToolFocusedRepositoryTest >> testFocusedRepositoryRequiredInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity
		                 -> #( 'repositoryName' )).
		                (MCPToolFindRepositoryChanges
		                 -> #( 'repositoryName' )).
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
		                (MCPToolAdoptRepositoryHead -> #( 'repositoryName' )) }.
	expectations do: [ :association |
			self
				assert: association key new inputSchema required asArray
				equals: association value ]
]

{ #category : 'tests' }
MCPToolFocusedRepositoryTest >> testFocusedRepositorySchemasOmitOperationAndBroadUpdateInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity
		                 ->
			                 #( 'repositoryName' 'location' 'branchName'
			                    'subdirectory' 'packageNames' 'modifiedPackageNames'
			                    'isModified' )).
		                (MCPToolFindRepositoryChanges
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolExportRepository
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolCommitRepository
		                 -> #( 'repositoryName' 'location' 'message' )).
		                (MCPToolFetchRepository
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolPullRepository
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolPushRepository
		                 -> #( 'repositoryName' 'location' )).
		                (MCPToolCreateRepositoryBranch
		                 -> #( 'repositoryName' 'location' 'branchName' )).
		                (MCPToolSwitchRepositoryBranch
		                 -> #( 'repositoryName' 'location' 'branchName' )).
		                (MCPToolAdoptRepositoryHead
		                 -> #( 'repositoryName' 'location' 'branchName' )) }.
	expectations do: [ :association |
			| propertyNames |
			propertyNames := self inputPropertyNamesFor: association key new.
			self assert: propertyNames asArray equals: association value.
			#( 'operation' 'name' 'addPackageNames' 'removePackageNames' ) do: [
				:each | self deny: (propertyNames includes: each) ] ]
]

{ #category : 'tests' }
MCPToolFocusedRepositoryTest >> testFocusedRepositoryToolsAreDiscoverableWithExpectedRisk [

	| metadataByName |
	metadataByName := self metadataByNameForRepositoryTools.
	#( 'repository_identity_verify' 'repository_change_list' ) do: [
			:toolName |
			| metadata |
			metadata := metadataByName at: toolName.
			self assert: (metadata at: #exposure) equals: 'discoverable'.
			self assert: (metadata at: #mutability) equals: 'read'.
			self assert: (metadata at: #risk) equals: 'low' ].
	#( 'repository_export' 'repository_commit' 'repository_fetch'
	   'repository_pull' 'repository_push' 'repository_branch_create'
	   'repository_branch_switch' 'repository_head_adopt' ) do: [
			:toolName |
			| metadata |
			metadata := metadataByName at: toolName.
			self assert: (metadata at: #exposure) equals: 'discoverable'.
			self assert: (metadata at: #mutability) equals: 'write'.
			self assert: (metadata at: #risk) equals: 'high' ].
	self assert: (metadataByName includesKey: 'repository_edit').
	self assert: (metadataByName includesKey: 'repository_load')
]

{ #category : 'tests' }
MCPToolFocusedRepositoryTest >> testFocusedRepositoryToolsRouteToRepositoryCommands [

	self focusedToolSpecifications do: [ :specification |
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
				equals: (specification at: #operation).
			self
				assert: command class
				equals: (specification at: #commandClass) ]
]
