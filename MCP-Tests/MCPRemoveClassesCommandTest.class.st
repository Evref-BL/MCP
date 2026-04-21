Class {
	#name : 'MCPRemoveClassesCommandTest',
	#superclass : 'TestCase',
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
MCPRemoveClassesCommandTest >> captureCommandError: aBlock [

	^ [
	  aBlock value.
	  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
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

	| builder superclass |
	superclass := self classNamed: aSuperclassName.
	builder := superclass << aClassName asSymbol.
	builder package: aPackageName.
	builder tag: 'Internal'.
	builder slots: #(  ).
	builder install
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
		createClassNamed: self packageCleanupClassName
		superclassName: 'Object'
		packageName: self packageCleanupPackageName
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> fixtureClassNames [

	^ {
		  self simpleClassName.
		  self emptyParentClassName.
		  self emptyChildClassName.
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
MCPRemoveClassesCommandTest >> removeClassNamed: aClassName [

	(Smalltalk globals includesKey: aClassName asSymbol) ifTrue: [
		(Smalltalk globals at: aClassName asSymbol) removeFromSystem ]
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ].
	self removePackageNamed: self packageCleanupPackageName
]

{ #category : 'private' }
MCPRemoveClassesCommandTest >> removePackageNamed: aPackageName [

	(PackageOrganizer default hasPackage: aPackageName) ifTrue: [
		PackageOrganizer default removePackage: aPackageName ]
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
	self assert: removedClass wasEmpty.
	self
		assert: removedClass reparentedSubclassNames
		equals: { self emptyChildClassName } asArray.
	self assert: result removedPackageNames isEmpty
]
