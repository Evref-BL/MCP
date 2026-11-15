"
Tests method scope query behavior for classes, packages, and sides.
"
Class {
	#name : 'MCPCompiledMethodScopeQueryTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPCompiledMethodScopeQueryTest >> methodIdentitiesFor: compiledMethods [

	^ compiledMethods
		  collect: [ :each |
				  String streamContents: [ :stream |
						  stream nextPutAll: each methodClass instanceSide name asString.
						  each methodClass isMeta ifTrue: [ stream nextPutAll: ' class' ].
						  stream
							  nextPutAll: '>>';
							  nextPutAll: each selector asString ] ]
		  as: Set
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testAClassWrittenWithItsSideSelectsTheClass [

	| query |
	query := MCPCompiledMethodScopeQuery new
		         classNames: #( 'MCPToolHierarchyTestChild class' );
		         side: 'instance';
		         yourself.
	self assert: ((self methodIdentitiesFor: query methods) includes: 'MCPToolHierarchyTestChild>>hierarchyProbe').
	self assert: query warnings isEmpty
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testACompleteScopeRefusesAMissingClassUnderItsKey [

	| error query |
	query := MCPCompiledMethodScopeQuery new
		         hierarchyClassNames: #( 'Zzqxw' );
		         requireCompleteScope;
		         yourself.
	error := [
		         query methods.
		         nil ]
		         on: MCPCommandError
		         do: [ :signal | signal return: signal ].
	self assert: error errorCode equals: #ClassNotFound.
	self assert: error messageText equals: 'Class Zzqxw, in scope.hierarchyOf, does not exist.'.
	self assert: (error details at: #scope) equals: 'scope.hierarchyOf'
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testAMissingClassIsNamedByItsScopeKey [
	"Each scope key warns under the name the schema gives it, never an internal label such as hierarchyClasses."

	{
		(#classNames: -> 'Class Zzqxw does not exist, so scope.classes skipped it.').
		(#hierarchyClassNames: -> 'Class Zzqxw does not exist, so scope.hierarchyOf skipped it.').
		(#parentClassNames: -> 'Class Zzqxw does not exist, so scope.superclassesOf skipped it.').
		(#subclassClassNames: -> 'Class Zzqxw does not exist, so scope.subclassesOf skipped it.') } do: [ :each |
			| query |
			query := MCPCompiledMethodScopeQuery new.
			query perform: each key with: #( 'Zzqxw' ).
			self assert: query methods isEmpty.
			self assert: query warnings asArray equals: { each value } ]
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testClassesScopeCollectsMethodsFromExactClasses [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         classNames: #( 'MCPToolHierarchyTestChild' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes: 'MCPToolHierarchyTestChild>>hierarchyProbe').
	self deny: (methodIdentities includes: 'MCPToolHierarchyTestBase>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testClassesScopeReturnsPartialMethodsAndWarningsWhenClassIsMissing [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         classNames: #( 'MCPToolHierarchyTestChild' 'MCPDefinitelyMissingCompiledMethodScopeQueryClass' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes: 'MCPToolHierarchyTestChild>>hierarchyProbe').
	self assert: query warnings size equals: 1.
	self assert: (query warnings first includesSubstring: 'MCPDefinitelyMissingCompiledMethodScopeQueryClass').
	self assert: (query warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testHierarchyScopeCollectsMethodsAcrossTheHierarchy [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         hierarchyClassNames: #( 'MCPToolHierarchyTestMid' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes: 'MCPToolHierarchyTestBase>>hierarchyProbe').
	self assert: (methodIdentities includes: 'MCPToolHierarchyTestChild>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testImageScopeRespectsSideFiltering [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         side: 'class';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes: 'MCPToolMethodSearchReferenceFixture class>>sharedTarget').
	self deny: (methodIdentities includes: 'MCPToolMethodSearchReferenceFixture>>sharedTarget')
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
	self assert: error messageText equals: 'side must be one of instance, class, or both.'
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testItsDictionaryUsesTheSchemaKeys [
	"Answers repeat a scope as a dictionary, so its keys are the schema's."

	| dictionary |
	dictionary := (MCPCompiledMethodScopeQuery new
		               hierarchyClassNames: #( 'A' );
		               subclassClassNames: #( 'B' );
		               parentClassNames: #( 'C' );
		               yourself) asDictionary.
	self assert: dictionary keys asSet equals: #( #packages #classes #hierarchyOf #subclassesOf #superclassesOf #side ) asSet.
	self assert: (dictionary at: #hierarchyOf) equals: #( 'A' ).
	self assert: (dictionary at: #subclassesOf) equals: #( 'B' ).
	self assert: (dictionary at: #superclassesOf) equals: #( 'C' )
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackageScopeIncludesExtensionMethods [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         packageNames: #( 'MCP-Tests-Resources-Extensions' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes: 'MCPToolMethodSearchReferenceTarget>>extensionProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testPackageScopeReturnsEmptyMethodsAndWarningsWhenPackageIsMissing [

	| query |
	query := MCPCompiledMethodScopeQuery new
		         packageNames: #( 'MCP-Definitely-Missing' );
		         side: 'instance';
		         yourself.
	self assert: query methods isEmpty.
	self assert: query warnings size equals: 1.
	self assert: (query warnings first includesSubstring: 'MCP-Definitely-Missing')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testParentScopeCollectsMethodsFromParentsOnly [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         parentClassNames: #( 'MCPToolHierarchyTestMid' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes: 'MCPToolHierarchyTestBase>>hierarchyProbe').
	self deny: (methodIdentities includes: 'MCPToolHierarchyTestChild>>hierarchyProbe')
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testScopePhraseLeavesOutWhatTheQueryCouldNotResolve [

	| query |
	query := MCPCompiledMethodScopeQuery new
		         classNames: #( 'MCPToolHierarchyTestChild' 'MCPDefinitelyMissingPhraseClass' );
		         side: 'class';
		         yourself.
	self assert: query scopePhrase equals: 'MCPToolHierarchyTestChild and MCPDefinitelyMissingPhraseClass, class side'.
	query methods.
	self assert: query scopePhrase equals: 'MCPToolHierarchyTestChild, class side'.
	self deny: query namesNothingThatExists.
	query classNames: #( 'MCPDefinitelyMissingPhraseClass' ).
	query methods.
	self assert: query namesNothingThatExists.
	self assert: query scopePhrase isNil
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testScopePhraseNamesWhereTheQueryLooks [
	"Names are listed up to three and counted from four on, in the order projects, packages, classes, hierarchies, subclasses, superclasses."

	self assert: MCPCompiledMethodScopeQuery new scopePhrase equals: 'the image'.
	self
		assert: (MCPCompiledMethodScopeQuery new
				 side: 'instance';
				 yourself) scopePhrase
		equals: 'the image, instance side'.
	self
		assert: (MCPCompiledMethodScopeQuery new
				 packageNames: #( 'A' 'B' );
				 classNames: #( 'C' 'D' 'E' );
				 yourself) scopePhrase
		equals: 'packages A and B and C, D and E'.
	self
		assert: (MCPCompiledMethodScopeQuery new
				 hierarchyClassNames: #( 'A' );
				 subclassClassNames: #( 'B' 'C' );
				 parentClassNames: #( 'A' 'B' 'C' 'D' );
				 yourself) scopePhrase
		equals: 'the hierarchy of A and the subclasses of B and C and the superclasses of 4 classes'.
	self
		assert: (MCPClassScopeQuery new
				 packageNames: #( 'A' 'B' 'C' 'D' 'E' 'F' );
				 hierarchyClassNames: #( 'A' 'B' 'C' 'D' );
				 yourself) scopePhrase
		equals: '6 packages and the hierarchies of 4 classes'.
	self
		assert: (MCPPackageScopeQuery new
				 projectNames: #( 'X' );
				 packageNames: #( 'P' 'P' );
				 yourself) scopePhrase
		equals: 'project X and package P'.
	self assert: MCPPackageScopeQuery new scopePhrase equals: 'the image'
]

{ #category : 'tests' }
MCPCompiledMethodScopeQueryTest >> testSubclassScopeCollectsMethodsFromSubclassesOnly [

	| methodIdentities query |
	query := MCPCompiledMethodScopeQuery new
		         subclassClassNames: #( 'MCPToolHierarchyTestMid' );
		         side: 'instance';
		         yourself.
	methodIdentities := self methodIdentitiesFor: query methods.
	self assert: (methodIdentities includes: 'MCPToolHierarchyTestChild>>hierarchyProbe').
	self deny: (methodIdentities includes: 'MCPToolHierarchyTestBase>>hierarchyProbe')
]
