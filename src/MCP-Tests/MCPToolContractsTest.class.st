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

{ #category : 'private' }
MCPToolContractsTest >> baseToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolFindRepositories).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPRepositoryQuerySpec).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolEditRepository).
			  (#arguments -> {
				   (#operation -> 'update').
				   (#repositoryName -> 'MCP').
				   (#addPackageNames -> #( 'MCP' )) } asDictionary).
			  (#requestClass -> MCPRepositoryUpdateRequest).
			  (#commandClass -> MCPUpdateRepositoryCommand) } asDictionary.
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
			  (#toolClass -> MCPToolFindPackages).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPFindPackagesRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindClasses).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPFindClassesRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolInspectClass).
			  (#arguments -> { (#className -> 'Object') } asDictionary).
			  (#requestClass -> MCPInspectClassRequest).
			  (#commandClass -> MCPInspectClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolEditClass).
			  (#arguments -> {
				   (#operation -> 'update').
				   (#className -> 'Object').
				   (#classComment -> '') } asDictionary).
			  (#requestClass -> MCPClassUpdateRequest).
			  (#commandClass -> MCPUpdateClassCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolRemoveClasses).
			  (#arguments -> { (#classNames -> #( 'Object' )) } asDictionary).
			  (#requestClass -> MCPRemoveClassesRequest).
			  (#commandClass -> MCPRemoveClassesCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindMethods).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPFindMethodsRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolInspectMethod).
			  (#arguments -> {
				   (#className -> 'Object').
				   (#selector -> 'class') } asDictionary).
			  (#requestClass -> MCPInspectMethodRequest).
			  (#commandClass -> MCPInspectMethodCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolEditMethod).
			  (#arguments -> {
				   (#operation -> 'update').
				   (#className -> 'Object').
				   (#selector -> 'class').
				   (#protocol -> 'accessing') } asDictionary).
			  (#requestClass -> MCPMethodUpdateRequest).
			  (#commandClass -> MCPUpdateMethodCommand) } asDictionary.
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
			  (#toolClass -> MCPToolManageChangeHistory).
			  (#arguments -> {
				   (#operation -> 'listFiles').
				   (#includeEntryCounts -> false) } asDictionary).
			  (#requestClass -> MCPChangeHistoryListLogsRequest).
			  (#commandClass -> MCPListChangeHistoryLogsCommand) } asDictionary.
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
			  (#toolClass -> MCPToolDebugSessions).
			  (#arguments -> { (#operation -> 'list') } asDictionary).
			  (#requestClass -> MCPDebugSessionsRequest).
			  (#commandClass -> MCPDebugSessionsCommand) } asDictionary.
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
			  (#toolClass -> MCPToolDebugControl).
			  (#arguments -> {
				   (#sessionId -> 'debug-session-1').
				   (#operation -> 'stepOver') } asDictionary).
			  (#requestClass -> MCPDebugControlRequest).
			  (#commandClass -> MCPDebugControlCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDebugBreakpoints).
			  (#arguments -> { (#operation -> 'list') } asDictionary).
			  (#requestClass -> MCPDebugBreakpointsRequest).
			  (#commandClass -> MCPDebugBreakpointsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDebugCapture).
			  (#arguments -> { (#expression -> '1') } asDictionary).
			  (#requestClass -> MCPDebugCaptureRequest).
			  (#commandClass -> MCPDebugCaptureCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDebugEdit).
			  (#arguments -> { (#sessionId -> 'debug-session-1') } asDictionary).
			  (#requestClass -> MCPDebugEditRequest).
			  (#commandClass -> MCPDebugEditCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolEvaluate).
			  (#arguments -> { (#code -> '1') } asDictionary).
			  (#requestClass -> MCPEvaluateRequest).
			  (#commandClass -> MCPEvaluateCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolDiscoverTools).
			  (#arguments -> Dictionary new).
			  (#requestClass -> MCPDiscoverToolsRequest).
			  (#commandClass -> MCPDiscoverToolsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolInspectTool).
			  (#arguments -> { (#toolName -> 'class_search') } asDictionary).
			  (#requestClass -> MCPInspectToolRequest).
			  (#commandClass -> MCPInspectToolCommand) } asDictionary.
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
MCPToolContractsTest >> focusedChangeHistoryToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolFindChangeHistoryFiles).
			  (#arguments -> { (#includeEntryCounts -> false) } asDictionary).
			  (#requestClass -> MCPChangeHistoryListLogsRequest).
			  (#commandClass -> MCPListChangeHistoryLogsCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindChangeHistoryEntries).
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
MCPToolContractsTest >> focusedClassEditToolClasses [

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
MCPToolContractsTest >> focusedClassEditToolFlowSpecs [

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
MCPToolContractsTest >> focusedDebugBreakpointToolFlowSpecs [

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
MCPToolContractsTest >> focusedDebugControlToolFlowSpecs [

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
MCPToolContractsTest >> focusedDebugSessionToolFlowSpecs [

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
MCPToolContractsTest >> focusedMethodEditToolFlowSpecs [

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
MCPToolContractsTest >> focusedMethodLookupToolFlowSpecs [

	^ {
		  {
			  (#toolClass -> MCPToolFindMethodSource).
			  (#arguments -> { (#filter -> 'class') } asDictionary).
			  (#requestClass -> MCPFindMethodsRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindEquivalentMethods).
			  (#arguments -> {
				   (#className -> 'MCPTool').
				   (#selector -> 'defaultName') } asDictionary).
			  (#requestClass -> MCPFindEquivalentMethodsRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindMethodImplementors).
			  (#arguments -> { (#selector -> 'class') } asDictionary).
			  (#requestClass -> MCPFindMethodsRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindMethodSenders).
			  (#arguments -> { (#selector -> 'class') } asDictionary).
			  (#requestClass -> MCPFindMethodsRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindClassReferences).
			  (#arguments -> { (#className -> 'Object') } asDictionary).
			  (#requestClass -> MCPFindMethodsRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary.
		  {
			  (#toolClass -> MCPToolFindVariableReferences).
			  (#arguments -> { (#variableName -> 'instVarNamed') } asDictionary).
			  (#requestClass -> MCPFindMethodsRequest).
			  (#commandClass -> MCPQueryToolCommand) } asDictionary }
]

{ #category : 'private' }
MCPToolContractsTest >> focusedRepositoryToolFlowSpecs [

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
			  (#toolClass -> MCPToolFindRepositoryChanges).
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
			  (#toolClass -> MCPToolAdoptRepositoryHead).
			  (#arguments -> { (#repositoryName -> 'MCP') } asDictionary).
			  (#requestClass -> MCPRepositoryAdoptHeadRequest).
			  (#commandClass -> MCPAdoptRepositoryHeadCommand) } asDictionary }
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
MCPToolContractsTest >> testAllToolsAdvertisePngIconsWithDataUris [

	| toolDefinitions |
	toolDefinitions := MCPTool concreteSubclasses collect: [ :each |
		                   each new asJRPCJSON ].
	toolDefinitions do: [ :definition |
		| icon icons |
		icons := definition
			         at: #icons
			         ifAbsent: [
			         self fail: 'Missing icons for tool definition.' ].
		self deny: icons isEmpty.
		icon := icons first.
		self assert: (icon at: #mimeType) equals: 'image/png'.
		self assert: ((icon at: #src) beginsWith: 'data:image/png;base64,').
		self assert: (icon at: #sizes) size equals: 1.
		self assert: ((icon at: #sizes) first includesSubstring: 'x') ]
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
			MCPToolDiscoverTools.
			MCPToolInspectTool.
			MCPToolCallTool.
			MCPToolFindRepositories.
			MCPToolVerifyRepositoryIdentity.
			MCPToolFindRepositoryChanges.
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
			MCPToolAdoptRepositoryHead.
			MCPToolLoadBaseline.
			MCPToolLoadRepository.
			MCPToolFindPackages.
			MCPToolFindClasses.
			MCPToolInspectClass.
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
			MCPToolFindMethods.
			MCPToolFindMethodSource.
			MCPToolFindEquivalentMethods.
			MCPToolFindMethodImplementors.
			MCPToolFindMethodSenders.
			MCPToolFindClassReferences.
			MCPToolFindVariableReferences.
			MCPToolInspectMethod.
			MCPToolCreateMethod.
			MCPToolUpdateMethodSelector.
			MCPToolUpdateMethodProtocol.
			MCPToolRewriteMethods.
			MCPToolRemoveMethods.
			MCPToolFindChangeHistoryFiles.
			MCPToolFindChangeHistoryEntries.
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
			MCPToolDebugEdit.
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
MCPToolContractsTest >> testClassPackageUpdateDescriptionMentionsRecategorization [

	| description |
	description := MCPToolUpdateClassPackage new description.
	self assert: (description includesSubstring: 'recategorize').
	self assert: (description includesSubstring: 'tag').
	self assert: (description includesSubstring: 'Omit packageName').
	self assert: (description includesSubstring: 'current package')
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassToolTraitOwnsSharedClassHelpers [

	| classToolClasses sharedSelectors |
	classToolClasses := {
		                    MCPToolFindClasses.
		                    MCPToolInspectClass }
	                    , self focusedClassEditToolClasses
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
	                 'debug_test_run' 'debug_method_repair' ).
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
				equals: 'debugging' ].
	self deny: (metadataByName includesKey: 'debug_control')
]

{ #category : 'tests' }
MCPToolContractsTest >> testDictionaryShapedCommandResultsUseDTOClasses [

	| commandResultClasses |
	commandResultClasses := {
		                        (MCPEvaluateCommand -> MCPEvaluateResult).
		                        (MCPInspectClassCommand
		                         -> MCPInspectClassResult).
		                        (MCPInspectMethodCommand
		                         -> MCPInspectMethodResult).
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
MCPToolContractsTest >> testDiscoverToolsCanIncludeStaticSurface [

	| metadataByName result |
	result := self callToolNamed: 'tool_search' withArguments: {
			          (#query -> 'classes').
			          (#includeStatic -> true) } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	self assert: (metadataByName includesKey: 'class_search').
	self
		assert: ((metadataByName at: 'class_search') at: #exposure)
		equals: 'static'
]

{ #category : 'tests' }
MCPToolContractsTest >> testDiscoverToolsKeywordsAreSingleSearchTerms [

	| metadataByName result |
	result := self callToolNamed: 'tool_search' withArguments: {
			          (#includeStatic -> true).
			          (#limit -> 200) } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	self
		assert: ((metadataByName at: 'tool_search') at: #keywords) asSet
		equals: #( 'tool' 'catalog' 'search' 'tools' ) asSet.
	self
		assert: ((metadataByName at: 'image_evaluate') at: #keywords) asSet
		equals:
			#( 'image' 'evaluate' 'runtime' 'expression' 'smalltalk'
			   'code' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testDiscoverToolsMatchesAgentGuidanceKeywords [

	| expectations |
	expectations := {
		                ('repo' -> 'repository_search').
		                ('identity' -> 'repository_identity_verify').
		                ('diff' -> 'repository_change_list').
		                ('SUnit' -> 'test_run').
		                ('coverage' -> 'test_coverage_run').
		                ('file' -> 'history_file_list').
		                ('entry' -> 'history_entry_list').
		                ('recover' -> 'history_entry_apply').
		                ('window' -> 'screenshot_capture').
		                ('display' -> 'screenshot_capture').
		                ('repair' -> 'debug_method_repair') }.
	expectations do: [ :expectation |
			| names result |
			result := self callToolNamed: 'tool_search' withArguments: {
					          (#query -> expectation key).
					          (#includeStatic -> true) } asDictionary.
			names := ((self dataFrom: result) at: #tools) collect: [ :each |
				         each at: #name ].
			self assert: (names includes: expectation value) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testDiscoverToolsMatchesMultipleQueryTerms [

	| names result |
	result := self callToolNamed: 'tool_search' withArguments: {
			          (#query -> 'method source').
			          (#includeStatic -> true) } asDictionary.
	names := ((self dataFrom: result) at: #tools) collect: [ :each |
		         each at: #name ].
	self assert: (names includes: 'method_source_search').

	result := self callToolNamed: 'tool_search' withArguments: {
			          (#query -> 'method equivalent').
			          (#includeStatic -> true) } asDictionary.
	names := ((self dataFrom: result) at: #tools) collect: [ :each |
		         each at: #name ].
	self assert: (names includes: 'method_equivalent_search')
]

{ #category : 'tests' }
MCPToolContractsTest >> testDiscoverToolsReturnsDiscoverableMetadata [

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
	self deny: (names includes: 'repository_edit').
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
MCPToolContractsTest >> testDiscoveryUsesConfiguredStaticToolNames [

	| metadataByName result server |
	server := MCP new.
	server staticToolNames:
		#( 'tool_search' 'tool_get' 'tool_call' 'repository_search' ).
	result := server rpcToolCall: 'tool_search' withParams: {
			          (#query -> 'repository').
			          (#includeStatic -> true) } asDictionary.
	metadataByName := (((self dataFrom: result) at: #tools) collect: [
		                   :each | (each at: #name) -> each ]) asDictionary.
	self
		assert: ((metadataByName at: 'repository_search') at: #exposure)
		equals: 'static'.
	self
		assert: ((metadataByName at: 'repository_create') at: #exposure)
		equals: 'discoverable'.
	self deny: (metadataByName includesKey: 'repository_edit')
]

{ #category : 'tests' }
MCPToolContractsTest >> testDisplayToolsCatalogSummarizesToolOperations [

	| presenter |
	presenter := MCPToolsCatalogPresenter new.
	self
		assert:
		(presenter toolCatalogOperationSummaryFor: MCPToolEditRepository new)
		equals: 'create | attach | +11'.
	self
		assert:
		(presenter toolCatalogOperationSummaryFor: MCPToolCreateMethod new)
		equals: 'create'.
	self
		assert: (presenter toolCatalogOperationSummaryFor:
				 MCPToolUpdateMethodSelector new)
		equals: 'update'.
	self
		assert: (presenter toolCatalogOperationSummaryFor:
				 MCPToolUpdateMethodProtocol new)
		equals: 'update'.
	self
		assert:
		(presenter toolCatalogOperationSummaryFor: MCPToolRewriteMethods new)
		equals: 'preview | apply'.
	self
		assert:
		(presenter toolCatalogOperationSummaryFor: MCPToolFindMethods new)
		equals: 'query'.
	self
		assert:
		(presenter toolCatalogOperationSummaryFor: MCPToolInspectClass new)
		equals: 'get'.
	self
		assert:
		(presenter toolCatalogOperationSummaryFor: MCPToolRemoveMethods new)
		equals: 'remove'
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditClassHasAccurateNameAndRequiredArguments [

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
MCPToolContractsTest >> testEditDescriptionsExplainForceWarningBehavior [

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
			self assert: (each includesSubstring: 'impactMessages').
			self assert: (each includesSubstring: 'howToProceed').
			self assert: (each includesSubstring: 'forceSupported=true').
			self assert: (each includesSubstring: 'warnings') ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditMethodHasAccurateNameAndRequiredArguments [

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
MCPToolContractsTest >> testEditMethodSchemaAdvertisesMethodState [

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
	self deny: (toolPropertyNames includes: 'operation').
	self assert:
		(permutationProperty extraProperties at: #items) type = 'integer'.
	self assert:
		(argumentNamesProperty extraProperties at: #items) type = 'string'.
	self assert:
		(argumentValuesProperty extraProperties at: #items) type = 'string'.
	self
		assert: propertyNames asSet
		equals: #( 'operation' 'updateAction' 'updatePlan' 'appliedChange'
			   'selector' 'className' 'classSide' 'packageName' 'isExtension'
			   'protocol' 'source' 'oldSelector' 'newSelector' 'oldProtocol'
			   'newProtocol' 'critiques' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditRepositoryDescriptionDocumentsRepositoryOperations [

	| branchNameDescription description isModifiedDescription locationDescription messageDescription modifiedPackageNamesDescription packageNamesDescription removePackageNamesDescription repositoryNameDescription subdirectoryDescription tool |
	tool := MCPToolEditRepository new.
	description := tool description.
	messageDescription := (self
		                       inputPropertyNamed: 'message'
		                       inTool: tool) description.
	branchNameDescription := (self
		                          inputPropertyNamed: 'branchName'
		                          inTool: tool) description.
	repositoryNameDescription := (self
		                              inputPropertyNamed: 'repositoryName'
		                              inTool: tool) description.
	locationDescription := (self
		                        inputPropertyNamed: 'location'
		                        inTool: tool) description.
	subdirectoryDescription := (self
		                             inputPropertyNamed: 'subdirectory'
		                             inTool: tool) description.
	packageNamesDescription := (self
		                            inputPropertyNamed: 'packageNames'
		                            inTool: tool) description.
	modifiedPackageNamesDescription := (self
		                                    inputPropertyNamed:
		                                    'modifiedPackageNames'
		                                    inTool: tool) description.
	isModifiedDescription := (self
		                          inputPropertyNamed: 'isModified'
		                          inTool: tool) description.
	removePackageNamesDescription := (self
		                                  inputPropertyNamed:
		                                  'removePackageNames'
		                                  inTool: tool) description.
	self assert: (description includesSubstring: 'repositoryName').
	self assert: (description includesSubstring: 'operation=attach').
	self assert: (description includesSubstring: 'existing Git checkout').
	self assert: (description includesSubstring: 'without creating').
	self assert: (description includesSubstring: 'operation=diff').
	self assert: (description includesSubstring: 'without writing files').
	self assert: (description includesSubstring: 'should be preferred').
	self assert: (description includesSubstring: 'operation=export').
	self assert: (description includesSubstring: 'escape hatch').
	self assert:
		(description includesSubstring: 'without staging or committing').
	self assert: (description includesSubstring: 'operation=verifyIdentity').
	self assert:
		(description includesSubstring: 'asserts expected repository identity fields').
	self assert:
		(description includesSubstring: 'provide at least one expected field').
	self assert: (description includesSubstring: 'operation=commit').
	self assert:
		(description includesSubstring: 'IceRepository>>commitWithMessage:').
	self assert: (description includesSubstring: 'operation=adoptHead').
	self assert:
		(description includesSubstring: 'IceWorkingCopy>>adoptCommit:').
	self assert:
		(description includesSubstring: 'before/after modified packages').
	self assert: (description includesSubstring: 'operation=fetch').
	self assert: (description includesSubstring: 'IceRepository>>fetch').
	self assert: (description includesSubstring: 'operation=pull').
	self assert: (description includesSubstring: 'IceRepository>>pull').
	self assert: (description includesSubstring: 'operation=push').
	self assert: (description includesSubstring: 'IceRepository>>push').
	self assert:
		(description includesSubstring: 'operation=createBranch').
	self assert:
		(description includesSubstring: 'operation=switchBranch').
	self assert:
		(messageDescription includesSubstring: 'operation=commit').
	self assert:
		(branchNameDescription includesSubstring: 'operation=createBranch').
	self assert:
		(branchNameDescription includesSubstring: 'operation=switchBranch').
	self assert:
		(branchNameDescription includesSubstring: 'operation=adoptHead').
	self assert:
		(branchNameDescription includesSubstring: 'operation=verifyIdentity').
	self assert:
		(repositoryNameDescription includesSubstring: 'existing repository').
	self assert:
		(repositoryNameDescription includesSubstring:
			 'Combine with location').
	self assert:
		(locationDescription includesSubstring: 'operation=create').
	self assert:
		(locationDescription includesSubstring: 'operation=attach').
	self assert:
		(locationDescription includesSubstring: 'operation=verifyIdentity').
	self assert: (locationDescription includesSubstring: 'disambiguate').
	self assert:
		(subdirectoryDescription includesSubstring: 'operation=verifyIdentity').
	self assert: (packageNamesDescription includesSubstring:
			 'operation=create or operation=attach').
	self assert: (packageNamesDescription includesSubstring:
			 'replaces the full managed package list').
	self assert:
		(packageNamesDescription includesSubstring: 'operation=verifyIdentity').
	self assert:
		(modifiedPackageNamesDescription includesSubstring:
			 'operation=verifyIdentity').
	self assert:
		(isModifiedDescription includesSubstring: 'operation=verifyIdentity').
	self assert:
		(removePackageNamesDescription includesSubstring: 'does not unload')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditRepositoryDescriptionExplainsPackageAndFilesystemSemantics [

	| branchNameDescription description locationDescription messageDescription packageNamesDescription removePackageNamesDescription repositoryNameDescription tool |
	tool := MCPToolEditRepository new.
	description := tool description.
	messageDescription := (self
		                       inputPropertyNamed: 'message'
		                       inTool: tool) description.
	branchNameDescription := (self
		                          inputPropertyNamed: 'branchName'
		                          inTool: tool) description.
	repositoryNameDescription := (self
		                              inputPropertyNamed: 'repositoryName'
		                              inTool: tool) description.
	locationDescription := (self
		                        inputPropertyNamed: 'location'
		                        inTool: tool) description.
	packageNamesDescription := (self
		                            inputPropertyNamed: 'packageNames'
		                            inTool: tool) description.
	removePackageNamesDescription := (self
		                                  inputPropertyNamed:
		                                  'removePackageNames'
		                                  inTool: tool) description.
	self assert: (description includesSubstring: 'repositoryName').
	self assert: (description includesSubstring: 'operation=attach').
	self assert: (description includesSubstring: 'existing Git checkout').
	self assert: (description includesSubstring: 'without creating').
	self assert: (description includesSubstring: 'operation=diff').
	self assert: (description includesSubstring: 'without writing files').
	self assert: (description includesSubstring: 'should be preferred').
	self assert: (description includesSubstring: 'operation=export').
	self assert: (description includesSubstring: 'escape hatch').
	self assert:
		(description includesSubstring: 'without staging or committing').
	self assert: (description includesSubstring: 'operation=commit').
	self assert:
		(description includesSubstring: 'IceRepository>>commitWithMessage:').
	self assert: (description includesSubstring: 'operation=fetch').
	self assert: (description includesSubstring: 'IceRepository>>fetch').
	self assert: (description includesSubstring: 'operation=pull').
	self assert: (description includesSubstring: 'IceRepository>>pull').
	self assert: (description includesSubstring: 'operation=push').
	self assert: (description includesSubstring: 'IceRepository>>push').
	self assert:
		(description includesSubstring: 'operation=createBranch').
	self assert:
		(description includesSubstring: 'operation=switchBranch').
	self assert:
		(messageDescription includesSubstring: 'operation=commit').
	self assert:
		(branchNameDescription includesSubstring: 'operation=createBranch').
	self assert:
		(branchNameDescription includesSubstring: 'operation=switchBranch').
	self assert:
		(repositoryNameDescription includesSubstring: 'existing repository').
	self assert:
		(repositoryNameDescription includesSubstring:
			 'Combine with location').
	self assert:
		(locationDescription includesSubstring: 'operation=create').
	self assert:
		(locationDescription includesSubstring: 'operation=attach').
	self assert: (locationDescription includesSubstring: 'disambiguate').
	self assert: (packageNamesDescription includesSubstring:
			 'operation=create or operation=attach').
	self assert: (packageNamesDescription includesSubstring:
			 'replaces the full managed package list').
	self assert:
		(removePackageNamesDescription includesSubstring: 'does not unload')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditRepositoryOutputSchemaUsesActionForExecutedAction [

	| dataProperties outputSchema required |
	outputSchema := MCPToolEditRepository new outputSchema asJRPCJSON.
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
MCPToolContractsTest >> testEditToolSchemasAdvertiseOperationEnumsWithoutComposition [

	| editRepository focusedMethodTools repositoryOperationProperty |
	editRepository := MCPToolEditRepository new.
	focusedMethodTools := {
		                      MCPToolCreateMethod new.
		                      MCPToolUpdateMethodSelector new.
		                      MCPToolUpdateMethodProtocol new }.
	repositoryOperationProperty := self
		                               inputPropertyNamed: 'operation'
		                               inTool: editRepository.
	self deny:
		(editRepository inputSchema asJRPCJSON includesKey: #oneOf).
	self focusedClassEditToolClasses do: [ :toolClass |
			| propertyNames tool |
			tool := toolClass new.
			propertyNames := tool inputSchema properties collect: [ :property |
				                 property name ].
			self deny: (tool inputSchema asJRPCJSON includesKey: #oneOf).
			self deny: (propertyNames includes: 'operation').
			self deny: (propertyNames includes: 'slotAction') ].
	focusedMethodTools do: [ :tool |
			| propertyNames |
			propertyNames := tool inputSchema properties collect: [ :property |
				                 property name ].
			self deny: (tool inputSchema asJRPCJSON includesKey: #oneOf).
			self deny: (propertyNames includes: 'operation') ].
	self
		assert: editRepository inputSchema required asSet
		equals: #( 'operation' ) asSet.
	self
		assert:
		(repositoryOperationProperty extraProperties at: #enum) asArray
		equals:
			#( 'create' 'attach' 'update' 'verifyIdentity' 'export' 'diff'
			   'commit' 'adoptHead' 'fetch' 'pull' 'push' 'createBranch'
			   'switchBranch' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditToolSchemasAdvertiseRenameScopeConditions [

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
MCPToolContractsTest >> testFindClassesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolFindClasses new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolFindClasses new name equals: 'class_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals: #( 'packageNames' 'classNames' 'hierarchyClassNames'
			   'subclassClassNames' 'parentClassNames' 'className' 'tag' 'instanceSlot'
			   'classSlot' 'filterMode' 'caseSensitive' 'limit' 'offset' )
				asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindClassesListsClassesForExistingPackage [

	| classNames data result |
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
		          { (#packageNames -> #( 'MCP-Tests' )) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) > 0.
	self assert: (classNames includes: 'MCPToolEditMethodTest')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindClassesReturnsWarningResultForMissingPackage [

	| data result warnings |
	result := self
		          callToolNamed: 'class_search'
		          withArguments:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing').
	self assert: (warnings first includesSubstring: 'packageNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsDescriptionPointsToFocusedReferenceTools [

	| description filterModeDescription filterModeProperty protocolDescription selectorDescription tool |
	tool := MCPToolFindMethods new.
	description := tool description.
	self assert: (description includesSubstring: 'method_source_search').
	self assert:
		(description includesSubstring: 'method_equivalent_search').
	self assert:
		(description includesSubstring: 'method_implementor_search').
	self assert: (description includesSubstring: 'method_sender_search').
	self assert:
		(description includesSubstring: 'method_class_reference_search').
	self assert:
		(description includesSubstring: 'method_variable_reference_search').
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
	self assert:
		(filterModeDescription includesSubstring: 'selector and protocol').
	self
		assert: (filterModeProperty extraProperties at: #enum) asArray
		equals: #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsHasAccurateNameAndSchema [

	| filterModeProperty propertyNames schema |
	schema := MCPToolFindMethods new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	filterModeProperty := schema properties detect: [ :each |
		                      each name = 'filterMode' ].
	self
		assert: MCPToolFindMethods new name
		equals: 'method_metadata_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals: #( 'packageNames' 'classNames' 'hierarchyClassNames'
			   'subclassClassNames' 'parentClassNames' 'selector' 'protocol'
			   'filterMode' 'side' 'includeSource' 'limit' 'offset' 'caseSensitive' )
				asSet.
	self
		assert: (filterModeProperty extraProperties at: #enum) asArray
		equals: #( 'substring' 'prefix' 'exact' 'regex' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsListsMethodsForExistingClassScope [

	| data result selectors |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments:
		          { (#classNames -> #( 'MCPToolFindMethodsTestTarget' )) }
			          asDictionary.
	data := (result at: #structuredContent) at: #data.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: selectors size.
	self assert: (selectors includes: 'alphaNeedleSelector').
	self assert: (selectors includes: 'classNeedleSelector')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsReturnsWarningResultForMissingClass [

	| data result warnings |
	result := self
		          callToolNamed: 'method_metadata_search'
		          withArguments:
			          { (#classNames
			           -> #( 'MCPDefinitelyMissingFindMethodsClass' )) }
				          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring:
			 'MCPDefinitelyMissingFindMethodsClass').
	self assert: (warnings first includesSubstring: 'classNames scope').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsTopLevelFilterModesAreTextOnly [

	| filterModeEnum filterModeProperty schema selectorProperty |
	schema := MCPToolFindMethods new inputSchema asJRPCJSON.
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
MCPToolContractsTest >> testFindPackagesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolFindPackages new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolFindPackages new name equals: 'package_search'.
	self assert: schema required equals: #(  ).
	self
		assert: propertyNames asSet
		equals:
			#( 'projectNames' 'packageNames' 'packageName' 'projectName'
			   'tag' 'filterMode' 'caseSensitive' 'limit' 'offset' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesListsPackagesForExistingProject [

	| packageNames data result |
	result := self
		          callToolNamed: 'package_search'
		          withArguments:
		          { (#projectNames -> #( 'MCP' )) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: packageNames size.
	self assert: (packageNames includes: 'MCP').
	self assert: (packageNames includes: 'MCP-Tests')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesReturnsErrorResultForMissingProject [

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
MCPToolContractsTest >> testFindRepositoriesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolFindRepositories new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self
		assert: MCPToolFindRepositories new name
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
MCPToolContractsTest >> testFocusedClassSchemaDescriptionsExplainRecategorizationForceAndReplacementSemantics [

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
	self assert: (forceDescription includesSubstring: 'force=false').
	self assert: (forceDescription includesSubstring: 'force=true').
	self assert: (forceDescription includesSubstring: 'impactMessages').
	self assert: (forceDescription includesSubstring: 'warnings').
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
MCPToolContractsTest >> testFocusedClassToolsOutputSchemaAdvertisesUpdateResultDTOs [

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
MCPToolContractsTest >> testFocusedRepositoryCreateAndUpdateRequiredArguments [

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
	schema := MCPToolFindMethods new inputSchema asJRPCJSON.
	self deny: (schema includesKey: #required).
	self deny: (schema includesKey: #oneOf).
	self deny: (schema includesKey: #anyOf).
	self deny: (schema includesKey: #allOf).
	self assert: (schema at: #additionalProperties) equals: false
]

{ #category : 'tests' }
MCPToolContractsTest >> testInspectClassHasAccurateNameAndRequiredArguments [

	| inputPropertyNames outputDataProperty outputPropertyNames tool |
	tool := MCPToolInspectClass new.
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
MCPToolContractsTest >> testInspectMethodHasAccurateNameAndRequiredArguments [

	| propertyNames variablePropertyNames |
	propertyNames := MCPToolInspectMethod new inputSchema properties
		                 collect: [ :each | each name ].
	variablePropertyNames := (MCPToolInspectMethod new
		                          variableReferenceSchema extraProperties
		                          at: #properties) collect: [ :each |
		                         each name ].
	self assert: MCPToolInspectMethod new name equals: 'method_get'.
	self
		assert: MCPToolInspectMethod new inputSchema required asSet
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
MCPToolContractsTest >> testInspectToolReturnsSchemaForDiscoveredTool [

	| inputProperties inspected result |
	result := self
		          callToolNamed: 'tool_get'
		          withArguments:
		          { (#toolName -> 'repository_create') } asDictionary.
	inspected := (self dataFrom: result) at: #tool.
	self assert: (inspected at: #name) equals: 'repository_create'.
	self assert: (inspected at: #group) equals: 'repositories'.
	self assert: (inspected at: #exposure) equals: 'discoverable'.
	inputProperties := ((inspected at: #inputSchema) at: #properties)
		                   keys.
	self assert: (inputProperties includes: 'name').
	self assert: (inputProperties includes: 'location').
	self deny: (inputProperties includes: 'operation').
	self
		assert: ((inspected at: #inputSchema) at: #required) asArray
		equals: #( 'name' 'location' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testMethodToolTraitOwnsSharedMethodHelpers [

	| methodToolClasses sharedSelectors |
	methodToolClasses := {
		                     MCPToolFindMethods.
		                     MCPToolInspectMethod.
		                     MCPToolEditMethod.
		                     MCPToolRewriteMethods.
		                     MCPToolRemoveMethods }.
	sharedSelectors := #( selectorStringFromRequest:
	                      behaviorNamed:classSide:
	                      methodReferenceForBehavior:selector:
	                      methodReferenceForClassName:selector:isClassSide:
	                      methodScopeQueryFromRequest: ).
	methodToolClasses do: [ :toolClass |
		self assert: (toolClass traits includes: TMCPMethodTool).
		sharedSelectors do: [ :selector |
			self assert: (toolClass >> selector) origin equals: TMCPMethodTool ] ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testMutatingToolsRequestImageSaveAfterSuccessfulExecution [

	self deny:
		MCPToolFindMethods new shouldSaveImageAfterSuccessfulExecution.
	self deny:
		MCPToolInspectClass new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolEditRepository new shouldSaveImageAfterSuccessfulExecution.
	self focusedClassEditToolClasses do: [ :toolClass |
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
MCPToolContractsTest >> testOptionalToolArgumentsAdvertiseDefaultsWhenAvailable [

	| classSlotTool classUpdateTool findClassesTool findMethodsTool findPackagesTool inspectClassTool inspectMethodTool removeClassesTool removeMethodsTool rewriteMethodsTool updateMethodTool |
	classUpdateTool := MCPToolUpdateClassName new.
	classSlotTool := MCPToolAddClassSlot new.
	inspectClassTool := MCPToolInspectClass new.
	inspectMethodTool := MCPToolInspectMethod new.
	updateMethodTool := MCPToolUpdateMethodSelector new.
	rewriteMethodsTool := MCPToolRewriteMethods new.
	findClassesTool := MCPToolFindClasses new.
	findMethodsTool := MCPToolFindMethods new.
	findPackagesTool := MCPToolFindPackages new.
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
			((self
				  inputPropertyNamed: 'includeComment'
				  inTool: inspectClassTool) extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'subclassDepth' inTool: inspectClassTool)
				 extraProperties at: #default)
		equals: 0.
	self
		assert:
			((self inputPropertyNamed: 'classSide' inTool: inspectMethodTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert: ((self
				  inputPropertyNamed: 'includeVariableDetails'
				  inTool: inspectMethodTool) extraProperties at: #default)
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
			((self inputPropertyNamed: 'filterMode' inTool: findClassesTool)
				 extraProperties at: #default)
		equals: 'substring'.
	self
		assert:
			((self inputPropertyNamed: 'caseSensitive' inTool: findClassesTool)
				 extraProperties at: #default)
		equals: true.
	self
		assert: ((self inputPropertyNamed: 'limit' inTool: findClassesTool)
				 extraProperties at: #default)
		equals: 100.
	self
		assert:
			((self inputPropertyNamed: 'filterMode' inTool: findMethodsTool)
				 extraProperties at: #default)
		equals: 'exact'.
	self
		assert:
			((self inputPropertyNamed: 'caseSensitive' inTool: findMethodsTool)
				 extraProperties at: #default)
		equals: true.
	self
		assert:
			((self inputPropertyNamed: 'includeSource' inTool: findMethodsTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'filterMode' inTool: findPackagesTool)
				 extraProperties at: #default)
		equals: 'substring'.
	self
		assert:
			((self inputPropertyNamed: 'caseSensitive' inTool: findPackagesTool)
				 extraProperties at: #default)
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

{ #category : 'tests - tools - parsing' }
MCPToolContractsTest >> testParserHelperBypassesSchemaValidation [

	| arguments tool |
	tool := MCPToolEditRepository new.
	arguments := { (#operation -> 'notAnOperation') } asDictionary.
	self
		should: [ tool requestFromToolCallArguments: arguments ]
		raise: MCPInvalidToolInput.
	self
		should: [ self parsedRequestForTool: tool arguments: arguments ]
		raise: Error
		whoseDescriptionIncludes: tool operationValidationErrorMessage
		description:
		'Parser helper should bypass transport schema validation.'
]

{ #category : 'tests' }
MCPToolContractsTest >> testQueryScopeDescriptionsExplainScopeSemantics [

	| classDescription findMethodsDescription methodDescription packageDescription parentDescription subclassDescription |
	findMethodsDescription := MCPToolFindMethods new description.
	classDescription := (self
		                     inputPropertyNamed: 'hierarchyClassNames'
		                     inTool: MCPToolFindClasses new) description.
	subclassDescription := (self
		                        inputPropertyNamed: 'subclassClassNames'
		                        inTool: MCPToolFindMethods new) description.
	parentDescription := (self
		                      inputPropertyNamed: 'parentClassNames'
		                      inTool: MCPToolFindClasses new) description.
	methodDescription := (self
		                      inputPropertyNamed: 'packageNames'
		                      inTool: MCPToolFindMethods new) description.
	packageDescription := (self
		                       inputPropertyNamed: 'projectNames'
		                       inTool: MCPToolFindPackages new) description.
	self assert: (findMethodsDescription includesSubstring:
			 'Missing class or package names').
	self assert:
		(classDescription includesSubstring:
			 'Omit all class scope properties').
	self assert: (classDescription includesSubstring:
			 'its superclasses, and its subclasses').
	self assert: (subclassDescription includesSubstring:
			 'methods defined on subclasses').
	self assert: (subclassDescription includesSubstring:
			 'The named classes are excluded').
	self assert:
		(parentDescription includesSubstring:
			 'superclasses of these classes').
	self assert:
		(parentDescription includesSubstring:
			 'The named classes are excluded').
	self assert:
		(methodDescription includesSubstring: 'including extension methods').
	self assert: (methodDescription includesSubstring:
			 'Omit all method scope properties').
	self assert: (packageDescription includesSubstring:
			 'project names whose packages are included').
	self assert:
		(packageDescription includesSubstring: 'Combine with packageNames')
]

{ #category : 'tests' }
MCPToolContractsTest >> testQueryToolSchemasAdvertiseFlatFieldProperties [

	| classProperties classSchema methodProperties methodSchema packageProperties packageSchema |
	classSchema := MCPToolFindClasses new inputSchema asJRPCJSON.
	methodSchema := MCPToolFindMethods new inputSchema asJRPCJSON.
	packageSchema := MCPToolFindPackages new inputSchema asJRPCJSON.
	classProperties := (classSchema at: #properties) keys asSet.
	methodProperties := (methodSchema at: #properties) keys asSet.
	packageProperties := (packageSchema at: #properties) keys asSet.
	self assert: (classSchema at: #type) equals: 'object'.
	self assert: (methodSchema at: #type) equals: 'object'.
	self assert: (packageSchema at: #type) equals: 'object'.
	self
		assert: classProperties
		equals: #( 'packageNames' 'classNames' 'hierarchyClassNames'
			   'subclassClassNames' 'parentClassNames' 'className' 'tag' 'instanceSlot'
			   'classSlot' 'filterMode' 'caseSensitive' 'limit' 'offset' )
				asSet.
	self
		assert: methodProperties
		equals: #( 'packageNames' 'classNames' 'hierarchyClassNames'
			   'subclassClassNames' 'parentClassNames' 'selector' 'protocol'
			   'filterMode' 'side' 'includeSource' 'limit' 'offset' 'caseSensitive' )
				asSet.
	self
		assert: packageProperties
		equals:
			#( 'projectNames' 'packageNames' 'packageName' 'projectName'
			   'tag' 'filterMode' 'caseSensitive' 'limit' 'offset' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testQueryToolsUseTypedRequestObjects [

	| classRequest methodRequest packageRequest repositoryRequest staleSelectors |
	repositoryRequest := MCPToolFindRepositories new
		                     queryRequestFromToolRequest: (MCPToolRequest
				                      tool: MCPToolFindRepositories new
				                      arguments: Dictionary new).
	classRequest := MCPToolFindClasses new queryRequestFromToolRequest:
		                (MCPToolRequest
			                 tool: MCPToolFindClasses new
			                 arguments: Dictionary new).
	methodRequest := MCPToolFindMethods new queryRequestFromToolRequest:
		                 (MCPToolRequest
			                  tool: MCPToolFindMethods new
			                  arguments: Dictionary new).
	packageRequest := MCPToolFindPackages new
		                  queryRequestFromToolRequest: (MCPToolRequest
				                   tool: MCPToolFindPackages new
				                   arguments: Dictionary new).
	self
		assert: repositoryRequest class
		equals: MCPRepositoryQuerySpec.
	self assert: classRequest class equals: MCPFindClassesRequest.
	self assert: methodRequest class equals: MCPFindMethodsRequest.
	self assert: packageRequest class equals: MCPFindPackagesRequest.
	staleSelectors := #( queryParametersFromRequest:
	                     queryEntriesForParameters:
	                     successSummaryForParameters:page:
	                     queryResultDataForParameters:page:
	                     querySpecFromRequest: queryEntriesForQuerySpec:
	                     successSummaryForQuerySpec:page:
	                     queryResultDataForQuerySpec:page: ).
	staleSelectors do: [ :selector |
		self deny: (MCPToolQuery withAllSubclasses anySatisfy: [ :each |
				 each includesSelector: selector ]) ]
]

{ #category : 'tests' }
MCPToolContractsTest >> testRPCAdvertisesStaticToolSurfaceOnly [

	| toolNames |
	toolNames := (MCP new rpcToolsList at: #tools) collect: [ :each |
		             each at: #name ].
	self
		assert: toolNames asSet
		equals: MCPToolRegistry staticToolNames asSet.
	#( 'tool_search' 'tool_get' 'tool_call' 'class_search' 'class_get'
	   'class_create' 'class_name_update' 'class_superclass_update'
	   'class_package_update' 'class_comment_update'
	   'class_slots_update' 'class_traits_update' 'class_side_traits_update'
	   'class_shared_variables_update' 'class_shared_pools_update'
	   'class_layout_update' 'class_slot_add' 'class_slot_remove'
	   'class_slot_name_update' 'class_slot_pull_up' 'class_slot_push_down'
	   'method_create' 'method_selector_update' 'method_protocol_update'
	   'image_evaluate' 'test_run' 'test_coverage_run' ) do: [ :each |
		self assert: (toolNames includes: each) ].
	#( 'class_edit' 'method_edit' 'repository_search' 'repository_identity_verify'
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
	staleTool := MCPToolFindClasses new.
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
		equals: #( 'packageNames' 'classNames' 'hierarchyClassNames'
			   'subclassClassNames' 'parentClassNames' 'className' 'tag' 'instanceSlot'
			   'classSlot' 'filterMode' 'caseSensitive' 'limit' 'offset' )
				asSet.
	result := mcp rpcToolCall: 'class_search' withParams: {
			          (#classNames -> #( 'MCPToolContractsTest' )).
			          (#packageNames -> #( 'MCP-Tests' )).
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
MCPToolContractsTest >> testRequestedToolIconsAreAdvertised [

	self
		assert: (MCPToolInspectClass new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #class
				 badgeIconNamed: #inspect) asJRPCJSON.
	self
		assert: (MCPToolInspectMethod new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #page
				 badgeIconNamed: #inspect) asJRPCJSON.
	self
		assert: (MCPToolEditRepository new asJRPCJSON at: #icons) first
		equals:
			(MCPStructureIcon
				 compositeBaseIconNamed: #box
				 badgeIconNamed: #edit) asJRPCJSON.
	self
		assert: (MCPToolLoadRepository new asJRPCJSON at: #icons) first
		equals:
			(MCPStructureIcon compositeBaseIconNamed: #box badgeIconNamed: #add)
				asJRPCJSON.
	self focusedClassEditToolClasses do: [ :toolClass |
			self
				assert: (toolClass new asJRPCJSON at: #icons) first
				equals:
					(MCPStructureIcon
						 compositeBaseIconNamed: #class
						 badgeIconNamed: #edit) asJRPCJSON ].
	{
		MCPToolCreateMethod.
		MCPToolUpdateMethodSelector.
		MCPToolUpdateMethodProtocol } do: [ :toolClass |
			self
				assert: (toolClass new asJRPCJSON at: #icons) first
				equals:
					(MCPStructureIcon
						 compositeBaseIconNamed: #page
						 badgeIconNamed: #edit) asJRPCJSON ].
	self
		assert: (MCPToolRewriteMethods new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #page
				 badgeIconNamed: #refreshCircling) asJRPCJSON.
	self
		assert: (MCPToolFindClasses new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #class
				 badgeIconNamed: #search) asJRPCJSON.
	self
		assert: (MCPToolFindMethods new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #page
				 badgeIconNamed: #search) asJRPCJSON.
	self
		assert: (MCPToolFindPackages new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #open
				 badgeIconNamed: #search) asJRPCJSON.
	self
		assert: (MCPToolFindRepositories new asJRPCJSON at: #icons) first
		equals:
			(MCPStructureIcon
				 compositeBaseIconNamed: #box
				 badgeIconNamed: #search) asJRPCJSON.
	self
		assert: (MCPToolRemoveClasses new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #class
				 badgeIconNamed: #delete) asJRPCJSON.
	self
		assert: (MCPToolRemoveMethods new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon
				 compositeBaseIconNamed: #page
				 badgeIconNamed: #delete) asJRPCJSON.
	self
		assert: (MCPToolRunTests new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon pngIconNamed: #testRunner) asJRPCJSON.
	self
		assert: (MCPToolCaptureScreenshot new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon pngIconNamed: #smallScreenshot) asJRPCJSON.
	self
		assert: (MCPToolEvaluate new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon pngIconNamed: #go) asJRPCJSON
]

{ #category : 'tests' }
MCPToolContractsTest >> testRewriteMethodsIsMethodScopedCommandTool [

	self assert: MCPToolRewriteMethods superclass equals: MCPTool.
	self assert: (MCPToolRewriteMethods traits includes: TMCPMethodTool)
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallCatchesUnhandledHaltFromTool [

	| mcp result text tool tools |
	tool := MCPTool basicNew
		        name: 'halting-test-tool';
		        handler: [ :request |
			        (Smalltalk globals at: #Halt) signal: 'mcp tool halt test' ];
		        yourself.
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
	self deny: (toolNames includes: 'class_edit')
]

{ #category : 'tests' }
MCPToolContractsTest >> testServerInitializationDoesNotRenderToolIcons [

	MCPStructureIcon resetCaches.
	MCP new.
	self assert: MCPStructureIcon cachedRenderedIconCount equals: 0
]

{ #category : 'tests' }
MCPToolContractsTest >> testStaticToolConfigurationRejectsUnknownToolNames [

	self
		should: [
		MCP new staticToolNames: #( 'tool_search' 'not-a-tool' ) ]
		raise: Error
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
MCPToolContractsTest >> testToolIconsAreSharedByToolClass [

	| firstIcons secondIcons |
	MCPStructureIcon resetCaches.
	firstIcons := MCPToolFindClasses new icons.
	secondIcons := MCPToolFindClasses new icons.
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
	self assert: MCPToolFindClasses toolName equals: 'class_search'.
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
		assert: MCPToolFindRepositoryChanges toolName
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
		assert: MCPToolFindChangeHistoryFiles toolName
		equals: 'history_file_list'.
	self
		assert: MCPToolFindChangeHistoryEntries toolName
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
	self assert: MCPToolDebugEdit toolName equals: 'debug_method_repair'
]

{ #category : 'private' }
MCPToolContractsTest >> toolFlowSpecs [

	| oldToolClasses specs |
	specs := OrderedCollection withAll: self baseToolFlowSpecs.
	oldToolClasses := {
		                  MCPToolEditRepository.
		                  MCPToolEditClass.
		                  MCPToolEditMethod.
		                  MCPToolManageChangeHistory.
		                  MCPToolDebugSessions.
		                  MCPToolDebugControl.
		                  MCPToolDebugBreakpoints }.
	specs removeAllSuchThat: [ :each |
		oldToolClasses includes: (each at: #toolClass) ].
	specs add: self baselineLoadToolFlowSpec.
	specs add: self coverageToolFlowSpec.
	specs addAll: self focusedClassEditToolFlowSpecs.
	specs addAll: self focusedMethodLookupToolFlowSpecs.
	specs addAll: self focusedMethodEditToolFlowSpecs.
	specs addAll: self focusedChangeHistoryToolFlowSpecs.
	specs addAll: self focusedRepositoryToolFlowSpecs.
	specs addAll: self focusedDebugSessionToolFlowSpecs.
	specs addAll: self focusedDebugControlToolFlowSpecs.
	specs addAll: self focusedDebugBreakpointToolFlowSpecs.
	specs add: self debugTestToolFlowSpec.
	^ specs asArray
]
