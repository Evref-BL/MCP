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

{ #category : 'private - fixtures' }
MCPJSONSchemaValidatorTest >> baseRepresentativeArgumentsByToolClass [

	^ {
		  (MCPToolEvaluate -> { (#code -> '1 + 1') } asDictionary).
		  (MCPToolRunTests -> { (#tests
		    -> { { (#className -> 'MCPToolContractsTest') } asDictionary }) }
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
		  (MCPToolVerifyRepositoryIdentity -> {
			   (#repositoryName -> 'MCP').
			   (#branchName -> 'main') } asDictionary).
		  (MCPToolFindRepositoryChanges
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolEditRepository -> {
			   (#operation -> 'update').
			   (#repositoryName -> 'MCP').
			   (#addPackageNames -> #( 'MCP' )) } asDictionary).
		  (MCPToolExportRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolCommitRepository -> {
			   (#repositoryName -> 'MCP').
			   (#message -> 'Example commit') } asDictionary).
		  (MCPToolFetchRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolPullRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolPushRepository
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolCreateRepositoryBranch -> {
			   (#repositoryName -> 'MCP').
			   (#branchName -> 'example-branch') } asDictionary).
		  (MCPToolSwitchRepositoryBranch -> {
			   (#repositoryName -> 'MCP').
			   (#branchName -> 'main') } asDictionary).
		  (MCPToolAdoptRepositoryHead
		   -> { (#repositoryName -> 'MCP') } asDictionary).
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
		  (MCPToolFindMethodImplementors
		   -> { (#selector -> 'toolName') } asDictionary).
		  (MCPToolFindMethodSenders
		   -> { (#selector -> 'toolName') } asDictionary).
		  (MCPToolFindClassReferences
		   -> { (#className -> 'MCPTool') } asDictionary).
		  (MCPToolFindVariableReferences
		   -> { (#variableName -> 'toolName') } asDictionary).
		  (MCPToolFindChangeHistoryFiles -> Dictionary new).
		  (MCPToolFindChangeHistoryEntries -> Dictionary new).
		  (MCPToolManageChangeHistory
		   -> { (#operation -> 'listFiles') } asDictionary).
		  (MCPToolCaptureScreenshot -> { (#target -> 'world') } asDictionary).
		  (MCPToolDebugSessions -> { (#operation -> 'list') } asDictionary).
		  (MCPToolDebugState
		   -> { (#sessionId -> 'debug-session-1') } asDictionary).
		  (MCPToolDebugVariables
		   ->
			   { (#variableRef
			    -> 'debug-session-1/state-0/frame-0/scope-receiver') }
				   asDictionary).
		  (MCPToolDebugEvaluate -> {
			   (#sessionId -> 'debug-session-1').
			   (#expression -> '1') } asDictionary).
		  (MCPToolDebugControl -> {
			   (#sessionId -> 'debug-session-1').
			   (#operation -> 'stepOver') } asDictionary).
		  (MCPToolDebugBreakpoints
		   -> { (#operation -> 'list') } asDictionary).
		  (MCPToolDebugCapture -> { (#expression -> '1') } asDictionary).
		  (MCPToolDebugEdit
		   -> { (#sessionId -> 'debug-session-1') } asDictionary).
		  (MCPToolFindMethods -> Dictionary new).
		  (MCPToolDiscoverTools -> Dictionary new).
		  (MCPToolInspectTool
		   -> { (#toolName -> 'class_search') } asDictionary).
		  (MCPToolCallTool -> {
			   (#toolName -> 'package_search').
			   (#arguments -> Dictionary new) } asDictionary) } asDictionary
]

{ #category : 'private - fixtures' }
MCPJSONSchemaValidatorTest >> focusedClassEditRepresentativeArgumentsByToolClass [

	^ {
		  (MCPToolCreateClass -> {
			   (#className -> 'MCPJSONSchemaValidatorTestTemporary').
			   (#superclassName -> 'Object').
			   (#packageName -> 'MCP-Tests') } asDictionary).
		  (MCPToolUpdateClassName -> {
			   (#className -> 'MCPTool').
			   (#newClassName -> 'MCPToolRenamed') } asDictionary).
		  (MCPToolUpdateClassSuperclass -> {
			   (#className -> 'MCPTool').
			   (#superclassName -> 'Object') } asDictionary).
		  (MCPToolUpdateClassPackage -> {
			   (#className -> 'MCPTool').
			   (#tag -> 'Tools') } asDictionary).
		  (MCPToolUpdateClassComment -> {
			   (#className -> 'MCPTool').
			   (#classComment -> '') } asDictionary).
		  (MCPToolUpdateClassSlots -> {
			   (#className -> 'MCPTool').
			   (#slots -> #(  )) } asDictionary).
		  (MCPToolUpdateClassTraits -> {
			   (#className -> 'MCPTool').
			   (#traits -> #(  )) } asDictionary).
		  (MCPToolUpdateClassSideTraits -> {
			   (#className -> 'MCPTool').
			   (#classTraits -> #(  )) } asDictionary).
		  (MCPToolUpdateClassSharedVariables -> {
			   (#className -> 'MCPTool').
			   (#sharedVariables -> #(  )) } asDictionary).
		  (MCPToolUpdateClassSharedPools -> {
			   (#className -> 'MCPTool').
			   (#sharedPools -> #(  )) } asDictionary).
		  (MCPToolUpdateClassLayout -> {
			   (#className -> 'MCPTool').
			   (#layout -> 'FixedLayout') } asDictionary).
		  (MCPToolAddClassSlot -> {
			   (#className -> 'MCPTool').
			   (#slotName -> 'temporarySlot') } asDictionary).
		  (MCPToolRemoveClassSlot -> {
			   (#className -> 'MCPTool').
			   (#slotName -> 'temporarySlot') } asDictionary).
		  (MCPToolUpdateClassSlotName -> {
			   (#className -> 'MCPTool').
			   (#slotName -> 'temporarySlot').
			   (#newSlotName -> 'renamedTemporarySlot') } asDictionary).
		  (MCPToolPullUpClassSlot -> {
			   (#className -> 'MCPTool').
			   (#slotName -> 'temporarySlot') } asDictionary).
		  (MCPToolPushDownClassSlot -> {
			   (#className -> 'MCPTool').
			   (#slotName -> 'temporarySlot') } asDictionary) } asDictionary
]

{ #category : 'private' }
MCPJSONSchemaValidatorTest >> keywordsFrom: violations [

	^ violations collect: [ :each | each keyword ]
]

{ #category : 'private - fixtures' }
MCPJSONSchemaValidatorTest >> representativeArgumentsByToolClass [

	| arguments |
	arguments := self baseRepresentativeArgumentsByToolClass.
	arguments removeKey: MCPToolEditRepository ifAbsent: [ ].
	arguments removeKey: MCPToolEditClass ifAbsent: [ ].
	arguments removeKey: MCPToolEditMethod ifAbsent: [ ].
	arguments removeKey: MCPToolManageChangeHistory ifAbsent: [ ].
	arguments removeKey: MCPToolDebugSessions ifAbsent: [ ].
	arguments removeKey: MCPToolDebugControl ifAbsent: [ ].
	arguments removeKey: MCPToolDebugBreakpoints ifAbsent: [ ].
	self focusedClassEditRepresentativeArgumentsByToolClass
		keysAndValuesDo: [ :toolClass :representativeArguments |
			arguments at: toolClass put: representativeArguments ].
	arguments
		at: MCPToolCreateMethod put: {
				(#className -> 'MCPTool').
				(#methodSource -> 'temporarySelector ^ self').
				(#protocol -> 'tests') } asDictionary;
		at: MCPToolUpdateMethodSelector put: {
				(#className -> 'MCPTool').
				(#selector -> 'defaultName').
				(#newSelector -> 'defaultTitle') } asDictionary;
		at: MCPToolUpdateMethodProtocol put: {
				(#className -> 'MCPTool').
				(#selector -> 'defaultName').
				(#protocol -> 'accessing') } asDictionary;
		at: MCPToolCreateRepository put: {
				(#name -> 'MCP Test Repository').
				(#location -> '/tmp/mcp-test-repository') } asDictionary;
		at: MCPToolAttachRepository put: {
				(#name -> 'MCP Test Repository').
				(#location -> '/tmp/mcp-test-repository') } asDictionary;
		at: MCPToolUpdateRepository
		put: { (#repositoryName -> 'MCP') } asDictionary;
		at: MCPToolLoadBaseline
		put: { (#baseline -> 'ExampleBaseline') } asDictionary;
		at: MCPToolApplyChangeHistoryEntries
		put: { (#latestCount -> 1) } asDictionary;
		at: MCPToolRevertChangeHistoryEntries
		put: { (#latestCount -> 1) } asDictionary;
		at: MCPToolListDebugSessions put: Dictionary new;
		at: MCPToolGetDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolRemoveDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolSearchDebugCandidates put: Dictionary new;
		at: MCPToolAttachDebugCandidate
		put: { (#candidateRef -> 'debugger-candidate-1') } asDictionary;
		at: MCPToolStepIntoDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolStepOverDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolStepThroughDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolRestartDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolResumeDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolTerminateDebugSession
		put: { (#sessionId -> 'debug-session-1') } asDictionary;
		at: MCPToolListDebugBreakpoints put: Dictionary new;
		at: MCPToolSetDebugBreakpoint put: {
				(#className -> 'MCPJSONSchemaValidatorTest').
				(#selector -> 'testCurrentToolSchemasValidate') } asDictionary;
		at: MCPToolRemoveDebugBreakpoint
		put: { (#breakpointId -> 'debug-breakpoint-1') } asDictionary;
		at: MCPToolEnableDebugBreakpoint
		put: { (#breakpointId -> 'debug-breakpoint-1') } asDictionary;
		at: MCPToolDisableDebugBreakpoint
		put: { (#breakpointId -> 'debug-breakpoint-1') } asDictionary;
		at: MCPToolClearDebugBreakpoints put: Dictionary new;
		at: MCPToolDebugTest put: {
				(#className -> 'MCPToolContractsTest').
				(#testMethodName -> 'testDebuggerToolsAreDiscoverableOnly') }
				asDictionary.
	^ arguments
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

	| legacyScopeViolations selectorUpdateViolations |
	legacyScopeViolations := self
		                         violationsFor:
		                         { (#scope -> 'packages') } asDictionary
		                         schema: MCPToolFindClasses new inputSchema.
	self
		assert: (self keywordsFrom: legacyScopeViolations)
		equals: #( 'additionalProperties' ).
	selectorUpdateViolations := self
		                            violationsFor: {
				                            (#className -> 'MCPTool').
				                            (#selector -> 'defaultName').
				                            (#newSelector -> 'defaultTitle').
				                            (#scope -> 'classes') } asDictionary
		                            schema:
		                            MCPToolUpdateMethodSelector new
			                            inputSchema.
	self
		assert: (self keywordsFrom: selectorUpdateViolations)
		equals: #( 'additionalProperties' )
]

{ #category : 'tests' }
MCPJSONSchemaValidatorTest >> testCurrentToolRequestValidationRejectsOperationSpecificMissingArguments [

	self
		should: [
				MCPToolCreateClass new requestFromToolCallArguments:
					{ (#className -> 'MCPTool') } asDictionary ]
		raise: MCPInvalidToolInput.
	self
		should: [
				MCPToolUpdateClassPackage new requestFromToolCallArguments:
					{ (#className -> 'MCPTool') } asDictionary ]
		raise: MCPInvalidToolInput.
	self
		should: [
				MCPToolCommitRepository new requestFromToolCallArguments:
					{ (#repositoryName -> 'MCP') } asDictionary ]
		raise: MCPInvalidToolInput.
	self
		should: [
				MCPToolRunTests new requestFromToolCallArguments: {
						(#operation -> 'coverage').
						(#tests
						 -> { { (#className -> 'MCPToolContractsTest') } asDictionary }) }
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
