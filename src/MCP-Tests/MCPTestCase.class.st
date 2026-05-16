Class {
	#name : 'MCPTestCase',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'testing' }
MCPTestCase class >> isAbstract [

	^ self = MCPTestCase or: [ super isAbstract ]
]

{ #category : 'private - classes' }
MCPTestCase >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private - classes' }
MCPTestCase >> createClassNamed: aClassName superclassName: aSuperclassName slots: someSlots classSlots: someClassSlots [

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

{ #category : 'private - methods' }
MCPTestCase >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [

	self withoutEpiceaDuring: [
		aBehavior compile: aMethodSource classified: aProtocol ]
]

{ #category : 'private - classes' }
MCPTestCase >> removeClassNamed: aClassName [

	| classSymbol |
	classSymbol := aClassName asSymbol.
	self withoutEpiceaDuring: [
		(Smalltalk globals includesKey: classSymbol) ifTrue: [
			(Smalltalk globals at: classSymbol) removeFromSystem ] ]
]

{ #category : 'private - packages' }
MCPTestCase >> removePackageNamed: aPackageName [

	self withoutEpiceaDuring: [
		(PackageOrganizer default hasPackage: aPackageName) ifTrue: [
			PackageOrganizer default removePackage: aPackageName ] ]
]

{ #category : 'private - methods' }
MCPTestCase >> removeSelector: aSelector from: aBehavior [

	self withoutEpiceaDuring: [
		(aBehavior includesSelector: aSelector) ifTrue: [
			aBehavior removeSelector: aSelector ] ]
]

{ #category : 'private - execution' }
MCPTestCase >> withoutEpiceaDuring: aBlock [

	| value |
	EpMonitor disableDuring: [ value := aBlock value ].
	^ value
]
