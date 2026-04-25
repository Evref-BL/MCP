"
Tests the edit-class public contract. Create tests exercise operation=create requests. Update tests exercise operation=update patch requests and verify the structured result data produced by the internal narrow commands.
"
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

{ #category : 'private - create' }
MCPToolEditClassTest >> createRequestArgumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ self createRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#superclassName -> aSuperclassName).
			  (#packageName -> aPackageName) }
]

{ #category : 'private - create' }
MCPToolEditClassTest >> createRequestArgumentsWith: associations [

	| arguments |
	arguments := Dictionary new.
	arguments at: #operation put: 'create'.
	associations do: [ :each | arguments at: each key put: each value ].
	^ arguments
]

{ #category : 'private' }
MCPToolEditClassTest >> createdClassNames [

	^ #( 'MCPToolEditClassTestGenerated' 'MCPToolEditClassTestTagged'
	     'MCPToolEditClassTestClassSlots'
	     'MCPToolEditClassTestConfigured'
	     'MCPToolEditClassTestTemporaryPackage'
	     'MCPToolEditClassTestCommentTarget'
	     'MCPToolEditClassTestCommented' 'MCPToolEditClassTestReparentTarget'
	     'MCPToolEditClassTestReparentSuperclass'
	     'MCPToolEditClassTestAddSlotTarget'
	     'MCPToolEditClassTestAddClassSlotTarget'
	     'MCPToolEditClassTestRemoveSlotTarget'
	     'MCPToolEditClassTestRemoveClassSlotTarget'
	     'MCPToolEditClassTestRenameSlotTarget'
	     'MCPToolEditClassTestRenameClassSideSlotTarget'
	     'MCPToolEditClassTestWarningRemoveSlotTarget'
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
MCPToolEditClassTest >> renamedClassName [

	^ 'MCPToolRenameClassTestRenamed'
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

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateAcceptsClassSlots [

	| createdClass data result |
	result := self callToolWith: (self createRequestArgumentsWith: {
				           (#className -> 'MCPToolEditClassTestClassSlots').
				           (#superclassName -> 'Object').
				           (#packageName -> self generatedPackageName).
				           (#classSlots -> #( 'defaultName' )) }).
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolEditClassTestClassSlots'.
	self
		assert: (createdClass classSide slots collect: #name as: Array)
		equals: #( #defaultName ).
	self assert: (data at: #classSlotNames) equals: #( 'defaultName' )
]

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateAcceptsDefinitionOptions [

	| arguments createdClass data result |
	arguments := self
		             createRequestArgumentsForClassName:
		             'MCPToolEditClassTestConfigured'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #traits put: #( 'TAbleToRotate' ).
	arguments at: #classTraits put: #( 'TAbleToRotate classTrait' ).
	arguments at: #sharedVariables put: #( 'AlphaShared' 'BetaShared' ).
	arguments at: #sharedPools put: #( 'ChronologyConstants' ).
	arguments at: #layout put: 'WeakLayout'.
	result := self callToolWith: arguments.
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolEditClassTestConfigured'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert:
		(createdClass traits
			 collect: [ :each | each name asString ]
			 as: Array)
		equals: #( 'TAbleToRotate' ).
	self
		assert: (createdClass classSide traits
				 collect: [ :each | each name asString ]
				 as: Array)
		equals: #( 'TAbleToRotate classTrait' ).
	self
		assert: createdClass classVarNames
		equals: #( #AlphaShared #BetaShared ).
	self
		assert: (createdClass sharedPools
				 collect: [ :each | each name asString ]
				 as: Array)
		equals: #( 'ChronologyConstants' ).
	self assert: createdClass classLayout class name equals: #WeakLayout.
	self assert: (data at: #traitNames) equals: #( 'TAbleToRotate' ).
	self
		assert: (data at: #classTraitNames)
		equals: #( 'TAbleToRotate classTrait' ).
	self
		assert: (data at: #sharedVariableNames)
		equals: #( 'AlphaShared' 'BetaShared' ).
	self
		assert: (data at: #sharedPoolNames)
		equals: #( 'ChronologyConstants' ).
	self assert: (data at: #layoutClassName) equals: 'WeakLayout'
]

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateAcceptsSlotsAndTag [

	| createdClass data result |
	result := self callToolWith: (self createRequestArgumentsWith: {
				           (#className -> 'MCPToolEditClassTestTagged').
				           (#superclassName -> 'Object').
				           (#packageName -> self generatedPackageName).
				           (#tag -> 'Generated').
				           (#slots -> #( 'firstName' 'lastName' )) }).
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

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateCreatesClass [

	| createdClass data result |
	result := self callToolWith: (self
			           createRequestArgumentsForClassName:
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

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateEnsuresMissingPackage [

	| createdClass |
	self callToolWith: (self
			 createRequestArgumentsForClassName:
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

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateReturnsStructuredErrorWhenClassAlreadyExists [

	| arguments error result |
	arguments := self
		             createRequestArgumentsForClassName:
		             'MCPToolEditClassTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	self callToolWith: arguments.
	result := self callToolWith: arguments.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self
		assert: (error at: #message)
		equals: 'Class MCPToolEditClassTestGenerated already exists.'
]

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateReturnsStructuredErrorWhenSuperclassIsMissing [

	| error result |
	result := self callToolWith: (self
			           createRequestArgumentsForClassName:
			           'MCPToolEditClassTestGenerated'
			           superclassName: 'DefinitelyMissingSuperclass'
			           packageName: self generatedPackageName).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SuperclassNotFound'.
	self
		assert: (error at: #superclassName)
		equals: 'DefinitelyMissingSuperclass'
]

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateReturnsStructuredErrorWhenTraitIsMissing [

	| arguments error result |
	arguments := self
		             createRequestArgumentsForClassName:
		             'MCPToolEditClassTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #traits put: #( 'DefinitelyMissingTrait' ).
	arguments at: #layout put: 'WeakLayout'.
	result := self callToolWith: arguments.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'TraitNotFound'.
	self assert: (error at: #traitName) equals: 'DefinitelyMissingTrait'.
	self
		assert: (error at: #traits)
		equals: #( 'DefinitelyMissingTrait' ).
	self assert: (error at: #layout) equals: 'WeakLayout'.
	self
		assert: (error at: #packageName)
		equals: self generatedPackageName.
	self assert: (error at: #superclassName) equals: 'Object'
]

{ #category : 'tests - create' }
MCPToolEditClassTest >> testCreateSetsClassComment [

	| arguments createdClass data result |
	arguments := self
		             createRequestArgumentsForClassName:
		             'MCPToolEditClassTestCommented'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #classComment put: 'Created with a comment.'.
	result := self callToolWith: arguments.
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolEditClassTestCommented'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: createdClass comment equals: 'Created with a comment.'.
	self assert: (data at: #operation) equals: 'create'.
	self
		assert: (data at: #classComment)
		equals: 'Created with a comment.'
]

{ #category : 'tests - schema' }
MCPToolEditClassTest >> testSchemaRequiresOperationAndClassName [

	| operationProperty propertyNames slotActionProperty |
	propertyNames := MCPToolEditClass new inputSchema properties
		                 collect: [ :each | each name ].
	operationProperty := MCPToolEditClass new inputSchema properties
		                     detect: [ :each | each name = 'operation' ].
	slotActionProperty := MCPToolEditClass new inputSchema properties
		                      detect: [ :each | each name = 'slotAction' ].
	self
		assert: MCPToolEditClass new inputSchema required asSet
		equals: #( 'operation' 'className' ) asSet.
	self assert: (propertyNames includes: 'classComment').
	self assert: (propertyNames includes: 'traits').
	self assert: (propertyNames includes: 'classTraits').
	self assert: (propertyNames includes: 'sharedVariables').
	self assert: (propertyNames includes: 'sharedPools').
	self assert: (propertyNames includes: 'layout').
	self assert: (propertyNames includes: 'scope').
	self assert: (propertyNames includes: 'packageNames').
	self assert: (propertyNames includes: 'classNames').
	self assert: (propertyNames includes: 'slotAction').
	self assert: (propertyNames includes: 'slotName').
	self assert: (propertyNames includes: 'newSlotName').
	self assert: (propertyNames includes: 'classSide').
	self
		assert: (operationProperty extraProperties at: #enum) asArray
		equals: #( 'create' 'update' ).
	self
		assert: (slotActionProperty extraProperties at: #enum) asArray
		equals: #( 'add' 'remove' 'rename' 'pullUp' 'pushDown' )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateAddsClassSideSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolEditClassTestAddClassSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolEditClassTestAddClassSlotTarget'
			           slotName: 'addedClassSlot'
			           classSide: true).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolEditClassTestAddClassSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (target classSide slots collect: #name as: Array)
		equals: #( #addedClassSlot ).
	self assert: (data at: #operation) equals: 'addSlot'.
	self assert: (data at: #slotName) equals: 'addedClassSlot'.
	self assert: (data at: #classSide) equals: true.
	self assert: (data at: #instanceSlotNames) equals: #(  ).
	self assert: (data at: #classSlotNames) equals: #( 'addedClassSlot' )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateAddsInstanceSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolEditClassTestAddSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolEditClassTestAddSlotTarget'
			           slotName: 'addedSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolEditClassTestAddSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (target slots collect: #name as: Array)
		equals: #( #addedSlot ).
	self assert: (data at: #operation) equals: 'addSlot'.
	self assert: (data at: #slotName) equals: 'addedSlot'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #instanceSlotNames) equals: #( 'addedSlot' ).
	self assert: (data at: #classSlotNames) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateCanClearClassComment [

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
		          (self updateRequestArgumentsForClassComment: '').
	data := self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target comment equals: ''.
	self assert: (data at: #classComment) equals: ''.
	self assert: (data at: #oldClassComment) equals: 'original comment'.
	self assert: (data at: #newClassComment) equals: ''
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateForcePullUpSlotContinuesPastRefactoringWarningAndReturnsWarnings [

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
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#className
				            -> 'MCPToolEditClassTestWarningPullUpTarget').
				           (#slotAction -> 'pullUp').
				           (#slotName -> 'sharedSlot').
				           (#classSide -> false).
				           (#force -> true) }).
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateForceRemoveSlotContinuesPastRefactoringWarningAndReturnsWarnings [

	| data result target warnings |
	self
		createClassNamed: 'MCPToolEditClassTestWarningRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( referencedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ referencedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolEditClassTestWarningRemoveSlotTarget').
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#className
				            -> 'MCPToolEditClassTestWarningRemoveSlotTarget').
				           (#slotAction -> 'remove').
				           (#slotName -> 'referencedSlot').
				           (#classSide -> false).
				           (#force -> true) }).
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	target := self classNamed:
		          'MCPToolEditClassTestWarningRemoveSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (warnings anySatisfy: [ :each |
			 each includesSubstring:
				 'Variable referencedSlot is still referenced' ]).
	self assert: (target slots collect: #name as: Array) equals: #(  ).
	self assert: (data at: #operation) equals: 'removeSlot'.
	self assert: (data at: #slotName) equals: 'referencedSlot'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #instanceSlotNames) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateMoveEnsuresMissingDestinationPackage [

	| data result |
	self removeDestinationPackage.
	result := self callToolWith:
		          self updateRequestArgumentsForMoveToPackage.
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateMoveEnsuresMissingDestinationTag [

	| data package result |
	self removeDestinationPackage.
	self withoutEpiceaDuring: [
		PackageOrganizer default ensurePackage: self destinationPackageName ].
	result := self callToolWith:
		          self updateRequestArgumentsForMoveToPackageAndTag.
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateMovesClassToAnotherPackage [

	| data result |
	result := self callToolWith:
		          self updateRequestArgumentsForMoveToPackage.
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateMovesClassToExistingTag [

	| data result |
	result := self callToolWith:
		          self updateRequestArgumentsForMoveToPackageAndTag.
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdatePullUpSlotReturnsStructuredCommandErrorForRefactoringFailure [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdatePullUpSlotStopsOnRefactoringWarningByDefault [

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
			           updateRequestArgumentsForSlotAction: 'pullUp'
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdatePullsUpInstanceSlotAcrossSubclasses [

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
			           updateRequestArgumentsForSlotAction: 'pullUp'
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdatePushesDownClassSlotToDirectSubclasses [

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
			           updateRequestArgumentsForSlotAction: 'pushDown'
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRecategorizesWithinCurrentPackageWhenPackageNameIsOmitted [

	| data package result |
	result := self callToolWith:
		          self updateRequestArgumentsForRecategorization.
	data := self dataFrom: result.
	package := PackageOrganizer default packageNamed:
		           self originalMovePackageName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (package hasTag: self destinationTagName).
	self
		assert: self moveTargetClass packageName asString
		equals: self originalMovePackageName.
	self
		assert: self currentTagOfMoveTargetClass
		equals: self destinationTagName.
	self assert: (data at: #operation) equals: 'move'.
	self
		assert: (data at: #packageName)
		equals: self originalMovePackageName.
	self assert: (data at: #tag) equals: self destinationTagName.
	self
		assert: (data at: #oldPackageName)
		equals: self originalMovePackageName.
	self assert: (data at: #oldTag) equals: 'Uncategorized'
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRemoveSlotStopsOnRefactoringWarningByDefault [

	| error result structured target |
	self
		createClassNamed: 'MCPToolEditClassTestWarningRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( referencedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ referencedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolEditClassTestWarningRemoveSlotTarget').
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolEditClassTestWarningRemoveSlotTarget'
			           slotName: 'referencedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	target := self classNamed:
		          'MCPToolEditClassTestWarningRemoveSlotTarget'.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'removeSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self
		assert: (error at: #errorCode)
		equals: 'RemoveSlotRefactoringWarning'.
	self
		assert: (error at: #causeClass)
		equals: 'RBBreakingChangeChecksFailedWarning'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestWarningRemoveSlotTarget'.
	self assert: (error at: #slotName) equals: 'referencedSlot'.
	self assert: (error at: #classSide) equals: false.
	self assert: (error at: #forceSupported) equals: true.
	self assert:
		((error at: #howToProceed) includesSubstring: 'force=true').
	self assert: ((error at: #impactMessages) anySatisfy: [ :each |
			 each includesSubstring:
				 'Variable referencedSlot is still referenced' ]).
	self
		assert: (target slots collect: #name as: Array)
		equals: #( #referencedSlot )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRemovesClassSideSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolEditClassTestRemoveClassSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #( removableClassSlot ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolEditClassTestRemoveClassSlotTarget'
			           slotName: 'removableClassSlot'
			           classSide: true).
	data := self dataFrom: result.
	target := self classNamed:
		          'MCPToolEditClassTestRemoveClassSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (target classSide slots collect: #name as: Array)
		equals: #(  ).
	self assert: (data at: #operation) equals: 'removeSlot'.
	self assert: (data at: #slotName) equals: 'removableClassSlot'.
	self assert: (data at: #classSide) equals: true.
	self assert: (data at: #instanceSlotNames) equals: #(  ).
	self assert: (data at: #classSlotNames) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRemovesInstanceSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolEditClassTestRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( removableSlot )
		classSlots: #(  ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolEditClassTestRemoveSlotTarget'
			           slotName: 'removableSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolEditClassTestRemoveSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target slots collect: #name as: Array) equals: #(  ).
	self assert: (data at: #operation) equals: 'removeSlot'.
	self assert: (data at: #slotName) equals: 'removableSlot'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #instanceSlotNames) equals: #(  ).
	self assert: (data at: #classSlotNames) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRenameCanLimitRefactoringToClassHierarchy [

	| hierarchyArguments referenceClass referenceSource result subclass |
	hierarchyArguments := self updateRequestArgumentsForRename copy
		                      at: #scope put: 'hierarchy';
		                      at: #classNames
		                      put: { self originalClassName };
		                      yourself.
	result := self callToolWith: hierarchyArguments.
	referenceClass := self classNamed: self referenceClassName.
	subclass := self classNamed: self subclassName.
	referenceSource := (referenceClass >> #referencedClass) sourceCode.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: subclass superclass name asString
		equals: self renamedClassName.
	self assert:
		(referenceSource includesSubstring: self originalClassName).
	self deny: (referenceSource includesSubstring: self renamedClassName).
	self assert: ((referenceClass >> #newReferencedInstance) sourceCode
			 includesSubstring: self originalClassName)
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRenameCanLimitRefactoringToNamedClasses [

	| classesArguments referenceClass result |
	classesArguments := self updateRequestArgumentsForRename copy
		                    at: #scope put: 'classes';
		                    at: #classNames put: {
				                    self originalClassName.
				                    self referenceClassName };
		                    yourself.
	result := self callToolWith: classesArguments.
	referenceClass := self classNamed: self referenceClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert:
		((referenceClass >> #referencedClass) sourceCode includesSubstring:
			 self renamedClassName).
	self assert: ((referenceClass >> #newReferencedInstance) sourceCode
			 includesSubstring: self renamedClassName)
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRenameUpdatesMethodReferences [

	| reference |
	self callToolWith: self updateRequestArgumentsForRename.
	reference := (self classNamed: self referenceClassName) new.
	self
		assert: reference referencedClass name asString
		equals: self renamedClassName.
	self
		assert: reference newReferencedInstance class name asString
		equals: self renamedClassName
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRenameUpdatesSubclassDefinitions [

	self callToolWith: self updateRequestArgumentsForRename.
	self
		assert:
		(self classNamed: self subclassName) superclass name asString
		equals: self renamedClassName
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRenamesClassAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self updateRequestArgumentsForRename.
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRenamesInstanceSlotAndUpdatesReferences [

	| data instance result target |
	self
		createClassNamed: 'MCPToolEditClassTestRenameSlotTarget'
		superclassName: 'Object'
		slots: #( oldSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'oldSlot ^ oldSlot'
		protocol: 'accessing'
		on: (self classNamed: 'MCPToolEditClassTestRenameSlotTarget').
	self
		ensureMethodSource: 'oldSlot: anObject oldSlot := anObject'
		protocol: 'accessing'
		on: (self classNamed: 'MCPToolEditClassTestRenameSlotTarget').
	self
		ensureMethodSource: 'slotProbe ^ self oldSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolEditClassTestRenameSlotTarget').
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotRenameInClassNamed:
			           'MCPToolEditClassTestRenameSlotTarget'
			           slotName: 'oldSlot'
			           newSlotName: 'renamedSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolEditClassTestRenameSlotTarget'.
	instance := target new.
	instance renamedSlot: 37.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (target slots collect: #name as: Array)
		equals: #( #renamedSlot ).
	self deny: (target includesSelector: #oldSlot).
	self deny: (target includesSelector: #oldSlot:).
	self assert: (target includesSelector: #renamedSlot).
	self assert: (target includesSelector: #renamedSlot:).
	self assert: instance renamedSlot equals: 37.
	self assert: instance slotProbe equals: 37.
	self assert: (data at: #operation) equals: 'renameSlot'.
	self assert: (data at: #oldSlotName) equals: 'oldSlot'.
	self assert: (data at: #newSlotName) equals: 'renamedSlot'.
	self assert: (data at: #classSide) equals: false.
	self assert: (data at: #instanceSlotNames) equals: #( 'renamedSlot' ).
	self assert: (data at: #classSlotNames) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReparentsClassAndPreservesExistingState [

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
	result := self callToolWith: self updateRequestArgumentsForReparent.
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateRequiresExplicitSlotActionForSlotPatch [

	| error result structured |
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#className -> 'Object').
				           (#slotName -> 'oldSlot').
				           (#newSlotName -> 'newSlot') }).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'update'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SlotActionRequired'.
	self assert: (error at: #className) equals: 'Object'.
	self assert: (error at: #slotName) equals: 'oldSlot'
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenAddSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolEditClassTestMissingAddSlot'
			           slotName: 'addedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'addSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestMissingAddSlot'.
	self assert: (error at: #slotName) equals: 'addedSlot'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenCommentClassIsMissing [

	| error result |
	result := self callToolWith: {
			          (#operation -> 'update').
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenDestinationTagIsMissing [

	self testUpdateMoveEnsuresMissingDestinationTag
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenMoveClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#operation -> 'update').
			          (#className -> 'MCPToolEditClassTestMissing').
			          (#packageName -> self destinationPackageName) }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'move'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestMissing'
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenPullUpSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenRemoveSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolEditClassTestMissingRemoveSlot'
			           slotName: 'removableSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'removeSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestMissingRemoveSlot'.
	self assert: (error at: #slotName) equals: 'removableSlot'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenRenameClassIsMissing [

	| error result |
	result := self callToolWith: {
			          (#operation -> 'update').
			          (#className -> 'MCPToolEditClassTestMissing').
			          (#newClassName -> self renamedClassName) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #operation) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #message)
		equals: 'Class MCPToolEditClassTestMissing does not exist.'
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenRenameSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotRenameInClassNamed:
			           'MCPToolEditClassTestMissingRenameSlot'
			           slotName: 'oldSlot'
			           newSlotName: 'renamedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'renameSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestMissingRenameSlot'.
	self assert: (error at: #slotName) equals: 'oldSlot'.
	self assert: (error at: #newSlotName) equals: 'renamedSlot'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenRenameSlotRejectsClassSide [

	| error result structured target |
	self
		createClassNamed: 'MCPToolEditClassTestRenameClassSideSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #( oldClassSlot ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotRenameInClassNamed:
			           'MCPToolEditClassTestRenameClassSideSlotTarget'
			           slotName: 'oldClassSlot'
			           newSlotName: 'renamedClassSlot'
			           classSide: true).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	target := self classNamed:
		          'MCPToolEditClassTestRenameClassSideSlotTarget'.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #operation) equals: 'renameSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self
		assert: (error at: #errorCode)
		equals: 'RenameSlotClassSideUnsupported'.
	self
		assert: (error at: #className)
		equals: 'MCPToolEditClassTestRenameClassSideSlotTarget'.
	self assert: (error at: #slotName) equals: 'oldClassSlot'.
	self assert: (error at: #newSlotName) equals: 'renamedClassSlot'.
	self assert: (error at: #classSide) equals: true.
	self assert:
		((error at: #message) includesSubstring: 'instance-side slots').
	self
		assert: (target classSide slots collect: #name as: Array)
		equals: #( #oldClassSlot )
]

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateReturnsStructuredErrorWhenReparentSuperclassIsMissing [

	| error result |
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: {
			          (#operation -> 'update').
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

{ #category : 'tests - update' }
MCPToolEditClassTest >> testUpdateSetsClassComment [

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
		          (self updateRequestArgumentsForClassComment:
			           'updated comment').
	data := self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target comment equals: 'updated comment'.
	self assert: (data at: #operation) equals: 'setComment'.
	self assert: (data at: #classComment) equals: 'updated comment'.
	self assert: (data at: #oldClassComment) equals: 'original comment'.
	self assert: (data at: #newClassComment) equals: 'updated comment'.
	self
		assert: ((data at: #updatePlan) at: #operation)
		equals: 'setComment'.
	self
		assert: ((data at: #updatePlan) at: #commandClassName)
		equals: 'MCPChangeClassCommentCommand'.
	self
		assert: ((data at: #appliedChange) at: #resultClassName)
		equals: 'MCPChangeClassCommentResult'
]

{ #category : 'private - calling' }
MCPToolEditClassTest >> toolName [

	^ 'edit-class'
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForClassComment: aClassComment [

	^ {
		  (#operation -> 'update').
		  (#className -> self commentTargetClassName).
		  (#classComment -> aClassComment) } asDictionary
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForMoveToPackage [

	^ {
		  (#operation -> 'update').
		  (#className -> self moveTargetClassName).
		  (#packageName -> self destinationPackageName) } asDictionary
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForMoveToPackageAndTag [

	^ {
		  (#operation -> 'update').
		  (#className -> self moveTargetClassName).
		  (#packageName -> self destinationPackageName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForRecategorization [

	^ {
		  (#operation -> 'update').
		  (#className -> self moveTargetClassName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForRename [

	^ {
		  (#operation -> 'update').
		  (#className -> self originalClassName).
		  (#newClassName -> self renamedClassName) } asDictionary
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForReparent [

	^ {
		  (#operation -> 'update').
		  (#className -> self reparentTargetClassName).
		  (#superclassName -> self reparentSuperclassName) } asDictionary
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForSlotAction: slotAction className: aClassName slotName: aSlotName classSide: aBoolean [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#slotAction -> slotAction).
			  (#slotName -> aSlotName).
			  (#classSide -> aBoolean) }
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsForSlotRenameInClassNamed: aClassName slotName: aSlotName newSlotName: aNewSlotName classSide: aBoolean [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#slotAction -> 'rename').
			  (#slotName -> aSlotName).
			  (#newSlotName -> aNewSlotName).
			  (#classSide -> aBoolean) }
]

{ #category : 'private - update' }
MCPToolEditClassTest >> updateRequestArgumentsWith: associations [

	| arguments |
	arguments := Dictionary new.
	arguments at: #operation put: 'update'.
	associations do: [ :each | arguments at: each key put: each value ].
	^ arguments
]
