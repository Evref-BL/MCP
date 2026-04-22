Class {
	#name : 'MCPRenameClassCommandTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPRenameClassCommandTest >> captureCommandError: aBlock [

	^ [
	  self withoutEpiceaDuring: [ aBlock value ].
	  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private' }
MCPRenameClassCommandTest >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private' }
MCPRenameClassCommandTest >> ensureOriginalFixtureState [

	| originalSymbol renamedSymbol |
	originalSymbol := self originalClassName asSymbol.
	renamedSymbol := self renamedClassName asSymbol.
	self withoutEpiceaDuring: [
		((Smalltalk globals includesKey: originalSymbol) and: [
			 Smalltalk globals includesKey: renamedSymbol ]) ifTrue: [
			(Smalltalk globals at: renamedSymbol) removeFromSystem ].
		((Smalltalk globals includesKey: renamedSymbol) and: [
			 (Smalltalk globals includesKey: originalSymbol) not ]) ifTrue: [
			(ReRenameClassRefactoring
				 rename: self renamedClassName
				 to: self originalClassName) execute ] ]
]

{ #category : 'private' }
MCPRenameClassCommandTest >> executeCommand: aCommand [

	^ self withoutEpiceaDuring: [ aCommand execute ]
]

{ #category : 'private' }
MCPRenameClassCommandTest >> originalClassName [

	^ 'MCPToolRenameClassTestOriginal'
]

{ #category : 'private' }
MCPRenameClassCommandTest >> renamedClassName [

	^ 'MCPToolRenameClassTestRenamed'
]

{ #category : 'running' }
MCPRenameClassCommandTest >> setUp [

	super setUp.
	self ensureOriginalFixtureState
]

{ #category : 'running' }
MCPRenameClassCommandTest >> tearDown [

	self ensureOriginalFixtureState.
	super tearDown
]

{ #category : 'tests' }
MCPRenameClassCommandTest >> testMissingClassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPRenameClassCommand
			          className: 'MCPRenameClassCommandTestMissing'
			          newClassName: self renamedClassName) execute ].
	self assert: error errorCode equals: #ClassNotFound.
	self
		assert: (error structuredDetails at: #className)
		equals: 'MCPRenameClassCommandTestMissing'
]

{ #category : 'tests' }
MCPRenameClassCommandTest >> testRenamesClassAndReturnsResultObject [

	| result |
	result := self executeCommand: (MCPRenameClassCommand
			           className: self originalClassName
			           newClassName: self renamedClassName).
	self assert:
		(Smalltalk globals includesKey: self renamedClassName asSymbol).
	self deny:
		(Smalltalk globals includesKey: self originalClassName asSymbol).
	self assert: result oldClassName equals: self originalClassName.
	self assert: result newClassName equals: self renamedClassName.
	self assert: result classInfo className equals: self renamedClassName
]
