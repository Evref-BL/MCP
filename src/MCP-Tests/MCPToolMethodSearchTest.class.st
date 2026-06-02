"
Tests method metadata, source, equivalent, and reference search tools.
"
Class {
	#name : 'MCPToolMethodSearchTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolMethodSearchTest >> entryForReference: aReference in: methods [

	^ methods
		  detect: [ :each |
			  | reference |
			  reference := String streamContents: [ :stream |
				               stream nextPutAll: (each at: #className).
				               (each at: #classSide) ifTrue: [
					               stream nextPutAll: ' class' ].
				               stream
					               nextPutAll: '>>';
					               nextPutAll: (each at: #selector) ].
			  reference = aReference ]
		  ifNone: [ self fail: 'Missing method ' , aReference ]
]

{ #category : 'private' }
MCPToolMethodSearchTest >> targetClassName [

	^ 'MCPToolMethodSearchTestTarget'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testCanFilterAcrossExplicitProtocolTarget [

	| data result selectors |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#protocol -> 'helpers').
			          (#filterMode -> 'substring') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self assert: (data at: #totalCount) equals: 2.
	self
		assert: selectors asSet
		equals: #( 'betaHelper' 'classUtility' ) asSet
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testCanFilterPaginateAndIncludeSource [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#side -> 'class').
			          (#protocol -> 'meta').
			          (#filterMode -> 'substring').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #methods) size equals: 1.
	self assert:
		((data at: #methods) allSatisfy: [ :each | each at: #classSide ]).
	self assert: ((data at: #methods) allSatisfy: [ :each |
			 (each at: #protocol) includesSubstring: 'meta' ]).
	self assert:
		((data at: #methods) allSatisfy: [ :each |
			 each includesKey: #source ]).
	self assert: ((data at: #methods) anySatisfy: [ :each |
			 (each at: #source) includesSubstring: String cr asString ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testCanIncludeFormattedSourceForImplementorLookup [

	| data method result |
	result := self callToolWith: {
			          (#selector -> 'sharedTarget').
			          (#side -> 'class').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolMethodSearchReferenceFixture class>>sharedTarget'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert:
		((method at: #source) includesSubstring: String cr asString)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testCaseInsensitiveExactSelectorFilterKeepsGeneralFilteringSemantics [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#selector -> 'ALPHANEEDLESELECTOR').
			          (#caseSensitive -> false) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: self targetClassName , '>>alphaNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesLimitImplementorLookupToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyProbe').
			          (#classNames -> #( 'MCPToolHierarchyTestChild' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesReturnMethodsForExactClasses [

	| data result selectors |
	result := self callToolWith:
		          { (#classNames -> { self targetClassName }) } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 5.
	self assert: (data at: #methods) size equals: 5.
	self
		assert: selectors asSet
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector'
			   'classUtility' 'gammaUtility' ) asSet.
	self
		entryForReference:
		self targetClassName , ' class>>classNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesSelectExactClassScope [

	| data result selectors |
	result := self callToolWith:
		          { (#classNames -> { self targetClassName }) } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 5.
	self
		assert: selectors asSet
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector'
			   'classUtility' 'gammaUtility' ) asSet
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceCanIncludeFormattedSource [

	| data method result |
	result := self
		          callToolNamed: 'method_class_reference_search'
		          withArguments: {
				          (#className -> 'MCPToolMethodSearchReferenceTarget').
				          (#side -> 'class').
				          (#includeSource -> true).
				          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert: ((method at: #source) includesSubstring:
			 'MCPToolMethodSearchReferenceTarget')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceClassScopeReturnsClassGlobalReferences [

	| data result |
	result := self
		          callToolNamed: 'method_class_reference_search'
		          withArguments: {
				          (#className -> 'MCPToolMethodSearchReferenceTarget').
				          (#classNames
				           -> #( 'MCPToolMethodSearchReferenceFixture' )) }
				          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceDoesNotIncludeSelectorSendsNamedLikeClass [

	| data result selectors |
	result := self
		          callToolNamed: 'method_class_reference_search'
		          withArguments:
		          { (#className -> 'MCPToolMethodSearchReferenceTarget') }
			          asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self deny: (selectors includes: 'sendExistingClassNamedSelector')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceReturnsInstanceAndClassGlobalReferences [

	| data result |
	result := self
		          callToolNamed: 'method_class_reference_search'
		          withArguments:
		          { (#className -> 'MCPToolMethodSearchReferenceTarget') }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self
		          callToolNamed: 'method_class_reference_search'
		          withArguments:
		          { (#className -> 'MCPDefinitelyMissingReferenceClass') }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: ((error at: #message) includesSubstring:
			 'There is no class named MCPDefinitelyMissingReferenceClass')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testDefaultExactSelectorFilterReturnsImplementors [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#selector -> 'alphaNeedleSelector') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: self targetClassName , '>>alphaNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testDefaultFilterAppliesToSelectorOnly [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#selector -> 'helpers') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #methods) isEmpty
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testDirectionalScopesAreUnionedForMethods [

	| data result |
	result := self callToolWith: {
			          (#subclassClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#parentClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#side -> 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe'
		in: (data at: #methods).
	self
		entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchDefaultsReferenceToInstanceSide [

	| data result subclassName |
	subclassName := 'MCPToolMethodSearchEquivalentDefaultSideFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolMethodSearchReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
		self
			ensureMethodSource: 'sharedTarget

	^ ''instance-target'''
			protocol: 'testing'
			on: (self classNamed: subclassName).
		result := self
			          callToolNamed: 'method_equivalent_search'
			          withArguments: {
					          (#classNames -> { subclassName }).
					          (#className -> 'MCPToolMethodSearchReferenceFixture').
					          (#selector -> 'sharedTarget') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #totalCount) equals: 1.
		self
			entryForReference: subclassName , '>>sharedTarget'
			in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchMatchesReferencedClassSideMethod [

	| data result subclass subclassName |
	subclassName := 'MCPToolMethodSearchEquivalentClassFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolMethodSearchReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
		subclass := self classNamed: subclassName.
		self
			ensureMethodSource: 'sharedTarget

	^ ''class-target'''
			protocol: 'testing'
			on: subclass classSide.
		result := self
			          callToolNamed: 'method_equivalent_search'
			          withArguments: {
					          (#classNames -> { subclassName }).
					          (#side -> 'class').
					          (#className -> 'MCPToolMethodSearchReferenceFixture').
					          (#selector -> 'sharedTarget').
					          (#classSide -> true) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #totalCount) equals: 1.
		self
			entryForReference: subclassName , ' class>>sharedTarget'
			in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchMatchesReferencedInstanceSideMethod [

	| data result subclassName |
	subclassName := 'MCPToolMethodSearchEquivalentInstanceFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolMethodSearchReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
		self
			ensureMethodSource: 'sharedTarget

	^ ''instance-target'''
			protocol: 'testing'
			on: (self classNamed: subclassName).
		result := self
			          callToolNamed: 'method_equivalent_search'
			          withArguments: {
					          (#classNames -> { subclassName }).
					          (#className -> 'MCPToolMethodSearchReferenceFixture').
					          (#selector -> 'sharedTarget').
					          (#classSide -> false) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #totalCount) equals: 1.
		self
			entryForReference: subclassName , '>>sharedTarget'
			in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchRejectsDifferentAst [

	| data result subclassName |
	subclassName := 'MCPToolMethodSearchDifferentAstFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolMethodSearchReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
		self
			ensureMethodSource: 'sharedTarget

	^ ''different-target'''
			protocol: 'testing'
			on: (self classNamed: subclassName).
		result := self
			          callToolNamed: 'method_equivalent_search'
			          withArguments: {
					          (#classNames -> { subclassName }).
					          (#className -> 'MCPToolMethodSearchReferenceFixture').
					          (#selector -> 'sharedTarget').
					          (#classSide -> false) } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #totalCount) equals: 0.
		self assert: (data at: #methods) equals: #(  ) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchReturnsStructuredErrorWhenReferenceClassIsMissing [

	| error result |
	result := self
		          callToolNamed: 'method_equivalent_search'
		          withArguments: {
				          (#classNames
				           -> #( 'MCPToolMethodSearchReferenceFixture' )).
				          (#className -> 'MCPToolMethodSearchMissingReferenceClass').
				          (#selector -> 'sharedTarget').
				          (#classSide -> false) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolMethodSearchMissingReferenceClass'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchReturnsStructuredErrorWhenReferenceMethodIsMissing [

	| error result |
	result := self
		          callToolNamed: 'method_equivalent_search'
		          withArguments: {
				          (#classNames
				           -> #( 'MCPToolMethodSearchReferenceFixture' )).
				          (#className -> 'MCPToolMethodSearchReferenceFixture').
				          (#selector -> 'missingEquivalentTarget').
				          (#classSide -> false) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolMethodSearchReferenceFixture'.
	self assert: (error at: #selector) equals: 'missingEquivalentTarget'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testExactEmptyFilterIsApplied [

	| error result structured |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#protocol -> '').
			          (#filterMode -> 'exact') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPInvalidToolInput'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testHierarchyClassNamesReturnWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#side -> 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe'
		in: (data at: #methods).
	self
		entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testHierarchyClassNamesSelectHierarchyScope [

	| data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#side -> 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe'
		in: (data at: #methods).
	self
		entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testImageScopeReturnsInstanceAndClassImplementors [

	| data result |
	result := self callToolWith:
		          { (#selector -> 'sharedTarget') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture>>sharedTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture class>>sharedTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testMissingClassScopeReturnsPartialResultsAndWarnings [

	| data result selectors warnings |
	result := self callToolWith: { (#classNames -> {
			           self targetClassName.
			           'MCPDefinitelyMissingMethodSearchClass' }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 5.
	self assert: (selectors includes: 'alphaNeedleSelector').
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring:
			 'MCPDefinitelyMissingMethodSearchClass')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testMultipleScopesAreUnioned [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) > 5.
	self assert: (data at: #totalCount) < 20.
	self
		entryForReference: self targetClassName , '>>alphaNeedleSelector'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceTarget>>extensionProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testPackageNamesIncludeExtensionMethods [

	| data method result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )).
			          (#selector -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolMethodSearchReferenceTarget>>extensionProbe'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (method at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testPackageNamesSelectPackageScope [

	| data method result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )).
			          (#selector -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolMethodSearchReferenceTarget>>extensionProbe'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (method at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testParentClassNamesReturnParentMethods [

	| data result |
	result := self callToolWith: {
			          (#parentClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#side -> 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsStructuredErrorForInvalidRegex [

	| error result structured |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#selector -> '[').
			          (#filterMode -> 'regex') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #scope) equals: 'classes'.
	self assert: (error at: #errorClass) equals: 'RegexSyntaxError'.
	self assert:
		((error at: #message) includesSubstring: 'no terminating')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsWarningsAndEmptyResultsWhenClassIsMissing [

	| data result warnings |
	result := self callToolWith:
		          { (#classNames
		           -> #( 'MCPDefinitelyMissingMethodSearchClass' )) }
			          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring:
			 'MCPDefinitelyMissingMethodSearchClass').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsWarningsAndEmptyResultsWhenPackageIsMissing [

	| data result warnings |
	result := self callToolWith:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testScopeArgumentIsRejected [

	self
		should: [
		self callToolWith: { (#scope -> 'packages') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceCanIncludeFormattedSource [

	| data method result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments: {
				          (#selector -> 'sharedTarget').
				          (#side -> 'class').
				          (#includeSource -> true).
				          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolMethodSearchReferenceFixture class>>classSendShared'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert:
		((method at: #source) includesSubstring: 'self sharedTarget')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceClassNamesLimitToExactClasses [

	| data result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments: {
				          (#selector -> 'hierarchyTarget').
				          (#classNames -> #( 'MCPToolHierarchyTestChild' )) }
				          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceHierarchyClassNamesSearchWholeHierarchy [

	| data result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments: {
				          (#selector -> 'hierarchyTarget').
				          (#hierarchyClassNames -> #( 'MCPToolHierarchyTestMid' )) }
				          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>baseHierarchySender'
		in: (data at: #methods).
	self
		entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferencePackageNamesIncludeExtensionMethods [

	| data method result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments: {
				          (#selector -> 'extensionTarget').
				          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )) }
				          asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolMethodSearchReferenceTarget>>extensionSender'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (method at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceParentClassNamesSearchParents [

	| data result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments: {
				          (#selector -> 'hierarchyTarget').
				          (#parentClassNames -> #( 'MCPToolHierarchyTestMid' )) }
				          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestBase>>baseHierarchySender'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceRejectsEmptyFilter [

	| error result structured |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments: { (#selector -> '') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPInvalidToolInput'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceReturnsInstanceAndClassSenders [

	| data result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments:
		          { (#selector -> 'sharedTarget') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture>>instanceSendShared'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture class>>classSendShared'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceReturnsSelectorSendsNamedLikeClass [

	| data result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments:
		          { (#selector -> 'MCPToolMethodSearchReferenceTarget') }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture>>sendExistingClassNamedSelector'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchReferenceFixture class>>sendExistingClassNamedSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceSubclassClassNamesSearchSubclasses [

	| data result |
	result := self
		          callToolNamed: 'method_sender_search'
		          withArguments: {
				          (#selector -> 'hierarchyTarget').
				          (#subclassClassNames -> #( 'MCPToolHierarchyTestMid' )) }
				          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSubclassClassNamesReturnSubclassMethods [

	| data result |
	result := self callToolWith: {
			          (#subclassClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#side -> 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testToolDoesNotRequireArgumentsInSchema [

	self
		assert: MCPToolSearchMethodMetadata new inputSchema required
		equals: #(  )
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceCanIncludeFormattedSource [

	| data method result |
	result := self
		          callToolNamed: 'method_variable_reference_search'
		          withArguments: {
				          (#variableName -> 'trackedSlot').
				          (#side -> 'instance').
				          (#classNames
				           -> #( 'MCPToolMethodSearchVariableReferenceTarget' )).
				          (#includeSource -> true).
				          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolMethodSearchVariableReferenceTarget>>readTrackedSlot'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert: ((method at: #source) includesSubstring: 'trackedSlot')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceReturnsClassSideVariableReferences [

	| data result |
	result := self
		          callToolNamed: 'method_variable_reference_search'
		          withArguments: {
				          (#variableName -> 'trackedClassSlot').
				          (#side -> 'class').
				          (#classNames
				           -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }
				          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchVariableReferenceTarget class>>readTrackedClassSlot'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchVariableReferenceTarget class>>writeTrackedClassSlot'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceReturnsInstanceVariableReferences [

	| data result |
	result := self
		          callToolNamed: 'method_variable_reference_search'
		          withArguments: {
				          (#variableName -> 'trackedSlot').
				          (#side -> 'instance').
				          (#classNames
				           -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }
				          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolMethodSearchVariableReferenceTarget>>readTrackedSlot'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolMethodSearchVariableReferenceTarget>>writeTrackedSlot'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceReturnsStructuredErrorWhenVariableIsMissing [

	| error result structured |
	result := self
		          callToolNamed: 'method_variable_reference_search'
		          withArguments: {
				          (#variableName -> 'missingTrackedSlot').
				          (#classNames
				           -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }
				          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: ((error at: #message) includesSubstring:
			 'No variable named missingTrackedSlot')
]

{ #category : 'private - calling' }
MCPToolMethodSearchTest >> toolName [

	^ 'method_metadata_search'
]
