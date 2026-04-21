Class {
	#name : 'MCPMoveClassCommandTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPMoveClassCommandTest >> captureCommandError: aBlock [

	^ [
	  aBlock value.
	  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private' }
MCPMoveClassCommandTest >> currentTagOfTargetClass [

	^ self targetClass packageTagName asString
]

{ #category : 'private' }
MCPMoveClassCommandTest >> destinationPackageName [

	^ 'MCP-Tests-MoveClass'
]

{ #category : 'private' }
MCPMoveClassCommandTest >> destinationTagName [

	^ 'Moved'
]

{ #category : 'private' }
MCPMoveClassCommandTest >> originalPackageName [

	^ 'MCP-Tests'
]

{ #category : 'private' }
MCPMoveClassCommandTest >> restoreTargetClassLocation [

	(self targetClass packageName asString = self originalPackageName
		 and: [ self currentTagOfTargetClass = 'Uncategorized' ]) ifTrue: [
		^ self ].
	(RBMoveClassTransformation
		 move: self targetClassName
		 toPackage: self originalPackageName) execute
]

{ #category : 'running' }
MCPMoveClassCommandTest >> setUp [

	super setUp.
	self restoreTargetClassLocation
]

{ #category : 'private' }
MCPMoveClassCommandTest >> targetClass [

	^ MCPToolMoveClassTestTarget
]

{ #category : 'private' }
MCPMoveClassCommandTest >> targetClassName [

	^ 'MCPToolMoveClassTestTarget'
]

{ #category : 'running' }
MCPMoveClassCommandTest >> tearDown [

	self restoreTargetClassLocation.
	super tearDown
]

{ #category : 'tests' }
MCPMoveClassCommandTest >> testMissingDestinationTagSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPMoveClassCommand
			          className: self targetClassName
			          packageName: self destinationPackageName
			          tag: 'DefinitelyMissing') execute ].
	self assert: error errorCode equals: #TagNotFound.
	self
		assert: (error structuredDetails at: #className)
		equals: self targetClassName.
	self
		assert: (error structuredDetails at: #tag)
		equals: 'DefinitelyMissing'
]

{ #category : 'tests' }
MCPMoveClassCommandTest >> testMissingPackageSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPMoveClassCommand
			          className: self targetClassName
			          packageName: 'MCP-Definitely-Missing'
			          tag: nil) execute ].
	self assert: error errorCode equals: #PackageNotFound.
	self
		assert: (error structuredDetails at: #packageName)
		equals: 'MCP-Definitely-Missing'
]

{ #category : 'tests' }
MCPMoveClassCommandTest >> testMovesClassAndReturnsResultObject [

	| result |
	result := (MCPMoveClassCommand
		           className: self targetClassName
		           packageName: self destinationPackageName
		           tag: self destinationTagName) execute.
	self
		assert: self targetClass packageName asString
		equals: self destinationPackageName.
	self
		assert: self currentTagOfTargetClass
		equals: self destinationTagName.
	self assert: result oldPackageName equals: self originalPackageName.
	self assert: result oldTag equals: 'Uncategorized'.
	self assert: result classInfo className equals: self targetClassName
]
