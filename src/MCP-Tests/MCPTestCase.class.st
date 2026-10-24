"
Common base class for MCP SUnit tests.
"
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

{ #category : 'support' }
MCPTestCase >> builtInToolClasses [

	^ MCPTool concreteSubclasses select: [ :toolClass | toolClass isBuiltIn ]
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
			  builder package: self generatedPackageName.
			  builder tag: self generatedTagName.
			  builder slots: someSlots.
			  builder classSlots: someClassSlots.
			  builder install ]
]

{ #category : 'private - methods' }
MCPTestCase >> ensureMethodSource: aMethodSource protocol: aProtocol on: aBehavior [
	"An extension protocol only makes the method an extension when the package it names exists, so it is created on demand."

	self withoutEpiceaDuring: [
			| selector |
			(aProtocol beginsWith: '*') ifTrue: [ PackageOrganizer default ensurePackage: aProtocol allButFirst ].
			selector := aBehavior compile: aMethodSource classified: aProtocol.
			(aBehavior >> selector) reformat ]
]

{ #category : 'private - classes' }
MCPTestCase >> generatedExtensionPackageName [
	"For a generated method whose package differs from its class's, which is what makes it an extension."

	^ 'MCP-Tests-Generated-Extensions'
]

{ #category : 'private - classes' }
MCPTestCase >> generatedExtensionProtocol [

	^ '*' , self generatedExtensionPackageName
]

{ #category : 'private - classes' }
MCPTestCase >> generatedPackageName [
	"Classes a test generates live outside the versioned packages. A class added to and removed from a versioned one leaves Iceberg holding that package modified, though the source it ends with is the source it started with."

	^ 'MCP-Tests-Generated'
]

{ #category : 'private - classes' }
MCPTestCase >> generatedTagName [

	^ 'Internal'
]

{ #category : 'private - observability' }
MCPTestCase >> mcpWithoutObservabilityExport [

	^ MCP new
		  observabilityExportDirectory: nil;
		  useContentAndStructuredContentToolResponses;
		  yourself
]

{ #category : 'private - classes' }
MCPTestCase >> removeClassNamed: aClassName [

	| classSymbol |
	classSymbol := aClassName asSymbol.
	self withoutEpiceaDuring: [
		(Smalltalk globals includesKey: classSymbol) ifTrue: [ (Smalltalk globals at: classSymbol) removeFromSystem ] ].
	self removeGeneratedPackagesIfEmpty
]

{ #category : 'private - classes' }
MCPTestCase >> removeGeneratedPackagesIfEmpty [
	"A package left behind with nothing in it is as much noise as a dirty one. An extension package holds methods and no classes, so both have to be gone."

	{
		self generatedPackageName.
		self generatedExtensionPackageName } do: [ :name |
			(PackageOrganizer default hasPackage: name) ifTrue: [
					| package |
					package := PackageOrganizer default packageNamed: name.
					(package definedClasses isEmpty and: [ package methods isEmpty ]) ifTrue: [ self removePackageNamed: name ] ] ]
]

{ #category : 'private - packages' }
MCPTestCase >> removePackageNamed: aPackageName [

	self withoutEpiceaDuring: [
		(PackageOrganizer default hasPackage: aPackageName) ifTrue: [ PackageOrganizer default removePackage: aPackageName ] ]
]

{ #category : 'private - methods' }
MCPTestCase >> removeSelector: aSelector from: aBehavior [

	self withoutEpiceaDuring: [ (aBehavior includesSelector: aSelector) ifTrue: [ aBehavior removeSelector: aSelector ] ]
]

{ #category : 'private - execution' }
MCPTestCase >> withoutEpiceaDuring: aBlock [

	| value |
	EpMonitor disableDuring: [ value := aBlock value ].
	^ value
]
