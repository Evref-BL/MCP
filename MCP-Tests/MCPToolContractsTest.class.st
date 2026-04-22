Class {
	#name : 'MCPToolContractsTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolContractsTest >> callToolNamed: aToolName withArguments: someArguments [

	^ MCP new rpcToolCall: aToolName withParams: someArguments
]

{ #category : 'private' }
MCPToolContractsTest >> firstTextFromToolResult: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private' }
MCPToolContractsTest >> handleJSON: aJSONString [

	^ MCP new server messageProcessor handleJSON: aJSONString
]

{ #category : 'tests' }
MCPToolContractsTest >> testDescribeClassHasAccurateNameAndRequiredArguments [

	self
		assert: MCPToolDescribeClass new name
		equals: 'pharo-describe-class'.
	self
		assert: MCPToolDescribeClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditClassHasAccurateNameAndRequiredArguments [

	self assert: MCPToolEditClass new name equals: 'pharo-edit-class'.
	self
		assert: MCPToolEditClass new inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testEditMethodHasAccurateNameAndRequiredArguments [

	self assert: MCPToolEditMethod new name equals: 'pharo-edit-method'.
	self
		assert: MCPToolEditMethod new inputSchema required asSet
		equals: #( 'operation' 'className' 'classSide' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvalIsMarkedAsAdvancedEscapeHatch [

	| description |
	description := MCPToolEval new description.
	self assert: (description includesSubstring: 'escape hatch').
	self assert:
		(description includesSubstring: 'arbitrary Smalltalk code')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvalRequiresCodeInSchema [

	self assert: (MCPToolEval new inputSchema required includes: 'code')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvalReturnsCompilationFailureInformation [

	| result text |
	result := self
		          callToolNamed: 'pharo-eval'
		          withArguments: { (#code -> '1 +') } asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring: 'failed during compilation').
	self assert: (text includesSubstring: 'RBSyntaxErrorNotice').
	self assert: (text includesSubstring: 'Position: 4')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvalReturnsRuntimeFailureInformation [

	| result text |
	result := self
		          callToolNamed: 'pharo-eval'
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
	self assert: MCPToolFindClasses new name equals: 'pharo-find-classes'.
	self assert: schema required equals: #(  ).
	self assert: (propertyNames includes: 'scope').
	self deny: (propertyNames includes: 'packageName').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'filter')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindClassesListsClassesForExistingPackage [

	| classNames data result |
	result := self callToolNamed: 'pharo-find-classes' withArguments: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests' )) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'packages'.
	self assert: (data at: #packageNames) equals: #( 'MCP-Tests' ).
	self assert: (classNames includes: 'MCPToolEditMethodTest')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindClassesReturnsErrorResultForMissingPackage [

	| result text |
	result := self callToolNamed: 'pharo-find-classes' withArguments: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Package MCP-Definitely-Missing does not exist.').
	self deny: (text includesSubstring: 'Tool pharo-find-classes failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolFindMethods new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: MCPToolFindMethods new name equals: 'pharo-find-methods'.
	self assert: schema required equals: #(  ).
	self assert: (propertyNames includes: 'scope').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'filter').
	self deny: (propertyNames includes: 'className')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsListsMethodsForExistingClassScope [

	| classNames data result selectors |
	result := self callToolNamed: 'pharo-find-methods' withArguments: {
			          (#scope -> 'classes').
			          (#classNames -> #( 'MCPToolFindMethodsTestTarget' )) }
			          asDictionary.
	data := (result at: #structuredContent) at: #data.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	classNames := data at: #classNames.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'classes'.
	self assert: classNames equals: #( 'MCPToolFindMethodsTestTarget' ).
	self assert: (selectors includes: 'alphaNeedleSelector').
	self assert: (selectors includes: 'classNeedleSelector')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindMethodsReturnsErrorResultForMissingClass [

	| result text |
	result := self callToolNamed: 'pharo-find-methods' withArguments: {
			          (#scope -> 'classes').
			          (#classNames
			           -> #( 'MCPDefinitelyMissingFindMethodsClass' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Class MCPDefinitelyMissingFindMethodsClass does not exist.').
	self deny: (text includesSubstring: 'Tool pharo-find-methods failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesHasAccurateNameAndSchema [

	| propertyNames schema |
	schema := MCPToolFindPackages new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self
		assert: MCPToolFindPackages new name
		equals: 'pharo-find-packages'.
	self assert: schema required equals: #(  ).
	self assert: (propertyNames includes: 'scope').
	self assert: (propertyNames includes: 'projectNames').
	self assert: (propertyNames includes: 'filter').
	self assert: (propertyNames includes: 'filterMode')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesListsPackagesForExistingProject [

	| packageNames data result |
	result := self callToolNamed: 'pharo-find-packages' withArguments: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'MCP' )) } asDictionary.
	data := (result at: #structuredContent) at: #data.
	packageNames := (data at: #packages) collect: [ :each |
		                each at: #packageName ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'project'.
	self assert: (data at: #projectNames) equals: #( 'MCP' ).
	self assert: (packageNames includes: 'MCP').
	self assert: (packageNames includes: 'MCP-Tests')
]

{ #category : 'tests' }
MCPToolContractsTest >> testFindPackagesReturnsErrorResultForMissingProject [

	| result text |
	result := self callToolNamed: 'pharo-find-packages' withArguments: {
			          (#scope -> 'project').
			          (#projectNames -> #( 'DefinitelyMissingProject' )) }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Project DefinitelyMissingProject does not exist.').
	self deny:
		(text includesSubstring: 'Tool pharo-find-packages failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testHandleJSONReturnsInvalidParamsForMissingRequiredArguments [

	| response |
	response := self handleJSON:
		            '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"pharo-eval","arguments":{}}}'.
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
MCPToolContractsTest >> testRemoveClassHasAccurateNameAndRequiredArguments [

	self
		assert: MCPToolRemoveClasses new name
		equals: 'pharo-remove-classes'.
	self
		assert: MCPToolRemoveClasses new inputSchema required asSet
		equals: #( 'classNames' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveMethodsHasAccurateNameAndRequiredArguments [

	self
		assert: MCPToolRemoveMethods new name
		equals: 'pharo-remove-methods'.
	self
		assert: MCPToolRemoveMethods new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selectors' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRpcToolCallSignalsInvalidParametersWhenRequiredArgumentIsMissing [

	self
		should: [
		self callToolNamed: 'pharo-eval' withArguments: Dictionary new ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolContractsTest >> testRunTestToolsHaveAccurateNamesAndRequiredArguments [

	self assert: MCPToolRunTests new name equals: 'pharo-run-tests'.
	self
		assert: MCPToolRunTests new inputSchema required asSet
		equals: #( 'tests' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolNamesUsePharoPrefix [

	self assert: (MCPTool allSubclasses allSatisfy: [ :each |
			 each new name beginsWith: 'pharo-' ])
]
