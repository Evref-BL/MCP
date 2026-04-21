Class {
	#name : 'MCPToolMoveClassTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolMoveClassTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'pharo-move-class' withParams: someArguments
]

{ #category : 'private' }
MCPToolMoveClassTest >> currentTagOfTargetClass [

	^ self targetClass packageTagName asString
]

{ #category : 'private' }
MCPToolMoveClassTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolMoveClassTest >> destinationPackageName [

	^ 'MCP-Tests-MoveClass'
]

{ #category : 'private' }
MCPToolMoveClassTest >> destinationTagName [

	^ 'Moved'
]

{ #category : 'private' }
MCPToolMoveClassTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolMoveClassTest >> moveToPackageAndTagArguments [

	^ {
		  (#className -> self targetClassName).
		  (#packageName -> self destinationPackageName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClassTest >> moveToPackageArguments [

	^ {
		  (#className -> self targetClassName).
		  (#packageName -> self destinationPackageName) } asDictionary
]

{ #category : 'private' }
MCPToolMoveClassTest >> originalPackageName [

	^ 'MCP-Tests'
]

{ #category : 'private' }
MCPToolMoveClassTest >> restoreTargetClassLocation [

	(self targetClass packageName asString = self originalPackageName
		 and: [ self currentTagOfTargetClass = 'Uncategorized' ]) ifTrue: [
		^ self ].
	(RBMoveClassTransformation
		 move: self targetClassName
		 toPackage: self originalPackageName) execute
]

{ #category : 'running' }
MCPToolMoveClassTest >> setUp [

	super setUp.
	self restoreTargetClassLocation
]

{ #category : 'private' }
MCPToolMoveClassTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'private' }
MCPToolMoveClassTest >> targetClass [

	^ MCPToolMoveClassTestTarget
]

{ #category : 'private' }
MCPToolMoveClassTest >> targetClassName [

	^ 'MCPToolMoveClassTestTarget'
]

{ #category : 'running' }
MCPToolMoveClassTest >> tearDown [

	self restoreTargetClassLocation.
	super tearDown
]

{ #category : 'tests' }
MCPToolMoveClassTest >> testMovesClassToAnotherPackage [

	| data result |
	result := self callToolWith: self moveToPackageArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: self targetClass packageName asString
		equals: self destinationPackageName.
	self assert: (data at: #className) equals: self targetClassName.
	self
		assert: (data at: #oldPackageName)
		equals: self originalPackageName.
	self
		assert: (data at: #packageName)
		equals: self destinationPackageName.
	self assert: (data at: #oldTag) equals: 'Uncategorized'.
	self assert: (data at: #tag) equals: self currentTagOfTargetClass.
	self assert: (data at: #superclassName) equals: 'Object'
]

{ #category : 'tests' }
MCPToolMoveClassTest >> testMovesClassToExistingTag [

	| data result |
	result := self callToolWith: self moveToPackageAndTagArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: self targetClass packageName asString
		equals: self destinationPackageName.
	self
		assert: self currentTagOfTargetClass
		equals: self destinationTagName.
	self
		assert: (data at: #packageName)
		equals: self destinationPackageName.
	self assert: (data at: #tag) equals: self destinationTagName
]

{ #category : 'tests' }
MCPToolMoveClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#className -> 'MCPToolMoveClassTestMissing').
			          (#packageName -> self destinationPackageName) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolMoveClassTestMissing'
]

{ #category : 'tests' }
MCPToolMoveClassTest >> testReturnsStructuredErrorWhenDestinationTagIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#className -> self targetClassName).
			          (#packageName -> self destinationPackageName).
			          (#tag -> 'DefinitelyMissing') } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'TagNotFound'.
	self assert: (error at: #className) equals: self targetClassName.
	self
		assert: (error at: #packageName)
		equals: self destinationPackageName.
	self assert: (error at: #tag) equals: 'DefinitelyMissing'
]

{ #category : 'tests' }
MCPToolMoveClassTest >> testToolRequiresClassNameAndPackageNameInSchema [

	self
		assert: MCPToolMoveClass new inputSchema required asSet
		equals: #( 'className' 'packageName' ) asSet
]
