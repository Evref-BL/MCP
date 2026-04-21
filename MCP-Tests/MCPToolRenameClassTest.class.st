Class {
	#name : 'MCPToolRenameClassTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRenameClassTest >> argumentsForRename [

	^ {
		  (#className -> self originalClassName).
		  (#newClassName -> self renamedClassName) } asDictionary
]

{ #category : 'private' }
MCPToolRenameClassTest >> classNamed: aClassName [

	^ self class environment at: aClassName asSymbol
]

{ #category : 'private' }
MCPToolRenameClassTest >> dataFromResult: aResult [

	^ aResult structuredContent at: #data
]

{ #category : 'private' }
MCPToolRenameClassTest >> ensureOriginalFixtureState [

	| originalSymbol renamedSymbol |
	originalSymbol := self originalClassName asSymbol.
	renamedSymbol := self renamedClassName asSymbol.
	((self class environment includesKey: originalSymbol) and: [
		 self class environment includesKey: renamedSymbol ]) ifTrue: [
		(self class environment at: renamedSymbol) removeFromSystem ].
	((self class environment includesKey: renamedSymbol) and: [
		 (self class environment includesKey: originalSymbol) not ])
		ifTrue: [
			(ReRenameClassRefactoring
				 rename: self renamedClassName
				 to: self originalClassName) execute ]
]

{ #category : 'private' }
MCPToolRenameClassTest >> errorFromResult: aResult [

	^ aResult structuredContent at: #error
]

{ #category : 'private' }
MCPToolRenameClassTest >> originalClassName [

	^ 'MCPToolRenameClassTestOriginal'
]

{ #category : 'private' }
MCPToolRenameClassTest >> referenceClassName [

	^ 'MCPToolRenameClassTestReference'
]

{ #category : 'private' }
MCPToolRenameClassTest >> renamedClassName [

	^ 'MCPToolRenameClassTestRenamed'
]

{ #category : 'running' }
MCPToolRenameClassTest >> setUp [

	super setUp.
	self ensureOriginalFixtureState
]

{ #category : 'private' }
MCPToolRenameClassTest >> subclassName [

	^ 'MCPToolRenameClassTestSubclass'
]

{ #category : 'running' }
MCPToolRenameClassTest >> tearDown [

	self ensureOriginalFixtureState.
	super tearDown
]

{ #category : 'tests' }
MCPToolRenameClassTest >> testRenameUpdatesMethodReferences [

	| reference |
	self tool executeWithArguments: self argumentsForRename.
	reference := (self classNamed: self referenceClassName) new.
	self
		assert: reference referencedClass name asString
		equals: self renamedClassName.
	self
		assert: reference newReferencedInstance class name asString
		equals: self renamedClassName
]

{ #category : 'tests' }
MCPToolRenameClassTest >> testRenameUpdatesSubclassDefinitions [

	self tool executeWithArguments: self argumentsForRename.
	self
		assert:
		(self classNamed: self subclassName) superclass name asString
		equals: self renamedClassName
]

{ #category : 'tests' }
MCPToolRenameClassTest >> testRenamesAClassAndReturnsStructuredData [

	| data result |
	result := self tool executeWithArguments: self argumentsForRename.
	data := self dataFromResult: result.
	self deny: result isError.
	self assert:
		(self class environment includesKey: self renamedClassName asSymbol).
	self deny:
		(self class environment includesKey: self originalClassName asSymbol).
	self assert: (data at: #oldClassName) equals: self originalClassName.
	self assert: (data at: #newClassName) equals: self renamedClassName.
	self assert: (data at: #superclassName) equals: 'Object'.
	self assert: (data at: #packageName) equals: 'MCP-Tests'.
	self
		assert: (data at: #subclassNames)
		equals: { self subclassName } asArray
]

{ #category : 'tests' }
MCPToolRenameClassTest >> testReturnsAnErrorForMissingClass [

	| error result |
	result := self tool executeWithArguments: {
			          (#className -> 'MCPToolRenameClassTestMissing').
			          (#newClassName -> self renamedClassName) } asDictionary.
	error := self errorFromResult: result.
	self assert: result isError.
	self assert: (error at: #errorClass) equals: 'ClassNotFound'.
	self
		assert: (error at: #message)
		equals: 'Class MCPToolRenameClassTestMissing does not exist.'
]

{ #category : 'private' }
MCPToolRenameClassTest >> tool [

	^ MCPToolRenameClass new
]
