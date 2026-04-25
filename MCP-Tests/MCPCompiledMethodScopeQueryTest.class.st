Class {
	#name : 'MCPCompiledMethodScopeQueryTest',
	#superclass : 'MCPTestCase',
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
	query := MCPCompiledMethodScopeQuery new
		         classNames: #( 'MCPToolHierarchyTestChild' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes:
			 'MCPToolHierarchyTestChild>>hierarchyProbe').
	self deny:
		(methodIdentities includes:
			 'MCPToolHierarchyTestBase>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testClassesScopeSignalsCommandErrorWhenClassIsMissing [

	| error query |
	query := MCPCompiledMethodScopeQuery new
		         classNames:
			         #( 'MCPDefinitelyMissingCompiledMethodScopeQueryClass' );
		         side: 'instance';
		         yourself.
	error := [
	         query methods.
	         self fail: 'Expected MCPCommandError' ]
		         on: MCPCommandError
		         do: [ :caught | caught ].
	self assert: error errorCode equals: #ClassNotFound.
	self
		assert: (error structuredDetails at: #className)
		equals: 'MCPDefinitelyMissingCompiledMethodScopeQueryClass'
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testHierarchyScopeCollectsMethodsAcrossTheHierarchy [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         hierarchyClassNames: #( 'MCPToolHierarchyTestMid' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert:
		(methodIdentities includes:
			 'MCPToolHierarchyTestBase>>hierarchyProbe').
	self assert: (methodIdentities includes:
			 'MCPToolHierarchyTestChild>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testImageScopeRespectsSideFiltering [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         side: 'class';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes:
			 'MCPToolFindMethodsReferenceFixture class>>sharedTarget').
	self deny: (methodIdentities includes:
			 'MCPToolFindMethodsReferenceFixture>>sharedTarget')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testInvalidSideSignalsErrorWhenQuerying [

	| error query |
	query := MCPCompiledMethodScopeQuery new
		         side: 'invalid';
		         yourself.
	error := [
	         query methods.
	         self fail: 'Expected Error' ]
		         on: Error
		         do: [ :caught | caught ].
	self
		assert: error messageText
		equals: 'side must be one of instance, class, or both.'
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackageScopeIncludesExtensionMethods [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         packageNames: #( 'MCP-Tests-Resources-Extensions' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes:
			 'MCPToolFindMethodsReferenceTarget>>extensionProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackageScopeSignalsCommandErrorWhenPackageIsMissing [

	| error query |
	query := MCPCompiledMethodScopeQuery new
		         packageNames: #( 'MCP-Definitely-Missing' );
		         side: 'instance';
		         yourself.
	error := [
	         query methods.
	         self fail: 'Expected MCPCommandError' ]
		         on: MCPCommandError
		         do: [ :caught | caught ].
	self assert: error errorCode equals: #PackageNotFound.
	self
		assert: (error structuredDetails at: #packageName)
		equals: 'MCP-Definitely-Missing'
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testParentScopeCollectsMethodsFromParentsOnly [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         parentClassNames: #( 'MCPToolHierarchyTestMid' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert:
		(methodIdentities includes:
			 'MCPToolHierarchyTestBase>>hierarchyProbe').
	self deny: (methodIdentities includes:
			 'MCPToolHierarchyTestChild>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testSubclassScopeCollectsMethodsFromSubclassesOnly [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         subclassClassNames: #( 'MCPToolHierarchyTestMid' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes:
			 'MCPToolHierarchyTestChild>>hierarchyProbe').
	self deny:
		(methodIdentities includes:
			 'MCPToolHierarchyTestBase>>hierarchyProbe')
]
