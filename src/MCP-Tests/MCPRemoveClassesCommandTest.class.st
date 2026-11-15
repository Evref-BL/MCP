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
	"Removed in reverse order, so a trait's user goes before the trait."

	^ {
		  self simpleClassName.
		  self emptyParentClassName.
		  self emptyChildClassName.
		  self referencedClassName.
		  self senderClassName.
		  self usedTraitName.
		  self traitUserClassName.
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
	self
		assert: ((error details at: #referencedBy) at: self referencedClassName)
		equals: { ('{1}>>useReferencedClass' format: { self senderClassName }) }.
	self assert: (error details at: #forceSupported) equals: self refactoringsRefuseBreakingChanges not.
	self assert: (Smalltalk globals includesKey: self referencedClassName asSymbol)
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testATraitsUsersAreItsBlockingUsersBeforePharo12 [
	"The users Pharo 10 and 11 count, by name; a class is no trait and has none."

	| command trait |
	self withoutEpiceaDuring: [
			trait := (Trait << self usedTraitName asSymbol)
				         package: 'MCP-Tests';
				         install.
			(Object << self traitUserClassName asSymbol)
				traits: trait;
				package: 'MCP-Tests';
				install ].
	command := MCPRemoveClassesCommand classNames: #(  ).
	self assert: (command traitUserNamesOf: trait) equals: { self traitUserClassName }.
	self assertEmpty: (command traitUserNamesOf: Object)
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
	self
		assert: result warningMessages
		equals: { ('1 method still referred to {1} and now refers to an undeclared variable: {2}>>useReferencedClass.' format: {
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

	| command |
	command := MCPRemoveClassesCommand classNames: { self emptyParentClassName }.
	self assertEmpty: command subclassesBlockingRemoval.
	self ensureMethodSource: 'marker ^ 1' onClassNamed: self emptyParentClassName.
	command := MCPRemoveClassesCommand classNames: { self emptyParentClassName }.
	self
		assert: (command subclassNamesOf: (self classNamed: self emptyParentClassName) excluding: #(  ))
		equals: { self emptyChildClassName }.
	self assertEmpty: (command subclassNamesOf: (self classNamed: self emptyParentClassName) excluding: { self emptyChildClassName }).
	self assert: (command subclassesBlockingRemoval at: self emptyParentClassName) equals: { self emptyChildClassName }
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
	"Pharo 10 and 11 keep no list of what refers to a class, so the command scans for the methods that access its binding, as method_reference_search does. A class asked for does not count, on either side."

	| references |
	references := (MCPRemoveClassesCommand classNames: { self referencedClassName }) referencesOutsideRemoval.
	self assert: references keys asArray equals: { self referencedClassName }.
	self
		assert: (MCPClassRemovalFacts referenceTextsOf: (references at: self referencedClassName))
		equals: { ('{1}>>useReferencedClass' format: { self senderClassName }) }.
	self withoutEpiceaDuring: [
			(self classNamed: self referencedClassName) classSide
				compile: ('make ^ {1} new' format: { self referencedClassName })
				classified: 'tests' ].
	references := (MCPRemoveClassesCommand classNames: {
			               self referencedClassName.
			               self senderClassName }) referencesOutsideRemoval.
	self assertEmpty: references
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> traitUserClassName [

	^ self fixturePrefix , 'TraitUser'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> usedTraitName [

	^ 'T' , self fixturePrefix , 'Used'
]
