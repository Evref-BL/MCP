Class {
	#name : 'MCPCompiledMethodScopeQueryTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPCompiledMethodScopeQueryTest >> methodIdentitiesFor: compiledMethods [

	^ (compiledMethods collect: [ :each |
		   String streamContents: [ :stream |
			   stream nextPutAll: each methodClass instanceSide name asString.
			   each methodClass isMeta ifTrue: [ stream nextPutAll: ' class' ].
			   stream
				   nextPutAll: '>>';
				   nextPutAll: each selector asString ] ]) asSet
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testClassesScopeCollectsMethodsFromExactClasses [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'classes'
		         packageNames: nil
		         classNames: #( 'MCPToolImplementorsTestChild' )
		         side: 'instance'.
	methodIdentities := self methodIdentitiesFor: query compiledMethods.
	self assert: (methodIdentities includes:
			 'MCPToolImplementorsTestChild>>hierarchyProbe').
	self deny: (methodIdentities includes:
			 'MCPToolImplementorsTestBase>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testHierarchyScopeCollectsMethodsAcrossTheHierarchy [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'hierarchy'
		         packageNames: nil
		         classNames: #( 'MCPToolImplementorsTestMid' )
		         side: 'instance'.
	methodIdentities := self methodIdentitiesFor: query compiledMethods.
	self assert: (methodIdentities includes:
			 'MCPToolImplementorsTestBase>>hierarchyProbe').
	self assert: (methodIdentities includes:
			 'MCPToolImplementorsTestChild>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testImageScopeRespectsSideFiltering [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'image'
		         packageNames: nil
		         classNames: nil
		         side: 'class'.
	methodIdentities := self methodIdentitiesFor: query compiledMethods.
	self assert: (methodIdentities includes:
			 'MCPToolImplementorsTestExact class>>dualProbe').
	self deny:
		(methodIdentities includes:
			 'MCPToolImplementorsTestExact>>dualProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackagesScopeIncludesExtensionMethods [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'packages'
		         packageNames: #( 'MCP-Tests-Extensions' )
		         classNames: nil
		         side: 'instance'.
	methodIdentities := self methodIdentitiesFor: query compiledMethods.
	self assert: (methodIdentities includes:
			 'MCPToolImplementorsTestExtensionTarget>>extensionProbe')
]
