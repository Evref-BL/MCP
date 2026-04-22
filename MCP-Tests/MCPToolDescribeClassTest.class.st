Class {
	#name : 'MCPToolDescribeClassTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Tests',
	#package : 'MCP-Tests',
	#tag : 'Tests'
}

{ #category : 'private' }
MCPToolDescribeClassTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolDescribeClassTest >> callToolWith: someArguments [

	^ MCP new
		  rpcToolCall: 'describe-class'
		  withParams: someArguments
]

{ #category : 'private' }
MCPToolDescribeClassTest >> childAClassName [

	^ self fixturePrefix , 'AChild'
]

{ #category : 'private' }
MCPToolDescribeClassTest >> childZClassName [

	^ self fixturePrefix , 'ZChild'
]

{ #category : 'private' }
MCPToolDescribeClassTest >> classNamed: aClassName [

	^ self class environment at: aClassName asSymbol
]

{ #category : 'private' }
MCPToolDescribeClassTest >> createClassNamed: aClassName superclassName: aSuperclassName slots: someSlots classSlots: someClassSlots [

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
MCPToolDescribeClassTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolDescribeClassTest >> ensureClassComment: aComment onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName) comment: aComment stamp: '' ]
]

{ #category : 'private' }
MCPToolDescribeClassTest >> ensureClassMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName) classSide
			compile: aMethodSource
			classified: 'testing' ]
]

{ #category : 'private' }
MCPToolDescribeClassTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName)
			compile: aMethodSource
			classified: 'testing' ]
]

{ #category : 'private' }
MCPToolDescribeClassTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolDescribeClassTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childAClassName.
		  self childZClassName.
		  self grandchildClassName } asArray
]

