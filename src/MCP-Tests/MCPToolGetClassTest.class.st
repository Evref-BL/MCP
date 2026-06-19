"
Tests the class_get tool.
"
Class {
	#name : 'MCPToolGetClassTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolGetClassTest >> baseClassName [

	^ self fixturePrefix , 'Base'
]

{ #category : 'private' }
MCPToolGetClassTest >> childAClassName [

	^ self fixturePrefix , 'AChild'
]

{ #category : 'private' }
MCPToolGetClassTest >> childZClassName [

	^ self fixturePrefix , 'ZChild'
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureClassComment: aComment onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName) comment: aComment stamp: '' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureClassMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName) classSide
			compile: aMethodSource
			classified: 'testing' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName)
			compile: aMethodSource
			classified: 'testing' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childAClassName.
		  self childZClassName.
		  self grandchildClassName } asArray
]

{ #category : 'private' }
MCPToolGetClassTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPToolGetClassTest >> grandchildClassName [

	^ self fixturePrefix , 'Grandchild'
]

{ #category : 'private' }
MCPToolGetClassTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolGetClassTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'private' }
MCPToolGetClassTest >> restoreFixtureClasses [

	self removeFixtureClasses.
	self
		createClassNamed: self baseClassName
		superclassName: 'Object'
		slots: #( betaSlot alphaSlot )
		classSlots: #( classBeta classAlpha ).
	self withoutEpiceaDuring: [
		(self classNamed: self baseClassName)
			addClassVarNamed: 'BetaShared';
			addClassVarNamed: 'AlphaShared' ].
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
MCPToolGetClassTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'running' }
MCPToolGetClassTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolGetClassTest >> testGetsClassMetadata [

	| data expectedLayoutClassName result |
	result := self callToolWith:
		          { (#className -> self baseClassName) } asDictionary.
	data := self dataFrom: result.
	expectedLayoutClassName := (self classNamed: self baseClassName)
		                           classLayout class name asString.
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
	self deny: (data includesKey: #traitNames).
	self deny: (data includesKey: #classTraitNames).
	self deny: (data includesKey: #traitComposition).
	self deny: (data includesKey: #classTraitComposition).
	self deny: (data includesKey: #sharedPoolNames).
	self
		assert: (data at: #sharedVariableNames)
		equals: #( 'AlphaShared' 'BetaShared' ).
	self
		assert: (data at: #layoutClassName)
		equals: expectedLayoutClassName.
	self assert: (data at: #instanceMethodCount) equals: 1.
	self assert: (data at: #classMethodCount) equals: 1.
	self deny: (data includesKey: #superclasses).
	self deny: (data includesKey: #subclasses)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesClassCommentsWhenRequested [

	| data result subclasses |
	result := self callToolWith: {
			          (#className -> self childZClassName).
			          (#includeComment -> true).
			          (#upToSuperclassName -> self baseClassName).
			          (#subclassDepth -> 1) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self structuredContentFrom: result) at: #status)
		equals: 'ok'.
	self
		assert: (data at: #classComment)
		equals: 'Child Z fixture class comment.'.
	self deny: (data includesKey: #superclasses).
	self assert: subclasses size equals: 1.
	self
		assert: (subclasses first at: #className)
		equals: self grandchildClassName.
	self
		assert: (subclasses first at: #classComment)
		equals: 'Grandchild fixture class comment.'
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesDirectSubclasses [

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
MCPToolGetClassTest >> testIncludesNamedSuperclassChain [

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
MCPToolGetClassTest >> testIncludesSharedPoolNamesForSharedPoolUsingClass [

	| data result |
	result := self callToolWith:
		          { (#className -> 'AbstractTimeZone') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		((data at: #sharedPoolNames) includes: 'ChronologyConstants')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesSubclassesUpToRequestedDepth [

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
MCPToolGetClassTest >> testIncludesTraitNamesForTraitUsingClass [

	| data result |
	result := self callToolWith:
		          { (#className -> 'AlignmentMorph') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((data at: #traitNames) anySatisfy: [ :each |
			 each includesSubstring: 'TAbleToRotate' ]).
	self assert: ((data at: #classTraitNames) anySatisfy: [ :each |
			 each includesSubstring: 'TAbleToRotate' ]).
	self assert:
		((data at: #traitComposition) includesSubstring: 'TAbleToRotate').
	self assert:
		((data at: #classTraitComposition) includesSubstring:
			 'TAbleToRotate')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testRejectsNegativeSubclassDepth [

	self
		should: [
				self callToolWith: {
						(#className -> self baseClassName).
						(#subclassDepth -> -1) } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPToolGetClassTest >> testRejectsSubclassDepthAboveMaximum [

	self
		should: [
				self callToolWith: {
						(#className -> self baseClassName).
						(#subclassDepth -> 4) } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPToolGetClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith:
		          { (#className -> self missingClassName) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: self missingClassName
]

{ #category : 'tests' }
MCPToolGetClassTest >> testToolRequiresClassNameInSchema [

	self
		assert: MCPToolGetClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]

{ #category : 'private - calling' }
MCPToolGetClassTest >> toolName [

	^ 'class_get'
]
