Class {
	#name : 'MCPCompiledMethodScopeQueryTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPCompiledMethodScopeQueryTest >> methodReferencesFor: compiledMethods [

	^ (compiledMethods collect: [ :each |
		   (MCPCompiledMethodInfo fromCompiledMethod: each) methodReference ])
		  asSet
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testClassesScopeCollectsMethodsFromExactClasses [

	| methodReferences query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'classes'
		         packageNames: nil
		         classNames: #( 'MCPToolImplementorsTestChild' )
		         side: 'instance'.
	methodReferences := self methodReferencesFor: query compiledMethods.
	self assert: (methodReferences includes:
			 'MCPToolImplementorsTestChild>>hierarchyProbe').
	self deny: (methodReferences includes:
			 'MCPToolImplementorsTestBase>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testHierarchyScopeCollectsMethodsAcrossTheHierarchy [

	| methodReferences query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'hierarchy'
		         packageNames: nil
		         classNames: #( 'MCPToolImplementorsTestMid' )
		         side: 'instance'.
	methodReferences := self methodReferencesFor: query compiledMethods.
	self assert: (methodReferences includes:
			 'MCPToolImplementorsTestBase>>hierarchyProbe').
	self assert: (methodReferences includes:
			 'MCPToolImplementorsTestChild>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testImageScopeRespectsSideFiltering [

	| methodReferences query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'image'
		         packageNames: nil
		         classNames: nil
		         side: 'class'.
	methodReferences := self methodReferencesFor: query compiledMethods.
	self assert: (methodReferences includes:
			 'MCPToolImplementorsTestExact class>>dualProbe').
	self deny:
		(methodReferences includes:
			 'MCPToolImplementorsTestExact>>dualProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackagesScopeIncludesExtensionMethods [

	| methodReferences query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'packages'
		         packageNames: #( 'MCP-Tests-Extensions' )
		         classNames: nil
		         side: 'instance'.
	methodReferences := self methodReferencesFor: query compiledMethods.
	self assert: (methodReferences includes:
			 'MCPToolImplementorsTestExtensionTarget>>extensionProbe')
]
