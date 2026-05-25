"
Tests the JSON Schema validator used to check MCP tool input payloads.
"
Class {
	#name : 'MCPJSONSchemaValidatorTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPJSONSchemaValidatorTest >> keywordsFrom: violations [

	^ violations collect: [ :each | each keyword ]
]

{ #category : 'private - fixtures' }
MCPJSONSchemaValidatorTest >> representativeArgumentsByToolClass [

	^ {
		  (MCPToolEvaluate -> { (#code -> '1 + 1') } asDictionary).
		  (MCPToolRunTests -> { (#tests
		    -> { { (#className -> 'MCPToolContractsTest') } asDictionary }) }
			   asDictionary).
		  (MCPToolRunTestBatch -> { (#tests
		    -> { { (#className -> 'MCPToolContractsTest') } asDictionary }) }
			   asDictionary).
		  (MCPToolRunTestCoverage -> {
			   (#tests
			    -> { { (#className -> 'MCPToolContractsTest') } asDictionary }).
			   (#coverage
			    ->
			    { (#classNames -> #( 'MCPToolContractsTest' )) } asDictionary) }
			   asDictionary).
		  (MCPToolInspectClass -> { (#className -> 'MCPTool') } asDictionary).
		  (MCPToolInspectMethod -> {
			   (#className -> 'MCPTool').
			   (#selector -> 'defaultName') } asDictionary).
		  (MCPToolRemoveClasses
		   ->
			   { (#classNames -> #( 'MCPJSONSchemaValidatorTestTemporary' )) }
				   asDictionary).
		  (MCPToolRemoveMethods -> {
			   (#className -> 'MCPTool').
			   (#selectors -> #( 'temporarySelector' )) } asDictionary).
		  (MCPToolFindRepositories -> Dictionary new).
		  (MCPToolEditRepository -> {
			   (#operation -> 'update').
			   (#repositoryName -> 'MCP').
			   (#addPackageNames -> #( 'MCP' )) } asDictionary).
		  (MCPToolCreateRepository -> {
			   (#name -> 'MCP').
			   (#location -> '/tmp/mcp') } asDictionary).
		  (MCPToolAttachRepository -> {
			   (#name -> 'MCP').
			   (#location -> '/tmp/mcp') } asDictionary).
		  (MCPToolUpdateRepository -> {
			   (#repositoryName -> 'MCP').
			   (#addPackageNames -> #( 'MCP' )) } asDictionary).
		  (MCPToolVerifyRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolDiffRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolExportRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolCommitRepository -> {
			   (#repositoryName -> 'MCP').
			   (#message -> 'Test commit') } asDictionary).
		  (MCPToolAdoptRepositoryHead
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolFetchRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolPullRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolPushRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolCreateRepositoryBranch -> {
			   (#repositoryName -> 'MCP').
			   (#branchName -> 'test-branch') } asDictionary).
		  (MCPToolSwitchRepositoryBranch -> {
			   (#repositoryName -> 'MCP').
			   (#branchName -> 'main') } asDictionary).
		  (MCPToolLoadRepository -> {
			   (#owner -> 'ExampleOwner').
			   (#project -> 'ExampleProject').
			   (#baseline -> 'ExampleBaseline').
			   (#sourceDirectory -> 'src') } asDictionary).
		  (MCPToolFindClasses -> Dictionary new).
		  (MCPToolFindPackages -> Dictionary new).
		  (MCPToolEditClass -> {
			   (#operation -> 'update').
			   (#className -> 'MCPTool').
			   (#newClassName -> 'MCPToolRenamed') } asDictionary).
		  (MCPToolEditMethod -> {
			   (#operation -> 'create').
			   (#className -> 'MCPTool').
			   (#methodSource -> 'temporarySelector ^ self').
			   (#protocol -> 'tests') } asDictionary).
		  (MCPToolRewriteMethods -> { (#rules -> { {
			    (#lhs -> 'self').
			    (#rhs -> 'self') } asDictionary }) } asDictionary).
		  (MCPToolManageChangeHistory
		   -> { (#operation -> 'listFiles') } asDictionary).
		  (MCPToolListChangeHistoryFiles -> Dictionary new).
		  (MCPToolListChangeHistoryEntries -> Dictionary new).
		  (MCPToolApplyChangeHistoryEntries -> {
			   (#latestCount -> 1).
			   (#confirm -> false) } asDictionary).
		  (MCPToolRevertChangeHistoryEntries -> {
			   (#latestCount -> 1).
			   (#confirm -> false) } asDictionary).
		  (MCPToolCaptureScreenshot -> { (#target -> 'world') } asDictionary).
		  (MCPToolFindMethods -> Dictionary new).
		  (MCPToolDiscoverTools -> Dictionary new).
		  (MCPToolInspectTool
		   -> { (#toolName -> 'find-classes') } asDictionary).
		  (MCPToolDispatchTool -> {
			   (#toolName -> 'find-packages').
			   (#arguments -> Dictionary new) } asDictionary) } asDictionary
]

{ #category : 'private' }
MCPJSONSchemaValidatorTest >> schemaPropertyType: typeName [

	^ { (#type -> typeName) } asDictionary
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testCurrentToolInputSchemasAcceptRepresentativeArguments [

	| argumentsByTool |
	argumentsByTool := self representativeArgumentsByToolClass.
	MCPTool concreteSubclasses do: [ :toolClass |
		| arguments violations |
		arguments := argumentsByTool
			             at: toolClass
			             ifAbsent: [
			             self fail:
				             'Missing representative arguments for '
				             , toolClass name ].
		violations := self
			              violationsFor: arguments
			              schema: toolClass new inputSchema.
		violations ifNotEmpty: [
			self fail:
				toolClass name , ' schema rejected representative arguments: '
				, violations printString ] ]
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testCurrentToolInputSchemasRejectInvalidShapeArguments [

	| editMethodViolations legacyScopeViolations |
	legacyScopeViolations := self
		                         violationsFor:
		                         { (#scope -> 'packages') } asDictionary
		                         schema: MCPToolFindClasses new inputSchema.
	self
		assert: (self keywordsFrom: legacyScopeViolations)
		equals: #( 'additionalProperties' ).
	editMethodViolations := self
		                        violationsFor: {
				                        (#operation -> 'update').
				                        (#className -> 'MCPTool').
				                        (#selector -> 'defaultName').
				                        (#newSelector -> 'defaultTitle').
				                        (#scope -> 'classes') } asDictionary
		                        schema: MCPToolEditMethod new inputSchema.
	self
		assert: (self keywordsFrom: editMethodViolations)
		equals: #( 'additionalProperties' )
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testCurrentToolRequestValidationRejectsOperationSpecificMissingArguments [

	self
		should: [
			MCPToolEditClass new requestFromToolCallArguments: {
					(#operation -> 'create').
					(#className -> 'MCPTool') } asDictionary ]
		raise: MCPInvalidToolInput.
	self
		should: [
			MCPToolEditRepository new requestFromToolCallArguments: {
					(#operation -> 'commit').
					(#repositoryName -> 'MCP') } asDictionary ]
		raise: MCPInvalidToolInput.
	self
		should: [
			MCPToolRunTests new requestFromToolCallArguments: {
					(#operation -> 'coverage').
					(#tests
					 ->
					 { { (#className -> 'MCPToolContractsTest') } asDictionary }) }
					asDictionary ]
		raise: MCPInvalidToolInput.
	self
		should: [
			MCPToolFindMethods new requestFromToolCallArguments:
				{ (#filterMode -> 'selectorReference') } asDictionary ]
		raise: MCPInvalidToolInput.
	self
		should: [
			MCPToolRewriteMethods new requestFromToolCallArguments: {
					(#apply -> true).
					(#rules -> { {
							      (#lhs -> 'self').
							      (#rhs -> 'self') } asDictionary }) } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testReportsRequiredTypeAndAdditionalPropertiesViolations [

	| arguments keywords schema violations |
	schema := {
		          (#type -> 'object').
		          (#required -> #( 'name' )).
		          (#properties -> {
			           ('name' -> (self schemaPropertyType: 'string')).
			           ('count' -> (self schemaPropertyType: 'integer')) }
			           asDictionary).
		          (#additionalProperties -> false) } asDictionary.
	arguments := {
		             (#count -> 'two').
		             (#extra -> true) } asDictionary.
	violations := self violationsFor: arguments schema: schema.
	keywords := self keywordsFrom: violations.
	self assert: (keywords includes: 'required').
	self assert: (keywords includes: 'type').
	self assert: (keywords includes: 'additionalProperties')
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testValidatesAllOfAndIfThen [

	| arguments keywords schema |
	schema := {
		          (#type -> 'object').
		          (#allOf -> {
			           { (#required -> #( 'operation' )) } asDictionary.
			           {
				           (#if -> {
					            (#type -> 'object').
					            (#properties
					             ->
						             { ('operation'
						              -> { (#const -> 'rename') } asDictionary) }
							             asDictionary).
					            (#required -> #( 'operation' )) } asDictionary).
				           (#then
				            -> { (#required -> #( 'newName' )) } asDictionary) }
				           asDictionary }) } asDictionary.
	arguments := { (#operation -> 'rename') } asDictionary.
	keywords := self keywordsFrom:
		            (self violationsFor: arguments schema: schema).
	self assert: keywords equals: #( 'required' )
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testValidatesArrayItemsEnumAndConst [

	| arguments schema violations |
	schema := {
		          (#type -> 'object').
		          (#properties -> {
			           ('mode' -> {
				            (#type -> 'string').
				            (#enum -> #( 'method' 'class' )) } asDictionary).
			           ('operation' -> {
				            (#type -> 'string').
				            (#const -> 'rename') } asDictionary).
			           ('names' -> {
				            (#type -> 'array').
				            (#items -> (self schemaPropertyType: 'string')) }
				            asDictionary) } asDictionary) } asDictionary.
	arguments := {
		             (#mode -> 'variable').
		             (#operation -> 'move').
		             (#names -> #( 'first' 2 )) } asDictionary.
	violations := self violationsFor: arguments schema: schema.
	self
		assert: (self keywordsFrom: violations) asBag
		equals: #( 'enum' 'const' 'type' ) asBag
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testValidatesMinItemsAndMinLength [

	| arguments schema violations |
	schema := {
		          (#type -> 'object').
		          (#properties -> { ('rules' -> {
			            (#type -> 'array').
			            (#minItems -> 1).
			            (#items -> {
				             (#type -> 'object').
				             (#properties -> {
					              ('lhs' -> {
						               (#type -> 'string').
						               (#minLength -> 1) } asDictionary).
					              ('rhs' -> {
						               (#type -> 'string').
						               (#minLength -> 1) } asDictionary) } asDictionary) }
				             asDictionary) } asDictionary) } asDictionary) }
		          asDictionary.
	arguments := { (#rules -> { {
		              (#lhs -> '').
		              (#rhs -> '') } asDictionary }) } asDictionary.
	violations := self violationsFor: arguments schema: schema.
	self
		assert: (self keywordsFrom: violations) asBag
		equals: #( 'minLength' 'minLength' ) asBag.
	violations := self
		              violationsFor: { (#rules -> #(  )) } asDictionary
		              schema: schema.
	self assert: (self keywordsFrom: violations) equals: #( 'minItems' )
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testValidatesNot [

	| allowedArguments conflictingArguments directSchema schema violations |
	directSchema := { (#not -> { (#type -> 'string') } asDictionary) }
		                asDictionary.
	self assert: (self violationsFor: 3 schema: directSchema) isEmpty.
	self
		assert:
		(self keywordsFrom:
			 (self violationsFor: 'name' schema: directSchema))
		equals: #( 'not' ).
	schema := {
		          (#type -> 'object').
		          (#not
		           ->
		           { (#required -> #( 'selector' 'references' )) }
			           asDictionary) } asDictionary.
	allowedArguments := { (#selector -> 'yourself') } asDictionary.
	self assert:
		(self violationsFor: allowedArguments schema: schema) isEmpty.
	conflictingArguments := {
		                        (#selector -> 'yourself').
		                        (#references -> {
			                         (#mode -> 'method').
			                         (#target -> 'yourself') } asDictionary) }
		                        asDictionary.
	violations := self violationsFor: conflictingArguments schema: schema.
	self assert: (self keywordsFrom: violations) equals: #( 'not' ).
	self assert: violations first path equals: #(  )
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testValidatesOneOfExactlyOneBranch [

	| invalidSchema validSchema |
	validSchema := { (#oneOf -> {
		                { (#type -> 'string') } asDictionary.
		                { (#type -> 'integer') } asDictionary }) }
		               asDictionary.
	self assert: (self violationsFor: 'name' schema: validSchema) isEmpty.
	self assert: (self violationsFor: 3 schema: validSchema) isEmpty.
	self
		assert:
		(self keywordsFrom: (self violationsFor: true schema: validSchema))
		equals: #( 'oneOf' ).
	invalidSchema := { (#oneOf -> {
		                  { (#type -> 'integer') } asDictionary.
		                  { (#type -> 'number') } asDictionary }) }
		                 asDictionary.
	self
		assert:
		(self keywordsFrom: (self violationsFor: 3 schema: invalidSchema))
		equals: #( 'oneOf' )
]

{ #category : 'private' }
MCPJSONSchemaValidatorTest >> violationsFor: arguments schema: schema [

	^ MCPJSONSchemaValidator violationsFor: arguments schema: schema
]
