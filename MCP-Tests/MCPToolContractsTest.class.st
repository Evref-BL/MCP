Class {
	#name : 'MCPToolContractsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

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
			MCPToolFindPackages.
			MCPToolFindClasses.
			MCPToolInspectClass.
			MCPToolEditClass.
			MCPToolRemoveClasses.
			MCPToolFindMethods.
			MCPToolInspectMethod.
			MCPToolEditMethod.
			MCPToolRemoveMethods.
			MCPToolRunTests.
			MCPToolEvaluate }
]

{ #category : 'tests' }
MCPToolContractsTest >> testClassToolTraitOwnsSharedClassHelpers [

	| classToolClasses sharedSelectors |
	classToolClasses := {
		                    MCPToolFindClasses.
		                    MCPToolInspectClass.
		                    MCPToolEditClass.
		                    MCPToolRemoveClasses }.
	sharedSelectors := #( resolvedClassNamed: sortedClassesByName: ).
	classToolClasses do: [ :toolClass |
		self assert: (toolClass traits includes: TMCPClassTool).
		sharedSelectors do: [ :selector |
			self assert: (toolClass >> selector) origin equals: TMCPClassTool ] ]
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
		                        (MCPRemoveMethodsCommand
		                         -> MCPRemoveMethodsResult) }.
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
MCPToolContractsTest >> testEditClassDescriptionMentionsRecategorizationViaMove [

	| description |
	description := MCPToolEditClass new description.
	self assert: (description includesSubstring: 'recategorize').
	self assert: (description includesSubstring: 'operation=update').
	self assert: (description includesSubstring: 'tag').
	self assert: (description includesSubstring: 'Omit packageName').
	self assert: (description includesSubstring: 'current package')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditClassHasAccurateNameAndRequiredArguments [

	| operationProperty propertyNames slotActionProperty tool |
	tool := MCPToolEditClass new.
	propertyNames := tool inputSchema properties collect: [ :each |
		                 each name ].
	operationProperty := tool inputSchema properties detect: [ :each |
		                     each name = 'operation' ].
	slotActionProperty := tool inputSchema properties detect: [ :each |
		                      each name = 'slotAction' ].
	self assert: tool name equals: 'edit-class'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet.
	self assert: (propertyNames includes: 'classComment').
	self assert: (propertyNames includes: 'traits').
	self assert: (propertyNames includes: 'classTraits').
	self assert: (propertyNames includes: 'sharedVariables').
	self assert: (propertyNames includes: 'sharedPools').
	self assert: (propertyNames includes: 'layout').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'hierarchyClassNames').
	self assert: (propertyNames includes: 'slotAction').
	self assert: (propertyNames includes: 'slotName').
	self assert: (propertyNames includes: 'newSlotName').
	self assert: (propertyNames includes: 'classSide').
	self assert: (propertyNames includes: 'force').
	self
		assert: (operationProperty extraProperties at: #enum) asArray
		equals: #( 'create' 'update' ).
	self
		assert: (slotActionProperty extraProperties at: #enum) asArray
		equals: #( 'add' 'remove' 'rename' 'pullUp' 'pushDown' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditClassOutputSchemaAdvertisesUpdateResultDTOs [

	| dataProperties outputSchema updatePlanProperties |
	outputSchema := MCPToolEditClass new outputSchema asJRPCJSON.
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
MCPToolContractsTest >> testEditClassSchemaDescriptionsExplainRecategorizationForceAndPatchSemantics [

	| classCommentDescription classSlotsDescription classTraitsDescription forceDescription layoutDescription operationDescription packageDescription sharedPoolsDescription sharedVariablesDescription slotsDescription tagDescription tool traitsDescription |
	tool := MCPToolEditClass new.
	operationDescription := (self
		                         inputPropertyNamed: 'operation'
		                         inTool: tool) description.
	packageDescription := (self
		                       inputPropertyNamed: 'packageName'
		                       inTool: tool) description.
	tagDescription := (self inputPropertyNamed: 'tag' inTool: tool)
		                  description.
	forceDescription := (self inputPropertyNamed: 'force' inTool: tool)
		                    description.
	classCommentDescription := (self
		                            inputPropertyNamed: 'classComment'
		                            inTool: tool) description.
	slotsDescription := (self inputPropertyNamed: 'slots' inTool: tool)
		                    description.
	classSlotsDescription := (self
		                          inputPropertyNamed: 'classSlots'
		                          inTool: tool) description.
	traitsDescription := (self inputPropertyNamed: 'traits' inTool: tool)
		                     description.
	classTraitsDescription := (self
		                           inputPropertyNamed: 'classTraits'
		                           inTool: tool) description.
	sharedVariablesDescription := (self
		                               inputPropertyNamed: 'sharedVariables'
		                               inTool: tool) description.
	sharedPoolsDescription := (self
		                           inputPropertyNamed: 'sharedPools'
		                           inTool: tool) description.
	layoutDescription := (self inputPropertyNamed: 'layout' inTool: tool)
		                     description.
	self assert: (operationDescription includesSubstring: 'patch style').
	self assert: (operationDescription includesSubstring: 'exactly one').
	self assert: (operationDescription includesSubstring: 'traits').
	self assert: (operationDescription includesSubstring: 'classTraits').
	self assert:
		(operationDescription includesSubstring: 'sharedVariables').
	self assert: (operationDescription includesSubstring: 'sharedPools').
	self assert: (operationDescription includesSubstring: 'layout').
	self assert: (packageDescription includesSubstring: 'recategorize').
	self assert:
		(packageDescription includesSubstring: 'Omit packageName').
	self assert:
		(packageDescription includesSubstring: 'current package').
	self assert:
		(tagDescription includesSubstring: 'recategorization patch').
	self assert: (forceDescription includesSubstring: 'force=false').
	self assert: (forceDescription includesSubstring: 'force=true').
	self assert: (forceDescription includesSubstring: 'impactMessages').
	self assert: (forceDescription includesSubstring: 'warnings').
	self assert:
		(classCommentDescription includesSubstring: 'set-comment patch').
	self assert:
		(classCommentDescription includesSubstring: 'do not combine').
	self assert: (slotsDescription includesSubstring:
			 'replaces the full instance-side slot list').
	self assert:
		(slotsDescription includesSubstring:
			 'May be combined with classSlots').
	self assert: (classSlotsDescription includesSubstring:
			 'replaces the full class-side slot list').
	self assert:
		(classSlotsDescription includesSubstring:
			 'May be combined with slots').
	self assert: (traitsDescription includesSubstring:
			 'replaces the full instance-side trait list').
	self assert: (traitsDescription includesSubstring: 'empty array').
	self assert: (classTraitsDescription includesSubstring:
			 'replaces the full class-side trait list').
	self assert:
		(classTraitsDescription includesSubstring: 'empty array').
	self assert: (sharedVariablesDescription includesSubstring:
			 'replaces the full class variable list').
	self assert:
		(sharedVariablesDescription includesSubstring: 'empty array').
	self assert: (sharedPoolsDescription includesSubstring:
			 'replaces the full shared pool list').
	self assert:
		(sharedPoolsDescription includesSubstring: 'empty array').
	self assert: (sharedPoolsDescription includesSubstring: 'SharedPool').
	self assert:
		(layoutDescription includesSubstring: 'replaces the layout class').
	self assert: (layoutDescription includesSubstring: 'AbstractLayout')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditDescriptionsExplainForceWarningBehavior [

	| classDescription forceDescription methodDescription |
	classDescription := MCPToolEditClass new description.
	methodDescription := MCPToolEditMethod new description.
	forceDescription := (self
		                     inputPropertyNamed: 'force'
		                     inTool: MCPToolEditClass new) description.
	self assert: (classDescription includesSubstring: 'force=false').
	self assert: (classDescription includesSubstring: 'force=true').
	self assert: (methodDescription includesSubstring: 'force=false').
	self assert: (methodDescription includesSubstring: 'force=true').
	self assert: (forceDescription includesSubstring: 'impactMessages').
	self assert: (forceDescription includesSubstring: 'howToProceed').
	self assert:
		(forceDescription includesSubstring: 'forceSupported=true').
	self assert: (forceDescription includesSubstring: 'warnings')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditMethodHasAccurateNameAndRequiredArguments [

	| propertyNames tool |
	tool := MCPToolEditMethod new.
	propertyNames := tool inputSchema properties collect: [ :each |
		                 each name ].
	self assert: tool name equals: 'edit-method'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet.
	self assert: (propertyNames includes: 'force').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'hierarchyClassNames').
	self deny: (propertyNames includes: 'projectNames')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditMethodSchemaAdvertisesMethodState [

	| argumentNamesProperty argumentValuesProperty dataProperties dataProperty operationProperty permutationProperty propertyNames tool |
	tool := MCPToolEditMethod new.
	operationProperty := tool inputSchema properties detect: [ :each |
		                     each name = 'operation' ].
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
	self
		assert: (operationProperty extraProperties at: #enum) asArray
		equals: #( 'create' 'update' ).
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
MCPToolContractsTest >> testEditToolSchemasAdvertiseOperationBranches [

	| classCreateBranch editClassBranches editMethodBranches methodCreateBranch updateBranch |
	editClassBranches := MCPToolEditClass new inputSchema asJRPCJSON at:
		                     #oneOf.
	editMethodBranches := MCPToolEditMethod new inputSchema asJRPCJSON
		                      at: #oneOf.
	self
		assert: (editClassBranches collect: [ :each |
				 ((each at: #properties) at: 'operation') at: #const ]) asArray
		equals: #( 'create' 'update' ).
	classCreateBranch := editClassBranches detect: [ :each |
		                     (((each at: #properties) at: 'operation') at:
			                      #const) = 'create' ].
	self
		assert: (classCreateBranch at: #required) asSet
		equals:
		#( 'operation' 'className' 'superclassName' 'packageName' ) asSet.
	updateBranch := editClassBranches detect: [ :each |
		                (((each at: #properties) at: 'operation') at: #const)
		                = 'update' ].
	self
		assert: (updateBranch at: #required) asSet
		equals: #( 'operation' 'className' ) asSet.
	self
		assert: (editMethodBranches collect: [ :each |
				 ((each at: #properties) at: 'operation') at: #const ]) asArray
		equals: #( 'create' 'update' ).
	methodCreateBranch := editMethodBranches detect: [ :each |
		                      (((each at: #properties) at: 'operation') at:
			                       #const) = 'create' ].
	self
		assert: (methodCreateBranch at: #required) asSet
		equals: #( 'operation' 'className' 'methodSource' 'protocol' ) asSet.
	updateBranch := editMethodBranches detect: [ :each |
		                (((each at: #properties) at: 'operation') at: #const)
		                = 'update' ].
	self
		assert: (updateBranch at: #required) asSet
		equals: #( 'operation' 'className' 'selector' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditToolSchemasAdvertiseRenameScopeConditions [

	| editClassInputSchema editClassPropertyNames editMethodInputSchema editMethodPropertyNames |
	editClassInputSchema := MCPToolEditClass new inputSchema.
	editMethodInputSchema := MCPToolEditMethod new inputSchema.
	editClassPropertyNames := editClassInputSchema properties collect: [
		                          :each | each name ].
	editMethodPropertyNames := editMethodInputSchema properties collect: [
		                           :each | each name ].
	{
		editClassPropertyNames.
		editMethodPropertyNames } do: [ :propertyNames |
		self deny: (propertyNames includes: 'scope').
		self assert: (propertyNames includes: 'packageNames').
		self assert: (propertyNames includes: 'classNames').
		self assert: (propertyNames includes: 'hierarchyClassNames') ].
	self
		assert: (editClassInputSchema asJRPCJSON at: #additionalProperties)
		equals: false.
	self
		assert: (editMethodInputSchema asJRPCJSON at: #additionalProperties)
		equals: false
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
		equals: 'evaluate'.
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

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateReturnsCompilationFailureInformation [

	| result text |
	result := self
		          callToolNamed: 'evaluate'
		          withArguments: { (#code -> '1 +') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during compilation').
	self assert: (text includesSubstring: 'RBSyntaxErrorNotice').
	self assert: (text includesSubstring: 'Position: 4')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvaluateReturnsRuntimeFailureInformation [

	| result text |
	result := self
		          callToolNamed: 'evaluate'
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
	self assert: MCPToolFindClasses new name equals: 'find-classes'.
	self assert: schema required equals: #(  ).
	self deny: (propertyNames includes: 'packageName').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'hierarchyClassNames').
	self assert: (propertyNames includes: 'subclassClassNames').
	self assert: (propertyNames includes: 'parentClassNames').
	self assert: (propertyNames includes: 'filter').
	self assert: (propertyNames includes: 'filterTargets')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindClassesListsClassesForExistingPackage [

	| classNames data result |
	result := self
		          callToolNamed: 'find-classes'
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
MCPToolContractsTest >> testFindClassesReturnsErrorResultForMissingPackage [

	| result text |
	result := self
		          callToolNamed: 'find-classes'
		          withArguments:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Package MCP-Definitely-Missing does not exist.').
	self deny: (text includesSubstring: 'Tool find-classes failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsDescriptionMentionsReferenceLookupModes [

	| description filterDescription filterModeDescription tool |
	tool := MCPToolFindMethods new.
	description := tool description.
	self assert:
		(description includesSubstring: 'filterMode=selectorReference').
	self assert: (description includesSubstring: 'senders').
	self assert:
		(description includesSubstring: 'filterMode=classReference').
	self assert:
		(description includesSubstring: 'filterMode=variableReference').
	self assert: (description includesSubstring: 'implementors').
	filterDescription := (self inputPropertyNamed: 'filter' inTool: tool)
		                     description.
	filterModeDescription := (self
		                          inputPropertyNamed: 'filterMode'
		                          inTool: tool) description.
	self assert:
		(filterDescription includesSubstring: 'referenced selector').
	self assert: (filterModeDescription includesSubstring:
			 'selectorReference for senders')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsHasAccurateNameAndSchema [

	| filterModeProperty filterTargetsProperty propertyNames schema |
	schema := MCPToolFindMethods new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	filterTargetsProperty := schema properties detect: [ :each |
		                         each name = 'filterTargets' ].
	filterModeProperty := schema properties detect: [ :each |
		                      each name = 'filterMode' ].
	self assert: MCPToolFindMethods new name equals: 'find-methods'.
	self assert: schema required equals: #(  ).
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'hierarchyClassNames').
	self assert: (propertyNames includes: 'subclassClassNames').
	self assert: (propertyNames includes: 'parentClassNames').
	self assert: (propertyNames includes: 'filter').
	self assert: (propertyNames includes: 'filterTargets').
	self
		assert:
			((filterTargetsProperty extraProperties at: #items) extraProperties
				 at: #enum) asArray
		equals: #( 'selector' 'class' 'package' 'protocol' 'source' ).
	self
		assert: (filterModeProperty extraProperties at: #enum) asArray
		equals: #( 'substring' 'prefix' 'exact' 'regex' 'selectorReference'
			   'classReference' 'variableReference' ).
	self deny: (propertyNames includes: 'className')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsListsMethodsForExistingClassScope [

	| data result selectors |
	result := self
		          callToolNamed: 'find-methods'
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
MCPToolContractsTest >> testFindMethodsReferenceModesShareRequiredFilterCondition [

	| condition filterModeProperty schema |
	schema := MCPToolFindMethods new inputSchema asJRPCJSON.
	self assert: (schema at: #allOf) size equals: 1.
	condition := (schema at: #allOf) first.
	filterModeProperty := ((condition at: #if) at: #properties) at:
		                      'filterMode'.
	self
		assert: (filterModeProperty at: #enum) asArray
		equals:
		#( 'selectorReference' 'classReference' 'variableReference' ).
	self
		assert: ((condition at: #if) at: #required) asArray
		equals: #( 'filterMode' ).
	self
		assert: ((condition at: #then) at: #required) asArray
		equals: #( 'filter' )
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsReturnsErrorResultForMissingClass [

	| result text |
	result := self
		          callToolNamed: 'find-methods'
		          withArguments:
			          { (#classNames
			           -> #( 'MCPDefinitelyMissingFindMethodsClass' )) }
				          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Class MCPDefinitelyMissingFindMethodsClass does not exist.').
	self deny: (text includesSubstring: 'Tool find-methods failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsWhereSchemaAdvertisesEquivalentToMethodReference [

	| classSideProperty equivalentToProperties equivalentToProperty nestedPropertyNames whereProperties whereProperty |
	whereProperty := MCPToolFindMethods new inputSchema properties
		                 detect: [ :each | each name = 'where' ].
	whereProperties := whereProperty extraProperties at: #properties.
	equivalentToProperty := whereProperties detect: [ :each |
		                        each name = 'equivalentTo' ].
	equivalentToProperties := equivalentToProperty extraProperties at:
		                          #properties.
	nestedPropertyNames := equivalentToProperties collect: [ :each |
		                       each name ].
	classSideProperty := equivalentToProperties detect: [ :each |
		                     each name = 'classSide' ].
	self assert: equivalentToProperty type equals: 'object'.
	self assert:
		(equivalentToProperty description includesSubstring:
			 'equivalent AST').
	self
		assert: (equivalentToProperty extraProperties at: #required) asArray
		equals: #( 'className' 'selector' ).
	self assert: (nestedPropertyNames includes: 'className').
	self assert: (nestedPropertyNames includes: 'selector').
	self assert: (nestedPropertyNames includes: 'classSide').
	self
		assert: (classSideProperty extraProperties at: #default)
		equals: false
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolFindPackages new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolFindPackages new name equals: 'find-packages'.
	self assert: schema required equals: #(  ).
	self assert: (propertyNames includes: 'projectNames').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'filter').
	self assert: (propertyNames includes: 'filterTargets').
	self assert: (propertyNames includes: 'filterMode')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesListsPackagesForExistingProject [

	| packageNames data result |
	result := self
		          callToolNamed: 'find-packages'
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
		          callToolNamed: 'find-packages'
		          withArguments:
		          { (#projectNames -> #( 'DefinitelyMissingProject' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Project DefinitelyMissingProject does not exist.').
	self deny: (text includesSubstring: 'Tool find-packages failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testHandleJSONReturnsInvalidParamsForMissingRequiredArguments [

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"evaluate","arguments":{}}}'.
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
MCPToolContractsTest >> testInputSchemaJSONOmitsDefaultSchemaNoise [

	| condition schema |
	schema := MCPToolFindMethods new inputSchema asJRPCJSON.
	self deny: (schema includesKey: #required).
	self deny: (schema includesKey: #oneOf).
	self assert: (schema at: #additionalProperties) equals: false.
	condition := (schema at: #allOf) first.
	self deny: (condition includesKey: #additionalProperties).
	self deny: ((condition at: #if) includesKey: #additionalProperties).
	self deny: ((condition at: #then) includesKey: #additionalProperties)
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
	self assert: tool name equals: 'inspect-class'.
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
	self assert: MCPToolInspectMethod new name equals: 'inspect-method'.
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
MCPToolContractsTest >> testMethodToolTraitOwnsSharedMethodHelpers [

	| methodToolClasses sharedSelectors |
	methodToolClasses := {
		                     MCPToolFindMethods.
		                     MCPToolInspectMethod.
		                     MCPToolEditMethod.
		                     MCPToolRemoveMethods }.
	sharedSelectors := #( selectorStringFromRequest:
	                      behaviorNamed:classSide:
	                      methodReferenceForBehavior:selector:
	                      methodReferenceForClassName:selector:isClassSide: ).
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
		MCPToolEditClass new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolEditMethod new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolRemoveClasses new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolRemoveMethods new shouldSaveImageAfterSuccessfulExecution.
	self assert:
		MCPToolEvaluate new shouldSaveImageAfterSuccessfulExecution
]

{ #category : 'tests' }
MCPToolContractsTest >> testOptionalToolArgumentsAdvertiseDefaultsWhenAvailable [

	| editClassTool inspectClassTool inspectMethodTool editMethodTool findClassesTool findMethodsTool findPackagesTool removeClassesTool removeMethodsTool |
	editClassTool := MCPToolEditClass new.
	inspectClassTool := MCPToolInspectClass new.
	inspectMethodTool := MCPToolInspectMethod new.
	editMethodTool := MCPToolEditMethod new.
	findClassesTool := MCPToolFindClasses new.
	findMethodsTool := MCPToolFindMethods new.
	findPackagesTool := MCPToolFindPackages new.
	removeClassesTool := MCPToolRemoveClasses new.
	removeMethodsTool := MCPToolRemoveMethods new.
	self
		assert: ((self inputPropertyNamed: 'force' inTool: editClassTool)
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
			((self inputPropertyNamed: 'classSide' inTool: editMethodTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert: ((self inputPropertyNamed: 'force' inTool: editMethodTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'filterTargets' inTool: findClassesTool)
				 extraProperties at: #default)
		equals: #( 'class' ).
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
			((self inputPropertyNamed: 'filterTargets' inTool: findMethodsTool)
				 extraProperties at: #default)
		equals: #( 'selector' ).
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

{ #category : 'tests' }
MCPToolContractsTest >> testQueryScopeDescriptionsExplainScopeSemantics [

	| classDescription methodDescription packageDescription parentDescription subclassDescription |
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
	self assert:
		(classDescription includesSubstring:
			 'Omit all class scope properties').
	self assert: (classDescription includesSubstring:
			 'superclasses, subclasses, and the named classes').
	self assert:
		(subclassDescription includesSubstring: 'subclass methods').
	self assert: (subclassDescription includesSubstring:
			 'The named classes are excluded').
	self assert:
		(parentDescription includesSubstring: 'superclasses are included').
	self assert:
		(parentDescription includesSubstring:
			 'The named classes are excluded').
	self assert:
		(methodDescription includesSubstring: 'extension methods').
	self assert: (methodDescription includesSubstring:
			 'Omit all method scope properties').
	self assert: (packageDescription includesSubstring:
			 'project names whose packages are included').
	self assert:
		(packageDescription includesSubstring: 'Combine with packageNames')
]

{ #category : 'tests' }
MCPToolContractsTest >> testQueryToolSchemasDoNotAdvertiseLegacyScopeBranches [

	| classSchema methodSchema packageSchema |
	classSchema := MCPToolFindClasses new inputSchema asJRPCJSON.
	methodSchema := MCPToolFindMethods new inputSchema asJRPCJSON.
	packageSchema := MCPToolFindPackages new inputSchema asJRPCJSON.
	self deny: (classSchema includesKey: #oneOf).
	self deny: (methodSchema includesKey: #oneOf).
	self deny: (packageSchema includesKey: #oneOf).
	self deny: ((classSchema at: #properties) includesKey: 'scope').
	self deny: ((methodSchema at: #properties) includesKey: 'scope').
	self deny: ((packageSchema at: #properties) includesKey: 'scope')
]

{ #category : 'tests' }
MCPToolContractsTest >> testQueryToolsUseTypedRequestObjects [

	| classRequest methodRequest packageRequest staleSelectors |
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
MCPToolContractsTest >> testRemoveClassHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRemoveClasses new name equals: 'remove-classes'.
	self
		assert: MCPToolRemoveClasses new inputSchema required asSet
		equals: #( 'classNames' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveMethodsHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRemoveMethods new name equals: 'remove-methods'.
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
		assert: (MCPToolEditClass new asJRPCJSON at: #icons) first
		equals:
			(MCPStructureIcon
				 compositeBaseIconNamed: #class
				 badgeIconNamed: #edit) asJRPCJSON.
	self
		assert: (MCPToolEditMethod new asJRPCJSON at: #icons) first
		equals:
			(MCPStructureIcon
				 compositeBaseIconNamed: #page
				 badgeIconNamed: #edit) asJRPCJSON.
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
		assert: (MCPToolEvaluate new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon pngIconNamed: #go) asJRPCJSON
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallRejectsLegacyScopeArgument [

	self
		should: [
			self
				callToolNamed: 'find-classes'
				withArguments: { (#scope -> 'packages') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersForInvalidNestedArrayItem [

	self
		should: [
			self
				callToolNamed: 'run-tests'
				withArguments:
				{ (#tests -> #( 'MCPToolContractsTest' )) } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersForUnexpectedArgument [

	self
		should: [
			self callToolNamed: 'evaluate' withArguments: {
					(#code -> '1 + 1').
					(#unexpected -> true) } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersForWrongArgumentType [

	self
		should: [
			self
				callToolNamed: 'find-classes'
				withArguments: { (#caseSensitive -> 'true') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersWhenRequiredArgumentIsMissing [

	self
		should: [
		self callToolNamed: 'evaluate' withArguments: Dictionary new ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestToolsHaveAccurateNamesAndRequiredArguments [

	| dataProperties outputSchema resultsProperty |
	self assert: MCPToolRunTests new name equals: 'run-tests'.
	self
		assert: MCPToolRunTests new inputSchema required asSet
		equals: #( 'tests' ) asSet.
	outputSchema := MCPToolRunTests new outputSchema asJRPCJSON.
	dataProperties := ((outputSchema at: #properties) at: 'data') at:
		                  #properties.
	resultsProperty := dataProperties at: 'results'.
	self assert: (resultsProperty at: #type) equals: 'array'.
	self
		assert: ((resultsProperty at: #items) at: #type)
		equals: 'object'.
	self deny: (dataProperties includesKey: 'tests')
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
MCPToolContractsTest >> testToolNamesDoNotUsePharoPrefix [

	self assert: (MCPTool concreteSubclasses noneSatisfy: [ :each |
			 each new name includesSubstring: 'pharo-' ])
]

{ #category : 'private' }
MCPToolContractsTest >> toolFlowSpecs [

	^ {
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
			  (#toolClass -> MCPToolEvaluate).
			  (#arguments -> { (#code -> '1') } asDictionary).
			  (#requestClass -> MCPEvaluateRequest).
			  (#commandClass -> MCPEvaluateCommand) } asDictionary }
]
