"
Tests method metadata, source, equivalent, and reference search tools.
"
Class {
	#name : 'MCPToolMethodSearchTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolMethodSearchTest >> entryForReference: aReference in: methods [

	^ methods
		  detect: [ :each |
				  | reference |
				  reference := String streamContents: [ :stream |
						               stream nextPutAll: (each at: #class).
						               (each at: #side ifAbsent: [ 'instance' ]) = 'class' ifTrue: [ stream nextPutAll: ' class' ].
						               stream
							               nextPutAll: '>>';
							               nextPutAll: (each at: #selector) ].
				  reference = aReference ]
		  ifNone: [ self fail: 'Missing method ' , aReference ]
]

{ #category : 'private' }
MCPToolMethodSearchTest >> referencesOf: methodEntries [

	^ methodEntries collect: [ :each | MCPToolSearchMethods new methodEntryLabel: each ] as: Array
]

{ #category : 'private' }
MCPToolMethodSearchTest >> targetClassName [

	^ MCPToolMethodSearchTestTarget name
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testAClassOverridingATraitMethodKeepsItsOwnAnswer [

	| entries entry |
	entries := self traitFixtureImplementors.
	entry := self entryForReference: 'MCPToolMethodSearchTraitOverrider>>mcpTraitFixtureValue' in: entries.
	self deny: (entry includesKey: #installedIn).
	self deny: (entry includesKey: #trait)
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
				          (#selector -> 'hierarchyProbe') } asDictionary).
	sided := self callToolWith: {
			         (self searchScope: { (#hierarchyOf -> #( 'MCPToolHierarchyTestMid class' )) }).
			         (#selector -> 'hierarchyProbe') } asDictionary.
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
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #side ifAbsent: [ 'instance' ]) = 'class' ]).
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #protocol) includesSubstring: 'meta' ]).
	self deny: ((data at: #methods) anySatisfy: [ :each | each includesKey: #source ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesLimitImplementorLookupToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#selector -> 'hierarchyProbe').
			          (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestChild' )) }) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassNamesReturnMethodsForExactClasses [

	| data result selectors |
	result := self callToolWith: { (self searchScope: { (#classes -> { self targetClassName }) }) } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each | each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
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
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 5.
	self
		assert: selectors asSet
		equals: #( 'alphaNeedleSelector' 'betaHelper' 'classNeedleSelector' 'classUtility' 'gammaUtility' ) asSet
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceClassScopeReturnsClassGlobalReferences [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#name -> 'MCPToolMethodSearchReferenceTarget').
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchReferenceFixture' )) }) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceDoesNotIncludeSelectorSendsNamedLikeClass [

	| data result selectors |
	result := self
		          callToolNamed: 'method_reference_search'
		          withArguments: { (#name -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each | each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self deny: (selectors includes: 'sendExistingClassNamedSelector')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceFindsAMethodThatNamesTheClassByAnAlias [
	"A global may hold a class under another name, as Pharo 14's deprecated aliases do, such as RBParser for OCParser. A method that names the alias refers to the class, in its body or in a block, so a search by either name finds it beside the methods that name the class itself. The classes are named by string, so that this test adds no reference to them."

	| aliasName writer writerName |
	aliasName := 'MCPToolMethodSearchReferenceTargetAlias'.
	writerName := 'MCPToolMethodSearchAliasWriter'.
	[
		Smalltalk globals at: aliasName asSymbol put: (self classNamed: 'MCPToolMethodSearchReferenceTarget').
		writer := self
			          createClassNamed: writerName
			          superclassName: 'Object'
			          slots: #(  )
			          classSlots: #(  ).
		self ensureMethodSource: 'writesAlias ^ ' , aliasName protocol: 'testing' on: writer.
		self ensureMethodSource: ('writesAliasInABlock ^ [ {1} ] value' format: { aliasName }) protocol: 'testing' on: writer.
		{
			'MCPToolMethodSearchReferenceTarget'.
			aliasName } do: [ :name |
				| methods result |
				result := self callToolNamed: 'method_reference_search' withArguments: {
						          (#name -> name).
						          (#kind -> 'class').
						          (self searchScope: { (#classes -> {
								            writerName.
								            'MCPToolMethodSearchReferenceFixture' }) }) } asDictionary.
				self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
				methods := (self dataFrom: result) at: #methods.
				self assert: methods size equals: 4.
				self entryForReference: writerName , '>>writesAlias' in: methods.
				self entryForReference: writerName , '>>writesAliasInABlock' in: methods.
				self entryForReference: 'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget' in: methods.
				self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget' in: methods ] ] ensure: [
			self removeClassNamed: writerName.
			Smalltalk globals removeKey: aliasName asSymbol ifAbsent: [ ] ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceReturnsInstanceAndClassGlobalReferences [

	| data result |
	result := self
		          callToolNamed: 'method_reference_search'
		          withArguments: { (#name -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>referenceExtensionTarget' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>referenceExtensionTarget' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testClassReferenceReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self
		          callToolNamed: 'method_reference_search'
		          withArguments: { (#name -> 'MCPDefinitelyMissingReferenceClass') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: ((error at: #message) includesSubstring: 'There is no class, variable or selector named MCPDefinitelyMissingReferenceClass')
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
			          (#selector -> 'alphaNeedleSelector') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: self targetClassName , '>>alphaNeedleSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testDefaultFilterAppliesToSelectorOnly [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#classes -> { self targetClassName }) }).
			          (#selector -> 'helpers') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #methods) size equals: 0.
	self assert: (data at: #methods) isEmpty
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testDirectionalScopesAreUnionedForMethods [

	| data result |
	result := self callToolWith: {
			          (self searchScope: {
					           (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )).
					           (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )) } side: 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe' in: (data at: #methods).
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
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
		result := self callToolNamed: 'method_equivalent_search' withArguments: {
				          (self searchScope: { (#classes -> { subclassName }) }).
				          (#class -> 'MCPToolMethodSearchReferenceFixture').
				          (#selector -> 'sharedTarget') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #methods) size equals: 1.
		self entryForReference: subclassName , '>>sharedTarget' in: (data at: #methods) ] ensure: [ self removeClassNamed: subclassName ]
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
		result := self callToolNamed: 'method_equivalent_search' withArguments: {
				          (self searchScope: { (#classes -> { subclassName }) } side: 'class').
				          (#class -> 'MCPToolMethodSearchReferenceFixture').
				          (#selector -> 'sharedTarget').
				          (#side -> 'class') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #methods) size equals: 1.
		self entryForReference: subclassName , ' class>>sharedTarget' in: (data at: #methods) ] ensure: [
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
		result := self callToolNamed: 'method_equivalent_search' withArguments: {
				          (self searchScope: { (#classes -> { subclassName }) }).
				          (#class -> 'MCPToolMethodSearchReferenceFixture').
				          (#selector -> 'sharedTarget').
				          (#side -> 'instance') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #methods) size equals: 1.
		self entryForReference: subclassName , '>>sharedTarget' in: (data at: #methods) ] ensure: [ self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchReadsAReferenceClassWrittenWithItsSide [

	| data result subclass subclassName |
	subclassName := 'MCPToolMethodSearchEquivalentSidedFixture'.
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
		result := self callToolNamed: 'method_equivalent_search' withArguments: {
				          (self searchScope: { (#classes -> { subclassName }) } side: 'class').
				          (#class -> 'MCPToolMethodSearchReferenceFixture class').
				          (#selector -> 'sharedTarget') } asDictionary.
		data := self dataFrom: result.
		self assert: (data at: #methods) size equals: 1.
		self entryForReference: subclassName , ' class>>sharedTarget' in: (data at: #methods) ] ensure: [
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
		result := self callToolNamed: 'method_equivalent_search' withArguments: {
				          (self searchScope: { (#classes -> { subclassName }) }).
				          (#class -> 'MCPToolMethodSearchReferenceFixture').
				          (#selector -> 'sharedTarget').
				          (#side -> 'instance') } asDictionary.
		data := self dataFrom: result.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (data at: #methods) size equals: 0.
		self assert: (data at: #methods) equals: #(  ) ] ensure: [ self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchReturnsStructuredErrorWhenReferenceClassIsMissing [

	| error result |
	result := self callToolNamed: 'method_equivalent_search' withArguments: {
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchReferenceFixture' )) }).
			          (#class -> 'MCPToolMethodSearchMissingReferenceClass').
			          (#selector -> 'sharedTarget').
			          (#side -> 'instance') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolMethodSearchMissingReferenceClass'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchReturnsStructuredErrorWhenReferenceMethodIsMissing [

	| error result |
	result := self callToolNamed: 'method_equivalent_search' withArguments: {
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchReferenceFixture' )) }).
			          (#class -> 'MCPToolMethodSearchReferenceFixture').
			          (#selector -> 'missingEquivalentTarget').
			          (#side -> 'instance') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self assert: (error at: #class) equals: 'MCPToolMethodSearchReferenceFixture'.
	self assert: (error at: #selector) equals: 'missingEquivalentTarget'.
	self assert: (error at: #side) equals: 'instance'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testEquivalentSearchSummaryNamesTheReferenceMethod [

	| result |
	result := self callToolNamed: 'method_equivalent_search' withArguments: {
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchReferenceFixture' )) } side: 'class').
			          (#class -> 'MCPToolMethodSearchReferenceFixture').
			          (#selector -> 'sharedTarget').
			          (#side -> 'class') } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals:
		'1 method equivalent to MCPToolMethodSearchReferenceFixture class>>sharedTarget in MCPToolMethodSearchReferenceFixture, class side.'.
	result := self callToolNamed: 'method_equivalent_search' withArguments: {
			          (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestMid' )) }).
			          (#class -> 'MCPToolMethodSearchReferenceFixture').
			          (#selector -> 'sharedTarget') } asDictionary.
	self
		assert: (self summaryFrom: result)
		equals: 'No methods equivalent to MCPToolMethodSearchReferenceFixture>>sharedTarget in MCPToolHierarchyTestMid.'
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
				             (#selector -> 'findOriginClassOf:') } asDictionary)) at: #methods.
	self deny: (methods anySatisfy: [ :each | (each at: #trait ifAbsent: [ '' ]) = 'TraitedClass' ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testImageScopeReturnsInstanceAndClassImplementors [

	| entries scopeQuery selector tool |
	selector := #mcpImageScopeUniqueTarget.
	scopeQuery := MCPMethodSearchImageScopeQueryTestDouble new
		              behaviors: {
				              MCPToolMethodSearchReferenceFixture.
				              MCPToolMethodSearchReferenceFixture class };
		              yourself.
	tool := MCPToolSearchMethodReferences new.
	entries := tool
		           queryEntriesForRequest: (tool requestFromToolCallArguments: {
					            (#name -> selector asString).
					            (#kind -> 'implementors') } asDictionary)
		           scopeQuery: scopeQuery.
	self assert: entries size equals: 2.
	self
		entryForReference: (String streamContents: [ :stream | stream << MCPToolMethodSearchReferenceFixture name << '>>' << selector ])
		in: entries.
	self
		entryForReference:
		(String streamContents: [ :stream | stream << MCPToolMethodSearchReferenceFixture name << ' class>>' << selector ])
		in: entries
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testImplementorsLeaveOutWhatTraitedClassInstalls [
	"An implementor lookup reads the behaviors of its scope itself, and leaves out the copies TraitedClass installs as a sweep does."

	| result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'implementors').
			          (#name -> 'allTraits').
			          (self searchScope: { (#classes -> { MCPToolMethodSearchTraitUser name }) }) } asDictionary.
	self assert: ((self dataFrom: result) at: #methods) isEmpty
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
	self deny: (result at: #isError ifAbsent: [ false ]).
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
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: methods isNotEmpty.
	self entryForReference: self targetClassName , '>>alphaNeedleSelector' in: methods.
	self entryForReference: 'MCPToolMethodSearchReferenceTarget>>extensionProbe' in: methods
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testPackageNamesIncludeExtensionMethods [

	| data method result |
	result := self callToolWith: {
			          (self searchScope: { (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }).
			          (#selector -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self entryForReference: 'MCPToolMethodSearchReferenceTarget>>extensionProbe' in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self assert: (method at: #package) equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testPackageNamesSelectPackageScope [

	| data method result |
	result := self callToolWith: {
			          (self searchScope: { (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }).
			          (#selector -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self entryForReference: 'MCPToolMethodSearchReferenceTarget>>extensionProbe' in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self assert: (method at: #package) equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testParentClassNamesReturnParentMethods [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )) } side: 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testRegexMatcherUsesBasicRegexWhenPCRE2Unavailable [

	| matcher tool |
	tool := MCPToolSearchWithoutPCRE2TestStub new.
	matcher := tool regexMatcherForPattern: 'MCP.*Test' caseSensitive: true.
	self assert: (matcher value: 'MCPToolMethodSearchTest').
	self deny: (matcher value: 'mcpToolMethodSearchTest')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testRegexMatcherUsesPCRE2WhenLibraryAvailable [

	| matcher tool |
	tool := MCPToolSearchMethods new.
	tool pcre2RegexLibraryAvailable ifFalse: [ self skip: 'PCRE2 native library unavailable' ].
	matcher := tool regexMatcherForPattern: '(?<=a)b' caseSensitive: true.
	self assert: (matcher value: 'ab').
	self deny: (matcher value: 'cb')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsStructuredErrorForInvalidRegex [

	| error result |
	result := self callToolNamed: 'method_source_search' withArguments: {
		          (self searchScope: { (#classes -> { self targetClassName }) }).
		          (#filterMode -> 'regex').
		          (#filter -> '[') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'RegexSyntaxError'.
	self assert: ((error at: #message) includesSubstring: 'terminating')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsWarningsAndEmptyResultsWhenClassIsMissing [

	| data result warnings |
	result := self callToolWith: { (self searchScope: { (#classes -> #( 'MCPDefinitelyMissingMethodSearchClass' )) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 0.
	self assert: (data at: #methods) isEmpty.
	self assert: warnings size equals: 1.
	self assert: (warnings first includesSubstring: 'MCPDefinitelyMissingMethodSearchClass').
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testReturnsWarningsAndEmptyResultsWhenPackageIsMissing [

	| data result warnings |
	result := self callToolWith: { (self searchScope: { (#packages -> #( 'MCP-Definitely-Missing' )) }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
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
MCPToolMethodSearchTest >> testSelectorReferenceClassNamesLimitToExactClasses [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#name -> 'hierarchyTarget').
			          (self searchScope: { (#classes -> #( 'MCPToolHierarchyTestChild' )) }) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferencePackageNamesIncludeExtensionMethods [

	| data method result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#name -> 'extensionTarget').
			          (self searchScope: { (#packages -> #( 'MCP-Tests-Resources-Extensions' )) }) } asDictionary.
	data := self dataFrom: result.
	method := self entryForReference: 'MCPToolMethodSearchReferenceTarget>>extensionSender' in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self assert: (method at: #package) equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceParentClassNamesSearchParents [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#name -> 'hierarchyTarget').
			          (self searchScope: { (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )) }) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestBase>>baseHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceRejectsEmptyFilter [

	| error result structured |
	result := self callToolNamed: 'method_reference_search' withArguments: { (#kind -> 'senders').
			          (#name -> '') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPInvalidToolInput'
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceReturnsInstanceAndClassSenders [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: { (#kind -> 'senders').
			          (#name -> 'sharedTarget') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>instanceSendShared' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>classSendShared' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceReturnsSelectorSendsNamedLikeClass [

	| data result |
	result := self
		          callToolNamed: 'method_reference_search'
		          withArguments: { (#kind -> 'senders').
			          (#name -> 'MCPToolMethodSearchReferenceTarget') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchReferenceFixture>>sendExistingClassNamedSelector' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchReferenceFixture class>>sendExistingClassNamedSelector' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceSubclassClassNamesSearchSubclasses [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#name -> 'hierarchyTarget').
			          (self searchScope: { (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) }) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSelectorReferenceSuperclassAndSubclassScopesSearchRelatedMethods [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'senders').
			          (#name -> 'hierarchyTarget').
			          (self searchScope: {
					           (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )).
					           (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) }) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolHierarchyTestBase>>baseHierarchySender' in: (data at: #methods).
	self entryForReference: 'MCPToolHierarchyTestChild>>childHierarchySender' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSourceHitsReadAsLineNumberAndText [
	"A source hit reads like grep: the method, then the number and text of the line that matched, unquoted; the data keeps both as fields."

	| contentText result |
	result := self callToolNamed: 'method_source_search' withArguments: {
			          (#filter -> 'SharedLimit').
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary.
	contentText := (result at: #content) first at: #text.
	self assert: (contentText lines includes:
			 '  MCPToolGetMethodTestTarget>>readInstanceWith: line 4: local := instanceCounter ifNil: [ SharedLimit ].').
	self assert: (contentText lines includes:
			 '  MCPToolGetMethodTestTarget class>>readClassSide line 4: local := classCounter ifNil: [ SharedLimit ].').
	self deny: (contentText includesSubstring: 'lineNumber=').
	self deny: (contentText includesSubstring: 'line="').
	self deny: (contentText includesSubstring: 'protocol=').
	self assert: (((self dataFrom: result) at: #methods) allSatisfy: [ :each |
			 (each at: #lineNumber) = 4 and: [ (each includesKey: #line) and: [ each includesKey: #protocol ] ] ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSourceSearchShowsTheLineThatMatched [

	| data result |
	result := self
		          callToolNamed: 'method_source_search'
		          withArguments: {
			          (#filter -> 'instanceCounter').
			          (self searchScope: { (#classes -> #( 'MCPToolGetMethodTestTarget' )) }) } asDictionary.
	data := self dataFrom: result.
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #methods) isNotEmpty.
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #line) includesSubstring: 'instanceCounter' ]).
	self assert: ((data at: #methods) allSatisfy: [ :each | (each at: #lineNumber) > 0 ]).
	self deny: ((data at: #methods) anySatisfy: [ :each | each includesKey: #source ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSubclassClassNamesReturnSubclassMethods [

	| data result |
	result := self callToolWith: {
			          (self searchScope: { (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) } side: 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 1.
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSuperclassAndSubclassScopesReturnRelatedMethods [

	| data result |
	result := self callToolWith: {
			          (self searchScope: {
					           (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )).
					           (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) } side: 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe' in: (data at: #methods).
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testSuperclassAndSubclassScopesSelectRelatedScope [

	| data result |
	result := self callToolWith: {
			          (self searchScope: {
					           (#superclassesOf -> #( 'MCPToolHierarchyTestMid' )).
					           (#subclassesOf -> #( 'MCPToolHierarchyTestMid' )) } side: 'instance').
			          (#selector -> 'hierarchyProbe') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolHierarchyTestBase>>hierarchyProbe' in: (data at: #methods).
	self entryForReference: 'MCPToolHierarchyTestChild>>hierarchyProbe' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testToolDoesNotRequireArgumentsInSchema [

	self assert: MCPToolSearchMethods new inputSchema required equals: #(  )
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testTraitMethodCopiesAreAnsweredOnceAsTheTraitDefiningThem [

	| entries entry |
	entries := self traitFixtureImplementors.
	entry := self entryForReference: 'TMCPToolMethodSearchFixture>>mcpTraitFixtureValue' in: entries.
	self assert: (entry at: #installedIn) asArray equals: {
			MCPToolMethodSearchTraitOtherUser name.
			MCPToolMethodSearchTraitUser name }.
	self deny: (entries anySatisfy: [ :each | (each at: #class) = MCPToolMethodSearchTraitUser name ])
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testTraitMethodCopiesAreAnsweredOncePerSide [

	| entries entry |
	entries := self traitFixtureImplementors.
	self assert: entries size equals: 3.
	entry := self entryForReference: 'TMCPToolMethodSearchFixture class>>mcpTraitFixtureValue' in: entries.
	self assert: (entry at: #installedIn) asArray equals: {
			MCPToolMethodSearchTraitOtherUser name.
			MCPToolMethodSearchTraitOverrider name.
			MCPToolMethodSearchTraitUser name }
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testTraitedClassStillListsItsOwnMethods [
	"TraitedClass's own methods are its own, not copies, so a sweep of TraitedClass lists them."

	| data |
	(Smalltalk globals includesKey: #TraitedClass) ifFalse: [ ^ self skip: 'This Pharo has no TraitedClass.' ].
	data := self dataFrom: (self callToolWith: {
				         (self searchScope: { (#classes -> #( 'TraitedClass' )) } side: 'instance').
				         (#selector -> 'allTraits') } asDictionary).
	self assert: ((self referencesOf: (data at: #methods)) includes: 'TraitedClass>>allTraits').
	data := self dataFrom:
		        (self callToolWith: { (self searchScope: { (#classes -> #( 'TraitedClass' )) } side: 'instance') } asDictionary).
	self assert: ((data at: #pagination) at: #totalCount) equals: (Smalltalk globals at: #TraitedClass) localMethods size
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceLooksForASlotOnlyInTheClassesThatHaveIt [
	"A method reaches a slot by its index, which another class gives to a slot of its own. Here sharedSlot is the third slot of one class and the second of another, so the first class's betaSlot, its second slot, is not a use of sharedSlot. A subclass's method uses the sharedSlot it inherits."

	| heirName methods ownerName strangerName |
	ownerName := 'MCPToolMethodSearchSlotOwner'.
	strangerName := 'MCPToolMethodSearchSlotStranger'.
	heirName := 'MCPToolMethodSearchSlotHeir'.
	[
		| heir owner stranger |
		owner := self
			         createClassNamed: ownerName
			         superclassName: 'Object'
			         slots: #( alphaSlot betaSlot sharedSlot )
			         classSlots: #(  ).
		stranger := self
			            createClassNamed: strangerName
			            superclassName: 'Object'
			            slots: #( gammaSlot sharedSlot )
			            classSlots: #(  ).
		heir := self
			        createClassNamed: heirName
			        superclassName: ownerName
			        slots: #(  )
			        classSlots: #(  ).
		self ensureMethodSource: 'readBetaSlot ^ betaSlot' protocol: 'accessing' on: owner.
		self ensureMethodSource: 'readSharedSlot ^ sharedSlot' protocol: 'accessing' on: owner.
		self ensureMethodSource: 'readSharedSlot ^ sharedSlot' protocol: 'accessing' on: stranger.
		self ensureMethodSource: 'writeSharedSlot: anObject sharedSlot := anObject' protocol: 'accessing' on: heir.
		methods := (self dataFrom: (self callToolNamed: 'method_reference_search' withArguments: {
					             (#name -> 'sharedSlot').
					             (#kind -> 'variable').
					             (self searchScope: { (#packages -> { self generatedPackageName }) }) } asDictionary)) at: #methods.
		self assert: (self referencesOf: methods) equals: {
				(heirName , '>>writeSharedSlot:').
				(ownerName , '>>readSharedSlot').
				(strangerName , '>>readSharedSlot') } ] ensure: [
			{
				heirName.
				ownerName.
				strangerName } do: [ :each | self removeClassNamed: each ] ]
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceReturnsClassSideVariableReferences [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#name -> 'trackedClassSlot').
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) } side: 'class') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: 'MCPToolMethodSearchVariableReferenceTarget class>>readTrackedClassSlot' in: (data at: #methods).
	self entryForReference: 'MCPToolMethodSearchVariableReferenceTarget class>>writeTrackedClassSlot' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceReturnsInstanceVariableReferences [

	| data result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#name -> 'trackedSlot').
			          (self searchScope: { (#classes -> { MCPToolMethodSearchVariableReferenceTarget name }) } side: 'instance') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #methods) size equals: 2.
	self entryForReference: MCPToolMethodSearchVariableReferenceTarget name , '>>readTrackedSlot' in: (data at: #methods).
	self entryForReference: MCPToolMethodSearchVariableReferenceTarget name , '>>writeTrackedSlot' in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolMethodSearchTest >> testVariableReferenceReturnsStructuredErrorWhenVariableIsMissing [

	| error result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#name -> 'missingTrackedSlot').
			          (#kind -> 'variable').
			          (self searchScope: { (#classes -> #( 'MCPToolMethodSearchVariableReferenceTarget' )) }) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert:
		((error at: #message) includesSubstring: 'No variable named missingTrackedSlot is accessible in the requested scope.')
]

{ #category : 'private - calling' }
MCPToolMethodSearchTest >> toolName [

	^ 'method_search'
]

{ #category : 'private' }
MCPToolMethodSearchTest >> traitFixtureImplementors [

	| result |
	result := self callToolNamed: 'method_reference_search' withArguments: {
			          (#kind -> 'implementors').
			          (#name -> 'mcpTraitFixtureValue').
			          (self searchScope: { (#classes -> {
							            TMCPToolMethodSearchFixture name.
							            MCPToolMethodSearchTraitUser name.
							            MCPToolMethodSearchTraitOtherUser name.
							            MCPToolMethodSearchTraitOverrider name }) }) } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	^ (self dataFrom: result) at: #methods
]
