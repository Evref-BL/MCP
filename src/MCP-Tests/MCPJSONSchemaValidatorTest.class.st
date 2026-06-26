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
		  (MCPToolRunTests
		   -> { (#classes -> { 'MCPToolContractsTest' }) } asDictionary).
		  (MCPToolGetClass -> { (#className -> 'MCPTool') } asDictionary).
		  (MCPToolGetMethod -> {
			   (#className -> 'MCPTool').
			   (#selector -> 'name') } asDictionary).
		  (MCPToolRemoveClasses
		   ->
			   { (#classNames -> #( 'MCPJSONSchemaValidatorTestTemporary' )) }
				   asDictionary).
		  (MCPToolRemoveMethods -> {
			   (#className -> 'MCPTool').
			   (#selectors -> #( 'temporarySelector' )) } asDictionary).
		  (MCPToolSearchRepositories -> Dictionary new).
		  (MCPToolVerifyRepositoryIdentity -> {
			   (#repositoryName -> 'MCP').
			   (#branchName -> 'main') } asDictionary).
		  (MCPToolListRepositoryChanges
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolRepositoryOperation -> {
			   (#action -> 'update').
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
		  (MCPToolCheckoutRepositoryBranch -> {
			   (#repositoryName -> 'MCP').
			   (#branchName -> 'main') } asDictionary).
		  (MCPToolAdoptRepositoryHead
		   -> { (#repositoryName -> 'MCP') } asDictionary).
		  (MCPToolLoadRepository -> {
			   (#owner -> 'ExampleOwner').
			   (#project -> 'ExampleProject').
			   (#baseline -> 'ExampleBaseline').
			   (#sourceDirectory -> 'src') } asDictionary).
		  (MCPToolSearchClasses -> Dictionary new).
		  (MCPToolSearchPackages -> Dictionary new).
		  (MCPToolClassMutation -> {
			   (#action -> 'update').
			   (#className -> 'MCPTool').
			   (#newClassName -> 'MCPToolRenamed') } asDictionary).
		  (MCPToolMethodMutation -> {
			   (#action -> 'create').
			   (#className -> 'MCPTool').
			   (#source -> 'temporarySelector ^ self').
			   (#protocol -> 'tests') } asDictionary).
		  (MCPToolRewriteMethods -> { (#rules -> { {
			    (#lhs -> 'self').
			    (#rhs -> 'self') } asDictionary }) } asDictionary).
		  (MCPToolSearchMethodImplementors
		   -> { (#selector -> 'toolName') } asDictionary).
		  (MCPToolSearchMethodSenders
		   -> { (#selector -> 'toolName') } asDictionary).
		  (MCPToolSearchClassReferences
		   -> { (#className -> 'MCPTool') } asDictionary).
		  (MCPToolSearchVariableReferences
		   -> { (#variableName -> 'toolName') } asDictionary).
		  (MCPToolListChangeHistoryFiles -> Dictionary new).
		  (MCPToolListChangeHistoryEntries -> Dictionary new).
		  (MCPToolChangeHistory -> { (#action -> 'listFiles') } asDictionary).
		  (MCPToolCaptureScreenshot -> { (#target -> 'world') } asDictionary).
		  (MCPToolDebugSessionOperation
		   -> { (#action -> 'list') } asDictionary).
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
		  (MCPToolDebugSessionControlOperation -> {
			   (#sessionId -> 'debug-session-1').
			   (#action -> 'stepOver') } asDictionary).
		  (MCPToolDebugBreakpointOperation
		   -> { (#action -> 'list') } asDictionary).
		  (MCPToolDebugCapture -> { (#expression -> '1') } asDictionary).
		  (MCPToolUpdateDebugMethod
		   -> { (#sessionId -> 'debug-session-1') } asDictionary).
		  (MCPToolSearchMethodMetadata -> Dictionary new).
		  (MCPToolSearchTools -> Dictionary new).
		  (MCPToolGetTool -> { (#toolName -> 'class_search') } asDictionary).
		  (MCPToolCallTool -> {
			   (#toolName -> 'package_search').
			   (#arguments -> Dictionary new) } asDictionary) } asDictionary
]

{ #category : 'private - fixtures' }
MCPJSONSchemaValidatorTest >> classMutationRepresentativeArgumentsByToolClass [

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

{ #category : 'private' }
MCPJSONSchemaValidatorTest >> representativeArgumentsByToolClass [

	| arguments |
	arguments := self baseRepresentativeArgumentsByToolClass.
	arguments removeKey: MCPToolRepositoryOperation ifAbsent: [ ].
	arguments removeKey: MCPToolClassMutation ifAbsent: [ ].
	arguments removeKey: MCPToolMethodMutation ifAbsent: [ ].
	arguments removeKey: MCPToolChangeHistory ifAbsent: [ ].
	arguments removeKey: MCPToolDebugSessionOperation ifAbsent: [ ].
	arguments
		removeKey: MCPToolDebugSessionControlOperation
		ifAbsent: [ ].
	arguments removeKey: MCPToolDebugBreakpointOperation ifAbsent: [ ].
	self classMutationRepresentativeArgumentsByToolClass
		keysAndValuesDo: [ :toolClass :representativeArguments |
			arguments at: toolClass put: representativeArguments ].
	arguments
		at: MCPToolSearchMethodSource
		put: { (#filter -> 'method') } asDictionary;
		at: MCPToolSearchEquivalentMethods put: {
				(#className -> 'Object').
				(#selector -> 'class') } asDictionary;
		at: MCPToolCompileMethod put: {
				(#className -> 'MCPTool').
				(#source -> 'temporarySelector ^ self').
				(#protocol -> 'tests') } asDictionary;
		at: MCPToolUpdateMethodSelector put: {
				(#className -> 'MCPTool').
				(#selector -> 'name').
				(#newSelector -> 'toolTitleForTesting') } asDictionary;
		at: MCPToolUpdateMethodProtocol put: {
				(#className -> 'MCPTool').
				(#selector -> 'name').
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
		at: MCPToolRunTestCoverage put: {
				(#classes -> { 'MCPToolContractsTest' }).
				(#coverage -> { (#scope
					  -> { (#classes -> #( 'MCPToolContractsTest' )) } asDictionary) }
						 asDictionary) } asDictionary;
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
MCPJSONSchemaValidatorTest >> testCurrentToolInputSchemasAdvertiseGroupedSearchScope [

	| classProperties classScopeProperties methodProperties methodScopeProperties |
	classProperties := MCPToolSearchClasses new inputSchema properties.
	methodProperties := MCPToolSearchMethodMetadata new inputSchema
		                    properties.
	classScopeProperties := ((classProperties detect: [ :each |
		                          each name = 'scope' ]) extraProperties
		                         at: #properties) collect: [ :each |
		                        each name ].
	methodScopeProperties := ((methodProperties detect: [ :each |
		                           each name = 'scope' ]) extraProperties
		                          at: #properties) collect: [ :each |
		                         each name ].
	self
		assert: (classProperties collect: [ :each | each name ]) asSet
		equals:
			#( 'scope' 'className' 'tag' 'instanceSlot' 'classSlot' 'filterMode'
			   'caseSensitive' 'limit' 'offset' ) asSet.
	self
		assert: (methodProperties collect: [ :each | each name ]) asSet
		equals:
			#( 'scope' 'selector' 'protocol' 'filterMode' 'side' 'includeSource'
			   'limit' 'offset' 'caseSensitive' ) asSet.
	self
		assert: classScopeProperties asSet
		equals:
			#( 'classes' 'packages' 'superclassesOf' 'subclassesOf'
			   'hierarchies' ) asSet.
	self
		assert: methodScopeProperties asSet
		equals: classScopeProperties asSet
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
				MCPToolRunTestCoverage new requestFromToolCallArguments:
					{ (#classes -> { 'MCPToolContractsTest' }) } asDictionary ]
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

	| additionalPropertyViolation arguments keywords schema violations |
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
	self assert: (keywords includes: 'additionalProperties').
	additionalPropertyViolation := (violations detect: [ :each |
		                                each keyword
		                                = 'additionalProperties' ])
		                               asDictionary.
	self assert: additionalPropertyViolation equals: {
			(#path -> #( 'extra' )).
			(#keyword -> 'additionalProperties').
			(#message -> 'Object contains an unexpected property.').
			(#actual -> 'extra') } asDictionary
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
MCPJSONSchemaValidatorTest >> testValidatesMinimumAndMaximum [

	| schema violations |
	schema := {
		          (#type -> 'object').
		          (#properties -> { ('count' -> {
			            (#type -> 'integer').
			            (#minimum -> 0).
			            (#maximum -> 100) } asDictionary) } asDictionary) }
		          asDictionary.
	self assert:
		(self violationsFor: { (#count -> 25) } asDictionary schema: schema)
			isEmpty.
	violations := self
		              violationsFor: { (#count -> -1) } asDictionary
		              schema: schema.
	self assert: (self keywordsFrom: violations) equals: #( 'minimum' ).
	violations := self
		              violationsFor: { (#count -> 101) } asDictionary
		              schema: schema.
	self assert: (self keywordsFrom: violations) equals: #( 'maximum' )
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
