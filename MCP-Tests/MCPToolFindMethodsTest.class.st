Class {
	#name : 'MCPToolFindMethodsTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolFindMethodsTest >> entryForReference: aReference in: methods [

	^ methods
		  detect: [ :each |
			  | reference |
			  reference := String streamContents: [ :stream |
				               stream nextPutAll: (each at: #className).
				               (each at: #side) = 'class' ifTrue: [
					               stream nextPutAll: ' class' ].
				               stream
					               nextPutAll: '>>';
					               nextPutAll: (each at: #selector) ].
			  reference = aReference ]
		  ifNone: [ self fail: 'Missing method ' , aReference ]
]

{ #category : 'private' }
MCPToolFindMethodsTest >> equivalentToWhereForClassName: aClassName selector: aSelector classSide: aBoolean [

	^ { (#equivalentTo -> {
		   (#className -> aClassName).
		   (#selector -> aSelector).
		   (#classSide -> aBoolean) } asDictionary) } asDictionary
]

{ #category : 'private' }
MCPToolFindMethodsTest >> targetClassName [

	^ 'MCPToolFindMethodsTestTarget'
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testCanFilterAcrossExplicitProtocolTarget [

	| data result selectors |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'helpers').
			          (#filterTargets -> #( 'protocol' )).
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
MCPToolFindMethodsTest >> testCanFilterAcrossExplicitScopeWithoutIncludingSource [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'gamma value').
			          (#filterTargets -> #( 'source' )).
			          (#filterMode -> 'substring') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: ((data at: #methods) first at: #selector)
		equals: 'gammaUtility'.
	self deny: ((data at: #methods) first includesKey: #source)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testCanFilterPaginateAndIncludeSource [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#side -> 'class').
			          (#filter -> 'meta').
			          (#filterTargets -> #( 'protocol' )).
			          (#filterMode -> 'substring').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #methods) size equals: 1.
	self assert:
		((data at: #methods) allSatisfy: [ :each |
			 (each at: #side) = 'class' ]).
	self assert: ((data at: #methods) allSatisfy: [ :each |
			 (each at: #protocol) includesSubstring: 'meta' ]).
	self assert:
		((data at: #methods) allSatisfy: [ :each |
			 each includesKey: #source ]).
	self assert: ((data at: #methods) anySatisfy: [ :each |
			 (each at: #source) includesSubstring: String cr asString ])
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testCanIncludeFormattedSourceForImplementorLookup [

	| data method result |
	result := self callToolWith: {
			          (#filter -> 'sharedTarget').
			          (#side -> 'class').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolFindMethodsReferenceFixture class>>sharedTarget'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert:
		((method at: #source) includesSubstring: String cr asString)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testCaseInsensitiveExactSelectorFilterKeepsGeneralFilteringSemantics [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'ALPHANEEDLESELECTOR').
			          (#caseSensitive -> false) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: self targetClassName , '>>alphaNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassNamesLimitImplementorLookupToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'hierarchyProbe').
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
MCPToolFindMethodsTest >> testClassNamesReturnMethodsForExactClasses [

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
MCPToolFindMethodsTest >> testClassNamesSelectExactClassScope [

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
MCPToolFindMethodsTest >> testClassReferenceCanIncludeFormattedSource [

	| data method result |
	result := self callToolWith: {
			          (#filter -> 'MCPToolFindMethodsReferenceTarget').
			          (#filterMode -> 'classReference').
			          (#side -> 'class').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolFindMethodsReferenceFixture class>>referenceExtensionTarget'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert: ((method at: #source) includesSubstring:
			 'MCPToolFindMethodsReferenceTarget')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassReferenceClassScopeFindsClassGlobalReferences [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'MCPToolFindMethodsReferenceTarget').
			          (#filterMode -> 'classReference').
			          (#classNames -> #( 'MCPToolFindMethodsReferenceFixture' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>referenceExtensionTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>referenceExtensionTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassReferenceDoesNotIncludeSelectorSendsNamedLikeClass [

	| data result selectors |
	result := self callToolWith: {
			          (#filter -> 'MCPToolFindMethodsReferenceTarget').
			          (#filterMode -> 'classReference') } asDictionary.
	data := self dataFrom: result.
	selectors := (data at: #methods) collect: [ :each |
		             each at: #selector ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self deny: (selectors includes: 'sendExistingClassNamedSelector')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassReferenceFindsInstanceAndClassGlobalReferences [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'MCPToolFindMethodsReferenceTarget').
			          (#filterMode -> 'classReference') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>referenceExtensionTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>referenceExtensionTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassReferenceIgnoresFilterTargets [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'MCPToolFindMethodsReferenceTarget').
			          (#filterMode -> 'classReference').
			          (#filterTargets -> #( 'protocol' )) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>referenceExtensionTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>referenceExtensionTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassReferenceRequiresFilter [

	self
		should: [
			self callToolWith:
				{ (#filterMode -> 'classReference') } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testClassReferenceReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#filter -> 'MCPDefinitelyMissingReferenceClass').
			          (#filterMode -> 'classReference') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: ((error at: #message) includesSubstring:
			 'There is no class named MCPDefinitelyMissingReferenceClass')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testDefaultExactSelectorFilterFindsImplementors [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'alphaNeedleSelector') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: self targetClassName , '>>alphaNeedleSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testDefaultFilterAppliesToSelectorOnly [

	| data result |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#filter -> 'helpers') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #methods) isEmpty
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testHierarchyClassNamesReturnWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#side -> 'instance').
			          (#filter -> 'hierarchyProbe') } asDictionary.
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
MCPToolFindMethodsTest >> testHierarchyClassNamesSelectHierarchyScope [

	| data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> #( 'MCPToolHierarchyTestMid' )).
			          (#side -> 'instance').
			          (#filter -> 'hierarchyProbe') } asDictionary.
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
MCPToolFindMethodsTest >> testImageScopeFindsInstanceAndClassImplementors [

	| data result |
	result := self callToolWith:
		          { (#filter -> 'sharedTarget') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>sharedTarget'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>sharedTarget'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testMultipleScopesAreUnioned [

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
		'MCPToolFindMethodsReferenceTarget>>extensionProbe'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testPackageNamesIncludeExtensionMethods [

	| data method result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )).
			          (#filter -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolFindMethodsReferenceTarget>>extensionProbe'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (method at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testPackageNamesSelectPackageScope [

	| data method result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )).
			          (#filter -> 'extensionProbe') } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolFindMethodsReferenceTarget>>extensionProbe'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (method at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testReturnsStructuredErrorForInvalidFilterTarget [

	self
		should: [
			self callToolWith: {
					(#classNames -> { self targetClassName }).
					(#filter -> 'needle').
					(#filterTargets -> #( 'bogus' )) } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testReturnsStructuredErrorForInvalidRegex [

	| error result structured |
	result := self callToolWith: {
			          (#classNames -> { self targetClassName }).
			          (#filter -> '[').
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
MCPToolFindMethodsTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith:
		          { (#classNames
		           -> #( 'MCPDefinitelyMissingFindMethodsClass' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPDefinitelyMissingFindMethodsClass'.
	self assert: (error at: #scope) equals: 'classes'
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testReturnsStructuredErrorWhenPackageIsMissing [

	| error result structured |
	result := self callToolWith:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'PackageNotFound'.
	self
		assert: (error at: #packageName)
		equals: 'MCP-Definitely-Missing'.
	self assert: (error at: #scope) equals: 'packages'
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testScopeArgumentIsRejected [

	self
		should: [
		self callToolWith: { (#scope -> 'packages') } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testSelectorReferenceCanIncludeFormattedSource [

	| data method result |
	result := self callToolWith: {
			          (#filter -> 'sharedTarget').
			          (#filterMode -> 'selectorReference').
			          (#side -> 'class').
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolFindMethodsReferenceFixture class>>classSendShared'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert:
		((method at: #source) includesSubstring: 'self sharedTarget')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testSelectorReferenceClassNamesLimitToExactClasses [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'hierarchyTarget').
			          (#filterMode -> 'selectorReference').
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
MCPToolFindMethodsTest >> testSelectorReferenceFindsInstanceAndClassSenders [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'sharedTarget').
			          (#filterMode -> 'selectorReference') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolFindMethodsReferenceFixture>>instanceSendShared'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>classSendShared'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testSelectorReferenceFindsSelectorSendsNamedLikeClass [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'MCPToolFindMethodsReferenceTarget').
			          (#filterMode -> 'selectorReference') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>sendExistingClassNamedSelector'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>sendExistingClassNamedSelector'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testSelectorReferenceHierarchyClassNamesSearchWholeHierarchy [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'hierarchyTarget').
			          (#filterMode -> 'selectorReference').
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
MCPToolFindMethodsTest >> testSelectorReferenceIgnoresFilterTargets [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'sharedTarget').
			          (#filterMode -> 'selectorReference').
			          (#filterTargets -> #( 'protocol' )) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference: 'MCPToolFindMethodsReferenceFixture>>instanceSendShared'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture class>>classSendShared'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testSelectorReferencePackageNamesIncludeExtensionMethods [

	| data method result |
	result := self callToolWith: {
			          (#filter -> 'extensionTarget').
			          (#filterMode -> 'selectorReference').
			          (#packageNames -> #( 'MCP-Tests-Resources-Extensions' )) }
			          asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolFindMethodsReferenceTarget>>extensionSender'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: (method at: #packageName)
		equals: 'MCP-Tests-Resources-Extensions'.
	self assert: (method at: #isExtension)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testSelectorReferenceRequiresFilter [

	self
		should: [
			self callToolWith:
				{ (#filterMode -> 'selectorReference') } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testToolDoesNotRequireArgumentsInSchema [

	self
		assert: MCPToolFindMethods new inputSchema required
		equals: #(  )
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testVariableReferenceCanIncludeFormattedSource [

	| data method result |
	result := self callToolWith: {
			          (#filter -> 'trackedSlot').
			          (#filterMode -> 'variableReference').
			          (#side -> 'instance').
			          (#classNames
			           -> #( 'MCPToolFindMethodsVariableReferenceTarget' )).
			          (#includeSource -> true).
			          (#limit -> 1) } asDictionary.
	data := self dataFrom: result.
	method := self
		          entryForReference:
		          'MCPToolFindMethodsVariableReferenceTarget>>readTrackedSlot'
		          in: (data at: #methods).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #methods) size equals: 1.
	self assert: (method includesKey: #source).
	self assert: ((method at: #source) includesSubstring: 'trackedSlot')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testVariableReferenceFindsClassSideVariableReferences [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'trackedClassSlot').
			          (#filterMode -> 'variableReference').
			          (#side -> 'class').
			          (#classNames
			           -> #( 'MCPToolFindMethodsVariableReferenceTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget class>>readTrackedClassSlot'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget class>>writeTrackedClassSlot'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testVariableReferenceFindsInstanceVariableReferences [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'trackedSlot').
			          (#filterMode -> 'variableReference').
			          (#side -> 'instance').
			          (#classNames
			           -> #( 'MCPToolFindMethodsVariableReferenceTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget>>readTrackedSlot'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget>>writeTrackedSlot'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testVariableReferenceIgnoresFilterTargets [

	| data result |
	result := self callToolWith: {
			          (#filter -> 'trackedSlot').
			          (#filterMode -> 'variableReference').
			          (#filterTargets -> #( 'protocol' )).
			          (#side -> 'instance').
			          (#classNames
			           -> #( 'MCPToolFindMethodsVariableReferenceTarget' )) }
			          asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget>>readTrackedSlot'
		in: (data at: #methods).
	self
		entryForReference:
		'MCPToolFindMethodsVariableReferenceTarget>>writeTrackedSlot'
		in: (data at: #methods)
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testVariableReferenceRequiresFilter [

	self
		should: [
			self callToolWith:
				{ (#filterMode -> 'variableReference') } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testVariableReferenceReturnsStructuredErrorWhenVariableIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#filter -> 'missingTrackedSlot').
			          (#filterMode -> 'variableReference').
			          (#classNames
			           -> #( 'MCPToolFindMethodsVariableReferenceTarget' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: ((error at: #message) includesSubstring:
			 'No variable named missingTrackedSlot')
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereCanFindMethodsSendingTwoSelectors [

	| data fixtureClass result selector |
	selector := #whereSendsSharedAndExtensionTarget.
	fixtureClass := Smalltalk globals at:
		                #MCPToolFindMethodsReferenceFixture.
	[
	self
		ensureMethodSource: 'whereSendsSharedAndExtensionTarget

	self sharedTarget.
	^ MCPToolFindMethodsReferenceTarget new extensionTarget'
		protocol: 'testing'
		on: fixtureClass.
	result := self callToolWith: {
			          (#classNames -> #( 'MCPToolFindMethodsReferenceFixture' )).
			          (#where -> { (#all -> {
				            {
					            (#filter -> 'sharedTarget').
					            (#filterMode -> 'selectorReference') } asDictionary.
				            {
					            (#filter -> 'extensionTarget').
					            (#filterMode -> 'selectorReference') } asDictionary }) }
				           asDictionary) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference:
		'MCPToolFindMethodsReferenceFixture>>whereSendsSharedAndExtensionTarget'
		in: (data at: #methods) ] ensure: [
		self removeSelector: selector from: fixtureClass ]
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereEquivalentToComposesUnderAll [

	| data result subclassName |
	subclassName := 'MCPToolFindMethodsEquivalentAllFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolFindMethodsReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
	self
		ensureMethodSource: 'instanceSendShared

	^ self sharedTarget'
		protocol: 'testing'
		on: (self classNamed: subclassName).
	result := self callToolWith: {
			          (#classNames -> { subclassName }).
			          (#where -> { (#all -> {
				            (self
					             equivalentToWhereForClassName:
					             'MCPToolFindMethodsReferenceFixture'
					             selector: 'instanceSendShared'
					             classSide: false).
				            {
					            (#filter -> 'sharedTarget').
					            (#filterMode -> 'selectorReference') } asDictionary }) }
				           asDictionary) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: subclassName , '>>instanceSendShared'
		in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereEquivalentToDefaultsReferenceToInstanceSide [

	| data result subclassName |
	subclassName := 'MCPToolFindMethodsEquivalentDefaultSideFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolFindMethodsReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
	self
		ensureMethodSource: 'sharedTarget

	^ ''instance-target'''
		protocol: 'testing'
		on: (self classNamed: subclassName).
	result := self callToolWith: {
			          (#classNames -> { subclassName }).
			          (#where -> { (#equivalentTo -> {
				            (#className -> 'MCPToolFindMethodsReferenceFixture').
				            (#selector -> 'sharedTarget') } asDictionary) }
				           asDictionary) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: subclassName , '>>sharedTarget'
		in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereEquivalentToMatchesReferencedClassSideMethod [

	| data result subclass subclassName |
	subclassName := 'MCPToolFindMethodsEquivalentClassFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolFindMethodsReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
	subclass := self classNamed: subclassName.
	self
		ensureMethodSource: 'sharedTarget

	^ ''class-target'''
		protocol: 'testing'
		on: subclass classSide.
	result := self callToolWith: {
			          (#classNames -> { subclassName }).
			          (#side -> 'class').
			          (#where -> (self
				            equivalentToWhereForClassName:
				            'MCPToolFindMethodsReferenceFixture'
				            selector: 'sharedTarget'
				            classSide: true)) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: subclassName , ' class>>sharedTarget'
		in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereEquivalentToMatchesReferencedInstanceSideMethod [

	| data result subclassName |
	subclassName := 'MCPToolFindMethodsEquivalentInstanceFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolFindMethodsReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
	self
		ensureMethodSource: 'sharedTarget

	^ ''instance-target'''
		protocol: 'testing'
		on: (self classNamed: subclassName).
	result := self callToolWith: {
			          (#classNames -> { subclassName }).
			          (#where -> (self
				            equivalentToWhereForClassName:
				            'MCPToolFindMethodsReferenceFixture'
				            selector: 'sharedTarget'
				            classSide: false)) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		entryForReference: subclassName , '>>sharedTarget'
		in: (data at: #methods) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereEquivalentToRejectsDifferentAst [

	| data result subclassName |
	subclassName := 'MCPToolFindMethodsDifferentAstFixture'.
	self
		createClassNamed: subclassName
		superclassName: 'MCPToolFindMethodsReferenceFixture'
		slots: #(  )
		classSlots: #(  ).
	[
	self
		ensureMethodSource: 'sharedTarget

	^ ''different-target'''
		protocol: 'testing'
		on: (self classNamed: subclassName).
	result := self callToolWith: {
			          (#classNames -> { subclassName }).
			          (#where -> (self
				            equivalentToWhereForClassName:
				            'MCPToolFindMethodsReferenceFixture'
				            selector: 'sharedTarget'
				            classSide: false)) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #methods) equals: #(  ) ] ensure: [
		self removeClassNamed: subclassName ]
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereEquivalentToReturnsStructuredErrorWhenReferenceClassIsMissing [

	| error result |
	result := self callToolWith: {
			          (#classNames -> #( 'MCPToolFindMethodsReferenceFixture' )).
			          (#where -> (self
				            equivalentToWhereForClassName:
				            'MCPToolFindMethodsMissingReferenceClass'
				            selector: 'sharedTarget'
				            classSide: false)) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolFindMethodsMissingReferenceClass'
]

{ #category : 'tests' }
MCPToolFindMethodsTest >> testWhereEquivalentToReturnsStructuredErrorWhenReferenceMethodIsMissing [

	| error result |
	result := self callToolWith: {
			          (#classNames -> #( 'MCPToolFindMethodsReferenceFixture' )).
			          (#where -> (self
				            equivalentToWhereForClassName:
				            'MCPToolFindMethodsReferenceFixture'
				            selector: 'missingEquivalentTarget'
				            classSide: false)) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'MethodNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolFindMethodsReferenceFixture'.
	self assert: (error at: #selector) equals: 'missingEquivalentTarget'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'private - calling' }
MCPToolFindMethodsTest >> toolName [

	^ 'find-methods'
]
