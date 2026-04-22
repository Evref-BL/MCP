Class {
	#name : 'MCPToolEditClassTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private - calling' }
MCPToolEditClassTest >> aroundToolCall: aBlock [

	^ self withoutEpiceaDuring: aBlock
]

{ #category : 'private' }
MCPToolEditClassTest >> createArgumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ self
		  createArgumentsForClassName: aClassName
		  superclassName: aSuperclassName
		  packageName: aPackageName
		  tag: nil
		  slots: nil
		  classSlots: nil
]

{ #category : 'private' }
MCPToolEditClassTest >> createArgumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName tag: aTag slots: someSlots classSlots: someClassSlots [

	| arguments |
	arguments := {
		             (#operation -> 'create').
		             (#className -> aClassName).
		             (#superclassName -> aSuperclassName).
		             (#packageName -> aPackageName) } asDictionary.
	aTag ifNotNil: [ arguments at: #tag put: aTag ].
	someSlots ifNotNil: [ arguments at: #slots put: someSlots ].
	someClassSlots ifNotNil: [
		arguments at: #classSlots put: someClassSlots ].
	^ arguments
]

{ #category : 'private' }
MCPToolEditClassTest >> createdClassNames [

	^ #( 'MCPToolEditClassTestGenerated' 'MCPToolEditClassTestTagged'
	     'MCPToolEditClassTestClassSlots'
	     'MCPToolEditClassTestTemporaryPackage' )
]

{ #category : 'private' }
MCPToolEditClassTest >> currentTagOfMoveTargetClass [

	^ self moveTargetClass packageTagName asString
]

{ #category : 'private' }
MCPToolEditClassTest >> destinationPackageName [

	^ 'MCP-Tests-MoveClass'
]

{ #category : 'private' }
MCPToolEditClassTest >> destinationTagName [

	^ 'Moved'
]

{ #category : 'private' }
MCPToolEditClassTest >> ensureDestinationPackage [

	self withoutEpiceaDuring: [
		| package |
		package := PackageOrganizer default ensurePackage:
			           self destinationPackageName.
		package ensureTag: self destinationTagName ]
]

{ #category : 'private' }
MCPToolEditClassTest >> ensureOriginalRenameFixtureState [

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
MCPToolEditClassTest >> generatedPackageName [

	^ 'MCP-Tests-EditClass'
]

{ #category : 'private' }
MCPToolEditClassTest >> moveTargetClass [

	^ MCPToolMoveClassTestTarget
]

{ #category : 'private' }
MCPToolEditClassTest >> moveTargetClassName [

	^ 'MCPToolMoveClassTestTarget'
]

{ #category : 'private' }
MCPToolEditClassTest >> moveToPackageAndTagArguments [

	^ {
		  (#operation -> 'move').
		  (#className -> self moveTargetClassName).
		  (#packageName -> self destinationPackageName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private' }
MCPToolEditClassTest >> moveToPackageArguments [

	^ {
		  (#operation -> 'move').
		  (#className -> self moveTargetClassName).
		  (#packageName -> self destinationPackageName) } asDictionary
]

{ #category : 'private' }
MCPToolEditClassTest >> originalClassName [

	^ 'MCPToolRenameClassTestOriginal'
]

{ #category : 'private' }
MCPToolEditClassTest >> originalMovePackageName [

	^ 'MCP-Tests-Resources'
]

{ #category : 'private' }
MCPToolEditClassTest >> referenceClassName [

	^ 'MCPToolRenameClassTestReference'
]

{ #category : 'private' }
MCPToolEditClassTest >> removeDestinationPackage [

	self withoutEpiceaDuring: [
		(PackageOrganizer default hasPackage: self destinationPackageName)
			ifTrue: [
				PackageOrganizer default removePackage:
					(PackageOrganizer default packageNamed:
						 self destinationPackageName) ] ]
]

{ #category : 'private' }
MCPToolEditClassTest >> removeGeneratedPackage [

	self withoutEpiceaDuring: [
		(self packageOrganizer hasPackage: self generatedPackageName)
			ifTrue: [
				self packageOrganizer removePackage:
					(self packageOrganizer packageNamed: self generatedPackageName) ] ]
]

{ #category : 'private' }
MCPToolEditClassTest >> renameArguments [

	^ {
		  (#operation -> 'rename').
		  (#className -> self originalClassName).
		  (#newClassName -> self renamedClassName) } asDictionary
]

{ #category : 'private' }
MCPToolEditClassTest >> renamedClassName [

	^ 'MCPToolRenameClassTestRenamed'
]

{ #category : 'private' }
MCPToolEditClassTest >> restoreMoveTargetClassLocation [

	(self moveTargetClass packageName asString
	 = self originalMovePackageName and: [
		 self currentTagOfMoveTargetClass = 'Uncategorized' ]) ifTrue: [
		^ self ].
	self withoutEpiceaDuring: [
		(RBMoveClassTransformation
			 move: self moveTargetClassName
			 toPackage: self originalMovePackageName) execute ]
]

{ #category : 'running' }
MCPToolEditClassTest >> setUp [

	super setUp.
	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage.
	self restoreMoveTargetClassLocation.
	self removeDestinationPackage.
	self ensureDestinationPackage.
	self ensureOriginalRenameFixtureState
]

{ #category : 'private' }
MCPToolEditClassTest >> subclassName [

	^ 'MCPToolRenameClassTestSubclass'
]

{ #category : 'running' }
MCPToolEditClassTest >> tearDown [

	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage.
	self restoreMoveTargetClassLocation.
	self removeDestinationPackage.
	self ensureOriginalRenameFixtureState.
	super tearDown
]

{ #category : 'tests' }
MCPToolEditClassTest >> testCreatesClass [

	| createdClass data result |
	result := self callToolWith: (self
			           createArgumentsForClassName:
			           'MCPToolEditClassTestGenerated'
			           superclassName: 'Object'
			           packageName: self generatedPackageName).
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolEditClassTestGenerated'.
	self assert: createdClass superclass equals: Object.
	self
		assert: createdClass packageName asString
		equals: self generatedPackageName.
	self assert: createdClass slots isEmpty.
	self assert: (data at: #operation) equals: 'create'.
	self
		assert: (data at: #className)
		equals: 'MCPToolEditClassTestGenerated'.
	self assert: (data at: #superclassName) equals: 'Object'.
	self
		assert: (data at: #packageName)
		equals: self generatedPackageName.
	self assert: (data at: #subclassNames) isEmpty
]

{ #category : 'tests' }
MCPToolEditClassTest >> testCreatesClassWithClassSlots [

	| createdClass data result |
	result := self callToolWith: (self
			           createArgumentsForClassName:
			           'MCPToolEditClassTestClassSlots'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: nil
			           slots: nil
			           classSlots: #( 'defaultName' )).
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolEditClassTestClassSlots'.
	self
		assert: (createdClass classSide slots collect: #name as: Array)
		equals: #( #defaultName ).
	self assert: (data at: #classSlotNames) equals: #( 'defaultName' )
]

{ #category : 'tests' }
MCPToolEditClassTest >> testCreatesClassWithSlotsAndTag [

	| createdClass data result |
	result := self callToolWith: (self
			           createArgumentsForClassName:
			           'MCPToolEditClassTestTagged'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: 'Generated'
			           slots: #( 'firstName' 'lastName' )
			           classSlots: nil).
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolEditClassTestTagged'.
	self
		assert: (createdClass slots collect: #name as: Array)
		equals: #( #firstName #lastName ).
	self assert: createdClass packageTagName asString equals: 'Generated'.
	self
		assert: createdClass category asString
		equals: self generatedPackageName , '-Generated'.
	self assert: (data at: #tag) equals: 'Generated'.
	self
		assert: (data at: #instanceSlotNames)
		equals: #( 'firstName' 'lastName' )
]

{ #category : 'tests' }
MCPToolEditClassTest >> testEnsuresMissingDestinationPackageBeforeMovingClass [

	| data result |
	self removeDestinationPackage.
	result := self callToolWith: self moveToPackageArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		(PackageOrganizer default hasPackage: self destinationPackageName).
	self
		assert: self moveTargetClass packageName asString
		equals: self destinationPackageName.
	self
		assert: (data at: #packageName)
		equals: self destinationPackageName.
	self
		assert: (data at: #oldPackageName)
		equals: self originalMovePackageName
]

{ #category : 'tests' }
MCPToolEditClassTest >> testEnsuresMissingDestinationTagBeforeMovingClass [

	| data package result |
	self removeDestinationPackage.
	self withoutEpiceaDuring: [
		PackageOrganizer default ensurePackage: self destinationPackageName ].
	result := self callToolWith: self moveToPackageAndTagArguments.
	data := self dataFrom: result.
	package := PackageOrganizer default packageNamed:
		           self destinationPackageName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (package hasTag: self destinationTagName).
	self
		assert: self moveTargetClass packageName asString
		equals: self destinationPackageName.
	self
		assert: self currentTagOfMoveTargetClass
		equals: self destinationTagName.
	self
		assert: (data at: #packageName)
		equals: self destinationPackageName.
	self assert: (data at: #tag) equals: self destinationTagName
]

{ #category : 'tests' }
MCPToolEditClassTest >> testEnsuresPackageBeforeCreatingClass [

	| createdClass |
	self callToolWith: (self
			 createArgumentsForClassName:
			 'MCPToolEditClassTestTemporaryPackage'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	createdClass := self classNamed:
		                'MCPToolEditClassTestTemporaryPackage'.
	self assert:
		(self packageOrganizer hasPackage: self generatedPackageName).
	self
		assert: createdClass packageName asString
		equals: self generatedPackageName
]

{ #category : 'tests' }
MCPToolEditClassTest >> testMovesClassToAnotherPackage [

	| data result |
	result := self callToolWith: self moveToPackageArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: self moveTargetClass packageName asString
		equals: self destinationPackageName.
	self assert: (data at: #operation) equals: 'move'.
	self assert: (data at: #className) equals: self moveTargetClassName.
	self
		assert: (data at: #oldPackageName)
		equals: self originalMovePackageName.
	self
		assert: (data at: #packageName)
		equals: self destinationPackageName.
	self assert: (data at: #oldTag) equals: 'Uncategorized'.
	self assert: (data at: #tag) equals: self currentTagOfMoveTargetClass.
	self assert: (data at: #superclassName) equals: 'Object'
]

{ #category : 'tests' }
MCPToolEditClassTest >> testMovesClassToExistingTag [

	| data result |
	result := self callToolWith: self moveToPackageAndTagArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: self moveTargetClass packageName asString
		equals: self destinationPackageName.
	self
		assert: self currentTagOfMoveTargetClass
		equals: self destinationTagName.
	self assert: (data at: #operation) equals: 'move'.
	self
		assert: (data at: #packageName)
		equals: self destinationPackageName.
	self assert: (data at: #tag) equals: self destinationTagName
]

{ #category : 'tests' }
MCPToolEditClassTest >> testRenameUpdatesMethodReferences [

	| reference |
	self callToolWith: self renameArguments.
	reference := (self classNamed: self referenceClassName) new.
	self
		assert: reference referencedClass name asString
		equals: self renamedClassName.
	self
		assert: reference newReferencedInstance class name asString
		equals: self renamedClassName
]

{ #category : 'tests' }
MCPToolEditClassTest >> testRenameUpdatesSubclassDefinitions [

	self callToolWith: self renameArguments.
	self
		assert:
		(self classNamed: self subclassName) superclass name asString
		equals: self renamedClassName
]

{ #category : 'tests' }
MCPToolEditClassTest >> testRenamesClassAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self renameArguments.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		(Smalltalk globals includesKey: self renamedClassName asSymbol).
	self deny:
		(Smalltalk globals includesKey: self originalClassName asSymbol).
	self assert: (data at: #operation) equals: 'rename'.
	self assert: (data at: #className) equals: self renamedClassName.
	self assert: (data at: #oldClassName) equals: self originalClassName.
	self assert: (data at: #newClassName) equals: self renamedClassName.
	self assert: (data at: #superclassName) equals: 'Object'.
	self
		assert: (data at: #packageName)
		equals:
		(self classNamed: self renamedClassName) packageName asString.
	self
		assert: (data at: #subclassNames)
		equals: { self subclassName } asArray
]

{ #category : 'tests' }
MCPToolEditClassTest >> testReturnsStructuredErrorWhenClassAlreadyExists [

	| arguments error result |
	arguments := self
		             createArgumentsForClassName:
		             'MCPToolEditClassTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	self callToolWith: arguments.
	result := self callToolWith: arguments.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self
		assert: (error at: #message)
		equals: 'Class MCPToolEditClassTestGenerated already exists.'
]

{ #category : 'tests' }
MCPToolEditClassTest >> testReturnsStructuredErrorWhenDestinationTagIsMissing [

	self testEnsuresMissingDestinationTagBeforeMovingClass
]

{ #category : 'tests' }
MCPToolEditClassTest >> testReturnsStructuredErrorWhenMoveClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#operation -> 'move').
			          (#className -> 'MCPToolEditClassTestMissing').
			          (#packageName -> self destinationPackageName) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'move'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestMissing'
]

{ #category : 'tests' }
MCPToolEditClassTest >> testReturnsStructuredErrorWhenRenameClassIsMissing [

	| error result |
	result := self callToolWith: {
			          (#operation -> 'rename').
			          (#className -> 'MCPToolEditClassTestMissing').
			          (#newClassName -> self renamedClassName) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #message)
		equals: 'Class MCPToolEditClassTestMissing does not exist.'
]

{ #category : 'tests' }
MCPToolEditClassTest >> testReturnsStructuredErrorWhenSuperclassIsMissing [

	| error result |
	result := self callToolWith: (self
			           createArgumentsForClassName:
			           'MCPToolEditClassTestGenerated'
			           superclassName: 'DefinitelyMissingSuperclass'
			           packageName: self generatedPackageName).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'. self assert: (error at: #errorCode) equals: 'SuperclassNotFound'.
	self
		assert: (error at: #superclassName)
		equals: 'DefinitelyMissingSuperclass'
]

{ #category : 'tests' }
MCPToolEditClassTest >> testToolRequiresOperationAndClassNameInSchema [

	self
		assert: MCPToolEditClass new inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet
]

{ #category : 'private - calling' }
MCPToolEditClassTest >> toolName [

	^ 'edit-class'
]
