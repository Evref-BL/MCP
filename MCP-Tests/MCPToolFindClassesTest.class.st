Class {
	#name : 'MCPToolFindClassesTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolFindClassesTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolFindClassesTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'pharo-find-classes' withParams: someArguments
]

{ #category : 'private' }
MCPToolFindClassesTest >> childClassName [

	^ self fixturePrefix , 'Child'
]

{ #category : 'private' }
MCPToolFindClassesTest >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private' }
MCPToolFindClassesTest >> createClassNamed: aClassName superclassName: aSuperclassName slots: someSlots classSlots: someClassSlots [

	^ self withoutEpiceaDuring: [
		  | builder superclass |
		  superclass := self classNamed: aSuperclassName.
		  builder := superclass << aClassName asSymbol.
		  builder package: 'MCP-Tests'.
		  builder tag: 'Internal'.
		  builder slots: someSlots.
		  builder classSlots: someClassSlots.
		  builder install ]
]

{ #category : 'private' }
MCPToolFindClassesTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolFindClassesTest >> entryNamed: aClassName in: classEntries [

	^ classEntries
		  detect: [ :each | (each at: #className) = aClassName ]
		  ifNone: [ self fail: 'Missing class entry ' , aClassName ]
]

{ #category : 'private' }
MCPToolFindClassesTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
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
MCPToolFindClassesTest >> removeClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(Smalltalk globals includesKey: aClassName asSymbol) ifTrue: [
			(Smalltalk globals at: aClassName asSymbol) removeFromSystem ] ]
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

{ #category : 'private' }
MCPToolFindClassesTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolFindClassesTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testClassesScopeReturnsExactClassInfos [

	| baseEntry data result |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> {
				           self childClassName.
				           self baseClassName }) } asDictionary.
	data := self dataFrom: result.
	baseEntry := self
		             entryNamed: self baseClassName
		             in: (data at: #classes).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'classes'.
	self assert: (data at: #totalCount) equals: 2.
	self assert: (data at: #classNames) asSet equals: {
			self baseClassName.
			self childClassName } asSet.
	self assert: (baseEntry at: #superclassName) equals: 'Object'.
	self assert: (baseEntry at: #packageName) equals: 'MCP-Tests'.
	self assert: (baseEntry at: #tag) equals: 'Internal'.
	self
		assert: (baseEntry at: #instanceSlotNames)
		equals: #( 'betaSlot' 'alphaSlot' ).
	self
		assert: (baseEntry at: #classSlotNames)
		equals: #( 'classBeta' 'classAlpha' ).
	self
		assert: (baseEntry at: #subclassNames)
		equals: { self childClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testFilterCanMatchSlotNames [

	| data result |
	result := self callToolWith: {
			          (#packageName -> 'MCP-Tests').
			          (#filter -> 'alphaSlot') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #totalCount) equals: 1.
	self entryNamed: self baseClassName in: (data at: #classes)
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testHierarchyScopeReturnsRelatedClasses [

	| classNames data result |
	result := self callToolWith: {
			          (#scope -> 'hierarchy').
			          (#classNames -> { self childClassName }).
			          (#filter -> self fixturePrefix).
			          (#filterMode -> 'prefix') } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'hierarchy'.
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
	self assert: (data at: #scope) equals: 'image'.
	self assert: (data at: #totalCount) equals: 3.
	self assert: (data at: #returnedCount) equals: 2.
	self deny: (data at: #truncated).
	self assert: classNames equals: {
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testPackagesScopeReturnsPackageClasses [

	| classNames data result |
	result := self callToolWith: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Tests' )).
			          (#filter -> self fixturePrefix) } asDictionary.
	data := self dataFrom: result.
	classNames := (data at: #classes) collect: [ :each |
		              each at: #className ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (data at: #scope) equals: 'packages'.
	self assert: (data at: #packageNames) equals: #( 'MCP-Tests' ).
	self assert: classNames equals: {
			self baseClassName.
			self childClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'classes').
			          (#classNames -> { self missingClassName }) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: self missingClassName.
	self assert: (error at: #scope) equals: 'classes'
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testReturnsStructuredErrorWhenPackageIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#scope -> 'packages').
			          (#packageNames -> #( 'MCP-Definitely-Missing' )) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'PackageNotFound'.
	self
		assert: (error at: #packageName)
		equals: 'MCP-Definitely-Missing'.
	self assert: (error at: #scope) equals: 'packages'
]

{ #category : 'tests' }
MCPToolFindClassesTest >> testToolDoesNotRequireArgumentsInSchema [

	self assert: MCPToolFindClasses new inputSchema required equals: #(  )
]
