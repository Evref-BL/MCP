Class {
	#name : 'MCPToolFindClassesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolFindClassesTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolFindClassesTest >> childClassName [

	^ self fixturePrefix , 'Child'
]

{ #category : 'private' }
MCPToolFindClassesTest >> entryNamed: aClassName in: classEntries [

	^ classEntries
		  detect: [ :each | (each at: #className) = aClassName ]
		  ifNone: [ self fail: 'Missing class entry ' , aClassName ]
]

{ #category : 'private' }
MCPToolFindClassesTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childClassName.
		  self grandchildClassName } asArray
]

{ #category : 'private' }
MCPToolFindClassesTest >> fixturePrefix [

	^ self class name asString , 'Fixture'
]

{ #category : 'private' }
MCPToolFindClassesTest >> grandchildClassName [

	^ self fixturePrefix , 'Grandchild'
]

{ #category : 'private' }
MCPToolFindClassesTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolFindClassesTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'private' }
MCPToolFindClassesTest >> restoreFixtureClasses [

	self removeFixtureClasses.
	self
		createClassNamed: self baseClassName
		superclassName: 'Object'
		slots: #( betaSlot alphaSlot )
		classSlots: #( classBeta classAlpha ).
	self
		createClassNamed: self childClassName
		superclassName: self baseClassName
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self grandchildClassName
		superclassName: self childClassName
		slots: #(  )
		classSlots: #(  )
]

{ #category : 'running' }
MCPToolFindClassesTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'running' }
MCPToolFindClassesTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testClassNamesReturnExactClassInfos [

	| baseEntry data result |
	result := self callToolWith: { (#classNames -> {
			           self childClassName.
			           self baseClassName }) } asDictionary.
	data := self dataFrom: result.
	baseEntry := self
		             entryNamed: self baseClassName
		             in: (data at: #classes).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #classes) size equals: 2.
	self assert: (baseEntry at: #packageName) equals: 'MCP-Tests'.
	self assert: (baseEntry at: #tag) equals: 'Internal'.
	self
		assert: (baseEntry at: #instanceSlotNames)
		equals: #( 'betaSlot' 'alphaSlot' ).
	self
		assert: (baseEntry at: #classSlotNames)
		equals: #( 'classBeta' 'classAlpha' ).
	self deny: (baseEntry includesKey: #superclassName).
	self deny: (baseEntry includesKey: #subclassNames)
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testClassNamesSelectExactClassScope [

	| classNames data result |
	result := self callToolWith: { (#classNames -> {
			           self childClassName.
			           self baseClassName }) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 2.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testDefaultFilterAppliesToClassOnly [

	| classNames data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#filter -> self baseClassName).
			          (#filterMode -> 'exact') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self assert: (data at: #totalCount) equals: 1.
	self assert: classNames equals: { self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testDirectionalScopesAreUnionedWithExactClassNames [

	| classNames data result |
	result := self callToolWith: {
			          (#classNames -> { self childClassName }).
			          (#subclassClassNames -> { self childClassName }).
			          (#parentClassNames -> { self childClassName }).
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testFilterCanMatchSlotNames [

	| data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#filter -> 'alphaSlot').
			          (#filterTargets -> #( 'instanceSlot' )) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self entryNamed: self baseClassName in: (data at: #classes)
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testHierarchyClassNamesReturnRelatedClasses [

	| classNames data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> { self childClassName }).
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testHierarchyClassNamesSelectHierarchyScope [

	| classNames data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> { self childClassName }).
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testImageScopeCanFilterAndPaginate [

	| classNames data result |
	result := self callToolWith: {
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix').
			          (#limit -> 2).
			          (#offset -> 1) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 3.
	self assert: classNames size equals: 2.
	self assert: classNames equals: {
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testIntersectionScopeKeepsOnlyClassesInEveryScopeDimension [

	| classNames data result |
	result := self callToolWith: {
			          (#classNames -> { self childClassName }).
			          (#hierarchyClassNames -> { self childClassName }).
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix').
			          (#scopeMode -> 'intersection') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: classNames equals: { self childClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testMissingClassScopeReturnsPartialResultsAndWarnings [

	| classNames data result warnings |
	result := self callToolWith: { (#classNames -> {
			           self baseClassName.
			           self missingClassName }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: classNames equals: { self baseClassName } asArray.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: self missingClassName)
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testMultipleScopesAreUnioned [

	| classNames data result |
	result := self callToolWith: {
			          (#classNames -> { self class name asString }).
			          (#hierarchyClassNames -> { self childClassName }).
			          (#filter -> 'MCPToolFindClasses').
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 4.
	self assert: classNames asSet equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName.
			self class name asString } asSet
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testPackageNamesReturnPackageClasses [

	| classNames data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#filter -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testPackageNamesSelectPackageScope [

	| classNames data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#filter -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testParentClassNamesReturnParentsOnly [

	| classNames data result |
	result := self callToolWith: {
			          (#parentClassNames -> { self childClassName }).
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: classNames equals: { self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testReturnsStructuredErrorForInvalidFilterTarget [

	self
		should: [
			self callToolWith: {
					(#packageNames -> #( 'MCP-Tests' )).
					(#filter -> 'needle').
					(#filterTargets -> #( 'bogus' )) } asDictionary ]
		raise: JRPCInvalidParameters
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testReturnsWarningsAndEmptyResultsWhenClassIsMissing [

	| data result warnings |
	result := self callToolWith:
		          { (#classNames -> { self missingClassName }) }
			          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: self missingClassName).
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testReturnsWarningsAndEmptyResultsWhenPackageIsMissing [

	| data result warnings |
	result := self callToolWith:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing')
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testSubclassClassNamesReturnSubclassesOnly [

	| classNames data result |
	result := self callToolWith: {
			          (#subclassClassNames -> { self childClassName }).
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self assert: classNames equals: { self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testToolDoesNotRequireArgumentsInSchema [

	self
		assert: MCPToolFindClasses new inputSchema required
		equals: #(  )
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testWhereCanMatchRelatedMethods [

	| classNames data result |
	result := self callToolWith: {
			          (#classNames -> #( 'MCPToolFindMethodsReferenceFixture'
			              'MCPToolFindMethodsReferenceTarget' )).
			          (#where -> {
				           (#exists -> 'methods').
				           (#where -> {
					            (#filter -> 'sharedTarget').
					            (#filterMode -> 'selectorReference') } asDictionary) }
				           asDictionary) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self
		assert: classNames
		equals: #( 'MCPToolFindMethodsReferenceFixture' )
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testWhereEquivalentToReturnsStructuredErrorForNonMethodPredicates [

	| error result |
	result := self callToolWith: {
			          (#classNames -> #( 'MCPToolFindMethodsReferenceFixture' )).
			          (#where -> { (#equivalentTo -> {
				            (#className -> 'MCPToolFindMethodsReferenceFixture').
				            (#selector -> 'sharedTarget') } asDictionary) }
				           asDictionary) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self
		assert: (error at: #errorCode)
		equals: 'WhereEquivalentToRequiresMethodEntity'.
	self assert: (error at: #entityKind) equals: 'class'
]

{ #category : 'private - calling' }
MCPToolFindClassesTest >> toolName [

	^ 'class_search'
]
