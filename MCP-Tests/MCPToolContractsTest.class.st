Class {
	#name : 'MCPToolContractsTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

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
MCPToolContractsTest >> testEvalReturnsCompilationFailureInformation [

	| result text |
	result := MCPToolEval new executeWithArguments:
		          { (#code -> '1 +') } asDictionary.
	text := result first text.
	self assert: (text includesSubstring: 'failed during compilation').
	self assert: (text includesSubstring: 'RBSyntaxErrorNotice').
	self assert: (text includesSubstring: 'Position: 4')
]

{ #category : 'tests' }
MCPToolContractsTest >> testEvalReturnsRuntimeFailureInformation [

	| result text |
	result := MCPToolEval new executeWithArguments:
		          { (#code -> 'Error signal: ''boom''') } asDictionary.
	text := result first text.
	self assert: (text includesSubstring: 'failed during execution').
	self assert: (text includesSubstring: 'boom').
	self assert: (text includesSubstring: 'Signaler context:')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetClassesListsClassesForExistingPackage [

	| result |
	result := MCPToolGetClasses new executeWithArguments:
		          { (#packageName -> 'MCP-Tests') } asDictionary.
	self assert: (result first text includesSubstring:
			 'MCP-Tests/MCPToolCompileMethodTest')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetClassesReportsMissingPackageErrorsInBand [

	| result text |
	result := MCPToolGetClasses new executeWithArguments:
		          { (#packageName -> 'MCP-Definitely-Missing') }
			          asDictionary.
	text := result first text.
	self assert: (text includesSubstring:
			 'Unable to list classes for package MCP-Definitely-Missing').
	self assert: (text includesSubstring: 'NotFound').
	self assert: (text includesSubstring:
			 'There is no package named MCP-Definitely-Missing')
]

{ #category : 'tests' }
MCPToolContractsTest >> testGetClassesSignalsMissingPackageErrors [

	| result text |
	result := MCPToolGetClasses new executeWithArguments:
		          { (#packageName -> 'MCP-Definitely-Missing') }
			          asDictionary.
	text := result first text.
	self assert: (text includesSubstring:
			 'Unable to list classes for package MCP-Definitely-Missing').
	self assert: (text includesSubstring: 'NotFound').
	self assert: (text includesSubstring:
			 'There is no package named MCP-Definitely-Missing')
]

{ #category : 'tests' }
MCPToolContractsTest >> testReadClassRequiresClassNameInSchema [

	self assert:
		(MCPToolReadClass new inputSchema required includes: 'className')
]
