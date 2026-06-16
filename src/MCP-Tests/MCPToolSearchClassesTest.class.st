"
Tests the class_search tool.
"
Class {
	#name : 'MCPToolSearchClassesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolSearchClassesTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> childClassName [

	^ self fixturePrefix , 'Child'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> entryNamed: aClassName in: classEntries [

	^ classEntries
		  detect: [ :each | (each at: #className) = aClassName ]
		  ifNone: [ self fail: 'Missing class entry ' , aClassName ]
]

{ #category : 'private' }
MCPToolSearchClassesTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childClassName.
		  self grandchildClassName } asArray
]

{ #category : 'private' }
MCPToolSearchClassesTest >> fixturePrefix [

	^ self class name asString , 'Fixture'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> grandchildClassName [

	^ self fixturePrefix , 'Grandchild'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolSearchClassesTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'private' }
MCPToolSearchClassesTest >> restoreFixtureClasses [

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
MCPToolSearchClassesTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'running' }
MCPToolSearchClassesTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testClassNamesReturnExactClassInfos [

	| baseEntry data result |
	result := self callToolWith: { (#classNames -> {
			           self childClassName.
			           self baseClassName }) } asDictionary.
	data := self dataFrom: result.
	baseEntry := self
		             entryNamed: self baseClassName
		             in: (data at: #classes).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 2.
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
MCPToolSearchClassesTest >> testClassNamesSelectExactClassScope [

	| classNames data result |
	result := self callToolWith: { (#classNames -> {
			           self childClassName.
			           self baseClassName }) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 2.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testDefaultFilterAppliesToClassOnly [

	| classNames data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#className -> self baseClassName).
			          (#filterMode -> 'exact') } asDictionary.
	self deny: (result at: #isError ifAbsent: [ false ]).
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testDirectionalScopesAreUnionedWithExactClassNames [

	| classNames data result |
	result := self callToolWith: {
			          (#classNames -> { self childClassName }).
			          (#subclassClassNames -> { self childClassName }).
			          (#parentClassNames -> { self childClassName }).
			          (#className -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testFilterCanMatchSlotNames [

	| data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#instanceSlot -> 'alphaSlot') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 1.
	self entryNamed: self baseClassName in: (data at: #classes)
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testHierarchyClassNamesReturnRelatedClasses [

	| classNames data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> { self childClassName }).
			          (#className -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testHierarchyClassNamesSelectHierarchyScope [

	| classNames data result |
	result := self callToolWith: {
			          (#hierarchyClassNames -> { self childClassName }).
			          (#className -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testImageScopeCanFilterAndPaginate [

	| classNames data result |
	result := self callToolWith: {
			          (#className -> self fixturePrefix).
			          (#filterMode -> 'prefix').
			          (#limit -> 2).
			          (#offset -> 1) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: classNames size equals: 2.
	self deny: (data includesKey: #nextOffset).
	self assert: classNames equals: {
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testMissingClassScopeReturnsPartialResultsAndWarnings [

	| classNames data result warnings |
	result := self callToolWith: { (#classNames -> {
			           self baseClassName.
			           self missingClassName }) } asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self baseClassName } asArray.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: self missingClassName)
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testMultipleScopesAreUnioned [

	| classNames data result |
	result := self callToolWith: {
			          (#classNames -> { self class name asString }).
			          (#hierarchyClassNames -> { self childClassName }).
			          (#className -> 'MCPToolSearchClasses').
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 4.
	self assert: classNames asSet equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName.
			self class name asString } asSet
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testPackageNamesReturnPackageClasses [

	| classNames data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#className -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testPackageNamesSelectPackageScope [

	| classNames data result |
	result := self callToolWith: {
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#className -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 3.
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testParentClassNamesReturnParentsOnly [

	| classNames data result |
	result := self callToolWith: {
			          (#parentClassNames -> { self childClassName }).
			          (#className -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testReturnsWarningsAndEmptyResultsWhenClassIsMissing [

	| data result warnings |
	result := self callToolWith:
		          { (#classNames -> { self missingClassName }) }
			          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: self missingClassName).
	self assert: (warnings first includesSubstring: 'Did you mean:')
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testReturnsWarningsAndEmptyResultsWhenPackageIsMissing [

	| data result warnings |
	result := self callToolWith:
		          { (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 0.
	self assert: (data at: #classes) isEmpty.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: 'MCP-Definitely-Missing')
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testSubclassClassNamesReturnSubclassesOnly [

	| classNames data result |
	result := self callToolWith: {
			          (#subclassClassNames -> { self childClassName }).
			          (#className -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #classes) size equals: 1.
	self assert: classNames equals: { self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolSearchClassesTest >> testToolDoesNotRequireArgumentsInSchema [

	self
		assert: MCPToolSearchClasses new inputSchema required
		equals: #(  )
]

{ #category : 'private - calling' }
MCPToolSearchClassesTest >> toolName [

	^ 'class_search'
]
