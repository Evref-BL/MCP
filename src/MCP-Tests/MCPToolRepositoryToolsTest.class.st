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
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'adoptHead').
			  (#requestClass -> MCPRepositoryAdoptHeadRequest).
			  (#commandClass -> MCPAdoptRepositoryHeadCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolReloadRepository).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'reload').
			  (#requestClass -> MCPRepositoryReloadRequest).
			  (#commandClass -> MCPReloadRepositoryCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolRepositoryToolsTest >> searchMetadataByToolName [

	| metadata |
	metadata := Dictionary new.
	self toolRegistry tools do: [ :tool | metadata at: tool name put: tool searchMetadata ].
	^ metadata
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsAreDiscoverableWithExpectedMetadata [

	| metadataByName |
	metadataByName := self searchMetadataByToolName.
	#( 'repository_identity_verify' 'repository_change_list' 'repository_create' 'repository_attach' 'repository_update'
	   'repository_export' 'repository_commit' 'repository_discard' 'repository_reload' 'repository_head_adopt' ) do: [ :toolName |
			| metadata tool |
			tool := self toolRegistry toolNamed: toolName ifAbsent: [ nil ].
			tool ifNotNil: [
					metadata := metadataByName at: toolName.
					self assert: tool defaultExposure equals: 'discoverable'.
					self assert: metadata keys asSet equals: #( name description ) asSet ] ].
	self assert: (metadataByName includesKey: 'repository_reload')
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsRequiredInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity -> #( 'name' )).
		                (MCPToolListRepositoryChanges -> #( 'name' )).
		                (MCPToolCreateRepository -> #( 'name' )).
		                (MCPToolAttachRepository -> #( 'name' 'location' )).
		                (MCPToolUpdateRepository -> #( 'name' )).
		                (MCPToolExportRepository -> #( 'name' )).
		                (MCPToolCommitRepository -> #( 'name' 'message' )).
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
		                 -> #( 'name' 'location' 'branchName' 'subdirectory' 'packageNames' 'modifiedPackageNames'
		                    'isModified' )).
		                (MCPToolListRepositoryChanges -> #( 'name' 'location' )).
		                (MCPToolCreateRepository -> #( 'name' 'location' 'subdirectory' 'packageNames' )).
		                (MCPToolAttachRepository -> #( 'name' 'location' 'subdirectory' 'packageNames' )).
		                (MCPToolUpdateRepository
		                 -> #( 'name' 'location' 'subdirectory' 'packageNames' 'addPackageNames' 'removePackageNames' )).
		                (MCPToolExportRepository -> #( 'name' 'location' )).
		                (MCPToolCommitRepository -> #( 'name' 'location' 'message' )).
		                (MCPToolAdoptRepositoryHead -> #( 'name' 'location' 'branchName' )) }.
	expectations do: [ :association |
			| propertyNames |
			propertyNames := self inputPropertyNamesFor: association key new.
			self assert: propertyNames asArray equals: association value ]
]
