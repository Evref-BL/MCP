"
Tests class metadata snapshots returned by MCPClassInfo.
"
Class {
	#name : 'MCPClassInfoTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPClassInfoTest >> baseClassName [

	^ 'MCPClassInfoTestBase'
]

{ #category : 'private' }
MCPClassInfoTest >> ensureFixtureClasses [

	self removeFixtureClasses.
	self
		createClassNamed: self baseClassName
		superclassName: 'Object'
		slots: #( betaSlot alphaSlot )
		classSlots: #( classBeta classAlpha )
]

{ #category : 'private' }
MCPClassInfoTest >> fixtureClassNames [

	^ { self baseClassName }
]

{ #category : 'running' }
MCPClassInfoTest >> setUp [

	super setUp.
	self ensureFixtureClasses
]

{ #category : 'tests' }
MCPClassInfoTest >> testDescribesTheClassWhereItLivesAndItsSlots [

	| info |
	info := MCPClassInfo fromClass: (self classNamed: self baseClassName).
	self assert: info className equals: self baseClassName.
	self assert: info packageName equals: self generatedPackageName.
	self assert: info tag equals: self generatedTagName.
	self assert: info instanceSlotNames equals: #( 'betaSlot' 'alphaSlot' ).
	self assert: info classSlotNames equals: #( 'classBeta' 'classAlpha' )
]
