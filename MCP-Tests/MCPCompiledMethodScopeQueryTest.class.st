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
	query := MCPCompiledMethodScopeQuery
		         scope: 'classes'
		         packageNames: nil
		         classNames: #( 'MCPToolHierarchyTestChild' )
		         side: 'instance'.
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
	query := MCPCompiledMethodScopeQuery
		         scope: 'classes'
		         packageNames: nil
		         classNames:
		         #( 'MCPDefinitelyMissingCompiledMethodScopeQueryClass' )
		         side: 'instance'.
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
	query := MCPCompiledMethodScopeQuery
		         scope: 'hierarchy'
		         packageNames: nil
		         classNames: #( 'MCPToolHierarchyTestMid' )
		         side: 'instance'.
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
	query := MCPCompiledMethodScopeQuery
		         scope: 'image'
		         packageNames: nil
		         classNames: nil
		         side: 'class'.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes:
			 'MCPToolReferencesTestExact class>>sharedTarget').
	self deny:
		(methodIdentities includes:
			 'MCPToolReferencesTestExact>>sharedTarget')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testInvalidScopeSignalsErrorWhenQuerying [

	| error query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'invalid'
		         packageNames: nil
		         classNames: nil
		         side: 'instance'.
	error := [
	         query methods.
	         self fail: 'Expected Error' ]
		         on: Error
		         do: [ :caught | caught ].
	self
		assert: error messageText
		equals:
		'scope must be one of image, packages, hierarchy, or classes.'
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackagesScopeIncludesExtensionMethods [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'packages'
		         packageNames: #( 'MCP-Tests-Resources-Extensions' )
		         classNames: nil
		         side: 'instance'.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes:
			 'MCPToolReferencesTestExtensionTarget>>extensionProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackagesScopeSignalsCommandErrorWhenPackageIsMissing [

	| error query |
	query := MCPCompiledMethodScopeQuery
		         scope: 'packages'
		         packageNames: #( 'MCP-Definitely-Missing' )
		         classNames: nil
		         side: 'instance'.
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
