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
				   (#name -> 'MCP').
				   (#branch -> 'main') } asDictionary).
			  (#action -> 'verifyIdentity') } asDictionary.
		  {
			  (#toolClass -> MCPToolListRepositoryChanges).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'diff') } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepository).
			  (#arguments -> {
				   (#name -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#action -> 'create') } asDictionary.
		  {
			  (#toolClass -> MCPToolAttachRepository).
			  (#arguments -> {
				   (#name -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#action -> 'attach') } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateRepository).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#addPackages -> #( 'MCP' )) } asDictionary).
			  (#action -> 'update') } asDictionary.
		  {
			  (#toolClass -> MCPToolExportRepository).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'export') } asDictionary.
		  {
			  (#toolClass -> MCPToolCommitRepository).
			  (#arguments -> {
				   (#name -> 'MCP').
				   (#message -> 'Commit from test') } asDictionary).
			  (#action -> 'commit') } asDictionary.
		  {
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
			  (#action -> 'adoptHead') } asDictionary.
		  {
			  (#toolClass -> MCPToolReloadRepository).
			  (#arguments -> { (#name -> 'MCP') } asDictionary).
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
	   'repository_discard' 'repository_reload' 'repository_head_adopt' ) do: [ :toolName |
			| metadata tool |
			tool := self toolRegistry toolNamed: toolName ifAbsent: [ nil ].
			tool ifNotNil: [
					metadata := metadataByName at: toolName.
					self assert: tool defaultExposure equals: 'discoverable'.
					self assert: metadata keys asSet equals: #( name description ) asSet ] ].
	#( 'repository_change_list' 'repository_export' ) do: [ :toolName |
			| tool |
			tool := self toolRegistry toolNamed: toolName ifAbsent: [ self fail: 'Missing tool ' , toolName ].
			self assert: tool defaultExposure equals: 'static'.
			self assert: (self toolRegistry advertisedToolNames includes: toolName).
			self assert: (metadataByName at: toolName) keys asSet equals: #( name description ) asSet ].
	self assert: (metadataByName includesKey: 'repository_reload')
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
MCPToolRepositoryToolsTest >> testRepositoryToolsUseDedicatedInputs [

	| expectations |
	expectations := {
		                (MCPToolVerifyRepositoryIdentity
		                 -> #( 'name' 'location' 'branch' 'subdirectory' 'packages' 'modifiedPackages'
		                    'isModified' )).
		                (MCPToolListRepositoryChanges -> #( 'name' 'location' )).
		                (MCPToolCreateRepository -> #( 'name' 'location' 'subdirectory' 'packages' )).
		                (MCPToolAttachRepository -> #( 'name' 'location' 'subdirectory' 'packages' )).
		                (MCPToolUpdateRepository
		                 -> #( 'name' 'location' 'subdirectory' 'packages' 'addPackages' 'removePackages' )).
		                (MCPToolExportRepository -> #( 'name' 'location' )).
		                (MCPToolCommitRepository -> #( 'name' 'location' 'message' )).
		                (MCPToolAdoptRepositoryHead -> #( 'name' 'location' 'branch' )) }.
	expectations do: [ :association |
			| propertyNames |
			propertyNames := self inputPropertyNamesFor: association key new.
			self assert: propertyNames asArray equals: association value ]
]
