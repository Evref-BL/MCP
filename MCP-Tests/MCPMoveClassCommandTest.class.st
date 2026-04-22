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
	  self withoutEpiceaDuring: [ aBlock value ].
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
MCPMoveClassCommandTest >> ensureDestinationPackage [

	self withoutEpiceaDuring: [
		| package |
		package := PackageOrganizer default ensurePackage:
			           self destinationPackageName.
		package ensureTag: self destinationTagName ]
]

{ #category : 'private' }
MCPMoveClassCommandTest >> executeCommand: aCommand [

	^ self withoutEpiceaDuring: [ aCommand execute ]
]

{ #category : 'private' }
MCPMoveClassCommandTest >> originalPackageName [

	^ 'MCP-Tests-Resources'
]

{ #category : 'private' }
MCPMoveClassCommandTest >> removeDestinationPackage [

	self withoutEpiceaDuring: [
		(PackageOrganizer default hasPackage: self destinationPackageName)
			ifTrue: [
				PackageOrganizer default removePackage:
					(PackageOrganizer default packageNamed:
						 self destinationPackageName) ] ]
]

{ #category : 'private' }
MCPMoveClassCommandTest >> restoreTargetClassLocation [

	(self targetClass packageName asString = self originalPackageName
		 and: [ self currentTagOfTargetClass = 'Uncategorized' ]) ifTrue: [
		^ self ].
	self withoutEpiceaDuring: [
		(RBMoveClassTransformation
			 move: self targetClassName
			 toPackage: self originalPackageName) execute ]
]

{ #category : 'running' }
MCPMoveClassCommandTest >> setUp [

	super setUp.
	self restoreTargetClassLocation.
	self removeDestinationPackage.
	self ensureDestinationPackage
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
	self removeDestinationPackage.
	super tearDown
]

{ #category : 'tests' }
MCPMoveClassCommandTest >> testEnsuresMissingDestinationPackageBeforeMovingClass [

	| result |
	self removeDestinationPackage.
	result := self executeCommand: (MCPMoveClassCommand
			           className: self targetClassName
			           packageName: self destinationPackageName
			           tag: nil).
	self assert:
		(PackageOrganizer default hasPackage: self destinationPackageName).
	self
		assert: self targetClass packageName asString
		equals: self destinationPackageName.
	self assert: result oldPackageName equals: self originalPackageName
]

{ #category : 'tests' }
MCPMoveClassCommandTest >> testEnsuresMissingDestinationTagBeforeMovingClass [

	| package result |
	self removeDestinationPackage.
	self withoutEpiceaDuring: [
		PackageOrganizer default ensurePackage: self destinationPackageName ].
	result := self executeCommand: (MCPMoveClassCommand
			           className: self targetClassName
			           packageName: self destinationPackageName
			           tag: self destinationTagName).
	package := PackageOrganizer default packageNamed:
		           self destinationPackageName.
	self assert: (package hasTag: self destinationTagName).
	self
		assert: self targetClass packageName asString
		equals: self destinationPackageName.
	self
		assert: self currentTagOfTargetClass
		equals: self destinationTagName.
	self assert: result oldPackageName equals: self originalPackageName
]

{ #category : 'tests' }
MCPMoveClassCommandTest >> testMissingDestinationTagSignalsCommandError [

	self testEnsuresMissingDestinationTagBeforeMovingClass
]

{ #category : 'tests' }
MCPMoveClassCommandTest >> testMovesClassAndReturnsResultObject [

	| result |
	result := self executeCommand: (MCPMoveClassCommand
			           className: self targetClassName
			           packageName: self destinationPackageName
			           tag: self destinationTagName).
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
