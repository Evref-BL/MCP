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
MCPToolEditClassTest >> commentTargetClassName [

	^ 'MCPToolEditClassTestCommentTarget'
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
	     'MCPToolEditClassTestTemporaryPackage'
	     'MCPToolEditClassTestCommentTarget'
	     'MCPToolEditClassTestReparentTarget'
	     'MCPToolEditClassTestReparentSuperclass'
	     'MCPToolEditClassTestPullUpTarget'
	     'MCPToolEditClassTestPullUpChildOne'
	     'MCPToolEditClassTestPullUpChildTwo'
	     'MCPToolEditClassTestPushDownTarget'
	     'MCPToolEditClassTestPushDownChildOne'
	     'MCPToolEditClassTestPushDownChildTwo'
	     'MCPToolEditClassTestWarningPullUpTarget'
	     'MCPToolEditClassTestWarningPullUpChildOne'
	     'MCPToolEditClassTestWarningPullUpChildTwo' )
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
MCPToolEditClassTest >> reparentArguments [

	^ {
		  (#operation -> 'reparent').
		  (#className -> self reparentTargetClassName).
		  (#superclassName -> self reparentSuperclassName) } asDictionary
]

{ #category : 'private' }
MCPToolEditClassTest >> reparentSuperclassName [

	^ 'MCPToolEditClassTestReparentSuperclass'
]

{ #category : 'private' }
MCPToolEditClassTest >> reparentTargetClassName [

	^ 'MCPToolEditClassTestReparentTarget'
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

{ #category : 'private' }
MCPToolEditClassTest >> setCommentArgumentsWith: aClassComment [

	^ {
		  (#operation -> 'setComment').
		  (#className -> self commentTargetClassName).
		  (#classComment -> aClassComment) } asDictionary
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
MCPToolEditClassTest >> slotOperationArgumentsFor: anOperation className: aClassName slotName: aSlotName classSide: aBoolean [

	^ self
		  slotOperationArgumentsFor: anOperation
		  className: aClassName
		  slotName: aSlotName
		  classSide: aBoolean
		  force: false
]

{ #category : 'private' }
MCPToolEditClassTest >> slotOperationArgumentsFor: anOperation className: aClassName slotName: aSlotName classSide: aBoolean force: forceRequested [

	^ {
		  (#operation -> anOperation).
		  (#className -> aClassName).
		  (#slotName -> aSlotName).
		  (#classSide -> aBoolean).
		  (#force -> forceRequested) } asDictionary
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
MCPToolEditClassTest >> testCanClearClassComment [

	| data result target |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self withoutEpiceaDuring: [
		(self classNamed: self commentTargetClassName) comment:
			'original comment' ].
	result := self callToolWith: (self setCommentArgumentsWith: '').
	data := self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target comment equals: ''.
	self assert: (data at: #classComment) equals: ''.
	self assert: (data at: #oldClassComment) equals: 'original comment'.
	self assert: (data at: #newClassComment) equals: ''
]

{ #category : 'tests' }
MCPToolEditClassTest >> testChangesClassComment [

	| data result target |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self withoutEpiceaDuring: [
		(self classNamed: self commentTargetClassName) comment:
			'original comment' ].
	result := self callToolWith:
		          (self setCommentArgumentsWith: 'updated comment').
	data := self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target comment equals: 'updated comment'.
	self assert: (data at: #operation) equals: 'setComment'.
	self assert: (data at: #classComment) equals: 'updated comment'.
	self assert: (data at: #oldClassComment) equals: 'original comment'.
	self assert: (data at: #newClassComment) equals: 'updated comment'
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
MCPToolEditClassTest >> testForcePullUpSlotContinuesPastRefactoringWarningAndReturnsWarnings [

	| childOne childTwo data instance result target warnings |
	self
		createClassNamed: 'MCPToolEditClassTestWarningPullUpTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolEditClassTestWarningPullUpChildOne'
		superclassName: 'MCPToolEditClassTestWarningPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolEditClassTestWarningPullUpChildTwo'
		superclassName: 'MCPToolEditClassTestWarningPullUpTarget'
		slots: #(  )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ sharedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolEditClassTestWarningPullUpChildOne').
	result := self callToolWith: (self
			           slotOperationArgumentsFor: 'pullUpSlot'
			           className: 'MCPToolEditClassTestWarningPullUpTarget'
			           slotName: 'sharedSlot'
			           classSide: false
			           force: true).
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	target := self classNamed: 'MCPToolEditClassTestWarningPullUpTarget'.
	childOne := self classNamed:
		            'MCPToolEditClassTestWarningPullUpChildOne'.
	childTwo := self classNamed:
		            'MCPToolEditClassTestWarningPullUpChildTwo'.
	instance := childOne new.
	instance instVarNamed: 'sharedSlot' put: 17.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (warnings anySatisfy: [ :each |
			 each includesSubstring:
				 'Not all subclasses have an instance variable named' ]).
	self
		assert: (target slots collect: #name as: Array)
		equals: #( #sharedSlot ).
	self assert: (childOne slots collect: #name as: Array) equals: #(  ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  ).
	self assert: instance slotProbe equals: 17.
	self assert: (data at: #operation) equals: 'pullUpSlot'.
	self assert: (data at: #slotName) equals: 'sharedSlot'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #instanceSlotNames) equals: #( 'sharedSlot' )
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
MCPToolEditClassTest >> testPullUpSlotReturnsStructuredCommandErrorForRefactoringFailure [

	| error result structured |
	result := self callToolWith: (self
			           slotOperationArgumentsFor: 'pullUpSlot'
			           className: 'MCPToolEditMethodTestTarget'
			           slotName: 'missingSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self
		assert: (error at: #errorCode)
		equals: 'PullUpSlotRefactoringError'.
	self assert: (error at: #causeClass) equals: 'RBRefactoringError'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditMethodTestTarget'.
	self assert: (error at: #slotName) equals: 'missingSlot'.
	self assert: (error at: #classSide) equals: false.
	self assert: ((error at: #message) includesSubstring: 'missingSlot')
]

{ #category : 'tests' }
MCPToolEditClassTest >> testPullUpSlotStopsOnRefactoringWarningByDefault [

	| childOne childTwo error result structured target |
	self
		createClassNamed: 'MCPToolEditClassTestWarningPullUpTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolEditClassTestWarningPullUpChildOne'
		superclassName: 'MCPToolEditClassTestWarningPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolEditClassTestWarningPullUpChildTwo'
		superclassName: 'MCPToolEditClassTestWarningPullUpTarget'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: (self
			           slotOperationArgumentsFor: 'pullUpSlot'
			           className: 'MCPToolEditClassTestWarningPullUpTarget'
			           slotName: 'sharedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	target := self classNamed: 'MCPToolEditClassTestWarningPullUpTarget'.
	childOne := self classNamed:
		            'MCPToolEditClassTestWarningPullUpChildOne'.
	childTwo := self classNamed:
		            'MCPToolEditClassTestWarningPullUpChildTwo'.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self
		assert: (error at: #errorCode)
		equals: 'PullUpSlotRefactoringWarning'.
	self assert: (error at: #causeClass) equals: 'RBRefactoringWarning'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestWarningPullUpTarget'.
	self assert: (error at: #slotName) equals: 'sharedSlot'.
	self assert: (error at: #classSide) equals: false.
	self assert: (error at: #forceSupported) equals: true.
	self assert:
		((error at: #howToProceed) includesSubstring: 'force=true').
	self assert: ((error at: #impactMessages) anySatisfy: [ :each |
			 each includesSubstring:
				 'Not all subclasses have an instance variable named' ]).
	self assert: (target slots collect: #name as: Array) equals: #(  ).
	self
		assert: (childOne slots collect: #name as: Array)
		equals: #( #sharedSlot ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  )
]

{ #category : 'tests' }
MCPToolEditClassTest >> testPullsUpInstanceSlotAcrossSubclasses [

	| childOne childTwo data instance result target |
	self
		createClassNamed: 'MCPToolEditClassTestPullUpTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolEditClassTestPullUpChildOne'
		superclassName: 'MCPToolEditClassTestPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolEditClassTestPullUpChildTwo'
		superclassName: 'MCPToolEditClassTestPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ sharedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolEditClassTestPullUpChildOne').
	result := self callToolWith: (self
			           slotOperationArgumentsFor: 'pullUpSlot'
			           className: 'MCPToolEditClassTestPullUpTarget'
			           slotName: 'sharedSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolEditClassTestPullUpTarget'.
	childOne := self classNamed: 'MCPToolEditClassTestPullUpChildOne'.
	childTwo := self classNamed: 'MCPToolEditClassTestPullUpChildTwo'.
	instance := childOne new.
	instance instVarNamed: 'sharedSlot' put: 41.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (target slots collect: #name as: Array)
		equals: #( #sharedSlot ).
	self assert: (childOne slots collect: #name as: Array) equals: #(  ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  ).
	self assert: instance slotProbe equals: 41.
	self assert: (data at: #operation) equals: 'pullUpSlot'.
	self assert: (data at: #slotName) equals: 'sharedSlot'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #instanceSlotNames) equals: #( 'sharedSlot' ).
	self
		assert: (data at: #affectedClassNames) asSet
		equals: #( 'MCPToolEditClassTestPullUpChildOne'
			   'MCPToolEditClassTestPullUpChildTwo' ) asSet
]

{ #category : 'tests' }
MCPToolEditClassTest >> testPushesDownClassSlotToDirectSubclasses [

	| childOne childTwo data result target |
	self
		createClassNamed: 'MCPToolEditClassTestPushDownTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #( sharedClassSlot ).
	self
		createClassNamed: 'MCPToolEditClassTestPushDownChildOne'
		superclassName: 'MCPToolEditClassTestPushDownTarget'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolEditClassTestPushDownChildTwo'
		superclassName: 'MCPToolEditClassTestPushDownTarget'
		slots: #(  )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ sharedClassSlot'
		protocol: 'testing'
		on:
		(self classNamed: 'MCPToolEditClassTestPushDownChildOne') classSide.
	result := self callToolWith: (self
			           slotOperationArgumentsFor: 'pushDownSlot'
			           className: 'MCPToolEditClassTestPushDownTarget'
			           slotName: 'sharedClassSlot'
			           classSide: true).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolEditClassTestPushDownTarget'.
	childOne := self classNamed: 'MCPToolEditClassTestPushDownChildOne'.
	childTwo := self classNamed: 'MCPToolEditClassTestPushDownChildTwo'.
	childOne instVarNamed: 'sharedClassSlot' put: 23.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (target classSide slots collect: #name as: Array)
		equals: #(  ).
	self
		assert: (childOne classSide slots collect: #name as: Array)
		equals: #( #sharedClassSlot ).
	self
		assert: (childTwo classSide slots collect: #name as: Array)
		equals: #( #sharedClassSlot ).
	self assert: childOne slotProbe equals: 23.
	self assert: (data at: #operation) equals: 'pushDownSlot'.
	self assert: (data at: #slotName) equals: 'sharedClassSlot'.
	self assert: (data at: #classSide) equals: true.
	self assert: (data at: #classSlotNames) equals: #(  ).
	self
		assert: (data at: #affectedClassNames) asSet
		equals: #( 'MCPToolEditClassTestPushDownChildOne'
			   'MCPToolEditClassTestPushDownChildTwo' ) asSet
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
MCPToolEditClassTest >> testReparentsClassAndPreservesExistingState [

	| data result target |
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
			'reparent comment' ].
	result := self callToolWith: self reparentArguments.
	data := self dataFrom: result.
	target := self classNamed: self reparentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: target superclass name asString
		equals: self reparentSuperclassName.
	self assert: target new probeMethod equals: 41.
	self assert: target comment equals: 'reparent comment'.
	self assert: (data at: #operation) equals: 'reparent'.
	self assert: (data at: #oldSuperclassName) equals: 'Object'.
	self
		assert: (data at: #superclassName)
		equals: self reparentSuperclassName.
	self assert: (data at: #classComment) equals: 'reparent comment'
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
MCPToolEditClassTest >> testReturnsStructuredErrorWhenCommentClassIsMissing [

	| error result |
	result := self callToolWith: {
			          (#operation -> 'setComment').
			          (#className -> 'MCPToolEditClassTestMissing').
			          (#classComment -> 'ignored') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'setComment'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #message)
		equals: 'Class MCPToolEditClassTestMissing does not exist.'
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
MCPToolEditClassTest >> testReturnsStructuredErrorWhenPullUpSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           slotOperationArgumentsFor: 'pullUpSlot'
			           className: 'MCPToolEditClassTestMissingPullUp'
			           slotName: 'sharedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestMissingPullUp'.
	self assert: (error at: #slotName) equals: 'sharedSlot'.
	self assert: (error at: #classSide) equals: false
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
MCPToolEditClassTest >> testReturnsStructuredErrorWhenReparentSuperclassIsMissing [

	| error result |
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: {
			          (#operation -> 'reparent').
			          (#className -> self reparentTargetClassName).
			          (#superclassName -> 'DefinitelyMissingSuperclass') }
			          asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'reparent'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SuperclassNotFound'.
	self
		assert: (error at: #superclassName)
		equals: 'DefinitelyMissingSuperclass'
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

	| operationProperty propertyNames |
	propertyNames := MCPToolEditClass new inputSchema properties
		                 collect: [ :each | each name ].
	operationProperty := MCPToolEditClass new inputSchema properties
		                     detect: [ :each | each name = 'operation' ].
	self
		assert: MCPToolEditClass new inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet.
	self assert: (propertyNames includes: 'classComment').
	self assert: (propertyNames includes: 'slotName').
	self assert: (propertyNames includes: 'classSide').
	self
		assert: (operationProperty extraProperties at: #enum) asArray
		equals:
			#( 'create' 'move' 'rename' 'reparent' 'setComment' 'pullUpSlot'
			   'pushDownSlot' )
]

{ #category : 'private - calling' }
MCPToolEditClassTest >> toolName [

	^ 'edit-class'
]
