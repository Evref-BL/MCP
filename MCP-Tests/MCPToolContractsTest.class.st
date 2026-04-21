Class {
	#name : 'MCPToolContractsTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
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
MCPToolContractsTest >> testChangeMethodProtocolHasAccurateNameAndRequiredArguments [

	self
		assert: MCPToolChangeMethodProtocol new name
		equals: 'pharo-change-method-protocol'.
	self
		assert: MCPToolChangeMethodProtocol new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selector' 'protocol' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testCreatePackageRequiresPackageNameInSchema [

	self assert:
		(MCPToolCreatePackage new inputSchema required includes:
			 'packageName')
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
MCPToolContractsTest >> testGetClassesListsClassesForExistingPackage [

	| data result |
	result := self
		          callToolNamed: 'pharo-list-package-classes'
		          withArguments:
		          { (#packageName -> 'MCP-Tests') } asDictionary.
	data := (result at: #structuredContent) at: #data.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		((data at: #classNames) includes: 'MCPToolCompileMethodTest')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetClassesReportsMissingPackageErrorsInBand [

	| result text |
	result := self
		          callToolNamed: 'pharo-list-package-classes'
		          withArguments:
		          { (#packageName -> 'MCP-Definitely-Missing') }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Unable to list classes for package MCP-Definitely-Missing').
	self assert: (text includesSubstring: 'There is no package named').
	self deny:
		(text includesSubstring: 'Tool pharo-list-package-classes failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetClassesSignalsMissingPackageErrors [

	| result text |
	result := self
		          callToolNamed: 'pharo-list-package-classes'
		          withArguments:
		          { (#packageName -> 'MCP-Definitely-Missing') }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Unable to list classes for package MCP-Definitely-Missing').
	self assert: (text includesSubstring: 'There is no package named').
	self deny:
		(text includesSubstring: 'Tool pharo-list-package-classes failed')
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
MCPToolContractsTest >> testListPackageClassesListsClassesForExistingPackage [

	| data result |
	result := self
		          callToolNamed: 'pharo-list-package-classes'
		          withArguments:
		          { (#packageName -> 'MCP-Tests') } asDictionary.
	data := (result at: #structuredContent) at: #data.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		((data at: #classNames) includes: 'MCPToolCompileMethodTest')
]

{ #category : 'tests' }
MCPToolContractsTest >> testListPackageClassesRequiresPackageNameInSchema [

	self assert:
		(MCPToolGetClasses new inputSchema required includes: 'packageName')
]

{ #category : 'tests' }
MCPToolContractsTest >> testListPackageClassesReturnsErrorResultForMissingPackage [

	| result text |
	result := self
		          callToolNamed: 'pharo-list-package-classes'
		          withArguments:
		          { (#packageName -> 'MCP-Definitely-Missing') }
			          asDictionary.
	text := self firstTextFromToolResult: result.
	self assert: (result at: #isError).
	self assert: (text includesSubstring:
			 'Unable to list classes for package MCP-Definitely-Missing').
	self assert: (text includesSubstring: 'There is no package named').
	self deny:
		(text includesSubstring: 'Tool pharo-list-package-classes failed')
]

{ #category : 'tests' }
MCPToolContractsTest >> testReadClassRequiresClassNameInSchema [

	self assert:
		(MCPToolReadClass new inputSchema required includes: 'className')
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveClassHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRemoveClass new name equals: 'pharo-remove-class'.
	self
		assert: MCPToolRemoveClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRemoveMethodHasAccurateNameAndRequiredArguments [

	self
		assert: MCPToolRemoveMethod new name
		equals: 'pharo-remove-method'.
	self
		assert: MCPToolRemoveMethod new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selector' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRenameClassHasAccurateNameAndRequiredArguments [

	self assert: MCPToolRenameClass new name equals: 'pharo-rename-class'.
	self
		assert: MCPToolRenameClass new inputSchema required asSet
		equals: #( 'className' 'newClassName' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testRenameMethodHasAccurateNameAndRequiredArguments [

	self
		assert: MCPToolRenameMethod new name
		equals: 'pharo-rename-method'.
	self
		assert: MCPToolRenameMethod new inputSchema required asSet
		equals: #( 'className' 'classSide' 'selector' 'newSelector' ) asSet
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

	self
		assert: MCPToolExecuteClassTest new name
		equals: 'pharo-run-test-method'.
	self
		assert: MCPToolExecuteClassTest new inputSchema required asSet
		equals: #( 'className' 'testMethodName' ) asSet.
	self
		assert: MCPToolExecuteAllTestOfClass new name
		equals: 'pharo-run-test-class'.
	self
		assert: MCPToolExecuteAllTestOfClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]

{ #category : 'tests' }
MCPToolContractsTest >> testToolNamesUsePharoPrefix [

	self assert: (MCPTool allSubclasses allSatisfy: [ :each |
			 each new name beginsWith: 'pharo-' ])
]
