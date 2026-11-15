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
MCPRemoveClassesCommandTest >> batchClassNames [

	^ {
		  self simpleClassName.
		  self packageCleanupClassName } asArray
]

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
	self createClassNamed: self simpleClassName superclassName: 'Object'.
	self createClassNamed: self emptyParentClassName superclassName: 'Object'.
	self createClassNamed: self emptyChildClassName superclassName: self emptyParentClassName.
	self createClassNamed: self referencedClassName superclassName: 'Object'.
	self createClassNamed: self senderClassName superclassName: 'Object'.
	self ensureMethodSource: self referenceSenderMethodSource onClassNamed: self senderClassName.
	self createClassNamed: self packageCleanupClassName superclassName: 'Object' packageName: self packageCleanupPackageName
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) compile: aMethodSource classified: 'tests' ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> fixtureClassNames [
	"Removed in reverse order, so a subclass goes before its superclass."

	^ {
		  self simpleClassName.
		  self emptyParentClassName.
		  self emptyChildClassName.
		  self referencedClassName.
		  self senderClassName.
		  self packageCleanupClassName }
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> packageCleanupClassName [

	^ self fixturePrefix , 'PackageCleanup'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> packageCleanupPackageName [

	^ self fixturePrefix , '-PackageCleanup'
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

	self fixtureClassNames reverseDo: [ :each | self removeClassNamed: each ].
	self removePackageNamed: self packageCleanupPackageName
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

{ #category : 'private' }
MCPRemoveClassesCommandTest >> simpleClassName [

	^ self fixturePrefix , 'Simple'
]

{ #category : 'running' }
MCPRemoveClassesCommandTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testABlockedRemovalSignalsWhatBlocksIt [

	| error |
	error := self captureCommandError: [ (MCPRemoveClassesCommand classNames: { self referencedClassName }) execute ].
	self assert: error errorCode equals: #ClassRemovalBlocked.
	self assert: (error details at: #classes) equals: { self referencedClassName }.
	self assert: (error details at: #impactMessages) equals: { ('{1} is referred to by {2}>>useReferencedClass.' format: {
				 self referencedClassName.
				 self senderClassName }) }.
	self assert: (error details at: #forceSupported) equals: self refactoringsRefuseBreakingChanges not.
	self assert: (Smalltalk globals includesKey: self referencedClassName asSymbol)
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testForceRemovesReferencedClassAndReturnsWarningMessages [

	| error result |
	self refactoringsRefuseBreakingChanges ifTrue: [
			error := self captureCommandError: [ (MCPRemoveClassesCommand classNames: { self referencedClassName } force: true) execute ].
			self assert: error errorCode equals: #ClassRemovalBlocked.
			self deny: (error details at: #forceSupported).
			^ self assert: (Smalltalk globals includesKey: self referencedClassName asSymbol) ].
	result := (MCPRemoveClassesCommand classNames: { self referencedClassName } force: true) execute.
	self deny: (Smalltalk globals includesKey: self referencedClassName asSymbol).
	self assert: ((self classNamed: self senderClassName) includesSelector: #useReferencedClass).
	self assert: result warningMessages equals: { ('{1} is referred to by {2}>>useReferencedClass.' format: {
				 self referencedClassName.
				 self senderClassName }) }
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testMissingClassSignalsCommandError [

	| error |
	error := self captureCommandError: [
			         (MCPRemoveClassesCommand classNames: {
					          self simpleClassName.
					          self missingClassName }) execute ].
	self assert: error errorCode equals: #ClassNotFound.
	self assert: (error structuredDetails at: #class) equals: self missingClassName.
	self assert: (Smalltalk globals includesKey: self simpleClassName asSymbol)
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
MCPRemoveClassesCommandTest >> testRemovesSimpleClassAndReturnsSnapshot [

	| removedClass removedClassNames result |
	result := (MCPRemoveClassesCommand classNames: self batchClassNames) execute.
	removedClass := result removedClasses detect: [ :each | each classInfo className = self simpleClassName ].
	removedClassNames := result removedClasses collect: [ :each | each classInfo className ] as: Array.
	self deny: (Smalltalk globals includesKey: self simpleClassName asSymbol).
	self deny: (Smalltalk globals includesKey: self packageCleanupClassName asSymbol).
	self assert: result warningMessages isEmpty.
	self assert: removedClassNames asSet equals: self batchClassNames asSet.
	self assert: removedClass wasEmpty.
	self assert: removedClass classInfo className equals: self simpleClassName.
	self assert: removedClass reparentedSubclassNames isEmpty.
	self assert: result removedPackageNames equals: { self packageCleanupPackageName } asArray
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testReparentsDirectSubclassesWhenRemovingEmptyClass [

	| removedClass result |
	result := (MCPRemoveClassesCommand classNames: { self emptyParentClassName }) execute.
	removedClass := result removedClasses first.
	self deny: (Smalltalk globals includesKey: self emptyParentClassName asSymbol).
	self assert: (self classNamed: self emptyChildClassName) superclass name asString equals: 'Object'.
	self assert: result warningMessages isEmpty.
	self assert: removedClass wasEmpty.
	self assert: removedClass reparentedSubclassNames equals: { self emptyChildClassName } asArray.
	self assert: result removedPackageNames isEmpty
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
