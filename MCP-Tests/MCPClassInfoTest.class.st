Class {
	#name : 'MCPClassInfoTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPClassInfoTest >> baseClassName [

	^ 'MCPClassInfoTestBase'
]

{ #category : 'private' }
MCPClassInfoTest >> childAClassName [

	^ 'MCPClassInfoTestAChild'
]

{ #category : 'private' }
MCPClassInfoTest >> childZClassName [

	^ 'MCPClassInfoTestZChild'
]

{ #category : 'private' }
MCPClassInfoTest >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private' }
MCPClassInfoTest >> createClassNamed: aClassName superclassName: aSuperclassName slots: someSlots classSlots: someClassSlots [

	| builder superclass |
	superclass := self classNamed: aSuperclassName.
	builder := superclass << aClassName asSymbol.
	builder package: 'MCP-Tests'.
	builder tag: 'Internal'.
	builder slots: someSlots.
	builder classSlots: someClassSlots.
	builder install
]

{ #category : 'private' }
MCPClassInfoTest >> ensureFixtureClasses [

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
		classSlots: #(  )
]

{ #category : 'private' }
MCPClassInfoTest >> fixtureClassNames [

	^ {
		  self baseClassName.
		  self childAClassName.
		  self childZClassName }
]

{ #category : 'private' }
MCPClassInfoTest >> removeClassNamed: aClassName [

	(Smalltalk globals includesKey: aClassName asSymbol) ifTrue: [
		(Smalltalk globals at: aClassName asSymbol) removeFromSystem ]
]

{ #category : 'private' }
MCPClassInfoTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'running' }
MCPClassInfoTest >> setUp [

	super setUp.
	self ensureFixtureClasses
]

{ #category : 'running' }
MCPClassInfoTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPClassInfoTest >> testBuildsSortedClassMetadataSnapshot [

	| info |
	info := MCPClassInfo fromClass: (self classNamed: self baseClassName).
	self assert: info className equals: self baseClassName.
	self assert: info superclassName equals: 'Object'.
	self assert: info packageName equals: 'MCP-Tests'.
	self assert: info tag equals: 'Internal'.
	self
		assert: info instanceSlotNames
		equals: #( 'betaSlot' 'alphaSlot' ).
	self
		assert: info classSlotNames
		equals: #( 'classBeta' 'classAlpha' ).
	self assert: info subclassNames equals: {
			self childAClassName.
			self childZClassName } asArray
]
