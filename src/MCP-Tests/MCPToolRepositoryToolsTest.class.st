"
Tests for repository tools split from the broad repository operation surface.
"
Class {
	#name : 'MCPToolRepositoryToolsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
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
				   (#repository -> 'MCP').
				   (#branch -> 'main') } asDictionary).
			  (#action -> 'verifyIdentity') } asDictionary.
		  {
			  (#toolClass -> MCPToolListRepositoryChanges).
			  (#arguments -> { (#repository -> 'MCP') } asDictionary).
			  (#action -> 'diff') } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepository).
			  (#arguments -> {
				   (#repository -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#action -> 'create') } asDictionary.
		  {
			  (#toolClass -> MCPToolAttachRepository).
			  (#arguments -> {
				   (#repository -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#action -> 'attach') } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateRepository).
			  (#arguments -> {
				   (#repository -> 'MCP').
				   (#addPackages -> #( 'MCP' )) } asDictionary).
			  (#action -> 'update') } asDictionary.
		  {
			  (#toolClass -> MCPToolExportRepository).
			  (#arguments -> { (#repository -> 'MCP') } asDictionary).
			  (#action -> 'export') } asDictionary.
		  {
			  (#toolClass -> MCPToolCommitRepository).
			  (#arguments -> {
				   (#repository -> 'MCP').
				   (#message -> 'Commit from test') } asDictionary).
			  (#action -> 'commit') } asDictionary.
		  {
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#repository -> 'MCP') } asDictionary).
			  (#action -> 'adoptHead') } asDictionary.
		  {
			  (#toolClass -> MCPToolReloadRepository).
			  (#arguments -> { (#repository -> 'MCP') } asDictionary).
			  (#action -> 'reload') } asDictionary }
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
	"repository_change_list and repository_export are advertised, since they move the image's work to the checkout in every project that has one; the other repository tools are found through tool_search."

	| metadataByName |
	metadataByName := self searchMetadataByToolName.
	#( 'repository_identity_verify' 'repository_create' 'repository_attach' 'repository_update' 'repository_commit'
	   'repository_change_discard' 'repository_reload' 'repository_head_adopt' ) do: [ :toolName |
			| tool |
			tool := self toolRegistry toolNamed: toolName ifAbsent: [ self fail: 'Missing tool ' , toolName ].
			self assert: tool defaultExposure equals: 'discoverable'.
			self assert: (metadataByName at: toolName) keys asSet equals: #( name description ) asSet ].
	#( 'repository_change_list' 'repository_export' ) do: [ :toolName |
			| tool |
			tool := self toolRegistry toolNamed: toolName ifAbsent: [ self fail: 'Missing tool ' , toolName ].
			self assert: tool defaultExposure equals: 'static'.
			self assert: (self toolRegistry advertisedToolNames includes: toolName).
			self assert: (metadataByName at: toolName) keys asSet equals: #( name description ) asSet ]
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsNameTheirAction [

	self repositoryToolSpecifications do: [ :specification |
			| request tool |
			tool := (specification at: #toolClass) new.
			request := tool requestFromToolCallArguments: (specification at: #arguments).
			self assert: (tool mutationActionFor: request checked: true) equals: (specification at: #action) ]
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsRequiredInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity -> #( 'repository' )).
		                (MCPToolListRepositoryChanges -> #( 'repository' )).
		                (MCPToolCreateRepository -> #( 'repository' )).
		                (MCPToolAttachRepository -> #( 'repository' 'location' )).
		                (MCPToolUpdateRepository -> #( 'repository' )).
		                (MCPToolExportRepository -> #( 'repository' )).
		                (MCPToolCommitRepository -> #( 'repository' 'message' )).
		                (MCPToolAdoptRepositoryHead -> #( 'repository' )) }.
	expectations do: [ :association | self assert: association key new inputSchema required asArray equals: association value ]
]

{ #category : 'tests' }
MCPToolRepositoryToolsTest >> testRepositoryToolsUseDedicatedInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity
		                 -> #( 'repository' 'location' 'branch' 'subdirectory' 'packages' 'modifiedPackages' 'isModified' )).
		                (MCPToolListRepositoryChanges -> #( 'repository' 'location' )).
		                (MCPToolCreateRepository -> #( 'repository' 'location' 'subdirectory' 'packages' )).
		                (MCPToolAttachRepository -> #( 'repository' 'location' 'subdirectory' 'packages' )).
		                (MCPToolUpdateRepository
		                 -> #( 'repository' 'location' 'subdirectory' 'packages' 'addPackages' 'removePackages' )).
		                (MCPToolExportRepository -> #( 'repository' 'location' )).
		                (MCPToolCommitRepository -> #( 'repository' 'location' 'message' )).
		                (MCPToolAdoptRepositoryHead -> #( 'repository' 'location' 'branch' )) }.
	expectations do: [ :association |
			| propertyNames |
			propertyNames := self inputPropertyNamesFor: association key new.
			self assert: propertyNames asArray equals: association value ]
]
