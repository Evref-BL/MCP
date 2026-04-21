Class {
	#name : 'MCPRemoveClassCommandTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPRemoveClassCommandTest >> captureCommandError: aBlock [

	^ [
	  aBlock value.
	  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> createClassNamed: aClassName superclassName: aSuperclassName [

	| builder superclass |
	superclass := self classNamed: aSuperclassName.
	builder := superclass << aClassName asSymbol.
	builder package: 'MCP-Tests'.
	builder tag: 'Internal'.
	builder slots: #(  ).
	builder install
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> emptyChildClassName [

	^ 'MCPRemoveClassCommandTestEmptyChild'
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> emptyParentClassName [

	^ 'MCPRemoveClassCommandTestEmptyParent'
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> ensureFixtureClasses [

	self removeFixtureClasses.
	self createClassNamed: self simpleClassName superclassName: 'Object'.
	self
		createClassNamed: self emptyParentClassName
		superclassName: 'Object'.
	self
		createClassNamed: self emptyChildClassName
		superclassName: self emptyParentClassName
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> fixtureClassNames [

	^ {
		  self simpleClassName.
		  self emptyParentClassName.
		  self emptyChildClassName }
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> missingClassName [

	^ 'MCPRemoveClassCommandTestMissing'
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> removeClassNamed: aClassName [

	(Smalltalk globals includesKey: aClassName asSymbol) ifTrue: [
		(Smalltalk globals at: aClassName asSymbol) removeFromSystem ]
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'running' }
MCPRemoveClassCommandTest >> setUp [

	super setUp.
	self ensureFixtureClasses
]

{ #category : 'private' }
MCPRemoveClassCommandTest >> simpleClassName [

	^ 'MCPRemoveClassCommandTestSimple'
]

{ #category : 'running' }
MCPRemoveClassCommandTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPRemoveClassCommandTest >> testMissingClassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPRemoveClassCommand className: self missingClassName)
			         execute ].
	self assert: error errorCode equals: #ClassNotFound.
	self
		assert: (error structuredDetails at: #className)
		equals: self missingClassName
]

{ #category : 'tests' }
MCPRemoveClassCommandTest >> testRemovesSimpleClassAndReturnsSnapshot [

	| result |
	result := (MCPRemoveClassCommand className: self simpleClassName)
		          execute.
	self deny:
		(Smalltalk globals includesKey: self simpleClassName asSymbol).
	self assert: result wasEmpty.
	self assert: result classInfo className equals: self simpleClassName.
	self assert: result reparentedSubclassNames isEmpty
]

{ #category : 'tests' }
MCPRemoveClassCommandTest >> testReparentsDirectSubclassesWhenRemovingEmptyClass [

	| result |
	result := (MCPRemoveClassCommand className: self emptyParentClassName)
		          execute.
	self deny:
		(Smalltalk globals includesKey: self emptyParentClassName asSymbol).
	self
		assert:
		(self classNamed: self emptyChildClassName) superclass name asString
		equals: 'Object'.
	self assert: result wasEmpty.
	self
		assert: result reparentedSubclassNames
		equals: { self emptyChildClassName } asArray
]
