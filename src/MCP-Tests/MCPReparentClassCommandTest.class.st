Class {
	#name : 'MCPReparentClassCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPReparentClassCommandTest >> ensureFixtureClasses [

	self removeFixtureClasses.
	self
		createClassNamed: self reparentSuperclassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #( alphaSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'probeMethod ^ 41'
		protocol: 'testing'
		on: (self classNamed: self reparentTargetClassName).
	self withoutEpiceaDuring: [
		(self classNamed: self reparentTargetClassName) comment:
			'reparent comment' ]
]

{ #category : 'private' }
MCPReparentClassCommandTest >> fixtureClassNames [

	^ {
		  self reparentTargetClassName.
		  self reparentSuperclassName }
]

{ #category : 'private' }
MCPReparentClassCommandTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ]
]

{ #category : 'private' }
MCPReparentClassCommandTest >> reparentSuperclassName [

	^ 'MCPReparentClassCommandTestNewSuperclass'
]

{ #category : 'private' }
MCPReparentClassCommandTest >> reparentTargetClassName [

	^ 'MCPReparentClassCommandTestTarget'
]

{ #category : 'running' }
MCPReparentClassCommandTest >> setUp [

	super setUp.
	self ensureFixtureClasses
]

{ #category : 'running' }
MCPReparentClassCommandTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPReparentClassCommandTest >> testMissingClassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPReparentClassCommand
			          className: 'MCPReparentClassCommandTestMissing'
			          superclassName: self reparentSuperclassName) execute ].
	self assert: error errorCode equals: #ClassNotFound.
	self
		assert: (error structuredDetails at: #className)
		equals: 'MCPReparentClassCommandTestMissing'
]

{ #category : 'tests' }
MCPReparentClassCommandTest >> testMissingSuperclassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPReparentClassCommand
			          className: self reparentTargetClassName
			          superclassName: 'DefinitelyMissingSuperclass') execute ].
	self assert: error errorCode equals: #SuperclassNotFound.
	self
		assert: (error structuredDetails at: #superclassName)
		equals: 'DefinitelyMissingSuperclass'
]

{ #category : 'tests' }
MCPReparentClassCommandTest >> testReparentsClassAndReturnsResultObject [

	| result target |
	result := self executeCommand: (MCPReparentClassCommand
			           className: self reparentTargetClassName
			           superclassName: self reparentSuperclassName).
	target := self classNamed: self reparentTargetClassName.
	self
		assert: target superclass name asString
		equals: self reparentSuperclassName.
	self assert: target new probeMethod equals: 41.
	self assert: target comment equals: 'reparent comment'.
	self
		assert: (target slots collect: #name as: Array)
		equals: #( #alphaSlot ).
	self assert: result oldSuperclassName equals: 'Object'.
	self
		assert: result classInfo className
		equals: self reparentTargetClassName.
	self
		assert: result classInfo superclassName
		equals: self reparentSuperclassName
]