{ #category : 'private' }
MCPToolDescribeClassTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPToolDescribeClassTest >> grandchildClassName [

	^ self fixturePrefix , 'Grandchild'
]

{ #category : 'private' }
MCPToolDescribeClassTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolDescribeClassTest >> removeClassNamed: aClassName [

	| symbol |
	symbol := aClassName asSymbol.
	self withoutEpiceaDuring: [
		(self class environment includesKey: symbol) ifTrue: [
			(self class environment at: symbol) removeFromSystem ] ]
]

{ #category : 'private' }
MCPToolDescribeClassTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'private' }
MCPToolDescribeClassTest >> restoreFixtureClasses [

	self removeFixtureClasses.
	self
		createClassNamed: self baseClassName
		superclassName: 'Object'
		slots: #( betaSlot alphaSlot )
		classSlots: #( classBeta classAlpha ).
	self
		createClassNamed: self childZClassName
		superclassName: self baseClassName
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self childAClassName
		superclassName: self baseClassName
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self grandchildClassName
		superclassName: self childZClassName
		slots: #(  )
		classSlots: #(  ).
	self
		ensureMethodSource: 'instanceMarker ^ 1'
		onClassNamed: self baseClassName.
	self
		ensureClassMethodSource: 'classMarker ^ 2'
		onClassNamed: self baseClassName.
	self
		ensureClassComment: 'Base fixture class comment.'
		onClassNamed: self baseClassName.
	self
		ensureClassComment: 'Child A fixture class comment.'
		onClassNamed: self childAClassName.
	self
		ensureClassComment: 'Child Z fixture class comment.'
		onClassNamed: self childZClassName.
	self
		ensureClassComment: 'Grandchild fixture class comment.'
		onClassNamed: self grandchildClassName
]

{ #category : 'running' }
MCPToolDescribeClassTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'private' }
MCPToolDescribeClassTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolDescribeClassTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testDescribesClassMetadata [

	| data result |
	result := self callToolWith:
		          { (#className -> self baseClassName) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self assert: (data at: #className) equals: self baseClassName.
	self assert: (data at: #superclassName) equals: 'Object'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self assert: (data at: #tag) equals: 'Internal'.
	self deny: (data includesKey: #classComment).
	self
		assert: (data at: #instanceSlotNames)
		equals: #( 'betaSlot' 'alphaSlot' ).
	self
		assert: (data at: #classSlotNames)
		equals: #( 'classBeta' 'classAlpha' ).
	self assert: (data at: #traitNames) isEmpty.
	self assert: (data at: #classTraitNames) isEmpty.
	self assert: (data at: #sharedPoolNames) isEmpty.
	self assert: (data at: #instanceMethodCount) equals: 1.
	self assert: (data at: #classMethodCount) equals: 1.
	self assert: (data at: #superclasses) isEmpty.
	self assert: (data at: #subclasses) isEmpty
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testIncludesClassCommentsWhenRequested [

	| data result subclasses superclasses |
	result := self callToolWith: {
			          (#className -> self childZClassName).
			          (#includeComment -> true).
			          (#includeSuperclasses -> true).
			          (#upToSuperclassName -> self baseClassName).
			          (#subclassDepth -> 1) } asDictionary.
	data := self dataFrom: result.
	superclasses := data at: #superclasses.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self
		assert: (data at: #classComment)
		equals: 'Child Z fixture class comment.'.
	self assert: superclasses size equals: 1.
	self
		assert: (superclasses first at: #className)
		equals: self baseClassName.
	self
		assert: (superclasses first at: #classComment)
		equals: 'Base fixture class comment.'.
	self assert: subclasses size equals: 1.
	self
		assert: (subclasses first at: #className)
		equals: self grandchildClassName.
	self
		assert: (subclasses first at: #classComment)
		equals: 'Grandchild fixture class comment.'
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testIncludesDirectSubclasses [

	| data result subclasses |
	result := self callToolWith: {
			          (#className -> self baseClassName).
			          (#subclassDepth -> 1) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self
		assert: (subclasses collect: [ :each | each at: #className ])
		equals: {
				self childAClassName.
				self childZClassName } asArray
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testIncludesNamedSuperclassChain [

	| data result superclasses |
	result := self callToolWith: {
			          (#className -> self grandchildClassName).
			          (#includeSuperclasses -> true).
			          (#upToSuperclassName -> 'Object') } asDictionary.
	data := self dataFrom: result.
	superclasses := data at: #superclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self
		assert: (superclasses collect: [ :each | each at: #className ])
		equals: {
				self childZClassName.
				self baseClassName.
				'Object' } asArray
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testIncludesSharedPoolNamesForSharedPoolUsingClass [

	| data result |
	result := self callToolWith:
		          { (#className -> 'AbstractTimeZone') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		((data at: #sharedPoolNames) includes: 'ChronologyConstants')
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testIncludesSubclassesUpToRequestedDepth [

	| data result subclasses |
	result := self callToolWith: {
			          (#className -> self baseClassName).
			          (#subclassDepth -> 2) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self
		assert: (subclasses collect: [ :each | each at: #className ])
		equals: {
				self childAClassName.
				self childZClassName.
				self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testIncludesTraitNamesForTraitUsingClass [

	| data result |
	result := self callToolWith:
		          { (#className -> 'AlignmentMorph') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((data at: #traitNames) anySatisfy: [ :each |
			 each includesSubstring: 'TAbleToRotate' ]).
	self assert: ((data at: #classTraitNames) anySatisfy: [ :each |
			 each includesSubstring: 'TAbleToRotate' ])
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testRejectsNegativeSubclassDepth [

	| error result structured |
	result := self callToolWith: {
			          (#className -> self baseClassName).
			          (#subclassDepth -> -1) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'Error'.
	self
		assert: (error at: #message)
		equals: 'subclassDepth must be a non-negative integer.'
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith:
		          { (#className -> self missingClassName) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: self missingClassName
]

{ #category : 'tests' }
MCPToolDescribeClassTest >> testToolRequiresClassNameInSchema [

	self
		assert: MCPToolDescribeClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]
