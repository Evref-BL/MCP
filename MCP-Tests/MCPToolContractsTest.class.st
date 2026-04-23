Class {
	#name : 'MCPToolContractsTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

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
MCPToolContractsTest >> testBrowseIconToolGroupsKeepRelatedToolsTogether [

	| orderedTools |
	orderedTools := OrderedCollection new.
	MCPTool toolGroups do: [ :group |
		orderedTools addAll: group value ].
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
			MCPToolImplementors.
			MCPToolReferences.
			MCPToolInspectMethod.
			MCPToolEditMethod.
			MCPToolRemoveMethods.
			MCPToolRunTests.
			MCPToolEvaluate }
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditClassHasAccurateNameAndRequiredArguments [

	| operationProperty propertyNames tool |
	tool := MCPToolEditClass new.
	propertyNames := tool inputSchema properties collect: [ :each |
		                 each name ].
	operationProperty := tool inputSchema properties detect: [ :each |
		                     each name = 'operation' ].
	self assert: tool name equals: 'edit-class'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet.
	self assert: (propertyNames includes: 'classComment').
	self assert: (propertyNames includes: 'slotName').
	self assert: (propertyNames includes: 'classSide').
	self assert: (propertyNames includes: 'force').
	self
		assert: (operationProperty extraProperties at: #enum) asArray
		equals:
			#( 'create' 'move' 'rename' 'reparent' 'setComment' 'pullUpSlot'
			   'pushDownSlot' )
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
	self deny: (propertyNames includes: 'projectNames')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditMethodSchemaAdvertisesMethodState [

	| dataProperties dataProperty operationProperty permutationProperty propertyNames tool |
	tool := MCPToolEditMethod new.
	operationProperty := tool inputSchema properties detect: [ :each |
		                     each name = 'operation' ].
	permutationProperty := tool inputSchema properties detect: [ :each |
		                       each name = 'permutation' ].
	dataProperty := tool outputSchema properties detect: [ :each |
		                each name = 'data' ].
	dataProperties := dataProperty extraProperties at: #properties.
	propertyNames := dataProperties collect: [ :each | each name ].
	self
		assert: (operationProperty extraProperties at: #enum) asArray
		equals: #( 'compile' 'rename' 'changeProtocol' ).
	self assert:
		(permutationProperty extraProperties at: #items) type = 'integer'.
	self
		assert: propertyNames asSet
		equals:
			#( 'selector' 'className' 'side' 'packageName' 'isExtension'
			   'protocol' 'source' 'critiques' ) asSet
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

	self assert: (MCPToolEvaluate new inputSchema required includes: 'code')
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
	self assert: (propertyNames includes: 'scope').
	self deny: (propertyNames includes: 'packageName').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'filter').
	self assert: (propertyNames includes: 'filterTargets')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindClassesListsClassesForExistingPackage [

	| classNames data result |
	result := self callToolNamed: 'find-classes' withArguments: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests' )) } asDictionary.
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
	result := self callToolNamed: 'find-classes' withArguments: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Package MCP-Definitely-Missing does not exist.').
	self deny: (text includesSubstring: 'Tool find-classes failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsHasAccurateNameAndSchema [

	| filterTargetsProperty propertyNames schema |
	schema := MCPToolFindMethods new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	filterTargetsProperty := schema properties detect: [ :each |
		                         each name = 'filterTargets' ].
	self assert: MCPToolFindMethods new name equals: 'find-methods'.
	self assert: schema required equals: #(  ).
	self assert: (propertyNames includes: 'scope').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'filter').
	self assert: (propertyNames includes: 'filterTargets').
	self
		assert:
			((filterTargetsProperty extraProperties at: #items) extraProperties
				 at: #enum) asArray
		equals:
		#( 'selector' 'class' 'package' 'protocol' 'reference' 'source' ).
	self deny: (propertyNames includes: 'className')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsListsMethodsForExistingClassScope [

	| data result selectors |
	result := self callToolNamed: 'find-methods' withArguments: {
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolFindMethodsTestTarget' )) }
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
MCPToolContractsTest >> testFindMethodsReturnsErrorResultForMissingClass [

	| result text |
	result := self callToolNamed: 'find-methods' withArguments: {
			          (#scope -> 'classes').
			          (#classNames
			           -> #( 'MCPDefinitelyMissingFindMethodsClass' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Class MCPDefinitelyMissingFindMethodsClass does not exist.').
	self deny: (text includesSubstring: 'Tool find-methods failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolFindPackages new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolFindPackages new name equals: 'find-packages'.
	self assert: schema required equals: #(  ).
	self assert: (propertyNames includes: 'scope').
	self assert: (propertyNames includes: 'projectNames').
	self assert: (propertyNames includes: 'filter').
	self assert: (propertyNames includes: 'filterTargets').
	self assert: (propertyNames includes: 'filterMode')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesListsPackagesForExistingProject [

	| packageNames data result |
	result := self callToolNamed: 'find-packages' withArguments: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'MCP' )) } asDictionary.
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
	result := self callToolNamed: 'find-packages' withArguments: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'DefinitelyMissingProject' )) }
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
MCPToolContractsTest >> testInspectClassHasAccurateNameAndRequiredArguments [

	| inputPropertyNames tool |
	tool := MCPToolInspectClass new.
	inputPropertyNames := tool inputSchema properties collect: [ :each |
		                      each name ].
	self assert: tool name equals: 'inspect-class'.
	self
		assert: tool inputSchema required asSet
		equals: #( 'className' ) asSet.
	self assert: (inputPropertyNames includes: 'includeComment')
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
	self assert: (propertyNames includes: 'side').
	self assert: (propertyNames includes: 'includeVariableDetails').
	self deny: (variablePropertyNames includes: 'sourceIntervals').
	self deny: (variablePropertyNames includes: 'external').
	self deny: (variablePropertyNames includes: 'declaredInMethod')
]

{ #category : 'tests' }
MCPToolContractsTest >> testOptionalToolArgumentsAdvertiseDefaultsWhenAvailable [

	| editClassTool inspectClassTool inspectMethodTool editMethodTool findClassesTool findMethodsTool findPackagesTool implementorsTool referencesTool removeClassesTool removeMethodsTool |
	editClassTool := MCPToolEditClass new.
	inspectClassTool := MCPToolInspectClass new.
	inspectMethodTool := MCPToolInspectMethod new.
	editMethodTool := MCPToolEditMethod new.
	findClassesTool := MCPToolFindClasses new.
	findMethodsTool := MCPToolFindMethods new.
	findPackagesTool := MCPToolFindPackages new.
	implementorsTool := MCPToolImplementors new.
	referencesTool := MCPToolReferences new.
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
			((self inputPropertyNamed: 'side' inTool: inspectMethodTool)
				 extraProperties at: #default)
		equals: 'instance'.
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
		assert: ((self inputPropertyNamed: 'scope' inTool: findClassesTool)
				 extraProperties at: #default)
		equals: 'image'.
	self
		assert:
			((self inputPropertyNamed: 'filterTargets' inTool: findClassesTool)
				 extraProperties at: #default)
		equals: #( 'class' ).
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
			((self inputPropertyNamed: 'includeSource' inTool: findMethodsTool)
				 extraProperties at: #default)
		equals: false.
	self
		assert:
			((self inputPropertyNamed: 'scope' inTool: findPackagesTool)
				 extraProperties at: #default)
		equals: 'image'.
	self
		assert: ((self inputPropertyNamed: 'side' inTool: implementorsTool)
				 extraProperties at: #default)
		equals: 'both'.
	self
		assert:
			((self inputPropertyNamed: 'includeSource' inTool: referencesTool)
				 extraProperties at: #default)
		equals: false.
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
MCPToolContractsTest >> testRemoveClassHasAccurateNameAndRequiredArguments [

	self
		assert: MCPToolRemoveClasses new name
		equals: 'remove-classes'.
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
		assert: (MCPToolImplementors new asJRPCJSON at: #icons) first
		equals:
			(MCPStructureIcon horizontallyFlippedPngIconNamed: #references)
				asJRPCJSON.
	self
		assert: (MCPToolReferences new asJRPCJSON at: #icons) first
		equals: (MCPStructureIcon pngIconNamed: #references) asJRPCJSON.
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
MCPToolContractsTest >> testToolNamesDoNotUsePharoPrefix [

	self assert: (MCPTool concreteSubclasses noneSatisfy: [ :each |
			 each new name includesSubstring: 'pharo-' ])
]
