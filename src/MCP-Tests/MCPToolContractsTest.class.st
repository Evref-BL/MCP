"
Tests shared MCP tool contracts and catalog metadata.
"
Class {
	#name : 'MCPToolContractsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolContractsTest >> assertNoCompositionKeywordsIn: aValue [

	self assertNoCompositionKeywordsIn: aValue path: #(  )
]

{ #category : 'private' }
MCPToolContractsTest >> assertNoCompositionKeywordsIn: aValue path: path [

	| compositionKeywords |
	compositionKeywords := #( oneOf anyOf allOf ).
	aValue isDictionary ifTrue: [
		compositionKeywords do: [ :keyword |
			self deny: (aValue includesKey: keyword).
			self deny: (aValue includesKey: keyword asString) ].
		aValue keysAndValuesDo: [ :key :nestedValue |
			self
				assertNoCompositionKeywordsIn: nestedValue
				path: (path copyWith: key) ].
		^ self ].
	(aValue isCollection and: [ aValue isString not ]) ifTrue: [
		aValue withIndexDo: [ :nestedValue :index |
			self
				assertNoCompositionKeywordsIn: nestedValue
				path: (path copyWith: index) ] ]
]

{ #category : 'private' }
MCPToolContractsTest >> assertToolFlowSpec: aSpec [

	| command parsedRequest rawRequest tool |
	tool := (aSpec at: #toolClass) new.
	rawRequest := tool requestFromToolCallArguments:
		              (aSpec at: #arguments).
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.
	self assert: parsedRequest class equals: (aSpec at: #requestClass).
	self assert: command class equals: (aSpec at: #commandClass)
]

{ #category : 'support' }
MCPToolContractsTest >> baseToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolSearchRepositories).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPRepositoryQuerySpec).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolLoadRepository).
			  (#arguments -> {
				   (#owner -> 'ExampleOwner').
				   (#project -> 'ExampleProject').
				   (#baseline -> 'ExampleBaseline').
				   (#sourceDirectory -> 'src') } asDictionary).
			  (#requestClass -> MCPLoadRepositoryRequest).
			  (#commandClass -> MCPLoadRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchPackages).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPSearchPackagesRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchClasses).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPSearchClassesRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolGetClass).
			  (#arguments -> { (#className -> 'Object') } asDictionary).
			  (#requestClass -> MCPGetClassRequest).
			  (#commandClass -> MCPGetClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRemoveClasses).
			  (#arguments -> { (#classNames -> #( 'Object' )) } asDictionary).
			  (#requestClass -> MCPRemoveClassesRequest).
			  (#commandClass -> MCPRemoveClassesCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchMethodMetadata).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPMethodSearchRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolGetMethod).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#selector -> 'class') } asDictionary).
			  (#requestClass -> MCPGetMethodRequest).
			  (#commandClass -> MCPGetMethodCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRewriteMethods).
			  (#arguments -> { (#rules -> { {
				    (#lhs -> 'self').
				    (#rhs -> 'self') } asDictionary }) } asDictionary).
			  (#requestClass -> MCPMethodRewriteRequest).
			  (#commandClass -> MCPRewriteMethodsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRemoveMethods).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#selectors -> #( 'class' )) } asDictionary).
			  (#requestClass -> MCPRemoveMethodsRequest).
			  (#commandClass -> MCPRemoveMethodsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRunTests).
			  (#arguments -> { (#tests
			    -> { { (#className -> 'MCPToolContractsTest') } asDictionary }) }
				   asDictionary).
			  (#requestClass -> MCPRunTestsRequest).
			  (#commandClass -> MCPRunTestsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCaptureScreenshot).
			  (#arguments -> { (#target -> 'world') } asDictionary).
			  (#requestClass -> MCPScreenshotRequest).
			  (#commandClass -> MCPScreenshotCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDebugState).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugStateRequest).
			  (#commandClass -> MCPDebugStateCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDebugVariables).
			  (#arguments
			   ->
				   { (#variableRef
				    -> 'debug-session-1/state-0/frame-0/scope-receiver') }
					   asDictionary).
			  (#requestClass -> MCPDebugVariablesRequest).
			  (#commandClass -> MCPDebugVariablesCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDebugEvaluate).
			  (#arguments -> {
				   (#sessionId -> 'debug-session-1').
				   (#expression -> '1') } asDictionary).
			  (#requestClass -> MCPDebugEvaluateRequest).
			  (#commandClass -> MCPDebugEvaluateCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDebugCapture).
			  (#arguments -> { (#expression -> '1') } asDictionary).
			  (#requestClass -> MCPDebugCaptureRequest).
			  (#commandClass -> MCPDebugCaptureCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateDebugMethod).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPUpdateDebugMethodRequest).
			  (#commandClass -> MCPUpdateDebugMethodCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolEvaluate).
			  (#arguments -> { (#code -> '1') } asDictionary).
			  (#requestClass -> MCPEvaluateRequest).
			  (#commandClass -> MCPEvaluateCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchTools).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPSearchToolsRequest).
			  (#commandClass -> MCPSearchToolsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolGetTool).
			  (#arguments -> { (#toolName -> 'class_search') } asDictionary).
			  (#requestClass -> MCPGetToolRequest).
			  (#commandClass -> MCPGetToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCallTool).
			  (#arguments -> {
				   (#toolName -> 'package_search').
				   (#arguments -> Dictionary new) } asDictionary).
			  (#requestClass -> MCPCallToolRequest).
			  (#commandClass -> MCPCallToolCommand) } asDictionary }

]

{ #category : 'private' }
MCPToolContractsTest >> baselineLoadToolFlowSpec [

	^ {
		  (#toolClass -> MCPToolLoadBaseline).
		  (#arguments -> { (#baseline -> 'ExampleBaseline') } asDictionary).
		  (#requestClass -> MCPLoadBaselineRequest).
		  (#commandClass -> MCPLoadBaselineCommand) } asDictionary
]

{ #category : 'private' }
MCPToolContractsTest >> changeHistoryToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolListChangeHistoryFiles).
			  (#arguments -> { (#includeEntryCounts -> false) } asDictionary).
			  (#requestClass -> MCPChangeHistoryListLogsRequest).
			  (#commandClass -> MCPListChangeHistoryLogsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolListChangeHistoryEntries).
			  (#arguments -> { (#limit -> 1) } asDictionary).
			  (#requestClass -> MCPChangeHistoryListEntriesRequest).
			  (#commandClass -> MCPListChangeHistoryEntriesCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolApplyChangeHistoryEntries).
			  (#arguments -> { (#latestCount -> 1) } asDictionary).
			  (#requestClass -> MCPChangeHistorySelectionRequest).
			  (#commandClass -> MCPChangeHistorySelectionCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolRevertChangeHistoryEntries).
			  (#arguments -> { (#latestCount -> 1) } asDictionary).
			  (#requestClass -> MCPChangeHistorySelectionRequest).
			  (#commandClass -> MCPChangeHistorySelectionCommand) }
			  asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> classMutationToolClasses [

	^ {
		  MCPToolCreateClass.
		  MCPToolUpdateClassName.
		  MCPToolUpdateClassSuperclass.
		  MCPToolUpdateClassPackage.
		  MCPToolUpdateClassComment.
		  MCPToolUpdateClassSlots.
		  MCPToolUpdateClassTraits.
		  MCPToolUpdateClassSideTraits.
		  MCPToolUpdateClassSharedVariables.
		  MCPToolUpdateClassSharedPools.
		  MCPToolUpdateClassLayout.
		  MCPToolAddClassSlot.
		  MCPToolRemoveClassSlot.
		  MCPToolUpdateClassSlotName.
		  MCPToolPullUpClassSlot.
		  MCPToolPushDownClassSlot }
]

{ #category : 'private' }
MCPToolContractsTest >> classMutationToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolCreateClass).
			  (#arguments -> {
				   (#className -> 'MCPTemporaryClass').
				   (#superclassName -> 'Object').
				   (#packageName -> 'MCP-Tests') } asDictionary).
			  (#requestClass -> MCPClassCreateRequest).
			  (#commandClass -> MCPCreateClassToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassName).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#newClassName -> 'MCPObject') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassSuperclass).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#superclassName -> 'ProtoObject') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassPackage).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#tag -> 'Kernel') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassComment).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#classComment -> '') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassSlots).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#slots -> #(  )) } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassTraits).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#traits -> #(  )) } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassSideTraits).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#classTraits -> #(  )) } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassSharedVariables).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#sharedVariables -> #(  )) } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassSharedPools).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#sharedPools -> #(  )) } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassLayout).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#layout -> 'FixedLayout') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolAddClassSlot).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#slotName -> 'temporarySlot') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRemoveClassSlot).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#slotName -> 'temporarySlot') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateClassSlotName).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#slotName -> 'temporarySlot').
				   (#newSlotName -> 'renamedTemporarySlot') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPullUpClassSlot).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#slotName -> 'temporarySlot') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPushDownClassSlot).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#slotName -> 'temporarySlot') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> coverageToolFlowSpec [

	^ {
		  (#toolClass -> MCPToolRunTestCoverage).
		  (#arguments -> {
			   (#tests
			    -> { { (#className -> 'MCPToolContractsTest') } asDictionary }).
			   (#coverage
			    ->
			    { (#classNames -> #( 'MCPToolContractsTest' )) } asDictionary) }
			   asDictionary).
		  (#requestClass -> MCPRunTestsRequest).
		  (#commandClass -> MCPRunTestsCommand) } asDictionary
]

{ #category : 'private' }
MCPToolContractsTest >> debugBreakpointToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolListDebugBreakpoints).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPDebugBreakpointsRequest).
			  (#commandClass -> MCPDebugBreakpointsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSetDebugBreakpoint).
			  (#arguments -> {
				   (#className -> 'MCPToolContractsTest').
				   (#selector -> 'testDebuggerToolsAreDiscoverableOnly') }
				   asDictionary).
			  (#requestClass -> MCPDebugBreakpointsRequest).
			  (#commandClass -> MCPDebugBreakpointsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRemoveDebugBreakpoint).
			  (#arguments
			   -> { (#breakpointId -> 'debug-breakpoint-1') } asDictionary).
			  (#requestClass -> MCPDebugBreakpointsRequest).
			  (#commandClass -> MCPDebugBreakpointsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolEnableDebugBreakpoint).
			  (#arguments
			   -> { (#breakpointId -> 'debug-breakpoint-1') } asDictionary).
			  (#requestClass -> MCPDebugBreakpointsRequest).
			  (#commandClass -> MCPDebugBreakpointsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDisableDebugBreakpoint).
			  (#arguments
			   -> { (#breakpointId -> 'debug-breakpoint-1') } asDictionary).
			  (#requestClass -> MCPDebugBreakpointsRequest).
			  (#commandClass -> MCPDebugBreakpointsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolClearDebugBreakpoints).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPDebugBreakpointsRequest).
			  (#commandClass -> MCPDebugBreakpointsCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> debugControlToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolStepIntoDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugControlRequest).
			  (#commandClass -> MCPDebugControlCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolStepOverDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugControlRequest).
			  (#commandClass -> MCPDebugControlCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolStepThroughDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugControlRequest).
			  (#commandClass -> MCPDebugControlCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRestartDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugControlRequest).
			  (#commandClass -> MCPDebugControlCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolResumeDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugControlRequest).
			  (#commandClass -> MCPDebugControlCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolTerminateDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugControlRequest).
			  (#commandClass -> MCPDebugControlCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> debugSessionToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolListDebugSessions).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPDebugSessionsRequest).
			  (#commandClass -> MCPDebugSessionsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolGetDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugSessionsRequest).
			  (#commandClass -> MCPDebugSessionsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRemoveDebugSession).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugSessionsRequest).
			  (#commandClass -> MCPDebugSessionsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchDebugCandidates).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPDebugSessionsRequest).
			  (#commandClass -> MCPDebugSessionsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolAttachDebugCandidate).
			  (#arguments
			   -> { (#candidateRef -> 'debugger-candidate-1') } asDictionary).
			  (#requestClass -> MCPDebugSessionsRequest).
			  (#commandClass -> MCPDebugSessionsCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> debugTestToolFlowSpec [

	^ {
		  (#toolClass -> MCPToolDebugTest).
		  (#arguments -> {
			   (#className -> 'MCPToolContractsTest').
			   (#testMethodName -> 'testDebuggerToolsAreDiscoverableOnly') }
			   asDictionary).
		  (#requestClass -> MCPDebugTestRequest).
		  (#commandClass -> MCPDebugTestCommand) } asDictionary
]

{ #category : 'private' }
MCPToolContractsTest >> firstTextFromToolResult: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private' }
MCPToolContractsTest >> handleJSON: aJSONString [

	^ MCP new server messageProcessor handleJSON: aJSONString
]

{ #category : 'private' }
MCPToolContractsTest >> inputPropertyNamed: aPropertyName inTool: aTool [

	^ aTool inputSchema properties detect: [ :each |
		  each name = aPropertyName ]
]

{ #category : 'private' }
MCPToolContractsTest >> mcpClassesInPackageTagNamed: aTagName [

	^ ((PackageOrganizer default packageNamed: #MCP) definedClasses
		   select: [ :each | each packageTagName asString = aTagName ])
		  asArray
]

{ #category : 'private' }
MCPToolContractsTest >> methodLookupToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolSearchMethodSource).
			  (#arguments -> { (#filter -> 'class') } asDictionary).
			  (#requestClass -> MCPMethodSearchRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchEquivalentMethods).
			  (#arguments -> {
				   (#className -> 'MCPTool').
				   (#selector -> 'defaultName') } asDictionary).
			  (#requestClass -> MCPSearchEquivalentMethodsRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchMethodImplementors).
			  (#arguments -> { (#selector -> 'class') } asDictionary).
			  (#requestClass -> MCPMethodSearchRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchMethodSenders).
			  (#arguments -> { (#selector -> 'class') } asDictionary).
			  (#requestClass -> MCPMethodSearchRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchClassReferences).
			  (#arguments -> { (#className -> 'Object') } asDictionary).
			  (#requestClass -> MCPMethodSearchRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolSearchVariableReferences).
			  (#arguments -> { (#variableName -> 'instVarNamed') } asDictionary).
			  (#requestClass -> MCPMethodSearchRequest).
			  (#commandClass -> MCPSearchToolCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> methodMutationToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolCreateMethod).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#methodSource -> 'mcpTemporaryMethod ^ self').
				   (#protocol -> 'tests') } asDictionary).
			  (#requestClass -> MCPMethodCreateRequest).
			  (#commandClass -> MCPCreateMethodCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateMethodSelector).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#selector -> 'class').
				   (#newSelector -> 'mcpClass') } asDictionary).
			  (#requestClass -> MCPMethodUpdateRequest).
			  (#commandClass -> MCPUpdateMethodCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateMethodProtocol).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#selector -> 'class').
				   (#protocol -> 'accessing') } asDictionary).
			  (#requestClass -> MCPMethodUpdateRequest).
			  (#commandClass -> MCPUpdateMethodCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> repositoryToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolVerifyRepositoryIdentity).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#requestClass -> MCPRepositoryVerifyIdentityRequest).
			  (#commandClass -> MCPRepositoryVerifyIdentityCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolListRepositoryChanges).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#requestClass -> MCPRepositoryDiffRequest).
			  (#commandClass -> MCPRepositoryDiffCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepository).
			  (#arguments -> {
				   (#name -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#requestClass -> MCPRepositoryCreateRequest).
			  (#commandClass -> MCPCreateRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolAttachRepository).
			  (#arguments -> {
				   (#name -> 'MCP Test Repository').
				   (#location -> '/tmp/mcp-test-repository') } asDictionary).
			  (#requestClass -> MCPRepositoryAttachRequest).
			  (#commandClass -> MCPAttachRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolUpdateRepository).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#addPackageNames -> #( 'MCP' )) } asDictionary).
			  (#requestClass -> MCPRepositoryUpdateRequest).
			  (#commandClass -> MCPUpdateRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolExportRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#requestClass -> MCPRepositoryExportRequest).
			  (#commandClass -> MCPExportRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCommitRepository).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#message -> 'Commit from test') } asDictionary).
			  (#requestClass -> MCPRepositoryCommitRequest).
			  (#commandClass -> MCPCommitRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFetchRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#requestClass -> MCPRepositoryFetchRequest).
			  (#commandClass -> MCPFetchRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPullRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#requestClass -> MCPRepositoryPullRequest).
			  (#commandClass -> MCPPullRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolPushRepository).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#requestClass -> MCPRepositoryPushRequest).
			  (#commandClass -> MCPPushRepositoryCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolCreateRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'feature') } asDictionary).
			  (#requestClass -> MCPRepositoryCreateBranchRequest).
			  (#commandClass -> MCPCreateRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolSwitchRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#requestClass -> MCPRepositorySwitchBranchRequest).
			  (#commandClass -> MCPSwitchRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolCheckoutRepositoryBranch).
			  (#arguments -> {
				   (#repositoryName -> 'MCP').
				   (#branchName -> 'main') } asDictionary).
			  (#requestClass -> MCPRepositoryCheckoutBranchRequest).
			  (#commandClass -> MCPCheckoutRepositoryBranchCommand) }
			  asDictionary.
		  {
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#requestClass -> MCPRepositoryAdoptHeadRequest).
			  (#commandClass -> MCPAdoptRepositoryHeadCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> signalHaltForMCPMessageProcessorTest [

	(Smalltalk globals at: #Halt) signal: 'mcp processor halt test'
]

{ #category : 'tests' }
MCPToolContractsTest >> testAllToolInputSchemasAvoidCompositionKeywords [

	MCPTool concreteSubclasses do: [ :toolClass |
		self assertNoCompositionKeywordsIn:
			(toolClass new asJRPCJSON at: #inputSchema) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testAllToolOutputSchemasAdvertiseStructuredSummaryWarningsAndStatus [

	MCPTool concreteSubclasses do: [ :toolClass |
		| outputSchema propertyNames statusProperty |
		outputSchema := toolClass new outputSchema.
		propertyNames := outputSchema properties collect: [ :each |
			                 each name ].
		statusProperty := outputSchema properties detect: [ :each |
			                  each name = 'status' ].
		self assert: (propertyNames includes: 'summary').
		self assert: (propertyNames includes: 'warnings').
		self
			assert: (statusProperty extraProperties at: #enum) asArray
			equals: #( 'ok' 'error' ) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testAllToolsHavePngIconsWithDataUris [

	MCPTool concreteSubclasses do: [ :toolClass |
			| icon icons |
			icons := toolClass new icons.
			self deny: icons isEmpty.
			icon := icons first.
			self assert: icon mimeType equals: 'image/png'.
			self assert: (icon src beginsWith: 'data:image/png;base64,').
			self assert: icon sizes size equals: 1.
			self assert: (icon sizes first includesSubstring: 'x') ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testAllToolsUseParsedRequestsAndCommands [

	| toolClasses |
	toolClasses := self toolFlowSpecs collect: [ :each |
		               each at: #toolClass ].
	self
		assert: toolClasses asSet
		equals: MCPTool concreteSubclasses asSet.
	self toolFlowSpecs do: [ :each | self assertToolFlowSpec: each ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testBaseToolDoesNotOwnToolSpecificPrivateHelpers [

	#( testIssueObjectSchema defaultFilterMode filterModeFromRequest:
	   normalizeFilterString:caseSensitive:
	   matcherForPattern:mode:caseSensitive:
	   methodScopeQueryFromRequest: targetNameForBehavior:
	   methodReferenceForBehavior:selector:
	   methodReferenceForClassName:selector:isClassSide:
	   methodEntryLabel: selectorStringFromRequest:
	   behaviorNamed:classSide: ) do: [ :selector |
		self deny: (MCPTool includesSelector: selector) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testBrowseIconToolGroupsKeepRelatedToolsTogether [

	| orderedTools |
	orderedTools := OrderedCollection new.
	MCPTool toolGroups do: [ :group | orderedTools addAll: group value ].
	self
		assert: orderedTools asSet
		equals: MCPTool concreteSubclasses asSet.
	self assert: orderedTools asArray equals: {
			MCPToolSearchTools.
			MCPToolGetTool.
			MCPToolCallTool.
			MCPToolSearchRepositories.
			MCPToolVerifyRepositoryIdentity.
			MCPToolListRepositoryChanges.
			MCPToolCreateRepository.
			MCPToolAttachRepository.
			MCPToolUpdateRepository.
			MCPToolExportRepository.
			MCPToolCommitRepository.
			MCPToolFetchRepository.
			MCPToolPullRepository.
			MCPToolPushRepository.
			MCPToolCreateRepositoryBranch.
			MCPToolSwitchRepositoryBranch.
			MCPToolCheckoutRepositoryBranch.
			MCPToolAdoptRepositoryHead.
			MCPToolLoadBaseline.
			MCPToolLoadRepository.
			MCPToolSearchPackages.
			MCPToolSearchClasses.
			MCPToolGetClass.
			MCPToolCreateClass.
			MCPToolUpdateClassName.
			MCPToolUpdateClassSuperclass.
			MCPToolUpdateClassPackage.
			MCPToolUpdateClassComment.
			MCPToolUpdateClassSlots.
			MCPToolUpdateClassTraits.
			MCPToolUpdateClassSideTraits.
			MCPToolUpdateClassSharedVariables.
			MCPToolUpdateClassSharedPools.
			MCPToolUpdateClassLayout.
			MCPToolAddClassSlot.
			MCPToolRemoveClassSlot.
			MCPToolUpdateClassSlotName.
			MCPToolPullUpClassSlot.
			MCPToolPushDownClassSlot.
			MCPToolRemoveClasses.
			MCPToolSearchMethodMetadata.
			MCPToolSearchMethodSource.
			MCPToolSearchEquivalentMethods.
			MCPToolSearchMethodImplementors.
			MCPToolSearchMethodSenders.
			MCPToolSearchClassReferences.
			MCPToolSearchVariableReferences.
			MCPToolGetMethod.
			MCPToolCreateMethod.
			MCPToolUpdateMethodSelector.
			MCPToolUpdateMethodProtocol.
			MCPToolRewriteMethods.
			MCPToolRemoveMethods.
			MCPToolListChangeHistoryFiles.
			MCPToolListChangeHistoryEntries.
			MCPToolApplyChangeHistoryEntries.
			MCPToolRevertChangeHistoryEntries.
			MCPToolRunTests.
			MCPToolRunTestCoverage.
			MCPToolCaptureScreenshot.
			MCPToolListDebugSessions.
			MCPToolGetDebugSession.
			MCPToolRemoveDebugSession.
			MCPToolSearchDebugCandidates.
			MCPToolAttachDebugCandidate.
			MCPToolDebugState.
			MCPToolDebugVariables.
			MCPToolDebugEvaluate.
			MCPToolStepIntoDebugSession.
			MCPToolStepOverDebugSession.
			MCPToolStepThroughDebugSession.
			MCPToolRestartDebugSession.
			MCPToolResumeDebugSession.
			MCPToolTerminateDebugSession.
			MCPToolListDebugBreakpoints.
			MCPToolSetDebugBreakpoint.
			MCPToolRemoveDebugBreakpoint.
			MCPToolEnableDebugBreakpoint.
			MCPToolDisableDebugBreakpoint.
			MCPToolClearDebugBreakpoints.
			MCPToolDebugCapture.
			MCPToolDebugTest.
			MCPToolUpdateDebugMethod.
			MCPToolEvaluate }
]

{ #category : 'tests' }
MCPToolContractsTest >> testCallToolInvokesDiscoverableToolAfterStaticConfiguration [

	| data result server |
	server := MCP new.
	server staticToolNames: #( 'tool_search' 'tool_get' 'tool_call' ).
	result := server rpcToolCall: 'tool_call' withParams: {
			          (#toolName -> 'package_search').
			          (#arguments -> {
				           (#packageName -> 'MCP').
				           (#filterMode -> 'substring').
				           (#limit -> 1) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #packages) size equals: 1.
	self assert:
		(((data at: #packages) first at: #packageName) includesSubstring:
			 'MCP')
]

{ #category : 'tests' }
MCPToolContractsTest >> testCallToolInvokesTargetToolThroughServerPath [

	| data result |
	result := self callToolNamed: 'tool_call' withArguments: {
			          (#toolName -> 'package_search').
			          (#arguments -> {
				           (#packageName -> 'MCP').
				           (#filterMode -> 'substring').
				           (#limit -> 1) } asDictionary) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #packages) size equals: 1.
	self assert:
		(((data at: #packages) first at: #packageName) includesSubstring:
			 'MCP')
]

{ #category : 'tests' }
MCPToolContractsTest >> testCaptureScreenshotHasAccurateNameAndSchemas [

	| dataProperty inputPropertyNames outputPropertyNames targetProperty tool |
	tool := MCPToolCaptureScreenshot new.
	inputPropertyNames := tool inputSchema properties collect: [ :each |
		                      each name ].
	dataProperty := tool outputSchema properties detect: [ :each |
		                each name = 'data' ].
	outputPropertyNames := (dataProperty extraProperties at: #properties)
		                       collect: [ :each | each name ].
	targetProperty := self inputPropertyNamed: 'target' inTool: tool.
	self assert: tool name equals: 'screenshot_capture'.
	self assert: tool inputSchema required equals: #(  ).
	self assert: inputPropertyNames equals: #( 'target' ).
	self
		assert: (targetProperty extraProperties at: #enum)
		equals: #( 'world' ).
	self
		assert: (targetProperty extraProperties at: #default)
		equals: 'world'.
	self assert: (outputPropertyNames includes: 'target').
	self assert: (outputPropertyNames includes: 'width').
	self assert: (outputPropertyNames includes: 'height').
	self assert: (outputPropertyNames includes: 'mimeType')
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassMutationToolsHaveAccurateNamesAndRequiredArguments [

	| classTools packagePropertyNames slotToolPropertyNames slotsPropertyNames |
	classTools := {
		              (MCPToolCreateClass -> 'class_create').
		              (MCPToolUpdateClassName -> 'class_name_update').
		              (MCPToolUpdateClassSuperclass
		               -> 'class_superclass_update').
		              (MCPToolUpdateClassPackage -> 'class_package_update').
		              (MCPToolUpdateClassComment -> 'class_comment_update').
		              (MCPToolUpdateClassSlots -> 'class_slots_update').
		              (MCPToolUpdateClassTraits -> 'class_traits_update').
		              (MCPToolUpdateClassSideTraits
		               -> 'class_side_traits_update').
		              (MCPToolUpdateClassSharedVariables
		               -> 'class_shared_variables_update').
		              (MCPToolUpdateClassSharedPools
		               -> 'class_shared_pools_update').
		              (MCPToolUpdateClassLayout -> 'class_layout_update').
		              (MCPToolAddClassSlot -> 'class_slot_add').
		              (MCPToolRemoveClassSlot -> 'class_slot_remove').
		              (MCPToolUpdateClassSlotName
		               -> 'class_slot_name_update').
		              (MCPToolPullUpClassSlot -> 'class_slot_pull_up').
		              (MCPToolPushDownClassSlot -> 'class_slot_push_down') }.
	classTools do: [ :association |
			| propertyNames tool |
			tool := association key new.
			propertyNames := tool inputSchema properties collect: [ :each |
				                 each name ].
			self assert: tool name equals: association value.
			self deny: (propertyNames includes: 'operation') ].
	self
		assert: MCPToolCreateClass new inputSchema required asSet
		equals: #( 'className' 'superclassName' 'packageName' ) asSet.
	self
		assert: MCPToolUpdateClassName new inputSchema required asSet
		equals: #( 'className' 'newClassName' ) asSet.
	self
		assert: MCPToolUpdateClassComment new inputSchema required asSet
		equals: #( 'className' 'classComment' ) asSet.
	self
		assert: MCPToolUpdateClassSlotName new inputSchema required asSet
		equals: #( 'className' 'slotName' 'newSlotName' ) asSet.
	packagePropertyNames := MCPToolUpdateClassPackage new inputSchema
		                        properties collect: [ :each | each name ].
	slotsPropertyNames := MCPToolUpdateClassSlots new inputSchema
		                      properties collect: [ :each | each name ].
	slotToolPropertyNames := MCPToolAddClassSlot new inputSchema
		                         properties collect: [ :each | each name ].
	self assert: (packagePropertyNames includes: 'packageName').
	self assert: (packagePropertyNames includes: 'tag').
	self assert: (slotsPropertyNames includes: 'slots').
	self assert: (slotsPropertyNames includes: 'classSlots').
	self deny: (slotToolPropertyNames includes: 'slotAction').
	self assert: (slotToolPropertyNames includes: 'classSide').
	self assert: (slotToolPropertyNames includes: 'force')
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassPackageUpdateDescriptionMentionsRecategorization [

	| description |
	description := MCPToolUpdateClassPackage new description.
	self assert: (description includesSubstring: 'recategorize').
	self assert: (description includesSubstring: 'tag').
	self assert: (description includesSubstring: 'Omit packageName').
	self assert: (description includesSubstring: 'current package')
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassToolSchemaDescriptionsExplainRecategorizationForceAndReplacementSemantics [

	| classSlotsDescription classTraitsDescription forceDescription layoutDescription packageDescription sharedPoolsDescription sharedVariablesDescription slotsDescription tagDescription traitsDescription |
	packageDescription := (self
		                       inputPropertyNamed: 'packageName'
		                       inTool: MCPToolUpdateClassPackage new)
		                      description.
	tagDescription := (self
		                   inputPropertyNamed: 'tag'
		                   inTool: MCPToolUpdateClassPackage new)
		                  description.
	forceDescription := (self
		                     inputPropertyNamed: 'force'
		                     inTool: MCPToolUpdateClassPackage new)
		                    description.
	slotsDescription := (self
		                     inputPropertyNamed: 'slots'
		                     inTool: MCPToolUpdateClassSlots new)
		                    description.
	classSlotsDescription := (self
		                          inputPropertyNamed: 'classSlots'
		                          inTool: MCPToolUpdateClassSlots new)
		                         description.
	traitsDescription := (self
		                      inputPropertyNamed: 'traits'
		                      inTool: MCPToolUpdateClassTraits new)
		                     description.
	classTraitsDescription := (self
		                           inputPropertyNamed: 'classTraits'
		                           inTool: MCPToolUpdateClassSideTraits new)
		                          description.
	sharedVariablesDescription := (self
		                               inputPropertyNamed: 'sharedVariables'
		                               inTool:
		                               MCPToolUpdateClassSharedVariables new)
		                              description.
	sharedPoolsDescription := (self
		                           inputPropertyNamed: 'sharedPools'
		                           inTool: MCPToolUpdateClassSharedPools new)
		                          description.
	layoutDescription := (self
		                      inputPropertyNamed: 'layout'
		                      inTool: MCPToolUpdateClassLayout new)
		                     description.
	self assert: (packageDescription includesSubstring: 'recategorize').
	self assert:
		(packageDescription includesSubstring: 'omit packageName').
	self assert:
		(packageDescription includesSubstring: 'current package').
	self assert: (tagDescription includesSubstring: 'recategorizes').
	self assert:
		(forceDescription includesSubstring: 'refactoring warnings').
	self assert: (forceDescription includesSubstring: 'stopping').
	self assert: (slotsDescription includesSubstring: 'empty array').
	self assert: (slotsDescription includesSubstring: 'classSlots').
	self assert: (classSlotsDescription includesSubstring: 'empty array').
	self assert: (classSlotsDescription includesSubstring: 'slots').
	self assert: (traitsDescription includesSubstring: 'empty array').
	self assert:
		(classTraitsDescription includesSubstring: 'empty array').
	self assert:
		(sharedVariablesDescription includesSubstring: 'empty array').
	self assert:
		(sharedPoolsDescription includesSubstring: 'empty array').
	self assert:
		(sharedPoolsDescription includesSubstring: 'shared pool').
	self assert: (layoutDescription includesSubstring: 'layout class').
	self assert: (layoutDescription includesSubstring: 'AbstractLayout')
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassToolTraitOwnsSharedClassHelpers [

	| classToolClasses sharedSelectors |
	classToolClasses := {
		                    MCPToolSearchClasses.
		                    MCPToolGetClass }
	                    , self classMutationToolClasses
	                    , { MCPToolRemoveClasses }.
	sharedSelectors := #( resolvedClassNamed: sortedClassesByName: ).
	classToolClasses do: [ :toolClass |
			self assert: (toolClass withAllSuperclasses anySatisfy: [ :each |
					 each traits includes: TMCPClassTool ]).
			sharedSelectors do: [ :selector |
					self
						assert: (toolClass lookupSelector: selector) origin
						equals: TMCPClassTool ] ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassToolsOutputSchemaAdvertisesUpdateResultDTOs [

	| dataProperties outputSchema updatePlanProperties |
	outputSchema := MCPToolUpdateClassName new outputSchema asJRPCJSON.
	dataProperties := ((outputSchema at: #properties) at: 'data') at:
		                  #properties.
	updatePlanProperties := (dataProperties at: 'updatePlan') at:
		                        #properties.
	self assert: (dataProperties includesKey: 'updatePlan').
	self assert: (dataProperties includesKey: 'appliedChange').
	self assert: (updatePlanProperties includesKey: 'updateAction').
	self assert: (updatePlanProperties includesKey: 'requestedContext').
	self deny: (updatePlanProperties includesKey: 'commandClassName').
	self assert:
		(((dataProperties at: 'appliedChange') at: #properties)
			 includesKey: 'resultClassName')
]

{ #category : 'tests' }
MCPToolContractsTest >> testConfiguredDiscoverableToolsAreNotDirectlyCallable [

	| server |
	server := MCP new.
	server staticToolNames:
		#( 'tool_search' 'tool_get' 'tool_call' ).
	self
		should: [
				server
					rpcToolCall: 'package_search'
					withParams: { (#limit -> 1) } asDictionary ]
		raise: JRPCNonExistentHandler
]

{ #category : 'tests' }
MCPToolContractsTest >> testDebuggerToolsAreDiscoverableOnly [

	| debugNames metadataByName result staticToolNames |
	debugNames := #( 'debug_session_list' 'debug_session_get'
	                 'debug_session_remove' 'debug_candidate_search'
	                 'debug_candidate_attach' 'debug_state_get'
	                 'debug_variable_get' 'debug_expression_evaluate'
	                 'debug_session_step_into' 'debug_session_step_over'
	                 'debug_session_step_through'
	                 'debug_session_restart' 'debug_session_resume'
	                 'debug_session_terminate' 'debug_breakpoint_list'
	                 'debug_breakpoint_set' 'debug_breakpoint_remove'
	                 'debug_breakpoint_enable' 'debug_breakpoint_disable'
	                 'debug_breakpoint_clear' 'debug_capture'
	                 'debug_test_run' 'debug_method_update' ).
	staticToolNames := MCPToolRegistry staticToolNames.
	debugNames do: [ :each | self deny: (staticToolNames includes: each) ].
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#group -> 'debugging') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	debugNames do: [ :each |
			self assert: (metadataByName includesKey: each).
			self
				assert: ((metadataByName at: each) at: #exposure)
				equals: 'discoverable'.
			self
				assert: ((metadataByName at: each) at: #group)
				equals: 'debugging' ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testDictionaryShapedCommandResultsUseDTOClasses [

	| commandResultClasses |
	commandResultClasses := {
		                        (MCPEvaluateCommand -> MCPEvaluateResult).
		                        (MCPGetClassCommand
		                         -> MCPGetClassResult).
		                        (MCPGetMethodCommand
		                         -> MCPGetMethodResult).
		                        (MCPRewriteMethodsCommand
		                         -> MCPMethodRewriteReport).
		                        (MCPRemoveMethodsCommand
		                         -> MCPRemoveMethodsResult).
		                        (MCPCreateRepositoryCommand
		                         -> MCPRepositoryCreateResult).
		                        (MCPAttachRepositoryCommand
		                         -> MCPRepositoryCreateResult).
		                        (MCPUpdateRepositoryCommand
		                         -> MCPRepositoryUpdateResult).
		                        (MCPExportRepositoryCommand
		                         -> MCPRepositoryExportResult).
		                        (MCPRepositoryDiffCommand
		                         -> MCPRepositoryDiffResult).
		                        (MCPRepositoryVerifyIdentityCommand
		                         -> MCPRepositoryVerifyIdentityResult).
		                        (MCPCommitRepositoryCommand
		                         -> MCPRepositoryCommitResult).
		                        (MCPAdoptRepositoryHeadCommand
		                         -> MCPRepositoryAdoptHeadResult).
		                        (MCPFetchRepositoryCommand
		                         -> MCPRepositoryFetchResult).
		                        (MCPPullRepositoryCommand
		                         -> MCPRepositoryPullResult).
		                        (MCPPushRepositoryCommand
		                         -> MCPRepositoryPushResult).
		                        (MCPCreateRepositoryBranchCommand
		                         -> MCPRepositoryBranchResult).
		                        (MCPSwitchRepositoryBranchCommand
		                         -> MCPRepositoryBranchResult).
		                        (MCPLoadBaselineCommand
		                         -> MCPLoadBaselineResult).
		                        (MCPLoadRepositoryCommand
		                         -> MCPLoadRepositoryResult) }.
	commandResultClasses do: [ :association |
			| source |
			source := (association key >> #execute) sourceCode.
			self assert:
				(source includesSubstring: association value name asString) ].
	self assert:
		((MCPRunTestsCommand
		  >> #aggregateDataForResults:timedOut:unrunTests:) sourceCode
			 includesSubstring: MCPRunTestsResult name asString)
]

{ #category : 'tests' }
MCPToolContractsTest >> testDiscoveryUsesConfiguredStaticToolNames [

	| metadataByName result server |
	server := MCP new.
	server staticToolNames:
		#( 'tool_search' 'tool_get' 'tool_call' 'repository_search' ).
	result := server
		          rpcToolCall: 'tool_search'
		          withParams: { (#query -> 'repository') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	self
		assert: ((metadataByName at: 'repository_search') at: #exposure)
		equals: 'static'.
	self
		assert: ((metadataByName at: 'repository_create') at: #exposure)
		equals: 'discoverable'
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateCatchesHaltAsRuntimeFailure [

	| result text |
	result := self
		          callDiscoveredToolNamed: 'image_evaluate'
		          withArguments:
		          { (#code -> 'Halt signal: ''mcp halt test''') }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during execution').
	self assert: (text includesSubstring: 'Halt').
	self assert: (text includesSubstring: 'mcp halt test')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateErrorSchemaAdvertisesStackTrace [

	| errorProperties errorProperty propertyNames |
	errorProperty := MCPToolEvaluate new outputSchema properties detect: [
		                 :each | each name = 'error' ].
	errorProperties := errorProperty extraProperties at: #properties.
	propertyNames := errorProperties collect: [ :each | each name ].
	self assert: (propertyNames includes: 'stackTrace')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateIsMarkedAsAdvancedEscapeHatch [

	| description |
	self
		assert: (MCPToolEvaluate new asJRPCJSON at: #name)
		equals: 'image_evaluate'.
	description := MCPToolEvaluate new description.
	self assert: (description includesSubstring: 'escape hatch').
	self assert:
		(description includesSubstring: 'arbitrary Smalltalk code')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateRequiresCodeInSchema [

	self assert:
		(MCPToolEvaluate new inputSchema required includes: 'code')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateReturnsCompilationFailureInformation [

	| result text |
	result := self
		          callDiscoveredToolNamed: 'image_evaluate'
		          withArguments: { (#code -> '1 +') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during compilation').
	self assert:
		(text includesSubstring: self expectedSyntaxErrorNoticeClassName).
	self assert: (text includesSubstring: 'Position: 4')
]

{ #category : 'tests - evaluate' }
MCPToolContractsTest >> testEvaluateReturnsRuntimeFailureInformation [

	| result text |
	result := self
		          callDiscoveredToolNamed: 'image_evaluate'
		          withArguments:
		          { (#code -> 'Error signal: ''boom''') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during execution').
	self assert: (text includesSubstring: 'boom').
	self assert: (text includesSubstring: 'Signaler context:')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetClassHasAccurateNameAndRequiredArguments [

	| inputPropertyNames outputDataProperty outputPropertyNames tool |
	tool := MCPToolGetClass new.
	inputPropertyNames := tool inputSchema properties collect: [ :each |
		                      each name ].
	outputDataProperty := tool outputSchema properties detect: [ :each |
		                      each name = 'data' ].
	outputPropertyNames := (outputDataProperty extraProperties at:
		                        #properties) collect: [ :each | each name ].
	self assert: tool name equals: 'class_get'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'className' ) asSet.
	self assert: (inputPropertyNames includes: 'includeComment').
	self assert: (outputPropertyNames includes: 'traitComposition').
	self assert: (outputPropertyNames includes: 'classTraitComposition')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetMethodHasAccurateNameAndRequiredArguments [

	| propertyNames variablePropertyNames |
	propertyNames := MCPToolGetMethod new inputSchema properties
		                 collect: [ :each | each name ].
	variablePropertyNames := (MCPToolGetMethod new
		                          variableReferenceSchema extraProperties
		                          at: #properties) collect: [ :each |
		                         each name ].
	self assert: MCPToolGetMethod new name equals: 'method_get'.
	self
		assert: MCPToolGetMethod new inputSchema required asSet
		equals: #( 'className' 'selector' ) asSet.
	self assert: (propertyNames includes: 'className').
	self assert: (propertyNames includes: 'selector').
	self assert: (propertyNames includes: 'classSide').
	self assert: (propertyNames includes: 'includeVariableDetails').
	self deny: (variablePropertyNames includes: 'sourceIntervals').
	self deny: (variablePropertyNames includes: 'external').
	self deny: (variablePropertyNames includes: 'declaredInMethod')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetToolReturnsSchemaForCatalogTool [

	| contract inputProperties result |
	result := self
		          callToolNamed: 'tool_get'
		          withArguments:
		          { (#toolName -> 'repository_create') } asDictionary.
	contract := (self dataFrom: result) at: #tool.
	self assert: (contract at: #name) equals: 'repository_create'.
	self assert: (contract at: #group) equals: 'repositories'.
	self assert: (contract at: #exposure) equals: 'discoverable'.
	inputProperties := ((contract at: #inputSchema) at: #properties) keys.
	self assert: (inputProperties includes: 'name').
	self assert: (inputProperties includes: 'location').
	self deny: (inputProperties includes: 'operation').
	self
		assert: ((contract at: #inputSchema) at: #required) asArray
		equals: #( 'name' 'location' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testHandleJSONReturnsInternalErrorForUnhandledHalt [

	| handler processor response |
	processor := MCPMessageProcessor new.
	handler := MCPMessageSendHandler new
		           receiver: self;
		           methodName: 'mcp/test-halt';
		           messageSelector: #signalHaltForMCPMessageProcessorTest;
		           yourself.
	processor addHandler: handler.
	response := processor handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"mcp/test-halt"}'.
	self assert: (response includesSubstring: '"code":-32603').
	self assert: (response includesSubstring: 'Halt').
	self assert: (response includesSubstring: 'mcp processor halt test')
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testHandleJSONReturnsInvalidParamsForMissingRequiredArguments [

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"tool_call","arguments":{"toolName":"image_evaluate","arguments":{}}}}'.
	self assert: (response includesSubstring: '"code":-32602').
	self assert: (response includesSubstring:
			 '"message":"Invalid method parameter(s)."')
]

{ #category : 'tests' }
MCPToolContractsTest >> testHandleJSONReturnsMethodNotFoundForUnknownTool [

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"does-not-exist","arguments":{}}}'.
	self assert: (response includesSubstring: '"code":-32601').
	self assert: (response includesSubstring:
			 '"message":"The method does not exist / is not available."')
]

{ #category : 'tests' }
MCPToolContractsTest >> testImageCodeChangeTrackerFallsBackToChangedWhenSubscriptionFails [

	| result tracker |
	tracker := MCPImageCodeChangeTracker new.
	tracker announcer: Object new.
	result := tracker trackDuring: [ 42 ].
	self assert: result equals: 42.
	self assert: tracker hasChanges
]

{ #category : 'tests' }
MCPToolContractsTest >> testImageCodeChangeTrackerPreservesResultForReadOnlyBlock [

	| result tracker |
	tracker := MCPImageCodeChangeTracker new.
	result := tracker trackDuring: [ 42 ].
	self assert: result equals: 42.
	self deny: tracker hasChanges
]

{ #category : 'tests' }
MCPToolContractsTest >> testImageCodeChangeTrackerRecordsCodeAnnouncements [

	| tracker |
	tracker := MCPImageCodeChangeTracker new.
	tracker recordCodeChangeAnnouncement: MethodAdded new.
	self assert: tracker hasChanges
]

{ #category : 'tests' }
MCPToolContractsTest >> testImageContentSerializesNativeMCPImageBlock [

	| content json |
	content := MCPStructureImageContent
		           data: 'abc123'
		           mimeType: 'image/png'.
	json := content asJRPCJSON.
	self assert: (json at: #type) equals: 'image'.
	self assert: (json at: #data) equals: 'abc123'.
	self assert: (json at: #mimeType) equals: 'image/png'
]

{ #category : 'tests' }
MCPToolContractsTest >> testIncludeSourceFlagsWarnAboutCost [

	| descriptions |
	descriptions := OrderedCollection new.
	MCPTool concreteSubclasses do: [ :toolClass |
			| tool |
			tool := toolClass new.
			tool inputSchema properties do: [ :property |
					property name = 'includeSource' ifTrue: [
							descriptions add: property description.
							self
								assert: (property extraProperties at: #default)
								equals: false ] ] ].
	self assert: descriptions notEmpty.
	descriptions do: [ :each |
			self
				assert: each
				equals: 'Include source code. Use only for small result sets.' ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeAdvertisesPharoServerIcon [

	| expectedIcon icon response serverInfo |
	expectedIcon := (MCPStructureIcon pngIconNamed: #pharo) asJRPCJSON.
	response := (MCP new
		             onInitialize: nil
		             capabilities: nil
		             clientInfo: nil
		             websiteUrl: nil) asJRPCJSON.
	serverInfo := response at: #serverInfo.
	self assert: (serverInfo includesKey: #icons).
	self deny: (serverInfo at: #icons) isEmpty.
	icon := (serverInfo at: #icons) first.
	self assert: icon equals: expectedIcon
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeAdvertisesSupportedPharoVersions [

	| metadata pharo response runtimeVersion serverInfo |
	response := (MCP new
		             onInitialize: nil
		             capabilities: nil
		             clientInfo: nil
		             websiteUrl: nil) asJRPCJSON.
	serverInfo := response at: #serverInfo.
	self deny: (serverInfo includesKey: #_meta).
	self assert: (response includesKey: #_meta).
	metadata := response at: #_meta.
	self assert: (metadata includesKey: #'io.github.evref-bl/pharo').
	pharo := metadata at: #'io.github.evref-bl/pharo'.
	self
		assert: (pharo at: #supportedMajorVersions)
		equals: #( 12 13 14 ).
	self
		assert: (pharo at: #supportedLauncherVersions)
		equals: #( '120' '130' '140' ).
	runtimeVersion := pharo at: #runtimeVersion.
	self assert: runtimeVersion isString.
	self deny: runtimeVersion isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testInitializeResponseSerializesSupportedPharoVersions [

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{},"websiteUrl":null}}'.
	self assert: (response includesSubstring: '"result"').
	self assert: (response includesSubstring: '"_meta"').
	self assert:
		(response includesSubstring: '"io.github.evref-bl/pharo"').
	self assert:
		(response includesSubstring: '"supportedMajorVersions":[12,13,14]').
	self assert: (response includesSubstring:
			 '"supportedLauncherVersions":["120","130","140"]').
	self assert: (response includesSubstring: '"runtimeVersion":"')
]

{ #category : 'tests' }
MCPToolContractsTest >> testInputSchemaJSONOmitsDefaultSchemaNoise [

	| schema |
	schema := MCPToolSearchMethodMetadata new inputSchema asJRPCJSON.
	self deny: (schema includesKey: #required).
	self deny: (schema includesKey: #oneOf).
	self deny: (schema includesKey: #anyOf).
	self deny: (schema includesKey: #allOf).
	self assert: (schema at: #additionalProperties) equals: false
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchDescriptionPointsToSpecializedReferenceTools [

	| description filterModeDescription filterModeProperty protocolDescription selectorDescription tool |
	tool := MCPToolSearchMethodMetadata new.
	description := tool description.
	self assert: (description includesSubstring: 'source').
	self assert: (description includesSubstring: 'senders').
	self assert: (description includesSubstring: 'implementors').
	self assert: (description includesSubstring: 'references').
	selectorDescription := (self
		                        inputPropertyNamed: 'selector'
		                        inTool: tool) description.
	protocolDescription := (self
		                        inputPropertyNamed: 'protocol'
		                        inTool: tool) description.
	filterModeProperty := self
		                      inputPropertyNamed: 'filterMode'
		                      inTool: tool.
	filterModeDescription := filterModeProperty description.
	self assert: (selectorDescription includesSubstring: 'selector').
	self assert: (protocolDescription includesSubstring: 'protocol').
	self assert: (filterModeDescription includesSubstring: 'selector').
	self assert: (filterModeDescription includesSubstring: 'protocol').
	self
		assert: (filterModeProperty extraProperties at: #enum) asArray
		equals: #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchHasAccurateNameAndSchema [

	| filterModeProperty propertyNames schema scopeProperty scopePropertyNames |
	schema := MCPToolSearchMethodMetadata new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	filterModeProperty := schema properties detect: [ :each |
		                      each name = 'filterMode' ].
	scopeProperty := schema properties detect: [ :each |
		                 each name = 'scope' ].
	scopePropertyNames := (scopeProperty extraProperties at: #properties)
		                      collect: [ :each | each name ].
	self
		assert: MCPToolSearchMethodMetadata new name
		equals: 'method_metadata_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals:
			#( 'scope' 'selector' 'protocol' 'filterMode' 'side' 'includeSource'
			   'limit' 'offset' 'caseSensitive' ) asSet.
	self
		assert: scopeProperty description
		equals:
		'Optional search scope. If omitted, searches all matching entities.'.
	self
		assert: (scopeProperty extraProperties at: #additionalProperties)
		equals: false.
	self
		assert: scopePropertyNames asSet
		equals:
			#( 'classes' 'packages' 'superclassesOf' 'subclassesOf'
			   'hierarchies' ) asSet.
	self
		assert: (filterModeProperty extraProperties at: #enum) asArray
		equals: #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchListsMethodsForExistingClassScope [

	| data methods result selectors |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments: { (self searchScope:
				           { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }) }
				          asDictionary.
	data := (result at: #structuredContent) at: #data.
	methods := data at: #methods.
	selectors := methods collect: [ :each | each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: methods notEmpty.
	self assert: (selectors includes: 'alphaNeedleSelector').
	self assert: (selectors includes: 'classNeedleSelector')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchReturnsWarningResultForMissingClass [

	| data result warnings |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments: { (self searchScope:
				           { (#classes
				            -> #( 'MCPDefinitelyMissingMethodSearchClass' )) }) }
				          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring:
			 'MCPDefinitelyMissingMethodSearchClass').
	self assert: (warnings first includesSubstring: 'classNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMetadataSearchTopLevelFilterModesAreTextOnly [

	| filterModeEnum filterModeProperty schema selectorProperty |
	schema := MCPToolSearchMethodMetadata new inputSchema asJRPCJSON.
	filterModeProperty := (schema at: #properties) at: 'filterMode'.
	selectorProperty := (schema at: #properties) at: 'selector'.
	filterModeEnum := (filterModeProperty at: #enum) asArray.
	self assert: (schema at: #type) equals: 'object'.
	self assert: (schema at: #additionalProperties) equals: false.
	self
		assert: filterModeEnum
		equals: #( 'substring' 'prefix' 'exact' 'regex' ).
	self assert:
		((selectorProperty at: #description) includesSubstring: 'selector')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMutationSchemaAdvertisesMethodState [

	| argumentNamesProperty argumentValuesProperty dataProperties dataProperty permutationProperty propertyNames tool toolPropertyNames |
	tool := MCPToolUpdateMethodSelector new.
	toolPropertyNames := tool inputSchema properties collect: [ :each |
		                     each name ].
	permutationProperty := tool inputSchema properties detect: [ :each |
		                       each name = 'permutation' ].
	argumentNamesProperty := tool inputSchema properties detect: [ :each |
		                         each name = 'argumentNames' ].
	argumentValuesProperty := tool inputSchema properties detect: [ :each |
		                          each name = 'argumentValueExpressions' ].
	dataProperty := tool outputSchema properties detect: [ :each |
		                each name = 'data' ].
	dataProperties := dataProperty extraProperties at: #properties.
	propertyNames := dataProperties collect: [ :each | each name ].
	self deny: (toolPropertyNames includes: 'action').
	self assert:
		(permutationProperty extraProperties at: #items) type = 'integer'.
	self assert:
		(argumentNamesProperty extraProperties at: #items) type = 'string'.
	self assert:
		(argumentValuesProperty extraProperties at: #items) type = 'string'.
	self
		assert: propertyNames asSet
		equals:
			#( 'action' 'changeKind' 'updateAction' 'updatePlan' 'appliedChange'
			   'selector' 'className' 'classSide' 'packageName' 'isExtension'
			   'protocol' 'source' 'oldSelector' 'newSelector' 'oldProtocol'
			   'newProtocol' 'critiques' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodMutationToolsHaveAccurateNamesAndRequiredArguments [

	| createPropertyNames createTool protocolPropertyNames protocolTool selectorPropertyNames selectorTool |
	createTool := MCPToolCreateMethod new.
	selectorTool := MCPToolUpdateMethodSelector new.
	protocolTool := MCPToolUpdateMethodProtocol new.
	createPropertyNames := createTool inputSchema properties collect: [
		                       :each | each name ].
	selectorPropertyNames := selectorTool inputSchema properties
		                         collect: [ :each | each name ].
	protocolPropertyNames := protocolTool inputSchema properties
		                         collect: [ :each | each name ].
	self assert: createTool name equals: 'method_create'.
	self assert: selectorTool name equals: 'method_selector_update'.
	self assert: protocolTool name equals: 'method_protocol_update'.
	self
		assert: createTool inputSchema required asSet
		equals: #( 'className' 'methodSource' 'protocol' ) asSet.
	self
		assert: selectorTool inputSchema required asSet
		equals: #( 'className' 'selector' 'newSelector' ) asSet.
	self
		assert: protocolTool inputSchema required asSet
		equals: #( 'className' 'selector' 'protocol' ) asSet.
	{
		createPropertyNames.
		selectorPropertyNames.
		protocolPropertyNames } do: [ :each |
			self deny: (each includes: 'operation').
			self assert: (each includes: 'classSide').
			self assert: (each includes: 'force') ].
	self assert: (selectorPropertyNames includes: 'packageNames').
	self assert: (selectorPropertyNames includes: 'classNames').
	self assert: (selectorPropertyNames includes: 'hierarchyClassNames').
	self deny: (createPropertyNames includes: 'packageNames').
	self deny: (protocolPropertyNames includes: 'packageNames')
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodToolTraitOwnsSharedMethodHelpers [

	| methodToolClasses sharedSelectors |
	methodToolClasses := {
		                     MCPToolGetMethod.
		                     MCPToolMethodMutation.
		                     MCPToolRewriteMethods.
		                     MCPToolRemoveMethods }.
	sharedSelectors := #( selectorStringFromRequest:
	                      behaviorNamed:classSide:
	                      methodReferenceForBehavior:selector:
	                      methodReferenceForClassName:selector:isClassSide:
	                      methodScopeQueryFromRequest: ).
	self assert:
		(MCPToolMethodSearch withAllSuperclasses anySatisfy: [ :each |
			 each traits includes: TMCPMethodTool ]).
	self
		assert:
		(MCPToolMethodSearch >> #methodScopeQueryFromRequest:) origin
		equals: MCPToolMethodSearch.
	methodToolClasses do: [ :toolClass |
			self assert: (toolClass withAllSuperclasses anySatisfy: [ :each |
					 each traits includes: TMCPMethodTool ]).
			sharedSelectors do: [ :selector |
					| implementingClass |
					implementingClass := toolClass whichClassIncludesSelector:
						                     selector.
					self assert: implementingClass notNil.
					self
						assert: (implementingClass >> selector) origin
						equals: TMCPMethodTool ] ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testMutatingToolsRequestImageSaveAfterSuccessfulExecution [

	self deny:
		MCPToolSearchMethodMetadata new shouldSaveImageAfterSuccessfulExecution.
	self deny:
		MCPToolGetClass new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolCreateRepository new shouldSaveImageAfterSuccessfulExecution.
	self classMutationToolClasses do: [ :toolClass |
		self assert: toolClass new shouldSaveImageAfterSuccessfulExecution ].
	self assert:
		MCPToolCreateMethod new shouldSaveImageAfterSuccessfulExecution.
	self assert: MCPToolUpdateMethodSelector new
			shouldSaveImageAfterSuccessfulExecution.
	self assert: MCPToolUpdateMethodProtocol new
			shouldSaveImageAfterSuccessfulExecution.
	self deny:
		MCPToolRewriteMethods new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolRemoveClasses new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolRemoveMethods new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolEvaluate new shouldSaveImageAfterSuccessfulExecution

]

{ #category : 'tests' }
MCPToolContractsTest >> testMutationDescriptionsExplainForceWarningBehavior [

	| classForceDescription methodForceDescription |
	classForceDescription := (self
		                          inputPropertyNamed: 'force'
		                          inTool: MCPToolUpdateClassName new)
		                         description.
	methodForceDescription := (self
		                           inputPropertyNamed: 'force'
		                           inTool: MCPToolUpdateMethodSelector new)
		                          description.
	{
		classForceDescription.
		methodForceDescription } do: [ :each |
			self assert: (each includesSubstring: 'refactoring warnings').
			self assert: (each includesSubstring: 'stopping') ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testMutationToolSchemasAdvertiseRenameScopeConditions [

	| classRenameInputSchema classRenamePropertyNames selectorInputSchema selectorPropertyNames |
	classRenameInputSchema := MCPToolUpdateClassName new inputSchema.
	selectorInputSchema := MCPToolUpdateMethodSelector new inputSchema.
	classRenamePropertyNames := classRenameInputSchema properties
		                            collect: [ :each | each name ].
	selectorPropertyNames := selectorInputSchema properties collect: [
		                         :each | each name ].
	{
		classRenamePropertyNames.
		selectorPropertyNames } do: [ :propertyNames |
			self deny: (propertyNames includes: 'scope').
			self assert: (propertyNames includes: 'packageNames').
			self assert: (propertyNames includes: 'classNames').
			self assert: (propertyNames includes: 'hierarchyClassNames') ].
	self
		assert:
		(classRenameInputSchema asJRPCJSON at: #additionalProperties)
		equals: false.
	self
		assert: (selectorInputSchema asJRPCJSON at: #additionalProperties)
		equals: false
]

{ #category : 'tests' }
MCPToolContractsTest >> testOptionalToolArgumentsAdvertiseDefaultsWhenAvailable [

	| classSlotTool classUpdateTool searchClassesTool methodMetadataTool searchPackagesTool getClassTool getMethodTool removeClassesTool removeMethodsTool rewriteMethodsTool updateMethodTool |
	classUpdateTool := MCPToolUpdateClassName new.
	classSlotTool := MCPToolAddClassSlot new.
	getClassTool := MCPToolGetClass new.
	getMethodTool := MCPToolGetMethod new.
	updateMethodTool := MCPToolUpdateMethodSelector new.
	rewriteMethodsTool := MCPToolRewriteMethods new.
	searchClassesTool := MCPToolSearchClasses new.
	methodMetadataTool := MCPToolSearchMethodMetadata new.
	searchPackagesTool := MCPToolSearchPackages new.
	removeClassesTool := MCPToolRemoveClasses new.
	removeMethodsTool := MCPToolRemoveMethods new.
	self
		assert: ((self inputPropertyNamed: 'force' inTool: classUpdateTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'classSide' inTool: classSlotTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'includeComment' inTool: getClassTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'subclassDepth' inTool: getClassTool)
				 extraProperties at: #default)
		equals: 0.
	self
		assert:
			((self inputPropertyNamed: 'classSide' inTool: getMethodTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert: ((self
				  inputPropertyNamed: 'includeVariableDetails'
				  inTool: getMethodTool) extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'classSide' inTool: updateMethodTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'force' inTool: updateMethodTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'apply' inTool: rewriteMethodsTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'force' inTool: rewriteMethodsTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self
				  inputPropertyNamed: 'includeSources'
				  inTool: rewriteMethodsTool) extraProperties at: #default)
		equals: true.
	self
		assert:
			((self inputPropertyNamed: 'side' inTool: rewriteMethodsTool)
				 extraProperties at: #default)
		equals: 'both'.
	self
		assert:
			((self inputPropertyNamed: 'filterMode' inTool: searchClassesTool)
				 extraProperties at: #default)
		equals: 'substring'.
	self
		assert:
			((self
				  inputPropertyNamed: 'caseSensitive'
				  inTool: searchClassesTool) extraProperties at: #default)
		equals: true.
	self
		assert:
			((self inputPropertyNamed: 'limit' inTool: searchClassesTool)
				 extraProperties at: #default)
		equals: 25.
	self
		assert:
			((self inputPropertyNamed: 'filterMode' inTool: methodMetadataTool)
				 extraProperties at: #default)
		equals: 'exact'.
	self
		assert:
			((self
				  inputPropertyNamed: 'caseSensitive'
				  inTool: methodMetadataTool) extraProperties at: #default)
		equals: true.
	self
		assert:
			((self
				  inputPropertyNamed: 'includeSource'
				  inTool: methodMetadataTool) extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'filterMode' inTool: searchPackagesTool)
				 extraProperties at: #default)
		equals: 'substring'.
	self
		assert:
			((self
				  inputPropertyNamed: 'caseSensitive'
				  inTool: searchPackagesTool) extraProperties at: #default)
		equals: true.
	self
		assert:
			((self inputPropertyNamed: 'force' inTool: removeClassesTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'classSide' inTool: removeMethodsTool)
				 extraProperties at: #default)
		equals: false
]

{ #category : 'tests' }
MCPToolContractsTest >> testOutputDtoClassesUseResultInfoOrReportSuffixes [

	| dtoClasses invalidNames suffixes |
	dtoClasses := (self mcpClassesInPackageTagNamed: 'DTOs')
	              , (self mcpClassesInPackageTagNamed: 'Results').
	suffixes := #( 'Result' 'Info' 'Report' ).
	invalidNames := dtoClasses reject: [ :each |
		                suffixes anySatisfy: [ :suffix |
			                each name asString endsWith: suffix ] ].
	self assert: dtoClasses notEmpty.
	self assert: invalidNames isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testParsedInputClassesUseRequestOrSpecSuffixes [

	| invalidNames parsedInputClasses suffixes |
	parsedInputClasses := (self mcpClassesInPackageTagNamed: 'Requests')
		                      reject: [ :each | each = MCPToolRequest ].
	suffixes := #( 'Request' 'Spec' ).
	invalidNames := parsedInputClasses reject: [ :each |
		                suffixes anySatisfy: [ :suffix |
			                each name asString endsWith: suffix ] ].
	self assert:
		((self mcpClassesInPackageTagNamed: 'Requests') includes:
			 MCPToolRequest).
	self assert: parsedInputClasses notEmpty.
	self assert: invalidNames isEmpty
]

{ #category : 'tests' }
MCPToolContractsTest >> testProjectMethodsDoNotHandleMessageNotUnderstoodAsControlFlow [

	| methods offendingMethods rule |
	rule := MCPMessageNotUnderstoodHandlerRule new.
	methods := #( 'MCP' 'MCP-Tests' ) flatCollect: [ :packageName |
		           (PackageOrganizer default packageNamed: packageName)
			           methods ].
	offendingMethods := methods select: [ :method |
			                    method sendNodes anySatisfy: [ :sendNode |
				                    rule isMessageNotUnderstoodHandlerSend:
					                    sendNode ] ].
	self
		assert: offendingMethods isEmpty
		description: ('Methods handling MessageNotUnderstood: {1}' format:
				 { (offendingMethods collect: [ :method | method printString ])
					 asArray printString })
]

{ #category : 'tests' }
MCPToolContractsTest >> testProjectMethodsDoNotSendReflectiveProtocolChecks [

	| forbiddenSelector methods offendingMethods |
	forbiddenSelector := MCPRespondsToUsageRule forbiddenSelector.
	methods := #( 'MCP' 'MCP-Tests' ) flatCollect: [ :packageName |
		           (PackageOrganizer default packageNamed: packageName)
			           methods ].
	offendingMethods := methods select: [ :method |
			                    method sendNodes anySatisfy: [ :sendNode |
				                    sendNode selector = forbiddenSelector ] ].
	self
		assert: offendingMethods isEmpty
		description: ('Methods sending {1}: {2}' format: {
					 forbiddenSelector.
					 (offendingMethods collect: [ :method | method printString ])
						 asArray printString })
]

{ #category : 'tests' }
MCPToolContractsTest >> testPublicToolsDoNotExposeOperationInput [

	MCPToolRegistry publicTools do: [ :tool |
			| propertyNames |
			propertyNames := tool inputSchema properties collect: [ :property |
				                 property name ].
			self deny: (propertyNames includes: 'operation') ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testQueryScopeDescriptionsExplainScopeSemantics [

	| classScope methodScope scopePropertyNames |
	classScope := self
		              inputPropertyNamed: 'scope'
		              inTool: MCPToolSearchClasses new.
	methodScope := self
		               inputPropertyNamed: 'scope'
		               inTool: MCPToolSearchMethodMetadata new.
	scopePropertyNames := (classScope extraProperties at: #properties)
		                      collect: [ :each | each name ].
	self
		assert: classScope description
		equals:
		'Optional search scope. If omitted, searches all matching entities.'.
	self assert: methodScope description equals: classScope description.
	self
		assert: (classScope extraProperties at: #additionalProperties)
		equals: false.
	self
		assert: (methodScope extraProperties at: #additionalProperties)
		equals: false.
	self
		assert: scopePropertyNames asSet
		equals:
			#( 'classes' 'packages' 'superclassesOf' 'subclassesOf'
			   'hierarchies' ) asSet.
	self assert:
		((classScope extraProperties at: #properties) allSatisfy: [ :each |
			 each description isNil ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testRPCAdvertisesStaticToolSurfaceOnly [

	| toolNames |
	toolNames := (MCP new rpcToolsList at: #tools) collect: [ :each |
		             each at: #name ].
	self
		assert: toolNames asSet
		equals: MCPToolRegistry staticToolNames asSet.
	#( 'tool_search' 'tool_get' 'tool_call' 'package_search'
	   'class_search' 'class_get' 'class_create' 'method_metadata_search'
	   'method_source_search' 'method_implementor_search'
	   'method_sender_search' 'method_get' 'method_create'
	   'method_selector_update' 'method_protocol_update'
	   'image_evaluate' 'test_run' ) do: [ :each |
		self assert: (toolNames includes: each) ].
	#( 'class_name_update' 'class_superclass_update'
	   'class_package_update' 'class_comment_update'
	   'class_slots_update' 'class_traits_update' 'class_side_traits_update'
	   'class_shared_variables_update' 'class_shared_pools_update'
	   'class_layout_update' 'class_slot_add' 'class_slot_remove'
	   'class_slot_name_update' 'class_slot_pull_up' 'class_slot_push_down'
	   'method_equivalent_search' 'method_class_reference_search'
	   'method_variable_reference_search'
	   'test_coverage_run' 'repository_search' 'repository_identity_verify'
	   'repository_change_list' 'repository_create' 'repository_attach'
	   'repository_update' 'repository_export' 'repository_commit'
	   'repository_fetch' 'repository_pull' 'repository_push'
	   'repository_branch_create' 'repository_branch_switch'
	   'repository_head_adopt' 'history_file_list' 'history_entry_list'
	   'history_entry_apply' 'history_entry_revert'
	   'screenshot_capture' 'debug_state_get' 'debug_session_step_over'
	   'debug_capture' ) do: [ :each |
		self deny: (toolNames includes: each) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testRPCRefreshesCachedToolMetadata [

	| mcp propertyNames result staleTool toolDefinition toolDefinitions |
	mcp := MCP new.
	staleTool := MCPToolSearchClasses new.
	staleTool inputSchema: (MCPStructureInputSchema new
			 type: 'object';
			 properties: #(  );
			 required: #(  );
			 additionalProperties: false;
			 yourself).
	mcp toolsList: (Dictionary new
			 at: staleTool name put: staleTool;
			 yourself).
	toolDefinitions := mcp rpcToolsList at: #tools.
	toolDefinition := toolDefinitions detect: [ :each |
		                  (each at: #name) = 'class_search' ].
	propertyNames := ((toolDefinition at: #inputSchema) at: #properties)
		                 keys asSet.
	self
		assert: propertyNames
		equals:
			#( 'scope' 'className' 'tag' 'instanceSlot' 'classSlot' 'filterMode'
			   'caseSensitive' 'limit' 'offset' ) asSet.
	result := mcp rpcToolCall: 'class_search' withParams: {
			          (self searchScope: {
					           (#classes -> #( 'MCPToolContractsTest' )).
					           (#packages -> #( 'MCP-Tests' )) }).
			          (#limit -> 1) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveClassHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRemoveClasses new name equals: 'class_remove'.
	self
		assert: MCPToolRemoveClasses new inputSchema required asSet
		equals: #( 'classNames' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveMethodsHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRemoveMethods new name equals: 'method_remove'.
	self
		assert: MCPToolRemoveMethods new inputSchema required asSet
		equals: #( 'className' 'selectors' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRepositoryBranchCheckoutIconUsesBranchObjectBadge [

	self
		assert: MCPToolCheckoutRepositoryBranch new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #git
				 leftBadgeIconNamed: #branch
				 rightBadgeIconNamed: #openFromUrl) asJRPCJSON
]

{ #category : 'tests' }
MCPToolContractsTest >> testRepositoryBranchCheckoutToolName [

	self
		assert: MCPToolCheckoutRepositoryBranch toolName
		equals: 'repository_branch_checkout'
]

{ #category : 'tests' }
MCPToolContractsTest >> testRepositoryCreateAndUpdateRequiredArguments [

	| createPropertyNames updatePropertyNames |
	createPropertyNames := MCPToolCreateRepository new inputSchema
		                       properties collect: [ :each | each name ].
	updatePropertyNames := MCPToolUpdateRepository new inputSchema
		                       properties collect: [ :each | each name ].
	self
		assert: MCPToolCreateRepository new name
		equals: 'repository_create'.
	self
		assert: MCPToolAttachRepository new name
		equals: 'repository_attach'.
	self
		assert: MCPToolUpdateRepository new name
		equals: 'repository_update'.
	self
		assert: MCPToolCreateRepository new inputSchema required asArray
		equals: #( 'name' 'location' ).
	self
		assert: MCPToolAttachRepository new inputSchema required asArray
		equals: #( 'name' 'location' ).
	self
		assert: MCPToolUpdateRepository new inputSchema required asArray
		equals: #( 'repositoryName' ).
	#( 'name' 'location' 'subdirectory' 'packageNames' ) do: [ :each |
		self assert: (createPropertyNames includes: each) ].
	#( 'repositoryName' 'location' 'subdirectory' 'packageNames'
	   'addPackageNames' 'removePackageNames' ) do: [ :each |
		self assert: (updatePropertyNames includes: each) ].
	self deny: (createPropertyNames includes: 'operation').
	self deny: (updatePropertyNames includes: 'operation')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRepositoryOperationOutputSchemaUsesActionForExecutedAction [

	| dataProperties outputSchema required |
	outputSchema := MCPToolUpdateRepository new outputSchema asJRPCJSON.
	dataProperties := ((outputSchema at: #properties) at: 'data') at:
		                  #properties.
	required := ((outputSchema at: #properties) at: 'data') at: #required.
	self assert: (dataProperties includesKey: 'action').
	self assert: (dataProperties includesKey: 'restoredOrderOnlyPaths').
	self assert:
		(dataProperties includesKey: 'modifiedPackageNamesBefore').
	self assert:
		(dataProperties includesKey: 'modifiedPackageNamesAfter').
	self assert: (dataProperties includesKey: 'checkedFields').
	self assert:
		(dataProperties includesKey: 'previousReferenceCommitId').
	self assert: (dataProperties includesKey: 'referenceCommitId').
	self assert: (dataProperties includesKey: 'adoptedCommitId').
	self assert: (dataProperties includesKey: 'didAdopt').
	self assert: (dataProperties includesKey: 'matched').
	self deny: (dataProperties includesKey: 'operation').
	self assert: (required includes: 'action').
	self deny: (required includes: 'operation')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRequestedToolIconsAreSelected [

	MCPStructureIcon resetCaches.
	self
		assert: MCPToolGetClass new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #class
				 badgeIconNamed: #inspect) asJRPCJSON.
	self
		assert: MCPToolCreateRepositoryBranch new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #git
				 leftBadgeIconNamed: #branch
				 rightBadgeIconNamed: #add) asJRPCJSON.
	self
		assert: MCPToolSearchMethodSource new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #page
				 leftBadgeIconNamed: #workspace
				 rightBadgeIconNamed: #search) asJRPCJSON.
	self
		assert: MCPToolSearchMethodImplementors new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #page
				 leftBadgeIconNamed: #referencesUpsideDown
				 rightBadgeIconNamed: #search) asJRPCJSON.
	self
		assert: MCPToolUpdateMethodProtocol new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #page
				 leftBadgeIconNamed: #protocolProtected
				 rightBadgeIconNamed: #edit) asJRPCJSON.
	self
		assert: MCPToolPullUpClassSlot new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #class
				 leftBadgeIconNamed: #instVarsSelected
				 rightBadgeIconNamed: #up) asJRPCJSON.
	self
		assert: MCPToolPushDownClassSlot new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #class
				 leftBadgeIconNamed: #instVarsSelected
				 rightBadgeIconNamed: #down) asJRPCJSON.
	self
		assert: MCPToolUpdateClassLayout new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #class
				 leftBadgeIconNamed: #objects
				 rightBadgeIconNamed: #edit) asJRPCJSON.
	self
		assert: MCPToolListChangeHistoryEntries new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #history
				 leftBadgeIconNamed: #changeUpdate
				 rightBadgeIconNamed: #browse) asJRPCJSON.
	self
		assert: MCPToolRunTestCoverage new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #testRunner
				 leftBadgeIconNamed: #processBrowser
				 rightBadgeIconNamed: #play) asJRPCJSON.
	self
		assert: MCPToolStepIntoDebugSession new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #bug
				 leftBadgeIconNamed: #announcement
				 rightBadgeIconNamed: #into) asJRPCJSON.
	self
		assert: MCPToolUpdateDebugMethod new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #bug
				 leftBadgeIconNamed: #page
				 rightBadgeIconNamed: #edit) asJRPCJSON.
	self
		assert: MCPToolCaptureScreenshot new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #window
				 badgeIconNamed: #smallScreenshot) asJRPCJSON.
	self
		assert: MCPToolRunTests new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #testRunner
				 badgeIconNamed: #play) asJRPCJSON.
	self
		assert: MCPToolEvaluate new icons first asJRPCJSON
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #pharoHalfScale
				 badgeIconNamed: #go) asJRPCJSON
]

{ #category : 'tests' }
MCPToolContractsTest >> testRewriteMethodsIsMethodScopedCommandTool [

	self assert: MCPToolRewriteMethods superclass equals: MCPTool.
	self assert: (MCPToolRewriteMethods traits includes: TMCPMethodTool)
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallCatchesUnhandledHaltFromTool [

	| mcp result text tool tools |
	tool := MCPHaltingTestTool new.
	tools := Dictionary new
		         at: tool name put: tool;
		         yourself.
	mcp := MCP new.
	mcp instVarNamed: 'toolsList' put: tools.
	result := mcp rpcToolCall: tool name withParams: Dictionary new.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert:
		(text includesSubstring: 'Tool halting-test-tool failed (Halt)').
	self assert: (text includesSubstring: 'mcp tool halt test')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallRejectsLegacyScopeArgument [

	self
		should: [
			self
				callToolNamed: 'class_search'
				withArguments: { (#scope -> 'packages') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersForInvalidNestedArrayItem [

	self
		should: [
				self
					callToolNamed: 'test_run'
					withArguments:
					{ (#tests -> #( 'MCPToolContractsTest' )) } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersForUnexpectedArgument [

	self
		should: [
				self callDiscoveredToolNamed: 'image_evaluate' withArguments: {
						(#code -> '1 + 1').
						(#unexpected -> true) } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersForWrongArgumentType [

	self
		should: [
			self
				callToolNamed: 'class_search'
				withArguments: { (#caseSensitive -> 'true') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests - validation' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersWhenRequiredArgumentIsMissing [

	self
		should: [
			self
				callDiscoveredToolNamed: 'image_evaluate'
				withArguments: Dictionary new ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestCoverageUsesNestedRequestDTOs [

	| command parsedRequest rawRequest tool validatedRequests |
	tool := MCPToolRunTestCoverage new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#tests
			               ->
			               { { (#className -> 'MCPToolContractsTest') }
				               asDictionary }).
			              (#coverage
			               ->
			               { (#classNames -> #( 'MCPToolContractsTest' )) }
				               asDictionary) } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.
	validatedRequests := command validatedRequestsFrom:
		                     parsedRequest testRequests.
	self assert: parsedRequest class equals: MCPRunTestsRequest.
	self assert: parsedRequest isCoverageOperation.
	self
		assert: parsedRequest coverageRequest class
		equals: MCPTestCoverageRequest.
	self
		assert: parsedRequest testRequests first class
		equals: MCPTestRunRequest.
	self
		assert: validatedRequests first class
		equals: MCPValidatedTestRunRequest.
	self
		assert: validatedRequests first testClass
		equals: MCPToolContractsTest
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestToolsHaveAccurateNamesAndRequiredArguments [

	| coverageDataProperties coverageInputProperty coverageOutputSchema coverageResultsProperty coverageTool dataProperties inputPropertyNames outputSchema resultsProperty timeoutMillisecondsProperty tool |
	tool := MCPToolRunTests new.
	self assert: tool name equals: 'test_run'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'tests' ) asSet.
	self deny: (tool inputSchema extraProperties includesKey: #oneOf).
	inputPropertyNames := tool inputSchema properties collect: [ :each |
		                      each name ].
	timeoutMillisecondsProperty := tool inputSchema properties detect: [
		                               :each |
		                               each name = 'timeoutMilliseconds' ].
	self deny: (inputPropertyNames includes: 'operation').
	self deny: (inputPropertyNames includes: 'coverage').
	self assert: (inputPropertyNames includes: 'timeoutSeconds').
	self assert: (inputPropertyNames includes: 'timeoutMilliseconds').
	self assert:
		(timeoutMillisecondsProperty description includesSubstring:
			 'Cannot be combined with timeoutSeconds').
	outputSchema := tool outputSchema asJRPCJSON.
	dataProperties := ((outputSchema at: #properties) at: 'data') at:
		                  #properties.
	resultsProperty := dataProperties at: 'results'.
	self assert: (resultsProperty at: #type) equals: 'array'.
	self
		assert: ((resultsProperty at: #items) at: #type)
		equals: 'object'.
	self deny: (dataProperties includesKey: 'coverage').
	self deny: (dataProperties includesKey: 'tests').

	coverageTool := MCPToolRunTestCoverage new.
	self assert: coverageTool name equals: 'test_coverage_run'.
	self
		assert: coverageTool inputSchema required asSet
		equals: #( 'tests' 'coverage' ) asSet.
	inputPropertyNames := coverageTool inputSchema properties collect: [
		                      :each | each name ].
	coverageInputProperty := coverageTool inputSchema properties detect: [
		                         :each | each name = 'coverage' ].
	self deny: (inputPropertyNames includes: 'operation').
	self assert: (inputPropertyNames includes: 'coverage').
	self assert: (inputPropertyNames includes: 'timeoutSeconds').
	self assert: (inputPropertyNames includes: 'timeoutMilliseconds').
	self assert:
		(((coverageInputProperty extraProperties at: #properties) collect: [
			  :each | each name ]) includes: 'packageNames').
	coverageOutputSchema := coverageTool outputSchema asJRPCJSON.
	coverageDataProperties := ((coverageOutputSchema at: #properties)
		                           at: 'data') at: #properties.
	coverageResultsProperty := coverageDataProperties at: 'results'.
	self assert: (coverageResultsProperty at: #type) equals: 'array'.
	self assert: (coverageDataProperties includesKey: 'coverage').
	self deny: (coverageDataProperties includesKey: 'tests')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestsParsesTimeoutMilliseconds [

	| parsedRequest rawRequest tool |
	tool := MCPToolRunTests new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#tests -> { {
				               (#className -> 'MCPToolContractsTest').
				               (#testMethodName
				                ->
				                'testRunTestToolsHaveAccurateNamesAndRequiredArguments') }
				               asDictionary }).
			              (#timeoutMilliseconds -> 25) } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	self assert: parsedRequest timeoutMilliseconds equals: 25
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestsRejectsConflictingTimeoutUnits [

	| rawRequest tool |
	tool := MCPToolRunTests new.
	rawRequest := tool requestFromToolCallArguments: {
			              (#tests -> { {
				               (#className -> 'MCPToolContractsTest').
				               (#testMethodName
				                ->
				                'testRunTestToolsHaveAccurateNamesAndRequiredArguments') }
				               asDictionary }).
			              (#timeoutSeconds -> 1).
			              (#timeoutMilliseconds -> 25) } asDictionary.
	self
		should: [ tool parsedRequestFromToolRequest: rawRequest ]
		raise: Error
		whoseDescriptionIncludes:
		'timeoutSeconds and timeoutMilliseconds cannot both be provided'
		description: 'Timeout requests should use one unit.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestsUsesNestedRequestDTOs [

	| command parsedRequest rawRequest tool validatedRequests |
	tool := MCPToolRunTests new.
	rawRequest := tool requestFromToolCallArguments: { (#tests -> { {
			               (#className -> 'MCPToolContractsTest').
			               (#testMethodName
			                ->
			                'testRunTestToolsHaveAccurateNamesAndRequiredArguments') }
			               asDictionary }) } asDictionary.
	parsedRequest := tool parsedRequestFromToolRequest: rawRequest.
	command := tool commandForRequest: parsedRequest.
	validatedRequests := command validatedRequestsFrom:
		                     parsedRequest testRequests.
	self assert: parsedRequest class equals: MCPRunTestsRequest.
	self
		assert: parsedRequest testRequests first class
		equals: MCPTestRunRequest.
	self
		assert: parsedRequest testRequests first className
		equals: 'MCPToolContractsTest'.
	self
		assert: parsedRequest testRequests first testMethodName
		equals: 'testRunTestToolsHaveAccurateNamesAndRequiredArguments'.
	self
		assert: validatedRequests first class
		equals: MCPValidatedTestRunRequest.
	self
		assert: validatedRequests first testRunRequest
		equals: parsedRequest testRequests first.
	self
		assert: validatedRequests first testClass
		equals: MCPToolContractsTest
]

{ #category : 'tests' }
MCPToolContractsTest >> testScreenshotCommandPackagesProvidedFormAsImageContent [

	| command form imageJSON request result |
	form := Form extent: 2 @ 3 depth: 32.
	request := MCPScreenshotRequest new
		           initializeTarget: 'world'
		           targetIdentifier: nil.
	command := MCPScreenshotCommand
		           tool: MCPToolCaptureScreenshot new
		           request: request
		           formProvider: [ form ].
	result := command execute.
	imageJSON := result imageContent asJRPCJSON.
	self assert: result target equals: 'world'.
	self assert: result width equals: 2.
	self assert: result height equals: 3.
	self assert: result imageContent mimeType equals: 'image/png'.
	self assert: result imageContent data notEmpty.
	self assert: (imageJSON at: #type) equals: 'image'.
	self assert: (imageJSON at: #mimeType) equals: 'image/png'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchClassesHasAccurateNameAndSchema [

	| propertyNames schema scopeProperty scopePropertyNames |
	schema := MCPToolSearchClasses new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	scopeProperty := schema properties detect: [ :each |
		                 each name = 'scope' ].
	scopePropertyNames := (scopeProperty extraProperties at: #properties)
		                      collect: [ :each | each name ].
	self assert: MCPToolSearchClasses new name equals: 'class_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals:
			#( 'scope' 'className' 'tag' 'instanceSlot' 'classSlot' 'filterMode'
			   'caseSensitive' 'limit' 'offset' ) asSet.
	self
		assert: scopeProperty description
		equals:
		'Optional search scope. If omitted, searches all matching entities.'.
	self
		assert: scopePropertyNames asSet
		equals:
			#( 'classes' 'packages' 'superclassesOf' 'subclassesOf'
			   'hierarchies' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchClassesListsClassesForExistingPackage [

	| classNames classes data result |
	result := self callToolNamed: 'class_search' withArguments: {
			          (self searchScope: { (#packages -> #( 'MCP-Tests' )) }).
			          (#limit -> 100) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	classes := data at: #classes.
	classNames := classes collect: [ :each | each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: classes notEmpty.
	self assert: (classNames includes: 'MCPToolMethodMutationTest')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchClassesReturnsWarningResultForMissingPackage [

	| data result warnings |
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
			          { (self searchScope:
				           { (#packages -> #( 'MCP-Definitely-Missing' )) }) }
				          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packageNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchPackagesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolSearchPackages new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolSearchPackages new name equals: 'package_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals:
			#( 'projectNames' 'packageNames' 'packageName' 'projectName'
			   'tag' 'filterMode' 'caseSensitive' 'limit' 'offset' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchPackagesListsPackagesForExistingProject [

	| data packageNames packages result |
	result := self
		          callToolNamed: 'package_search'
		          withArguments:
		          { (#projectNames -> #( 'MCP' )) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	packages := data at: #packages.
	packageNames := packages collect: [ :each | each at: #packageName ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: packages notEmpty.
	self assert: (packageNames includes: 'MCP').
	self assert: (packageNames includes: 'MCP-Tests')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchPackagesReturnsErrorResultForMissingProject [

	| result text |
	result := self
		          callToolNamed: 'package_search'
		          withArguments:
		          { (#projectNames -> #( 'DefinitelyMissingProject' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Project DefinitelyMissingProject does not exist.').
	self deny: (text includesSubstring: 'Tool package_search failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchRepositoriesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolSearchRepositories new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self
		assert: MCPToolSearchRepositories new name
		equals: 'repository_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals:
			#( 'repositoryNames' 'directoryPaths' 'packageNames' 'isModified'
			   'isMissing' 'repositoryName' 'repositoryClassName'
			   'location' 'subdirectory' 'branchName' 'headDescription'
			   'headClassName' 'headCommitId' 'packageName' 'modifiedPackageName'
			   'remoteName' 'remoteUrl' 'upstreamRemoteName'
			   'upstreamBranchName' 'upstreamRemoteUrl' 'filterMode'
			   'caseSensitive' 'limit' 'offset' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolPaginationSchemasAdvertiseBounds [

	MCPToolSearch concreteSubclasses do: [ :toolClass |
			| limitProperty offsetProperty tool |
			tool := toolClass new.
			limitProperty := self inputPropertyNamed: 'limit' inTool: tool.
			offsetProperty := self inputPropertyNamed: 'offset' inTool: tool.
			self assert: (limitProperty extraProperties at: #minimum) equals: 0.
			self
				assert: (limitProperty extraProperties at: #maximum)
				equals: 100.
			self
				assert: (limitProperty extraProperties at: #default)
				equals: 25.
			self
				assert: (offsetProperty extraProperties at: #minimum)
				equals: 0.
			self deny: (offsetProperty extraProperties includesKey: #maximum).
			self
				assert: (offsetProperty extraProperties at: #default)
				equals: 0 ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolSchemasAdvertiseGroupedScopeProperties [

	| oldScopePropertyNames searchTools scopePropertyNames |
	oldScopePropertyNames := #( 'packageNames' 'classNames' 'hierarchyClassNames'
	                            'subclassClassNames' 'parentClassNames' ).
	searchTools := {
		               MCPToolSearchClasses new.
		               MCPToolSearchMethodMetadata new.
		               MCPToolSearchMethodSource new.
		               MCPToolSearchMethodSenders new.
		               MCPToolSearchMethodImplementors new.
		               MCPToolSearchEquivalentMethods new.
		               MCPToolSearchClassReferences new.
		               MCPToolSearchVariableReferences new }.
	searchTools do: [ :tool |
			| propertyNames scopeProperty |
			propertyNames := tool inputSchema properties collect: [ :each |
				                 each name ].
			scopeProperty := self inputPropertyNamed: 'scope' inTool: tool.
			scopePropertyNames := (scopeProperty extraProperties at:
				                       #properties) collect: [ :each | each name ].
			self assert: (propertyNames includes: 'scope').
			oldScopePropertyNames do: [ :each |
				self deny: (propertyNames includes: each) ].
			self
				assert: scopePropertyNames asSet
				equals:
					#( 'classes' 'packages' 'superclassesOf' 'subclassesOf'
					   'hierarchies' ) asSet ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsIncludesStaticSurface [

	| metadataByName result |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#query -> 'classes') } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	self assert: (metadataByName includesKey: 'class_search').
	self
		assert: ((metadataByName at: 'class_search') at: #exposure)
		equals: 'static'
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsKeywordsAreSingleSearchTerms [

	| metadataByName result |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#limit -> 100) } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	self
		assert: ((metadataByName at: 'tool_search') at: #keywords) asSet
		equals: #( 'tool' 'catalog' 'search' ) asSet.
	self
		assert: ((metadataByName at: 'image_evaluate') at: #keywords) asSet
		equals:
			#( 'image' 'evaluate' 'runtime' 'expression' 'smalltalk'
			   'code' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsMatchesAgentGuidanceKeywords [

	| expectations |
	expectations := {
		                ('repo' -> 'repository_search').
		                ('identity' -> 'repository_identity_verify').
		                ('diff' -> 'repository_change_list').
		                ('stale' -> 'repository_branch_checkout').
		                ('SUnit' -> 'test_run').
		                ('coverage' -> 'test_coverage_run').
		                ('file' -> 'history_file_list').
		                ('entry' -> 'history_entry_list').
		                ('recover' -> 'history_entry_apply').
		                ('window' -> 'screenshot_capture').
		                ('display' -> 'screenshot_capture').
		                ('repair' -> 'debug_method_update').
		                ('refactor' -> 'class_slot_pull_up').
		                ('refactoring' -> 'method_selector_update') }.
	expectations do: [ :expectation |
			| names result |
			result := self
				          callToolNamed: 'tool_search'
				          withArguments:
				          { (#query -> expectation key) } asDictionary.
			names := ((self dataFrom: result) at: #tools) collect: [ :each |
				         each at: #name ].
			self assert: (names includes: expectation value) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsMatchesMultipleQueryTerms [

	| names result |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments:
		          { (#query -> 'method source') } asDictionary.
	names := ((self dataFrom: result) at: #tools) collect: [ :each |
		         each at: #name ].
	self assert: (names includes: 'method_source_search').

	result := self
		          callToolNamed: 'tool_search'
		          withArguments:
		          { (#query -> 'method equivalent') } asDictionary.
	names := ((self dataFrom: result) at: #tools) collect: [ :each |
		         each at: #name ].
	self assert: (names includes: 'method_equivalent_search')
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsMatchesPluralQueryTerms [

	| expectations |
	expectations := {
		                ('classes' -> 'class_search').
		                ('repositories' -> 'repository_search').
		                ('traits' -> 'class_traits_update').
		                ('variables' -> 'class_shared_variables_update').
		                ('refactorings' -> 'class_slot_pull_up') }.
	expectations do: [ :expectation |
			| names result |
			result := self callToolNamed: 'tool_search' withArguments: {
					          (#query -> expectation key).
					          (#limit -> 100) } asDictionary.
			names := ((self dataFrom: result) at: #tools) collect: [ :each |
				         each at: #name ].
			self assert: (names includes: expectation value) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsMatchesSpecializedClassKeywords [

	| expectations |
	expectations := {
		                ('trait composition' -> 'class_traits_update').
		                ('metaclass trait' -> 'class_side_traits_update').
		                ('classvar' -> 'class_shared_variables_update').
		                ('pooldictionary' -> 'class_shared_pools_update').
		                ('weak layout' -> 'class_layout_update') }.
	expectations do: [ :expectation |
			| names result |
			result := self callToolNamed: 'tool_search' withArguments: {
					          (#query -> expectation key).
					          (#limit -> 100) } asDictionary.
			names := ((self dataFrom: result) at: #tools) collect: [ :each |
				         each at: #name ].
			self assert: (names includes: expectation value) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsReturnsDiscoverableMetadata [

	| createRepositoryMetadata data names result tools |
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#query -> 'repository') } asDictionary.
	data := self dataFrom: result.
	tools := data at: #tools.
	names := tools collect: [ :each | each at: #name ].
	self assert: (names includes: 'repository_search').
	self assert: (names includes: 'repository_create').
	self assert: (names includes: 'repository_attach').
	self assert: (names includes: 'repository_update').
	self assert: (names includes: 'repository_load').
	self deny: (names includes: 'class_search').
	createRepositoryMetadata := tools detect: [ :each |
		                            (each at: #name) = 'repository_create' ].
	self
		assert: (createRepositoryMetadata at: #group)
		equals: 'repositories'.
	self
		assert: (createRepositoryMetadata at: #exposure)
		equals: 'discoverable'.
	self assert: (createRepositoryMetadata at: #schemaInspectionRequired)
]

{ #category : 'tests' }
MCPToolContractsTest >> testSearchToolsUseTypedRequestObjects [

	| classRequest methodRequest packageRequest repositoryRequest |
	repositoryRequest := MCPToolSearchRepositories new
		                     searchRequestFromToolRequest: (MCPToolRequest
				                      tool: MCPToolSearchRepositories new
				                      arguments: Dictionary new).
	classRequest := MCPToolSearchClasses new
		                searchRequestFromToolRequest: (MCPToolRequest
				                 tool: MCPToolSearchClasses new
				                 arguments: Dictionary new).
	methodRequest := MCPToolSearchMethodMetadata new
		                 searchRequestFromToolRequest: (MCPToolRequest
				                  tool: MCPToolSearchMethodMetadata new
				                  arguments: Dictionary new).
	packageRequest := MCPToolSearchPackages new
		                  searchRequestFromToolRequest: (MCPToolRequest
				                   tool: MCPToolSearchPackages new
				                   arguments: Dictionary new).
	self assert: repositoryRequest class equals: MCPRepositoryQuerySpec.
	self assert: classRequest class equals: MCPSearchClassesRequest.
	self assert: methodRequest class equals: MCPMethodSearchRequest.
	self assert: packageRequest class equals: MCPSearchPackagesRequest
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerCanConfigureStaticToolNames [

	| server toolNames |
	server := MCP new.
	server staticToolNames:
		#( 'tool_search' 'tool_get' 'tool_call' 'class_search' ).
	toolNames := (server rpcToolsList at: #tools) collect: [ :each |
		             each at: #name ].
	self
		assert: toolNames asSet
		equals:
		#( 'tool_search' 'tool_get' 'tool_call' 'class_search' )
			asSet.
	self deny: (toolNames includes: 'class_name_update')
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerInitializationDoesNotRenderToolIcons [

	MCPStructureIcon resetCaches.
	MCP new.
	self assert: MCPStructureIcon cachedRenderedIconCount equals: 0
]

{ #category : 'tests' }
MCPToolContractsTest >> testSpecializedClassAndMethodToolsAreDiscoverableOnly [

	| discoverableOnlyNames metadataByName result |
	discoverableOnlyNames := #( 'class_name_update' 'class_superclass_update'
	                            'class_package_update'
	                            'class_comment_update'
	                            'class_slots_update' 'class_traits_update'
	                            'class_side_traits_update'
	                            'class_shared_variables_update'
	                            'class_shared_pools_update'
	                            'class_layout_update'
	                            'class_slot_add' 'class_slot_remove'
	                            'class_slot_name_update'
	                            'class_slot_pull_up' 'class_slot_push_down'
	                            'method_equivalent_search'
	                            'method_class_reference_search'
	                            'method_variable_reference_search'
	                            'test_coverage_run' ).
	result := self
		          callToolNamed: 'tool_search'
		          withArguments: { (#limit -> 100) } asDictionary.
	metadataByName := Dictionary new.
	((self dataFrom: result) at: #tools) do: [ :each |
		metadataByName at: (each at: #name) put: each ].
	discoverableOnlyNames do: [ :each |
			| metadata tool |
			self assert: (MCPToolRegistry publicToolNames includes: each).
			self deny: (MCPToolRegistry staticToolNames includes: each).
			tool := MCPToolRegistry
				        toolNamed: each
				        ifAbsent: [ self fail: 'Missing tool ' , each ].
			self
				assert: (MCPToolRegistry exposureForTool: tool)
				equals: 'discoverable'.
			metadata := metadataByName
				            at: each
				            ifAbsent: [
				            self fail: 'Missing discoverable metadata for ' , each ].
			self assert: (metadata at: #exposure) equals: 'discoverable'.
			self assert: (metadata at: #schemaInspectionRequired) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testStaticToolConfigurationRejectsUnknownToolNames [

	self
		should: [
		MCP new staticToolNames: #( 'tool_search' 'not-a-tool' ) ]
		raise: Error
]

{ #category : 'tests' }
MCPToolContractsTest >> testStringArrayItemDescriptionsStayUseful [

	| compactProperty usefulProperty |
	compactProperty := MCPToolSearchClasses new
		                   stringArraySchemaNamed: 'packageNames'
		                   description: 'Packages to search.'
		                   itemDescription: 'Package name.'.
	self deny:
		((compactProperty asJRPCJSON at: #items) includesKey: #description).
	usefulProperty := self
		                  inputPropertyNamed: 'argumentValueExpressions'
		                  inTool: MCPToolUpdateMethodSelector new.
	self
		assert: ((usefulProperty asJRPCJSON at: #items) at: #description)
		equals: 'Smalltalk expression.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolFlowSelectorNamesSeparateTransportAndParsedInput [

	| staleSelectors |
	self assert:
		(MCPTool includesSelector: #parsedRequestFromToolRequest:).
	staleSelectors := #( toolRequestFromRequest: querySpecFromRequest:
	                     methodQueryParametersFromRequest:
	                     refactoringScopeParametersFromRequest:
	                     refactoringModelForScopeParameters:anchoredAtBehavior: ).
	staleSelectors do: [ :selector |
		self deny: (MCPTool withAllSubclasses anySatisfy: [ :each |
				 each includesSelector: selector ]) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolIconSpecsAreDerivedFromToolNames [

	self
		assert: (MCPTool withAllSubclasses count: [ :each |
				 each class includesSelector: #toolIconSpec ])
		equals: 1.
	self assert: (MCPTool class includesSelector: #toolIconSpec)
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolIconsAreSharedByToolClass [

	| firstIcons secondIcons |
	MCPStructureIcon resetCaches.
	firstIcons := MCPToolSearchClasses new icons.
	secondIcons := MCPToolSearchClasses new icons.
	self assert: firstIcons identicalTo: secondIcons.
	self assert: firstIcons first identicalTo: secondIcons first.
	self assert: MCPStructureIcon cachedRenderedIconCount equals: 1
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolNamesDoNotUsePharoPrefix [

	self assert: (MCPTool concreteSubclasses noneSatisfy: [ :each |
			 each new name includesSubstring: 'pharo-' ])
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolRegistryNamesUseClassSideMetadata [

	| names |
	names := MCPToolRegistry publicToolClasses collect: [ :each |
		         each toolName ].
	self assert: MCPToolRegistry publicToolNames equals: names.
	self assert: MCPToolSearchClasses toolName equals: 'class_search'.
	self assert: MCPToolCreateClass toolName equals: 'class_create'.
	self
		assert: MCPToolUpdateClassName toolName
		equals: 'class_name_update'.
	self
		assert: MCPToolUpdateClassSuperclass toolName
		equals: 'class_superclass_update'.
	self
		assert: MCPToolUpdateClassPackage toolName
		equals: 'class_package_update'.
	self
		assert: MCPToolUpdateClassComment toolName
		equals: 'class_comment_update'.
	self
		assert: MCPToolUpdateClassSlots toolName
		equals: 'class_slots_update'.
	self
		assert: MCPToolUpdateClassTraits toolName
		equals: 'class_traits_update'.
	self
		assert: MCPToolUpdateClassSideTraits toolName
		equals: 'class_side_traits_update'.
	self
		assert: MCPToolUpdateClassSharedVariables toolName
		equals: 'class_shared_variables_update'.
	self
		assert: MCPToolUpdateClassSharedPools toolName
		equals: 'class_shared_pools_update'.
	self
		assert: MCPToolUpdateClassLayout toolName
		equals: 'class_layout_update'.
	self assert: MCPToolAddClassSlot toolName equals: 'class_slot_add'.
	self
		assert: MCPToolRemoveClassSlot toolName
		equals: 'class_slot_remove'.
	self
		assert: MCPToolUpdateClassSlotName toolName
		equals: 'class_slot_name_update'.
	self
		assert: MCPToolPullUpClassSlot toolName
		equals: 'class_slot_pull_up'.
	self
		assert: MCPToolPushDownClassSlot toolName
		equals: 'class_slot_push_down'.
	self assert: MCPToolRunTests toolName equals: 'test_run'.
	self assert: MCPToolCreateMethod toolName equals: 'method_create'.
	self
		assert: MCPToolUpdateMethodSelector toolName
		equals: 'method_selector_update'.
	self
		assert: MCPToolUpdateMethodProtocol toolName
		equals: 'method_protocol_update'.
	self
		assert: MCPToolVerifyRepositoryIdentity toolName
		equals: 'repository_identity_verify'.
	self
		assert: MCPToolListRepositoryChanges toolName
		equals: 'repository_change_list'.
	self
		assert: MCPToolCreateRepository toolName
		equals: 'repository_create'.
	self
		assert: MCPToolAttachRepository toolName
		equals: 'repository_attach'.
	self
		assert: MCPToolUpdateRepository toolName
		equals: 'repository_update'.
	self
		assert: MCPToolExportRepository toolName
		equals: 'repository_export'.
	self
		assert: MCPToolCommitRepository toolName
		equals: 'repository_commit'.
	self
		assert: MCPToolFetchRepository toolName
		equals: 'repository_fetch'.
	self assert: MCPToolPullRepository toolName equals: 'repository_pull'.
	self assert: MCPToolPushRepository toolName equals: 'repository_push'.
	self
		assert: MCPToolCreateRepositoryBranch toolName
		equals: 'repository_branch_create'.
	self
		assert: MCPToolSwitchRepositoryBranch toolName
		equals: 'repository_branch_switch'.
	self
		assert: MCPToolAdoptRepositoryHead toolName
		equals: 'repository_head_adopt'.
	self
		assert: MCPToolListChangeHistoryFiles toolName
		equals: 'history_file_list'.
	self
		assert: MCPToolListChangeHistoryEntries toolName
		equals: 'history_entry_list'.
	self
		assert: MCPToolApplyChangeHistoryEntries toolName
		equals: 'history_entry_apply'.
	self
		assert: MCPToolRevertChangeHistoryEntries toolName
		equals: 'history_entry_revert'.
	self assert: MCPToolDebugState toolName equals: 'debug_state_get'.
	self
		assert: MCPToolStepOverDebugSession toolName
		equals: 'debug_session_step_over'.
	self assert: MCPToolDebugCapture toolName equals: 'debug_capture'.
	self assert: MCPToolUpdateDebugMethod toolName equals: 'debug_method_update'
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolSearchLimitSchemaAdvertisesBounds [

	| limitProperty |
	limitProperty := self
		                 inputPropertyNamed: 'limit'
		                 inTool: MCPToolSearchTools new.
	self assert: (limitProperty extraProperties at: #minimum) equals: 0.
	self assert: (limitProperty extraProperties at: #maximum) equals: 100.
	self assert: (limitProperty extraProperties at: #default) equals: 25
]

{ #category : 'support' }
MCPToolContractsTest >> toolFlowSpecs [

	| specs |
	specs := OrderedCollection withAll: self baseToolFlowSpecs.
	specs add: self baselineLoadToolFlowSpec.
	specs add: self coverageToolFlowSpec.
	specs addAll: self classMutationToolFlowSpecs.
	specs addAll: self methodLookupToolFlowSpecs.
	specs addAll: self methodMutationToolFlowSpecs.
	specs addAll: self changeHistoryToolFlowSpecs.
	specs addAll: self repositoryToolFlowSpecs.
	specs addAll: self debugSessionToolFlowSpecs.
	specs addAll: self debugControlToolFlowSpecs.
	specs addAll: self debugBreakpointToolFlowSpecs.
	specs add: self debugTestToolFlowSpec.
	^ specs asArray

]
