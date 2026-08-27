"
Create tests exercise class creation tool requests. Update tests exercise class update tool requests and verify the structured result data produced by the internal narrow commands.
"
Class {
	#name : 'MCPToolClassMutationTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private - calling' }
MCPToolClassMutationTest >> aroundToolCall: aBlock [

	^ self withoutEpiceaDuring: aBlock
]

{ #category : 'private - asserting' }
MCPToolClassMutationTest >> assertIncludesReferencedSlotWarning: warningMessages [

	self assert:
		(warningMessages anySatisfy: [ :each | (each includesSubstring: 'referencedSlot') and: [ each includesSubstring: 'referenced' ] ])
]

{ #category : 'private - calling' }
MCPToolClassMutationTest >> callToolWith: someArguments [

	| action arguments request result slotAction tool toolClass |
	arguments := someArguments copy.
	action := arguments removeKey: #action ifAbsent: [ nil ].
	slotAction := arguments removeKey: #slotAction ifAbsent: [ nil ].
	toolClass := action = 'create'
		             ifTrue: [ MCPToolCreateClass ]
		             ifFalse: [ self classToolClassForArguments: arguments slotAction: slotAction ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private - calling' }
MCPToolClassMutationTest >> classToolClassForArguments: arguments slotAction: slotAction [

	((arguments includesKey: #superclassName) and: [ arguments includesKey: #packageName ]) ifTrue: [ ^ MCPToolCreateClass ].
	slotAction = 'add' ifTrue: [ ^ MCPToolAddClassSlot ].
	slotAction = 'remove' ifTrue: [ ^ MCPToolRemoveClassSlot ].
	slotAction = 'rename' ifTrue: [ ^ MCPToolUpdateClassSlotName ].
	slotAction = 'pullUp' ifTrue: [ ^ MCPToolPullUpClassSlot ].
	slotAction = 'pushDown' ifTrue: [ ^ MCPToolPushDownClassSlot ].
	(arguments includesKey: #newName) ifTrue: [ ^ MCPToolUpdateClassName ].
	(arguments includesKey: #comment) ifTrue: [ ^ MCPToolUpdateClassComment ].
	(arguments includesKey: #traits) ifTrue: [ ^ MCPToolUpdateClassTraits ].
	(arguments includesKey: #classTraits) ifTrue: [ ^ MCPToolUpdateClassSideTraits ].
	(arguments includesKey: #sharedVariables) ifTrue: [ ^ MCPToolUpdateClassSharedVariables ].
	(arguments includesKey: #sharedPools) ifTrue: [ ^ MCPToolUpdateClassSharedPools ].
	(arguments includesKey: #layout) ifTrue: [ ^ MCPToolUpdateClassLayout ].
	((arguments includesKey: #slots) or: [ arguments includesKey: #classSlots ]) ifTrue: [ ^ MCPToolUpdateClassSlots ].
	(arguments includesKey: #superclassName) ifTrue: [ ^ MCPToolUpdateClassSuperclass ].
	((arguments includesKey: #packageName) or: [ arguments includesKey: #tag ]) ifTrue: [ ^ MCPToolUpdateClassPackage ].
	^ MCPToolUpdateClassComment
]

{ #category : 'private' }
MCPToolClassMutationTest >> commentTargetClassName [

	^ 'MCPToolClassMutationTestCommentTarget'
]

{ #category : 'private - create' }
MCPToolClassMutationTest >> createRequestArgumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ self createRequestArgumentsWith: {
			  (#name -> aClassName).
			  (#superclassName -> aSuperclassName).
			  (#packageName -> aPackageName) }
]

{ #category : 'private - create' }
MCPToolClassMutationTest >> createRequestArgumentsWith: associations [

	| arguments |
	arguments := Dictionary new.
	arguments at: #action put: 'create'.
	associations do: [ :each | arguments at: each key put: each value ].
	^ arguments
]

{ #category : 'private' }
MCPToolClassMutationTest >> createdClassNames [

	^ #( 'MCPToolClassMutationTestGenerated' 'MCPToolClassMutationTestTagged' 'MCPToolClassMutationTestClassSlots'
	     'MCPToolClassMutationTestConfigured' 'MCPToolClassMutationTestTemporaryPackage' 'MCPToolClassMutationTestCommentTarget'
	     'MCPToolClassMutationTestCommented' 'MCPToolClassMutationTestReparentTarget' 'MCPToolClassMutationTestReparentSuperclass'
	     'MCPToolClassMutationTestTraitTarget' 'MCPToolClassMutationTestTraitRemovalTarget'
	     'MCPToolClassMutationTestMissingTraitTarget' 'MCPToolClassMutationTestClassTraitTarget'
	     'MCPToolClassMutationTestClassTraitRemovalTarget' 'MCPToolClassMutationTestMissingClassTraitTarget'
	     'MCPToolClassMutationTestSharedVariableTarget' 'MCPToolClassMutationTestSharedVariableRemovalTarget'
	     'MCPToolClassMutationTestSharedVariablePreservationTarget' 'MCPToolClassMutationTestSharedPoolTarget'
	     'MCPToolClassMutationTestSharedPoolRemovalTarget' 'MCPToolClassMutationTestMissingSharedPoolTarget'
	     'MCPToolClassMutationTestLayoutTarget' 'MCPToolClassMutationTestMissingLayoutTarget'
	     'MCPToolClassMutationTestInvalidLayoutTarget' 'MCPToolClassMutationTestDefinitionTarget'
	     'MCPToolClassMutationTestAddSlotTarget' 'MCPToolClassMutationTestAddClassSlotTarget'
	     'MCPToolClassMutationTestRemoveSlotTarget' 'MCPToolClassMutationTestRemoveClassSlotTarget'
	     'MCPToolClassMutationTestRenameSlotTarget' 'MCPToolClassMutationTestRenameClassSideSlotTarget'
	     'MCPToolClassMutationTestWarningRemoveSlotTarget' 'MCPToolClassMutationTestPullUpTarget'
	     'MCPToolClassMutationTestPullUpChildOne' 'MCPToolClassMutationTestPullUpChildTwo' 'MCPToolClassMutationTestPushDownTarget'
	     'MCPToolClassMutationTestPushDownChildOne' 'MCPToolClassMutationTestPushDownChildTwo'
	     'MCPToolClassMutationTestWarningPullUpTarget' 'MCPToolClassMutationTestWarningPullUpChildOne'
	     'MCPToolClassMutationTestWarningPullUpChildTwo' )
]

{ #category : 'private' }
MCPToolClassMutationTest >> currentTagOfMoveTargetClass [

	^ self moveTargetClass packageTagName asString
]

{ #category : 'private' }
MCPToolClassMutationTest >> destinationPackageName [

	^ 'MCP-Tests-MoveClass'
]

{ #category : 'private' }
MCPToolClassMutationTest >> destinationTagName [

	^ 'Moved'
]

{ #category : 'private' }
MCPToolClassMutationTest >> ensureDestinationPackage [

	self withoutEpiceaDuring: [
			| package |
			package := PackageOrganizer default ensurePackage: self destinationPackageName.
			package ensureTag: self destinationTagName ]
]

{ #category : 'private' }
MCPToolClassMutationTest >> ensureOriginalRenameFixtureState [

	| originalSymbol renamedSymbol |
	originalSymbol := self originalClassName asSymbol.
	renamedSymbol := self renamedClassName asSymbol.
	self withoutEpiceaDuring: [
			((Smalltalk globals includesKey: originalSymbol) and: [ Smalltalk globals includesKey: renamedSymbol ]) ifTrue: [
				(Smalltalk globals at: renamedSymbol) removeFromSystem ].
			((Smalltalk globals includesKey: renamedSymbol) and: [ (Smalltalk globals includesKey: originalSymbol) not ]) ifTrue: [
				(ReRenameClassRefactoring rename: self renamedClassName to: self originalClassName) execute ] ]
]

{ #category : 'private' }
MCPToolClassMutationTest >> generatedPackageName [

	^ 'MCP-Tests-ClassMutation'
]

{ #category : 'private' }
MCPToolClassMutationTest >> moveTargetClass [

	^ MCPToolMoveClassTestTarget
]

{ #category : 'private' }
MCPToolClassMutationTest >> moveTargetClassName [

	^ 'MCPToolMoveClassTestTarget'
]

{ #category : 'private' }
MCPToolClassMutationTest >> originalClassName [

	^ 'MCPToolRenameClassTestOriginal'
]

{ #category : 'private' }
MCPToolClassMutationTest >> originalMovePackageName [

	^ 'MCP-Tests-Resources'
]

{ #category : 'private' }
MCPToolClassMutationTest >> referenceClassName [

	^ MCPToolRenameClassTestReference name
]

{ #category : 'private' }
MCPToolClassMutationTest >> removeDestinationPackage [

	self withoutEpiceaDuring: [
			(PackageOrganizer default hasPackage: self destinationPackageName) ifTrue: [
				PackageOrganizer default removePackage: (PackageOrganizer default packageNamed: self destinationPackageName) ] ]
]

{ #category : 'private' }
MCPToolClassMutationTest >> removeGeneratedPackage [

	self withoutEpiceaDuring: [
			(self packageOrganizer hasPackage: self generatedPackageName) ifTrue: [
				self packageOrganizer removePackage: (self packageOrganizer packageNamed: self generatedPackageName) ] ]
]

{ #category : 'private' }
MCPToolClassMutationTest >> renamedClassName [

	^ 'MCPToolRenameClassTestRenamed'
]

{ #category : 'private' }
MCPToolClassMutationTest >> reparentSuperclassName [

	^ 'MCPToolClassMutationTestReparentSuperclass'
]

{ #category : 'private' }
MCPToolClassMutationTest >> reparentTargetClassName [

	^ 'MCPToolClassMutationTestReparentTarget'
]

{ #category : 'private' }
MCPToolClassMutationTest >> restoreMoveTargetClassLocation [

	(self moveTargetClass packageName asString = self originalMovePackageName and: [
		 self currentTagOfMoveTargetClass = 'Uncategorized' ]) ifTrue: [ ^ self ].
	self withoutEpiceaDuring: [
		(RBMoveClassTransformation move: self moveTargetClassName toPackage: self originalMovePackageName) execute ]
]

{ #category : 'running' }
MCPToolClassMutationTest >> setUp [

	super setUp.
	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage.
	self restoreMoveTargetClassLocation.
	self removeDestinationPackage.
	self ensureDestinationPackage.
	self ensureOriginalRenameFixtureState
]

{ #category : 'private' }
MCPToolClassMutationTest >> subclassName [

	^ MCPToolRenameClassTestSubclass name
]

{ #category : 'running' }
MCPToolClassMutationTest >> tearDown [

	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage.
	self restoreMoveTargetClassLocation.
	self removeDestinationPackage.
	self ensureOriginalRenameFixtureState.
	super tearDown
]

{ #category : 'tests - schema' }
MCPToolClassMutationTest >> testClassToolSchemasDeclareExpectedInputs [

	| createProperties packageProperties renameProperties slotProperties |
	createProperties := MCPToolCreateClass new inputSchema properties collect: [ :each | each name ].
	renameProperties := MCPToolUpdateClassName new inputSchema properties collect: [ :each | each name ].
	packageProperties := MCPToolUpdateClassPackage new inputSchema properties collect: [ :each | each name ].
	slotProperties := MCPToolAddClassSlot new inputSchema properties collect: [ :each | each name ].
	self
		assert: createProperties asArray
		equals:
			#( 'name' 'superclassName' 'packageName' 'tag' 'slots' 'classSlots' 'traits' 'classTraits' 'sharedVariables' 'sharedPools'
			   'layout' 'comment' ).
	self assert: MCPToolCreateClass new inputSchema required asSet equals: #( 'name' 'superclassName' 'packageName' ) asSet.
	self assert: renameProperties asArray equals: #( 'name' 'newName' ).
	self assert: MCPToolUpdateClassName new inputSchema required asSet equals: #( 'name' 'newName' ) asSet.
	self assert: packageProperties asArray equals: #( 'className' 'packageName' 'tag' ).
	self assert: MCPToolUpdateClassPackage new inputSchema required asSet equals: #( 'className' ) asSet.
	self assert: slotProperties asArray equals: #( 'className' 'slotName' 'classSide' ).
	self assert: MCPToolAddClassSlot new inputSchema required asSet equals: #( 'className' 'slotName' ) asSet
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateAcceptsClassSlots [

	| createdClass data result |
	result := self callToolWith: (self createRequestArgumentsWith: {
				           (#name -> 'MCPToolClassMutationTestClassSlots').
				           (#superclassName -> 'Object').
				           (#packageName -> self generatedPackageName).
				           (#classSlots -> #( 'defaultName' )) }).
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestClassSlots'.
	self assert: (createdClass classSide slots collect: #name as: Array) equals: #( #defaultName ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateAcceptsDefinitionOptions [

	| arguments createdClass data result |
	arguments := self
		             createRequestArgumentsForClassName: 'MCPToolClassMutationTestConfigured'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #traits put: #( 'TAbleToRotate' ).
	arguments at: #classTraits put: #( 'TAbleToRotate classTrait' ).
	arguments at: #sharedVariables put: #( 'AlphaShared' 'BetaShared' ).
	arguments at: #sharedPools put: #( 'ChronologyConstants' ).
	arguments at: #layout put: 'WeakLayout'.
	result := self callToolWith: arguments.
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestConfigured'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (createdClass traits collect: [ :each | each name asString ] as: Array) equals: #( 'TAbleToRotate' ).
	self assert: createdClass traitCompositionString equals: 'TAbleToRotate'.
	self
		assert: (createdClass classSide traits collect: [ :each | each name asString ] as: Array)
		equals: #( 'TAbleToRotate classTrait' ).
	self assert: createdClass classSide traitCompositionString equals: 'TAbleToRotate classTrait'.
	self assert: createdClass classVarNames equals: #( #AlphaShared #BetaShared ).
	self assert: (createdClass sharedPools collect: [ :each | each name asString ] as: Array) equals: #( 'ChronologyConstants' ).
	self assert: createdClass classLayout class name equals: #WeakLayout.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateAcceptsSlotsAndTag [

	| createdClass data result |
	result := self callToolWith: (self createRequestArgumentsWith: {
				           (#name -> 'MCPToolClassMutationTestTagged').
				           (#superclassName -> 'Object').
				           (#packageName -> self generatedPackageName).
				           (#tag -> 'Generated').
				           (#slots -> #( 'firstName' 'lastName' )) }).
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestTagged'.
	self assert: (createdClass slots collect: #name as: Array) equals: #( #firstName #lastName ).
	self assert: createdClass packageTagName asString equals: 'Generated'.
	self assert: createdClass category asString equals: self generatedPackageName , '-Generated'.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateCreatesClass [

	| createdClass data result |
	result := self callToolWith: (self
			           createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			           superclassName: 'Object'
			           packageName: self generatedPackageName).
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestGenerated'.
	self assert: createdClass superclass equals: Object.
	self assert: createdClass packageName asString equals: self generatedPackageName.
	self assert: createdClass slots isEmpty.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateEnsuresMissingPackage [

	| createdClass |
	self callToolWith: (self
			 createRequestArgumentsForClassName: 'MCPToolClassMutationTestTemporaryPackage'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	createdClass := self classNamed: 'MCPToolClassMutationTestTemporaryPackage'.
	self assert: (self packageOrganizer hasPackage: self generatedPackageName).
	self assert: createdClass packageName asString equals: self generatedPackageName
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateReturnsStructuredErrorWhenClassAlreadyExists [

	| arguments error result |
	arguments := self
		             createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	self callToolWith: arguments.
	result := self callToolWith: arguments.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self assert: (error at: #message) equals: 'Class MCPToolClassMutationTestGenerated already exists.'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateReturnsStructuredErrorWhenSuperclassIsMissing [

	| error result |
	result := self callToolWith: (self
			           createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			           superclassName: 'DefinitelyMissingSuperclass'
			           packageName: self generatedPackageName).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SuperclassNotFound'.
	self assert: (error at: #superclassName) equals: 'DefinitelyMissingSuperclass'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateReturnsStructuredErrorWhenTraitIsMissing [

	| arguments error result |
	arguments := self
		             createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #traits put: #( 'DefinitelyMissingTrait' ).
	arguments at: #layout put: 'WeakLayout'.
	result := self callToolWith: arguments.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'TraitNotFound'.
	self assert: (error at: #traitName) equals: 'DefinitelyMissingTrait'.
	self assert: (error at: #traits) equals: #( 'DefinitelyMissingTrait' ).
	self assert: (error at: #layout) equals: 'WeakLayout'.
	self assert: (error at: #packageName) equals: self generatedPackageName.
	self assert: (error at: #superclassName) equals: 'Object'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateSetsClassComment [

	| arguments createdClass data result |
	arguments := self
		             createRequestArgumentsForClassName: 'MCPToolClassMutationTestCommented'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #comment put: 'Created with a comment.'.
	result := self callToolWith: arguments.
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestCommented'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: createdClass comment equals: 'Created with a comment.'.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateAddsClassSideSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestAddClassSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolClassMutationTestAddClassSlotTarget'
			           slotName: 'addedClassSlot'
			           classSide: true).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestAddClassSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target classSide slots collect: #name as: Array) equals: #( #addedClassSlot ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateAddsInstanceSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestAddSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolClassMutationTestAddSlotTarget'
			           slotName: 'addedSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestAddSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target slots collect: #name as: Array) equals: #( #addedSlot ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateCanClearClassComment [

	| data result target |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self withoutEpiceaDuring: [ (self classNamed: self commentTargetClassName) comment: 'original comment' ].
	result := self callToolWith: (self updateRequestArgumentsForClassComment: '').
	data := self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target comment equals: ''.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateForcePullUpSlotContinuesPastRefactoringWarningAndReturnsWarnings [

	| childOne childTwo data instance result target warnings |
	self
		createClassNamed: 'MCPToolClassMutationTestWarningPullUpTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestWarningPullUpChildOne'
		superclassName: 'MCPToolClassMutationTestWarningPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestWarningPullUpChildTwo'
		superclassName: 'MCPToolClassMutationTestWarningPullUpTarget'
		slots: #(  )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ sharedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestWarningPullUpChildOne').
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#className -> 'MCPToolClassMutationTestWarningPullUpTarget').
				           (#slotAction -> 'pullUp').
				           (#slotName -> 'sharedSlot').
				           (#classSide -> false).
				           (#force -> true) }).
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestWarningPullUpTarget'.
	childOne := self classNamed: 'MCPToolClassMutationTestWarningPullUpChildOne'.
	childTwo := self classNamed: 'MCPToolClassMutationTestWarningPullUpChildTwo'.
	instance := childOne new.
	instance instVarNamed: 'sharedSlot' put: 17.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (warnings anySatisfy: [ :each | each includesSubstring: 'Not all subclasses have an instance variable named' ]).
	self assert: (target slots collect: #name as: Array) equals: #( #sharedSlot ).
	self assert: (childOne slots collect: #name as: Array) equals: #(  ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  ).
	self assert: instance slotProbe equals: 17.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateForceRemoveSlotContinuesPastRefactoringWarningAndReturnsWarnings [

	| data result target warnings |
	self
		createClassNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( referencedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ referencedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget').
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#className -> 'MCPToolClassMutationTestWarningRemoveSlotTarget').
				           (#slotAction -> 'remove').
				           (#slotName -> 'referencedSlot').
				           (#classSide -> false).
				           (#force -> true) }).
	data := self dataFrom: result.
	warnings := self warningsFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assertIncludesReferencedSlotWarning: warnings.
	self assert: (target slots collect: #name as: Array) equals: #(  ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMoveEnsuresMissingDestinationPackage [

	| data result |
	self removeDestinationPackage.
	result := self callToolWith: self updateRequestArgumentsForMoveToPackage.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (PackageOrganizer default hasPackage: self destinationPackageName).
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMoveEnsuresMissingDestinationTag [

	| data package result |
	self removeDestinationPackage.
	self withoutEpiceaDuring: [ PackageOrganizer default ensurePackage: self destinationPackageName ].
	result := self callToolWith: self updateRequestArgumentsForMoveToPackageAndTag.
	data := self dataFrom: result.
	package := PackageOrganizer default packageNamed: self destinationPackageName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (package hasTag: self destinationTagName).
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName.
	self assert: self currentTagOfMoveTargetClass equals: self destinationTagName.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMovesClassToAnotherPackage [

	| data result |
	result := self callToolWith: self updateRequestArgumentsForMoveToPackage.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMovesClassToExistingTag [

	| data result |
	result := self callToolWith: self updateRequestArgumentsForMoveToPackageAndTag.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName.
	self assert: self currentTagOfMoveTargetClass equals: self destinationTagName.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePreservesSharedVariableValueWhenNameIsKept [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedVariablePreservationTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedVariables put: #( 'AlphaShared' ).
	self callToolWith: createArguments.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariablePreservationTarget'.
	targetClass writeClassVariableNamed: #AlphaShared value: 123.
	result := self callToolWith: (self
			           updateRequestArgumentsForSharedVariablesInClassNamed: 'MCPToolClassMutationTestSharedVariablePreservationTarget'
			           sharedVariables: #( 'AlphaShared' 'BetaShared' )).
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariablePreservationTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass classVarNames equals: #( #AlphaShared #BetaShared ).
	self assert: (targetClass readClassVariableNamed: #AlphaShared) equals: 123.
	self assert: (targetClass readClassVariableNamed: #BetaShared) isNil
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullUpSlotReturnsStructuredCommandErrorForRefactoringFailure [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolMethodMutationTestTarget'
			           slotName: 'missingSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'PullUpSlotRefactoringError'.
	self assert: (error at: #causeClass) equals: 'RBRefactoringError'.
	self assert: (error at: #className) equals: 'MCPToolMethodMutationTestTarget'.
	self assert: (error at: #slotName) equals: 'missingSlot'.
	self assert: (error at: #classSide) equals: false.
	self assert: ((error at: #message) includesSubstring: 'missingSlot')
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullUpSlotStopsOnRefactoringWarningByDefault [

	| childOne childTwo error result structured target |
	self
		createClassNamed: 'MCPToolClassMutationTestWarningPullUpTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestWarningPullUpChildOne'
		superclassName: 'MCPToolClassMutationTestWarningPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestWarningPullUpChildTwo'
		superclassName: 'MCPToolClassMutationTestWarningPullUpTarget'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestWarningPullUpTarget'
			           slotName: 'sharedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestWarningPullUpTarget'.
	childOne := self classNamed: 'MCPToolClassMutationTestWarningPullUpChildOne'.
	childTwo := self classNamed: 'MCPToolClassMutationTestWarningPullUpChildTwo'.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'PullUpSlotRefactoringWarning'.
	self assert: (error at: #causeClass) equals: 'RBRefactoringWarning'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestWarningPullUpTarget'.
	self assert: (error at: #slotName) equals: 'sharedSlot'.
	self assert: (error at: #classSide) equals: false.
	self assert: (error at: #forceSupported) equals: true.
	self assert: ((error at: #howToProceed) includesSubstring: 'force=true').
	self assert:
		((error at: #impactMessages) anySatisfy: [ :each | each includesSubstring: 'Not all subclasses have an instance variable named' ]).
	self assert: (target slots collect: #name as: Array) equals: #(  ).
	self assert: (childOne slots collect: #name as: Array) equals: #( #sharedSlot ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullsUpInstanceSlotAcrossSubclasses [

	| childOne childTwo data instance result target |
	self
		createClassNamed: 'MCPToolClassMutationTestPullUpTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestPullUpChildOne'
		superclassName: 'MCPToolClassMutationTestPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestPullUpChildTwo'
		superclassName: 'MCPToolClassMutationTestPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ sharedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestPullUpChildOne').
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestPullUpTarget'
			           slotName: 'sharedSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestPullUpTarget'.
	childOne := self classNamed: 'MCPToolClassMutationTestPullUpChildOne'.
	childTwo := self classNamed: 'MCPToolClassMutationTestPullUpChildTwo'.
	instance := childOne new.
	instance instVarNamed: 'sharedSlot' put: 41.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target slots collect: #name as: Array) equals: #( #sharedSlot ).
	self assert: (childOne slots collect: #name as: Array) equals: #(  ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  ).
	self assert: instance slotProbe equals: 41.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePushesDownClassSlotToDirectSubclasses [

	| childOne childTwo data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestPushDownTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #( sharedClassSlot ).
	self
		createClassNamed: 'MCPToolClassMutationTestPushDownChildOne'
		superclassName: 'MCPToolClassMutationTestPushDownTarget'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestPushDownChildTwo'
		superclassName: 'MCPToolClassMutationTestPushDownTarget'
		slots: #(  )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ sharedClassSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestPushDownChildOne') classSide.
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pushDown'
			           className: 'MCPToolClassMutationTestPushDownTarget'
			           slotName: 'sharedClassSlot'
			           classSide: true).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestPushDownTarget'.
	childOne := self classNamed: 'MCPToolClassMutationTestPushDownChildOne'.
	childTwo := self classNamed: 'MCPToolClassMutationTestPushDownChildTwo'.
	childOne instVarNamed: 'sharedClassSlot' put: 23.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target classSide slots collect: #name as: Array) equals: #(  ).
	self assert: (childOne classSide slots collect: #name as: Array) equals: #( #sharedClassSlot ).
	self assert: (childTwo classSide slots collect: #name as: Array) equals: #( #sharedClassSlot ).
	self assert: childOne slotProbe equals: 23.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRecategorizesWithinCurrentPackageWhenPackageNameIsOmitted [

	| data package result |
	result := self callToolWith: self updateRequestArgumentsForRecategorization.
	data := self dataFrom: result.
	package := PackageOrganizer default packageNamed: self originalMovePackageName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (package hasTag: self destinationTagName).
	self assert: self moveTargetClass packageName asString equals: self originalMovePackageName.
	self assert: self currentTagOfMoveTargetClass equals: self destinationTagName.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemoveSlotStopsOnRefactoringWarningByDefault [

	| error result structured target |
	self
		createClassNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( referencedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ referencedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget').
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
			           slotName: 'referencedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'removeSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'RemoveSlotRefactoringWarning'.
	self assert: (self expectedRefactoringWarningCauseClassNames includes: (error at: #causeClass)).
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestWarningRemoveSlotTarget'.
	self assert: (error at: #slotName) equals: 'referencedSlot'.
	self assert: (error at: #classSide) equals: false.
	self assert: (error at: #forceSupported) equals: true.
	self assert: ((error at: #howToProceed) includesSubstring: 'force=true').
	self assertIncludesReferencedSlotWarning: (error at: #impactMessages).
	self assert: (target slots collect: #name as: Array) equals: #( #referencedSlot )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesClassSideSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestRemoveClassSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #( removableClassSlot ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestRemoveClassSlotTarget'
			           slotName: 'removableClassSlot'
			           classSide: true).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRemoveClassSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target classSide slots collect: #name as: Array) equals: #(  ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesClassSideTraitsWithEmptyArray [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestClassTraitRemovalTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #classTraits put: #( 'TAbleToRotate classTrait' ).
	self callToolWith: createArguments.
	result := self callToolWith:
		          (self
			           updateRequestArgumentsForClassTraitsInClassNamed: 'MCPToolClassMutationTestClassTraitRemovalTarget'
			           classTraits: #(  )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestClassTraitRemovalTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass classSide traits isEmpty.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesInstanceSlot [

	| data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( removableSlot )
		classSlots: #(  ).
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestRemoveSlotTarget'
			           slotName: 'removableSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRemoveSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target slots collect: #name as: Array) equals: #(  ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesSharedPoolsWithEmptyArray [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedPoolRemovalTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedPools put: #( 'ChronologyConstants' ).
	self callToolWith: createArguments.
	result := self callToolWith:
		          (self
			           updateRequestArgumentsForSharedPoolsInClassNamed: 'MCPToolClassMutationTestSharedPoolRemovalTarget'
			           sharedPools: #(  )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedPoolRemovalTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass sharedPools isEmpty.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesSharedVariablesWithEmptyArray [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedVariableRemovalTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedVariables put: #( 'AlphaShared' ).
	self callToolWith: createArguments.
	result := self callToolWith: (self
			           updateRequestArgumentsForSharedVariablesInClassNamed: 'MCPToolClassMutationTestSharedVariableRemovalTarget'
			           sharedVariables: #(  )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariableRemovalTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass classVarNames isEmpty.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesTraitsWithEmptyArray [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestTraitRemovalTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #traits put: #( 'TAbleToRotate' ).
	self callToolWith: createArguments.
	result := self callToolWith:
		          (self updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestTraitRemovalTarget' traits: #(  )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestTraitRemovalTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass traits isEmpty.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenameUpdatesMethodReferences [

	| reference |
	self callToolWith: self updateRequestArgumentsForRename.
	reference := (self classNamed: self referenceClassName) new.
	self assert: reference referencedClass name asString equals: self renamedClassName.
	self assert: reference newReferencedInstance class name asString equals: self renamedClassName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenameUpdatesSubclassDefinitions [

	self callToolWith: self updateRequestArgumentsForRename.
	self assert: (self classNamed: self subclassName) superclass name asString equals: self renamedClassName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenamesClassAndReturnsStructuredData [

	| data result |
	result := self callToolWith: self updateRequestArgumentsForRename.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (Smalltalk globals includesKey: self renamedClassName asSymbol).
	self deny: (Smalltalk globals includesKey: self originalClassName asSymbol).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenamesClassSideSlotAndPreservesValue [

	| data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #( oldClassSlot ).
	target := self classNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'.
	self ensureMethodSource: 'oldClassSlot ^ oldClassSlot' protocol: 'accessing' on: target classSide.
	self ensureMethodSource: 'oldClassSlot: anObject oldClassSlot := anObject' protocol: 'accessing' on: target classSide.
	self ensureMethodSource: 'slotProbe ^ self oldClassSlot' protocol: 'testing' on: target classSide.
	target oldClassSlot: 73.
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'
			           slotName: 'oldClassSlot'
			           newSlotName: 'renamedClassSlot'
			           classSide: true).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target classSide slots collect: #name as: Array) equals: #( #renamedClassSlot ).
	self deny: (target classSide includesSelector: #oldClassSlot).
	self deny: (target classSide includesSelector: #oldClassSlot:).
	self assert: (target classSide includesSelector: #renamedClassSlot).
	self assert: (target classSide includesSelector: #renamedClassSlot:).
	self assert: target renamedClassSlot equals: 73.
	target renamedClassSlot: 91.
	self assert: target slotProbe equals: 91.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenamesInstanceSlotAndUpdatesReferences [

	| data instance result target |
	self
		createClassNamed: 'MCPToolClassMutationTestRenameSlotTarget'
		superclassName: 'Object'
		slots: #( oldSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'oldSlot ^ oldSlot'
		protocol: 'accessing'
		on: (self classNamed: 'MCPToolClassMutationTestRenameSlotTarget').
	self
		ensureMethodSource: 'oldSlot: anObject oldSlot := anObject'
		protocol: 'accessing'
		on: (self classNamed: 'MCPToolClassMutationTestRenameSlotTarget').
	self
		ensureMethodSource: 'slotProbe ^ self oldSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestRenameSlotTarget').
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestRenameSlotTarget'
			           slotName: 'oldSlot'
			           newSlotName: 'renamedSlot'
			           classSide: false).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRenameSlotTarget'.
	instance := target new.
	instance renamedSlot: 37.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target slots collect: #name as: Array) equals: #( #renamedSlot ).
	self deny: (target includesSelector: #oldSlot).
	self deny: (target includesSelector: #oldSlot:).
	self assert: (target includesSelector: #renamedSlot).
	self assert: (target includesSelector: #renamedSlot:).
	self assert: instance renamedSlot equals: 37.
	self assert: instance slotProbe equals: 37.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReparentsClassAndPreservesExistingState [

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
	self ensureMethodSource: 'probeMethod ^ 41' protocol: 'testing' on: (self classNamed: self reparentTargetClassName).
	self withoutEpiceaDuring: [ (self classNamed: self reparentTargetClassName) comment: 'reparent comment' ].
	result := self callToolWith: self updateRequestArgumentsForReparent.
	data := self dataFrom: result.
	target := self classNamed: self reparentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target superclass name asString equals: self reparentSuperclassName.
	self assert: target new probeMethod equals: 41.
	self assert: target comment equals: 'reparent comment'.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesClassSideTraits [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestClassTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #classTraits put: #( 'TAbleToRotate classTrait' ).
	self callToolWith: createArguments.
	result := self callToolWith:
		          (self
			           updateRequestArgumentsForClassTraitsInClassNamed: 'MCPToolClassMutationTestClassTraitTarget'
			           classTraits: #( 'TComparable' )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestClassTraitTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: (targetClass classSide traits collect: [ :each | each name asString ] as: Array)
		equals: #( 'TComparable classTrait' ).
	self assert: targetClass classSide traitCompositionString equals: 'TComparable classTrait'.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesLayout [

	| data result targetClass |
	self
		createClassNamed: 'MCPToolClassMutationTestLayoutTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith:
		          (self updateRequestArgumentsForLayoutInClassNamed: 'MCPToolClassMutationTestLayoutTarget' layout: 'WeakLayout').
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestLayoutTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass classLayout class name equals: #WeakLayout.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesSharedPools [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedPoolTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedPools put: #( 'ChronologyConstants' ).
	self callToolWith: createArguments.
	result := self callToolWith: (self
			           updateRequestArgumentsForSharedPoolsInClassNamed: 'MCPToolClassMutationTestSharedPoolTarget'
			           sharedPools: #( 'TextConstants' )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedPoolTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (targetClass sharedPools collect: [ :each | each name asString ] as: Array) equals: #( 'TextConstants' ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesSharedVariables [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedVariableTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedVariables put: #( 'AlphaShared' ).
	self callToolWith: createArguments.
	result := self callToolWith: (self
			           updateRequestArgumentsForSharedVariablesInClassNamed: 'MCPToolClassMutationTestSharedVariableTarget'
			           sharedVariables: #( 'BetaShared' )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariableTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass classVarNames equals: #( #BetaShared ).
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesSlotDefinitionAndPreservesMatchingValues [

	| data instance result target |
	self
		createClassNamed: 'MCPToolClassMutationTestDefinitionTarget'
		superclassName: 'Object'
		slots: #( oldSlot keptSlot )
		classSlots: #( oldClassSlot keptClassSlot ).
	target := self classNamed: 'MCPToolClassMutationTestDefinitionTarget'.
	instance := target new.
	instance instVarNamed: 'keptSlot' put: 13.
	target instVarNamed: 'keptClassSlot' put: 17.
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#className -> 'MCPToolClassMutationTestDefinitionTarget').
				           (#slots -> #( 'keptSlot' 'newSlot' )).
				           (#classSlots -> #( 'keptClassSlot' 'newClassSlot' )) }).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestDefinitionTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target slots collect: #name as: Array) equals: #( #keptSlot #newSlot ).
	self assert: (target classSide slots collect: #name as: Array) equals: #( #keptClassSlot #newClassSlot ).
	self assert: (instance instVarNamed: 'keptSlot') equals: 13.
	self assert: (target instVarNamed: 'keptClassSlot') equals: 17.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesTraits [

	| createArguments data result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #traits put: #( 'TAbleToRotate' ).
	self callToolWith: createArguments.
	result := self callToolWith:
		          (self updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestTraitTarget' traits: #( 'TComparable' )).
	data := self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestTraitTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (targetClass traits collect: [ :each | each name asString ] as: Array) equals: #( 'TComparable' ).
	self assert: targetClass traitCompositionString equals: 'TComparable'.
	self assert: targetClass classSide traitCompositionString equals: 'TComparable classTrait'.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenAddSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolClassMutationTestMissingAddSlot'
			           slotName: 'addedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'addSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingAddSlot'.
	self assert: (error at: #slotName) equals: 'addedSlot'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenCommentClassIsMissing [

	| error result suggestions |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#className -> 'MCPToolClassMutationTestMissing').
			          (#comment -> 'ignored') } asDictionary.
	error := self errorFrom: result.
	suggestions := error at: #suggestions.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'setComment'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissing'.
	self assert: (error at: #scopeName) equals: 'className'.
	self assert: suggestions size <= 5.
	self assert: ((error at: #message) includesSubstring: 'MCPToolClassMutationTestMissing does not exist')
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenDestinationTagIsMissing [

	self testUpdateMoveEnsuresMissingDestinationTag
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenMoveClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#className -> 'MCPToolClassMutationTestMissing').
			          (#packageName -> self destinationPackageName) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'move'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissing'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenPullUpSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestMissingPullUp'
			           slotName: 'sharedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingPullUp'.
	self assert: (error at: #slotName) equals: 'sharedSlot'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenRemoveSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestMissingRemoveSlot'
			           slotName: 'removableSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'removeSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingRemoveSlot'.
	self assert: (error at: #slotName) equals: 'removableSlot'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenRenameClassIsMissing [

	| error result suggestions |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#name -> 'MCPToolClassMutationTestMissing').
			          (#newName -> self renamedClassName) } asDictionary.
	error := self errorFrom: result.
	suggestions := error at: #suggestions.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissing'.
	self assert: (error at: #scopeName) equals: 'className'.
	self assert: suggestions size <= 5.
	self assert: ((error at: #message) includesSubstring: 'MCPToolClassMutationTestMissing does not exist')
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenRenameSlotClassIsMissing [

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestMissingRenameSlot'
			           slotName: 'oldSlot'
			           newSlotName: 'renamedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'renameSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingRenameSlot'.
	self assert: (error at: #slotName) equals: 'oldSlot'.
	self assert: (error at: #newSlotName) equals: 'renamedSlot'.
	self assert: (error at: #classSide) equals: false
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReparentSuperclassIsMissing [

	| error result |
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: {
			          (#action -> 'update').
			          (#className -> self reparentTargetClassName).
			          (#superclassName -> 'DefinitelyMissingSuperclass') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'reparent'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SuperclassNotFound'.
	self assert: (error at: #superclassName) equals: 'DefinitelyMissingSuperclass'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementClassTraitIsMissing [

	| createArguments error result |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestMissingClassTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	self callToolWith: createArguments.
	result := self callToolWith: (self
			           updateRequestArgumentsForClassTraitsInClassNamed: 'MCPToolClassMutationTestMissingClassTraitTarget'
			           classTraits: #( 'DefinitelyMissingClassTrait' )).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceClassTraits'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassTraitNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingClassTraitTarget'.
	self assert: (error at: #classTraitName) equals: 'DefinitelyMissingClassTrait'.
	self assert: (error at: #classTraits) equals: #( 'DefinitelyMissingClassTrait' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementLayoutIsInvalid [

	| error result |
	self
		createClassNamed: 'MCPToolClassMutationTestInvalidLayoutTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith:
		          (self updateRequestArgumentsForLayoutInClassNamed: 'MCPToolClassMutationTestInvalidLayoutTarget' layout: 'Object').
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceLayout'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'InvalidLayoutClass'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestInvalidLayoutTarget'.
	self assert: (error at: #layout) equals: 'Object'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementLayoutIsMissing [

	| error result |
	self
		createClassNamed: 'MCPToolClassMutationTestMissingLayoutTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith:
		          (self
			           updateRequestArgumentsForLayoutInClassNamed: 'MCPToolClassMutationTestMissingLayoutTarget'
			           layout: 'DefinitelyMissingLayout').
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceLayout'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'LayoutClassNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingLayoutTarget'.
	self assert: (error at: #layout) equals: 'DefinitelyMissingLayout'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementSharedPoolIsMissing [

	| createArguments error result |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestMissingSharedPoolTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	self callToolWith: createArguments.
	result := self callToolWith: (self
			           updateRequestArgumentsForSharedPoolsInClassNamed: 'MCPToolClassMutationTestMissingSharedPoolTarget'
			           sharedPools: #( 'DefinitelyMissingSharedPool' )).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceSharedPools'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SharedPoolNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingSharedPoolTarget'.
	self assert: (error at: #sharedPoolName) equals: 'DefinitelyMissingSharedPool'.
	self assert: (error at: #sharedPools) equals: #( 'DefinitelyMissingSharedPool' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementTraitIsMissing [

	| createArguments error result |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestMissingTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	self callToolWith: createArguments.
	result := self callToolWith: (self
			           updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget'
			           traits: #( 'DefinitelyMissingTrait' )).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceTraits'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'TraitNotFound'.
	self assert: (error at: #className) equals: 'MCPToolClassMutationTestMissingTraitTarget'.
	self assert: (error at: #traitName) equals: 'DefinitelyMissingTrait'.
	self assert: (error at: #traits) equals: #( 'DefinitelyMissingTrait' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateSetsClassComment [

	| data result target |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self withoutEpiceaDuring: [ (self classNamed: self commentTargetClassName) comment: 'original comment' ].
	result := self callToolWith: (self updateRequestArgumentsForClassComment: 'updated comment').
	data := self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target comment equals: 'updated comment'.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'private - calling' }
MCPToolClassMutationTest >> toolName [

	self shouldNotImplement
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForClassComment: aClassComment [

	^ {
		  (#action -> 'update').
		  (#className -> self commentTargetClassName).
		  (#comment -> aClassComment) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForClassTraitsInClassNamed: aClassName classTraits: someClassTraitNames [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#classTraits -> someClassTraitNames) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForLayoutInClassNamed: aClassName layout: aLayoutName [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#layout -> aLayoutName) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForMoveToPackage [

	^ {
		  (#action -> 'update').
		  (#className -> self moveTargetClassName).
		  (#packageName -> self destinationPackageName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForMoveToPackageAndTag [

	^ {
		  (#action -> 'update').
		  (#className -> self moveTargetClassName).
		  (#packageName -> self destinationPackageName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForRecategorization [

	^ {
		  (#action -> 'update').
		  (#className -> self moveTargetClassName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForRename [

	^ {
		  (#action -> 'update').
		  (#name -> self originalClassName).
		  (#newName -> self renamedClassName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForReparent [

	^ {
		  (#action -> 'update').
		  (#className -> self reparentTargetClassName).
		  (#superclassName -> self reparentSuperclassName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSharedPoolsInClassNamed: aClassName sharedPools: someNames [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#sharedPools -> someNames) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSharedVariablesInClassNamed: aClassName sharedVariables: someNames [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#sharedVariables -> someNames) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSlotAction: slotAction className: aClassName slotName: aSlotName classSide: aBoolean [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#slotAction -> slotAction).
			  (#slotName -> aSlotName).
			  (#classSide -> aBoolean) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSlotRenameInClassNamed: aClassName slotName: aSlotName newSlotName: aNewSlotName classSide: aBoolean [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#slotAction -> 'rename').
			  (#slotName -> aSlotName).
			  (#newSlotName -> aNewSlotName).
			  (#classSide -> aBoolean) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForTraitsInClassNamed: aClassName traits: someTraitNames [

	^ self updateRequestArgumentsWith: {
			  (#className -> aClassName).
			  (#traits -> someTraitNames) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsWith: associations [

	| arguments |
	arguments := Dictionary new.
	arguments at: #action put: 'update'.
	associations do: [ :each | arguments at: each key put: each value ].
	^ arguments
]
