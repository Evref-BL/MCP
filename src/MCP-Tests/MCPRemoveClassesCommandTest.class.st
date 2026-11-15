"
Tests command-level class removal and related package cleanup.
"
Class {
	#name : 'MCPRemoveClassesCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPRemoveClassesCommandTest >> createClassNamed: aClassName superclassName: aSuperclassName [

	^ self createClassNamed: aClassName superclassName: aSuperclassName packageName: 'MCP-Tests'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> createClassNamed: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ self withoutEpiceaDuring: [
			  | builder superclass |
			  superclass := self classNamed: aSuperclassName.
			  self packageOrganizer ensurePackage: aPackageName.
			  builder := superclass << aClassName asSymbol.
			  builder package: aPackageName.
			  builder tag: 'Internal'.
			  builder slots: #(  ).
			  builder install ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> emptyChildClassName [

	^ self fixturePrefix , 'EmptyChild'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> emptyParentClassName [

	^ self fixturePrefix , 'EmptyParent'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> ensureFixtureClasses [

	self removeFixtureClasses.
	self createClassNamed: self emptyParentClassName superclassName: 'Object'.
	self createClassNamed: self emptyChildClassName superclassName: self emptyParentClassName.
	self createClassNamed: self referencedClassName superclassName: 'Object'.
	self createClassNamed: self senderClassName superclassName: 'Object'.
	self ensureMethodSource: self referenceSenderMethodSource onClassNamed: self senderClassName
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) compile: aMethodSource classified: 'tests' ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> fixtureClassNames [
	"Removed in reverse order, so a subclass goes before its superclass."

	^ {
		  self emptyParentClassName.
		  self emptyChildClassName.
		  self referencedClassName.
		  self senderClassName }
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> referenceSenderMethodSource [

	^ String streamContents: [ :stream | stream << 'useReferencedClass ^ ' << self referencedClassName << ' new' ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> referencedClassName [

	^ self fixturePrefix , 'Referenced'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each | self removeClassNamed: each ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> senderClassName [

	^ self fixturePrefix , 'Sender'
]

{ #category : 'running' }
MCPRemoveClassesCommandTest >> setUp [

	super setUp.
	self ensureFixtureClasses
]

{ #category : 'running' }
MCPRemoveClassesCommandTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testOnlyAClassThatIsNotEmptyIsBlockedByItsSubclasses [

	| command parent |
	parent := self classNamed: self emptyParentClassName.
	command := MCPRemoveClassesCommand classNames: { self emptyParentClassName }.
	self assertEmpty: (command subclassesBlockingRemovalOf: parent).
	self ensureMethodSource: 'marker ^ 1' onClassNamed: self emptyParentClassName.
	self assert: (command subclassesBlockingRemovalOf: parent) equals: { self emptyChildClassName }.
	command := MCPRemoveClassesCommand classNames: {
			           self emptyParentClassName.
			           self emptyChildClassName }.
	self assertEmpty: (command subclassesBlockingRemovalOf: parent)
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testTheScanFindsReferencesOutsideTheClassesAskedFor [
	"The command finds the methods that access a class's binding, as method_reference_search does. A class asked for does not count, on either side."

	| command references |
	command := MCPRemoveClassesCommand classNames: { self referencedClassName }.
	references := command referencesOutsideRemoval.
	self assert: references keys asArray equals: { self referencedClassName }.
	self
		assert: (command referenceListOf: (references at: self referencedClassName))
		equals: ('{1}>>useReferencedClass' format: { self senderClassName }).
	self withoutEpiceaDuring: [
			(self classNamed: self referencedClassName) classSide
				compile: ('make ^ {1} new' format: { self referencedClassName })
				classified: 'tests' ].
	references := (MCPRemoveClassesCommand classNames: {
			               self referencedClassName.
			               self senderClassName }) referencesOutsideRemoval.
	self assertEmpty: references
]
