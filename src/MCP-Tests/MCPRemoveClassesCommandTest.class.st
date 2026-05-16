Class {
	#name : 'MCPRemoveClassesCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPRemoveClassesCommandTest >> batchClassNames [

	^ {
		  self simpleClassName.
		  self packageCleanupClassName } asArray
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> createClassNamed: aClassName superclassName: aSuperclassName [

	^ self
		  createClassNamed: aClassName
		  superclassName: aSuperclassName
		  packageName: 'MCP-Tests'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> createClassNamed: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ self withoutEpiceaDuring: [
		  | builder superclass |
		  superclass := self classNamed: aSuperclassName.
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
	self
		createClassNamed: self emptyParentClassName
		superclassName: 'Object'.
	self
		createClassNamed: self emptyChildClassName
		superclassName: self emptyParentClassName.
	self
		createClassNamed: self referencedClassName
		superclassName: 'Object'.
	self createClassNamed: self senderClassName superclassName: 'Object'.
	self
		ensureMethodSource: self referenceSenderMethodSource
		onClassNamed: self senderClassName.
	self
		createClassNamed: self packageCleanupClassName
		superclassName: 'Object'
		packageName: self packageCleanupPackageName
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
		(self classNamed: aClassName)
			compile: aMethodSource
			classified: 'tests' ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> fixtureClassNames [

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

	^ 'useReferencedClass ^ ' , self referencedClassName , ' new'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> referencedClassName [

	^ self fixturePrefix , 'Referenced'
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ].
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
MCPRemoveClassesCommandTest >> testForceRemovesReferencedClassAndReturnsWarningMessages [

	| result |
	result := (MCPRemoveClassesCommand
		           classNames: { self referencedClassName }
		           force: true) execute.
	self deny:
		(Smalltalk globals includesKey: self referencedClassName asSymbol).
	self assert:
		((self classNamed: self senderClassName) includesSelector:
			 #useReferencedClass).
	self assert: result warningMessages size equals: 1.
	self assert: (result warningMessages first includesSubstring:
			 self referencedClassName)
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testMissingClassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPRemoveClassesCommand classNames: {
				          self simpleClassName.
				          self missingClassName }) execute ].
	self assert: error errorCode equals: #ClassNotFound.
	self
		assert: (error structuredDetails at: #className)
		equals: self missingClassName.
	self assert:
		(Smalltalk globals includesKey: self simpleClassName asSymbol)
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testRemovesSimpleClassAndReturnsSnapshot [

	| removedClass result |
	result := (MCPRemoveClassesCommand classNames: self batchClassNames)
		          execute.
	removedClass := result removedClasses detect: [ :each |
		                each classInfo className = self simpleClassName ].
	self deny:
		(Smalltalk globals includesKey: self simpleClassName asSymbol).
	self deny:
		(Smalltalk globals includesKey:
			 self packageCleanupClassName asSymbol).
	self assert: result warningMessages isEmpty.
	self
		assert: (result asDictionary at: #classNames)
		equals: self batchClassNames.
	self assert: removedClass wasEmpty.
	self
		assert: removedClass classInfo className
		equals: self simpleClassName.
	self assert: removedClass reparentedSubclassNames isEmpty.
	self
		assert: result removedPackageNames
		equals: { self packageCleanupPackageName } asArray
]

{ #category : 'tests' }
MCPRemoveClassesCommandTest >> testReparentsDirectSubclassesWhenRemovingEmptyClass [

	| removedClass result |
	result := (MCPRemoveClassesCommand classNames:
		           { self emptyParentClassName }) execute.
	removedClass := result removedClasses first.
	self deny:
		(Smalltalk globals includesKey: self emptyParentClassName asSymbol).
	self
		assert:
		(self classNamed: self emptyChildClassName) superclass name asString
		equals: 'Object'.
	self assert: result warningMessages isEmpty.
	self assert: removedClass wasEmpty.
	self
		assert: removedClass reparentedSubclassNames
		equals: { self emptyChildClassName } asArray.
	self assert: result removedPackageNames isEmpty
]
