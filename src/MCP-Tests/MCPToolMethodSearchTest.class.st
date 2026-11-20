"
Tests the method_search tool.
"
Class {
	#name : 'MCPToolMethodSearchTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolMethodSearchTest >> targetClassName [

	^ MCPToolMethodSearchTestTarget name
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testAGlobalThatIsNotAClassIsSkippedFromAScope [

	| result |
	result := self callToolWith: { (self searchScope: { (#classes -> #( 'Transcript' )) }) } asDictionary.
	self assert: ((self dataFrom: result) at: #methods) isEmpty.
	self
		assert: (self warningsFrom: result)
		equals: #( 'Transcript is a global variable, not a class, so scope.classes skipped it.' )
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testAHierarchyEntryWrittenWithItsSideSelectsItsHierarchy [

	| plain sided |
	plain := self dataFrom: (self callToolWith: {
				          (self searchScope: { (#hierarchyOf -> #( 'MCPToolHierarchyTestMid' )) }).
				          (#query -> 'hierarchyProbe') } asDictionary).
	sided := self callToolWith: {
			         (self searchScope: { (#hierarchyOf -> #( 'MCPToolHierarchyTestMid class' )) }).
			         (#query -> 'hierarchyProbe') } asDictionary.
	self assert: (self warningsFrom: sided) isEmpty.
	self assert: ((self dataFrom: sided) at: #methods) equals: (plain at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testAScopeEntryWrittenWithItsSideSelectsItsClass [
	"A scope sweeps whole classes, and scope.side picks the sides, so Foo class selects Foo, without a warning: the rows print the side."

	| data result |
	result := self callToolWith: { (self searchScope: { (#classes -> { (self targetClassName , ' class') }) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (self warningsFrom: result) isEmpty.
	self
		assert: ((data at: #methods) collect: [ :each | each at: #selector ] as: Set)
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector' 'classUtility' 'gammaUtility' ) asSet.
	result := self callToolWith:
		          { (self searchScope: { (#classes -> { (self targetClassName , ' class') }) } side: 'class') } asDictionary.
	data := self dataFrom: result.
	self assert: (self warningsFrom: result) isEmpty.
	self deny: (data at: #methods) isEmpty.
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #side) = 'class' ]).
	self entryForReference: self targetClassName , ' class>>classNeedleSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testASearchGivenNothingToNarrowItSaysWhatNarrowsIt [
	"A search whose scope selects no class or package, and that keeps no selector or protocol, lists every method in the image, which is what a call sends when its client drops an argument the schema does not have. The answer names what narrows it, also when the scope keeps one side. A page built here stands in for a sweep of the image."

	| hint page tool |
	tool := MCPToolSearchMethods new.
	page := tool queryPageForEntries: (1 to: 30) asArray limit: 25 offset: 0.
	hint := ' This search names no class, package, selector or protocol: scope.classes keeps the methods of the classes it names, and query the methods whose selector contains its text.'.
	self
		assert: (self summaryOf: tool forArguments: Dictionary new page: page)
		equals: '25 of 30 methods in the image. Next page: offset 25, or narrow the search.' , hint.
	self
		assert: (self summaryOf: tool forArguments: { (self searchScope: { (#side -> 'class') }) } asDictionary page: page)
		equals: '25 of 30 methods in the image, class side. Next page: offset 25, or narrow the search.' , hint.
	self
		assert: (self summaryOf: tool forArguments: { (#protocol -> 'printing') } asDictionary page: page)
		equals: '25 of 30 methods match in the image. Next page: offset 25, or narrow the search.'.
	self
		assert: (self
				 summaryOf: tool
				 forArguments: { (self searchScope: { (#classes -> #( 'MCPToolMethodSearchTestTarget' )) }) } asDictionary
				 page: page)
		equals: '25 of 30 methods in MCPToolMethodSearchTestTarget. Next page: offset 25, or narrow the search.'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testCanFilterAcrossExplicitProtocolTarget [

	| data result selectors |
	result := self callToolWith: {
			          (self searchScope: { (#classes -> { self targetClassName }) }).
			          (#protocol -> 'helpers') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each | each at: #selector ].
	self assert: (data at: #methods) size equals: 2.
	self assert: selectors asSet equals: #( 'betaHelper' 'classUtility' ) asSet
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testCanFilterPaginateAndIncludeSource [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#classes -> { self targetClassName }) } side: 'class').
			          (#protocol -> 'meta') } asDictionary.
	data := self dataFrom: result.
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #side ifAbsent: [ 'instance' ]) = 'class' ]).
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #protocol) includesSubstring: 'meta' ]).
	self deny: ((data at: #methods) anySatisfy: [ :each | each includesKey: #source ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesLimitImplementorLookupToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#query -> 'hierarchyProbe').
			          (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestChild' )) }) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesReturnMethodsForExactClasses [

	| data result selectors |
	result := self callToolWith: { (self searchScope: { (#classes -> { self targetClassName }) }) } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each | each at: #selector ].
	self assert: (data at: #methods) size equals: 5.
	self assert: (data at: #methods) size equals: 5.
	self
		assert: selectors asSet
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector' 'classUtility' 'gammaUtility' ) asSet.
	self entryForReference: self targetClassName , ' class>>classNeedleSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesSelectExactClassScope [

	| data result selectors |
	result := self callToolWith: { (self searchScope: { (#classes -> { self targetClassName }) }) } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each | each at: #selector ].
	self assert: (data at: #methods) size equals: 5.
	self
		assert: selectors asSet
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector' 'classUtility' 'gammaUtility' ) asSet
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassScopeLeavesOutWhatTraitedClassInstalls [
	"Pharo installs TraitedClass's methods on the class side of every class using traits. Nobody wrote them there, so a sweep of the class leaves them out and lists what the class and its own traits define."

	| methods |
	methods := (self dataFrom:
		            (self callToolWith:
			             { (self searchScope: { (#classes -> { MCPToolMethodSearchTraitUser name }) } side: 'class') } asDictionary)) at:
		           #methods.
	self deny: (methods anySatisfy: [ :each | (each at: #trait ifAbsent: [ '' ]) = 'TraitedClass' ]).
	self assert: (self referencesOf: methods) equals: #( 'TMCPToolMethodSearchFixture class>>mcpTraitFixtureValue' )
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testDefaultExactSelectorFilterReturnsImplementors [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#classes -> { self targetClassName }) }).
			          (#query -> 'alphaNeedleSelector') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: self targetClassName , '>>alphaNeedleSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testDefaultFilterAppliesToSelectorOnly [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#classes -> { self targetClassName }) }).
			          (#query -> 'helpers') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 0.
	self assert: (data at: #methods) isEmpty
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testExactEmptyFilterIsApplied [
	"A blank filter matches nothing and is not missing either, so the answer says to leave it out."

	| error result |
	result := self callToolWith: {
			          (self searchScope: { (#classes -> { self targetClassName }) }).
			          (#protocol -> '') } asDictionary.
	error := self errorFrom: result.
	self assertResult: result refusesArgumentsSaying: 'protocol is blank; leave it out or give it a value.'.
	self assert: (error at: #errorClass) equals: 'MCPInvalidToolInput'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testImageScopeLeavesOutWhatTraitedClassInstalls [

	| methods |
	methods := (self dataFrom: (self callToolWith: {
				             (self searchScope: {  } side: 'class').
				             (#query -> 'findOriginClassOf:') } asDictionary)) at: #methods.
	self deny: (methods anySatisfy: [ :each | (each at: #trait ifAbsent: [ '' ]) = 'TraitedClass' ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testMissingClassScopeReturnsPartialResultsAndWarnings [

	| data result selectors warnings |
	result := self callToolWith: { (self searchScope: { (#classes -> {
				            self targetClassName.
				            'MCPDefinitelyMissingMethodSearchClass' }) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	selectors := (data at: #methods) collect: [ :each | each at: #selector ].
	self assert: (data at: #methods) size equals: 5.
	self assert: (selectors includes: 'alphaNeedleSelector').
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCPDefinitelyMissingMethodSearchClass')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testMissingScopeEntriesAreNamedByTheirKey [
	"A warning names the key as the schema spells it, never an internal label."

	| warnings |
	warnings := self warningsFrom: (self callToolWith: { (self searchScope: {
					              (#classes -> #( 'Zzqxw' )).
					              (#hierarchyOf -> #( 'Zzqxw' )).
					              (#superclassesOf -> #( 'Zzqxw' )).
					              (#subclassesOf -> #( 'Zzqxw' )).
					              (#packages -> #( 'Zzqxw-Package' )) }) } asDictionary).
	self
		assert: warnings asSet
		equals:
			#( 'Class Zzqxw does not exist, so scope.classes skipped it.' 'Class Zzqxw does not exist, so scope.hierarchyOf skipped it.'
			   'Class Zzqxw does not exist, so scope.superclassesOf skipped it.'
			   'Class Zzqxw does not exist, so scope.subclassesOf skipped it.'
			   'Package Zzqxw-Package does not exist, so scope.packages skipped it.' ) asSet
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testMultipleScopesAreUnioned [

	| data methods result |
	result := self callToolWith: { (self searchScope: {
				           (#classes -> { self targetClassName }).
				           (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }) } asDictionary.
	data := self dataFrom: result.
	methods := data at: #methods.
	self assert: methods isNotEmpty.
	self entryForReference: self targetClassName , '>>alphaNeedleSelector' in: methods.
	self entryForReference: 'MCPToolMethodSearchReferenceTarget>>extensionProbe' in: methods
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testPackageNamesIncludeExtensionMethods [

	| data method result |
	result := self callToolWith: {
			          (self searchScope: { (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }).
			          (#query -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self entryForReference: 'MCPToolMethodSearchReferenceTarget>>extensionProbe' in: (data at: #methods).
	self assert: (data at: #methods) size equals: 1.
	self assert: (method at: #package) equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testParentClassNamesReturnParentMethods [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )) } side: 'instance').
			          (#query -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testRegexMatcherReadsPerlCompatibleSyntax [

	| matcher |
	matcher := MCPToolSearchMethods new regexMatcherForPattern: '(?<=a)b' caseSensitive: true.
	self assert: (matcher value: 'ab').
	self deny: (matcher value: 'cb')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsWarningsAndEmptyResultsWhenClassIsMissing [

	| data result warnings |
	result := self callToolWith: { (self searchScope: { (#classes -> #( 'MCPDefinitelyMissingMethodSearchClass' )) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self assert: (data at: #methods) size equals: 0.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCPDefinitelyMissingMethodSearchClass').
	self assert: (warnings first includesSubstring: 'does not exist, so ').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsWarningsAndEmptyResultsWhenPackageIsMissing [

	| data result warnings |
	result := self callToolWith: { (self searchScope: { (#packages -> #( 'MCP-Definitely-Missing' )) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self assert: (data at: #methods) size equals: 0.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCP-Definitely-Missing')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testRowsDoNotRepeatExtensionBesideItsProtocol [
	"An extension's protocol names its package with a star, so its row leaves out isExtension; the data keeps it."

	| contentText result |
	result := self callToolWith: { (self searchScope: { (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }) } asDictionary.
	contentText := (result at: #content) first at: #text.
	self assert:
		(contentText includesSubstring: 'MCPToolMethodSearchReferenceTarget>>extensionProbe protocol=*MCP-Tests-Resources-Extensions').
	self deny: (contentText includesSubstring: 'isExtension').
	self assert: (((self dataFrom: result) at: #methods) anySatisfy: [ :each | each at: #isExtension ifAbsent: [ false ] ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testScopeArgumentIsRejected [

	self
		assertResult: (self callToolWith: { (#scope -> 'packages') } asDictionary)
		refusesArgumentsSaying: 'scope must be object, not string.'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSubclassClassNamesReturnSubclassMethods [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) } side: 'instance').
			          (#query -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSuperclassAndSubclassScopesReturnRelatedMethods [

	| data result |
	result := self callToolWith: {
			          (self
				           searchScope: {
						           (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )).
						           (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) }
				           side: 'instance').
			          (#query -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe' in: (data at: #methods).
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testToolDoesNotRequireArgumentsInSchema [

	| schema scopeProperty |
	schema := MCPToolSearchMethods new inputSchema.
	scopeProperty := schema properties detect: [ :each | each name = 'scope' ].
	self assert: MCPToolSearchMethods new name equals: 'method_search'.
	self assert: schema required equals: #(  ).
	self assert: (schema properties collect: [ :each | each name ] as: Set) equals: #( 'scope' 'query' 'protocol' 'offset' ) asSet.
	self assert: (scopeProperty extraProperties at: #additionalProperties) equals: false.
	self
		assert: ((scopeProperty extraProperties at: #properties) collect: [ :each | each name ] as: Set)
		equals: #( 'classes' 'packages' 'superclassesOf' 'subclassesOf' 'hierarchyOf' 'side' ) asSet
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testTraitedClassStillListsItsOwnMethods [
	"TraitedClass's own methods are its own, not copies, so a sweep of TraitedClass lists them."

	| data |
	(Smalltalk globals includesKey: #TraitedClass) ifFalse: [ ^ self skip: 'This Pharo has no TraitedClass.' ].
	data := self dataFrom: (self callToolWith: {
				         (self searchScope: { (#classes -> #( 'TraitedClass' )) } side: 'instance').
				         (#query -> 'allTraits') } asDictionary).
	self assert: ((self referencesOf: (data at: #methods)) includes: 'TraitedClass>>allTraits').
	data := self dataFrom:
		        (self callToolWith: { (self searchScope: { (#classes -> #( 'TraitedClass' )) } side: 'instance') } asDictionary).
	self assert: ((data at: #pagination) at: #totalCount) equals: (Smalltalk globals at: #TraitedClass) localMethods size
]

{ #category : 'private - calling' }
MCPToolMethodSearchTest >> toolName [

	^ 'method_search'
]
