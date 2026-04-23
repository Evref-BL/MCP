Class {
	#name : 'MCPToolInspectClassTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolInspectClassTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolInspectClassTest >> childAClassName [

	^ self fixturePrefix , 'AChild'
]

{ #category : 'private' }
MCPToolInspectClassTest >> childZClassName [

	^ self fixturePrefix , 'ZChild'
]

{ #category : 'private' }
MCPToolInspectClassTest >> ensureClassComment: aComment onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName) comment: aComment stamp: '' ]
]

{ #category : 'private' }
MCPToolInspectClassTest >> ensureClassMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName) classSide
			compile: aMethodSource
			classified: 'testing' ]
]

{ #category : 'private' }
MCPToolInspectClassTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName)
			compile: aMethodSource
			classified: 'testing' ]
]

{ #category : 'private' }
MCPToolInspectClassTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childAClassName.
		  self childZClassName.
		  self grandchildClassName } asArray
]

{ #category : 'private' }
MCPToolInspectClassTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPToolInspectClassTest >> grandchildClassName [

	^ self fixturePrefix , 'Grandchild'
]

{ #category : 'private' }
MCPToolInspectClassTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolInspectClassTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'private' }
MCPToolInspectClassTest >> restoreFixtureClasses [

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
MCPToolInspectClassTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'running' }
MCPToolInspectClassTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolInspectClassTest >> testIncludesClassCommentsWhenRequested [

	| data result subclasses superclasses |
	result := self callToolWith: {
			          (#className -> self childZClassName).
			          (#includeComment -> true).
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
	self assert: superclasses isEmpty.
	self assert: subclasses size equals: 1.
	self
		assert: (subclasses first at: #className)
		equals: self grandchildClassName.
	self
		assert: (subclasses first at: #classComment)
		equals: 'Grandchild fixture class comment.'
]

{ #category : 'tests' }
MCPToolInspectClassTest >> testIncludesDirectSubclasses [

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
MCPToolInspectClassTest >> testIncludesNamedSuperclassChain [

	| data result superclasses |
	result := self callToolWith: {
			          (#className -> self grandchildClassName).
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
				self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolInspectClassTest >> testIncludesSharedPoolNamesForSharedPoolUsingClass [

	| data result |
	result := self callToolWith:
		          { (#className -> 'AbstractTimeZone') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		((data at: #sharedPoolNames) includes: 'ChronologyConstants')
]

{ #category : 'tests' }
MCPToolInspectClassTest >> testIncludesSubclassesUpToRequestedDepth [

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
MCPToolInspectClassTest >> testIncludesTraitNamesForTraitUsingClass [

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
MCPToolInspectClassTest >> testInspectsClassMetadata [

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
MCPToolInspectClassTest >> testRejectsNegativeSubclassDepth [

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
MCPToolInspectClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

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
MCPToolInspectClassTest >> testToolRequiresClassNameInSchema [

	self
		assert: MCPToolInspectClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]

{ #category : 'private - calling' }
MCPToolInspectClassTest >> toolName [

	^ 'inspect-class'
]
