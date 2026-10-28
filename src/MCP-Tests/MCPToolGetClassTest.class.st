"
Tests the class_get tool.
"
Class {
	#name : 'MCPToolGetClassTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
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

	self withoutEpiceaDuring: [ (self classNamed: aClassName) comment: aComment stamp: '' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureClassMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) classSide compile: aMethodSource classified: 'testing' ]
]

{ #category : 'private' }
MCPToolGetClassTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) compile: aMethodSource classified: 'testing' ]
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

	self fixtureClassNames reverseDo: [ :each | self removeClassNamed: each ]
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
	self ensureMethodSource: 'instanceMarker ^ 1' onClassNamed: self baseClassName.
	self ensureClassMethodSource: 'classMarker ^ 2' onClassNamed: self baseClassName.
	self ensureClassComment: 'Base fixture class comment.' onClassNamed: self baseClassName.
	self ensureClassComment: 'Child A fixture class comment.' onClassNamed: self childAClassName.
	self ensureClassComment: 'Child Z fixture class comment.' onClassNamed: self childZClassName.
	self ensureClassComment: 'Grandchild fixture class comment.' onClassNamed: self grandchildClassName
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
MCPToolGetClassTest >> testClampsSubclassDepthAboveMaximum [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#subclassDepth -> 1000) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (subclasses collect: [ :each | each at: #class ]) equals: {
			self childAClassName.
			self childZClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testClassFieldsReadInOrderAndAreNotRepeated [
	"The summary already names the class, so a class: field would say it twice, and a reader wants what the class is before how big it is."

	| labels text |
	text := ((self callToolNamed: 'class_get' withArguments: { (#name -> self baseClassName) } asDictionary) at: #content) first at:
		        #text.
	labels := (text lines allButFirst select: [ :each | each includesSubstring: ': ' ] thenCollect: [ :each | each copyUpTo: $: ])
		          asArray.
	self assert: text lines first equals: (String streamContents: [ :stream | stream << 'Got class ' << self baseClassName << '.' ]).
	self deny: (labels includes: 'class').
	self assert: (labels copyFrom: 1 to: 2) equals: #( 'superclass' 'layout' ).
	self assert: ((labels indexOf: 'package') between: 1 and: (labels indexOf: 'classMethods')).
	self assert: (labels indexOf: 'classMethods') < (labels indexOf: 'methods')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testDescribesATraitAndNamesTheClassesUsingIt [

	| data result text |
	result := self callToolWith: { (#name -> TMCPToolMethodSearchFixture name) } asDictionary.
	data := self dataFrom: result.
	text := (result at: #content) first at: #text.
	self
		assert: text lines first
		equals: (String streamContents: [ :stream | stream << 'Got trait ' << TMCPToolMethodSearchFixture name << '.' ]).
	self assert: (data at: #isTrait).
	self deny: (data includesKey: #superclass).
	self assert: (data at: #users) equals: {
			MCPToolMethodSearchTraitExcluder name asString.
			MCPToolMethodSearchTraitOtherUser name asString.
			MCPToolMethodSearchTraitOverrider name asString.
			MCPToolMethodSearchTraitUser name asString }
]

{ #category : 'tests' }
MCPToolGetClassTest >> testGetsClassMetadata [

	| data expectedLayoutClassName result |
	result := self callToolWith: { (#name -> self baseClassName) } asDictionary.
	data := self dataFrom: result.
	expectedLayoutClassName := (self classNamed: self baseClassName) classLayout class name asString.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #class) equals: self baseClassName.
	self assert: (data at: #superclass) equals: 'Object'.
	self assert: (data at: #package) equals: self generatedPackageName.
	self assert: (data at: #tag) equals: self generatedTagName.
	self deny: (data includesKey: #comment).
	self assert: (data at: #instanceSlots) equals: #( 'betaSlot' 'alphaSlot' ).
	self assert: (data at: #classSlots) equals: #( 'classBeta' 'classAlpha' ).
	self deny: (data includesKey: #traits).
	self deny: (data includesKey: #classTraits).
	self deny: (data includesKey: #traitComposition).
	self deny: (data includesKey: #classTraitComposition).
	self deny: (data includesKey: #sharedPools).
	self assert: (data at: #sharedVariables) equals: #( 'AlphaShared' 'BetaShared' ).
	self assert: (data at: #layout) equals: expectedLayoutClassName.
	self assert: (data at: #methods) equals: 1.
	self assert: (data at: #classMethods) equals: 1.
	self deny: (data includesKey: #superclasses).
	self deny: (data includesKey: #subclasses)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesClassCommentsWhenRequested [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self childZClassName).
			          (#includeComment -> true).
			          (#upToSuperclass -> self baseClassName).
			          (#subclassDepth -> 1) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (data at: #comment) equals: 'Child Z fixture class comment.'.
	self deny: (data includesKey: #superclasses).
	self assert: subclasses size equals: 1.
	self assert: (subclasses first at: #class) equals: self grandchildClassName.
	self assert: (subclasses first at: #comment) equals: 'Grandchild fixture class comment.'
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesDirectSubclasses [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#subclassDepth -> 1) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (subclasses collect: [ :each | each at: #class ]) equals: {
			self childAClassName.
			self childZClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesNamedSuperclassChain [

	| data result superclasses |
	result := self callToolWith: {
			          (#name -> self grandchildClassName).
			          (#upToSuperclass -> 'Object') } asDictionary.
	data := self dataFrom: result.
	superclasses := data at: #superclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (superclasses collect: [ :each | each at: #class ]) equals: {
			self childZClassName.
			self baseClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesSharedPoolNamesForSharedPoolUsingClass [

	| data result |
	result := self callToolWith: { (#name -> 'AbstractTimeZone') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((data at: #sharedPools) includes: 'ChronologyConstants')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesSubclassesUpToRequestedDepth [

	| data result subclasses |
	result := self callToolWith: {
			          (#name -> self baseClassName).
			          (#subclassDepth -> 2) } asDictionary.
	data := self dataFrom: result.
	subclasses := data at: #subclasses.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self resultIndicatesError: result).
	self assert: (subclasses collect: [ :each | each at: #class ]) equals: {
			self childAClassName.
			self childZClassName.
			self grandchildClassName } asArray
]

{ #category : 'tests' }
MCPToolGetClassTest >> testIncludesTraitNamesForTraitUsingClass [

	| data result |
	result := self callToolWith: { (#name -> 'AlignmentMorph') } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: ((data at: #traits) anySatisfy: [ :each | each includesSubstring: 'TAbleToRotate' ]).
	self assert: ((data at: #classTraits) anySatisfy: [ :each | each includesSubstring: 'TAbleToRotate' ])
]

{ #category : 'tests' }
MCPToolGetClassTest >> testKeepsATraitCompositionThatExcludesAMethod [

	| data result |
	result := self callToolWith: { (#name -> MCPToolMethodSearchTraitExcluder name) } asDictionary.
	data := self dataFrom: result.
	self assert: ((data at: #traitComposition) includesSubstring: 'mcpTraitFixtureValue').
	self assert: ((data at: #classTraitComposition) includesSubstring: 'mcpTraitFixtureValue')
]

{ #category : 'tests' }
MCPToolGetClassTest >> testOmitsATraitCompositionThatOnlyRepeatsTheTraits [

	| data result |
	result := self callToolWith: { (#name -> MCPToolMethodSearchTraitUser name) } asDictionary.
	data := self dataFrom: result.
	self assert: (data at: #traits) equals: { TMCPToolMethodSearchFixture name asString }.
	self deny: (data includesKey: #traitComposition).
	self deny: (data includesKey: #classTraitComposition)
]

{ #category : 'tests' }
MCPToolGetClassTest >> testRejectsNegativeSubclassDepth [

	self
		should: [
				self callToolWith: {
						(#name -> self baseClassName).
						(#subclassDepth -> -1) } asDictionary ]
		raise: MCPInvalidToolInput
]

{ #category : 'tests' }
MCPToolGetClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith: { (#name -> self missingClassName) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: self missingClassName
]

{ #category : 'tests' }
MCPToolGetClassTest >> testToolRequiresNameInSchema [

	self assert: MCPToolGetClass new inputSchema required asSet equals: #( 'name' ) asSet
]

{ #category : 'private - calling' }
MCPToolGetClassTest >> toolName [

	^ 'class_get'
]
