"
Tests the class_create and class_update tools.
"
Class {
	#name : 'MCPToolClassMutationTest',
	#superclass : 'MCPToolAPITestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private - asserting' }
MCPToolClassMutationTest >> assertIncludesReferencedSlotWarning: warningMessages [

	self assert:
		(warningMessages anySatisfy: [ :each | (each includesSubstring: 'referencedSlot') and: [ each includesSubstring: 'referenced' ] ])
]

{ #category : 'private - calling' }
MCPToolClassMutationTest >> callUpdateWrittenIn: aMessage [
	"Make the class_update call a refusal of class_create writes, as a client that reads the text would."

	^ self callRawToolNamed: 'class_update' withArguments: (STONJSON fromString: (aMessage
				    copyFrom: (aMessage indexOfSubCollection: 'class_update {') + 'class_update ' size
				    to: (aMessage indexOfSubCollection: '. class_get shows it.') - 1))
]

{ #category : 'private' }
MCPToolClassMutationTest >> commentTargetClassName [

	^ 'MCPToolClassMutationTestCommentTarget'
]

{ #category : 'private - create' }
MCPToolClassMutationTest >> createRequestArgumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ {
		  (#name -> aClassName).
		  (#superclass -> aSuperclassName).
		  (#package -> aPackageName) } asDictionary
]

{ #category : 'private - fixtures' }
MCPToolClassMutationTest >> createSlotUserFixture [
	"A class whose slot and class-side slot its methods read and write, with a subclass reading the slot it inherits."

	| target subclass |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
		          superclassName: 'Object'
		          slots: #( usedSlot )
		          classSlots: #( usedClassSlot ).
	subclass := self
		            createClassNamed: 'MCPToolClassMutationTestSlotUserSubclass'
		            superclassName: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
		            slots: #(  )
		            classSlots: #(  ).
	self ensureMethodSource: 'readsUsed ^ usedSlot' protocol: 'testing' on: target.
	self ensureMethodSource: 'writesUsed: anObject usedSlot := anObject' protocol: 'testing' on: target.
	self ensureMethodSource: 'bumpsUsed usedSlot := usedSlot + 1' protocol: 'testing' on: target.
	self ensureMethodSource: 'subclassReadsUsed ^ usedSlot' protocol: 'testing' on: subclass.
	self ensureMethodSource: 'readsUsedClassSlot ^ usedClassSlot' protocol: 'testing' on: target classSide
]

{ #category : 'private' }
MCPToolClassMutationTest >> createdClassNames [

	^ #( 'MCPToolClassMutationTestGenerated' 'MCPToolClassMutationTestTagged' 'MCPToolClassMutationTestClassSlots'
	     'MCPToolClassMutationTestConfigured' 'MCPToolClassMutationTestTemporaryPackage' 'MCPToolClassMutationTestCommentTarget'
	     'MCPToolClassMutationTestCommented' 'MCPToolClassMutationTestDefaultSuperclass' 'MCPToolClassMutationTestReparentTarget'
	     'MCPToolClassMutationTestReparentChild' 'MCPToolClassMutationTestReparentSuperclass'
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
	     'MCPToolClassMutationTestSlotUserSubclass' 'MCPToolClassMutationTestWarningRemoveSlotTarget'
	     'MCPToolClassMutationTestPullUpTarget' 'MCPToolClassMutationTestPullUpChildOne' 'MCPToolClassMutationTestPullUpChildTwo'
	     'MCPToolClassMutationTestPushDownTarget' 'MCPToolClassMutationTestPushDownChildOne'
	     'MCPToolClassMutationTestPushDownChildTwo' 'MCPToolClassMutationTestWarningPullUpTarget'
	     'MCPToolClassMutationTestWarningPullUpChildOne' 'MCPToolClassMutationTestWarningPullUpChildTwo'
	     'TMCPToolClassMutationTestTrait' )
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
			package := self packageOrganizer ensurePackage: self destinationPackageName.
			package ensureTag: self destinationTagName ]
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
			(self packageOrganizer hasPackage: self destinationPackageName) ifTrue: [
				self packageOrganizer removePackage: (self packageOrganizer packageNamed: self destinationPackageName) ] ]
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
MCPToolClassMutationTest >> reparentChildClassName [

	^ 'MCPToolClassMutationTestReparentChild'
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
	self restoreClassNamed: self originalClassName renamedTo: self renamedClassName
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
	self restoreClassNamed: self originalClassName renamedTo: self renamedClassName.
	super tearDown
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testASingleUpdateAnswersNoData [
	"Several updates in one call each add their action to the data, and nothing else."

	| result |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: (self updateRequestArgumentsForClassComment: 'updated comment').
	self assert: (self dataFrom: result) isEmpty
]

{ #category : 'tests' }
MCPToolClassMutationTest >> testClassToolSchemaDescriptionsExplainRecategorizationAndReplacementSemantics [

	| tool layoutDescription packageDescription sharedPoolsDescription sharedVariablesDescription slotsSchema tagDescription traitsDescription |
	tool := MCPToolUpdateClass new.
	packageDescription := (self inputPropertyNamed: 'package' inTool: tool) description.
	tagDescription := (self inputPropertyNamed: 'tag' inTool: tool) description.
	traitsDescription := (self inputPropertyNamed: 'traits' inTool: tool) description.
	sharedVariablesDescription := (self inputPropertyNamed: 'sharedVariables' inTool: tool) description.
	sharedPoolsDescription := (self inputPropertyNamed: 'sharedPools' inTool: tool) description.
	layoutDescription := (self inputPropertyNamed: 'layout' inTool: tool) description.
	"Moving and retagging are different changes, and package says how to ask for the second one."
	self assert: (packageDescription includesSubstring: 'tag alone').
	self assert: (tagDescription includesSubstring: 'package').
	"The stateless collections are replaced by value, and say so."
	self assert: (traitsDescription includesSubstring: 'empty array').
	"A trait is used by the whole class, so traits says it covers the class side too."
	self assert: (traitsDescription includesSubstring: 'class side').
	self assert: (sharedVariablesDescription includesSubstring: 'empty array').
	self assert: (sharedPoolsDescription includesSubstring: 'empty array').
	self assert: (sharedPoolsDescription includesSubstring: 'Shared pools').
	self assert: (layoutDescription includesSubstring: 'AbstractLayout').
	"Slots are patched, and each part of the patch says what it does."
	slotsSchema := (tool inputSchema asJRPCJSON at: #properties) at: 'slots'.
	self
		assert: (((slotsSchema at: #properties) at: 'rename') at: #description)
		equals: 'Slots to rename, as current name to new name. Values are migrated and references updated.'.
	self assert: ((((slotsSchema at: #properties) at: 'replace') at: #description) includesSubstring: 'Prefer add and remove')
]

{ #category : 'tests - schema' }
MCPToolClassMutationTest >> testClassToolSchemasDeclareExpectedInputs [

	| createProperties slotsSchema updateProperties |
	createProperties := MCPToolCreateClass new inputSchema properties collect: [ :each | each name ].
	updateProperties := MCPToolUpdateClass new inputSchema properties collect: [ :each | each name ].
	self assert: MCPToolCreateClass new name equals: 'class_create'.
	self assert: MCPToolUpdateClass new name equals: 'class_update'.
	self
		assert: createProperties asArray
		equals:
		#( 'name' 'superclass' 'package' 'tag' 'slots' 'classSlots' 'traits' 'sharedVariables' 'sharedPools' 'layout' 'comment' ).
	self assert: MCPToolCreateClass new inputSchema required asSet equals: #( 'name' 'package' ) asSet.
	self
		assert: updateProperties asArray
		equals:
			#( 'name' 'newName' 'superclass' 'package' 'tag' 'comment' 'slots' 'classSlots' 'traits' 'sharedVariables' 'sharedPools'
			   'layout' 'force' ).
	self assert: MCPToolUpdateClass new inputSchema required asSet equals: #( 'name' ) asSet.
	"Slots are patched, so their argument is a delta rather than a list."
	slotsSchema := (MCPToolUpdateClass new inputSchema asJRPCJSON at: #properties) at: 'slots'.
	self assert: (slotsSchema at: #type) equals: 'object'.
	self assert: (slotsSchema at: #properties) keys asSet equals: #( 'add' 'remove' 'rename' 'pullUp' 'pushDown' 'replace' ) asSet
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateAcceptsClassSlots [

	| createdClass result |
	result := self callToolNamed: 'class_create' withArguments: {
			          (#name -> 'MCPToolClassMutationTestClassSlots').
			          (#superclass -> 'Object').
			          (#package -> self generatedPackageName).
			          (#classSlots -> #( 'defaultName' )) } asDictionary.
	self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestClassSlots'.
	self assert: (createdClass classSide slots collect: #name as: Array) equals: #( #defaultName )
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateAcceptsDefinitionOptions [

	| arguments createdClass result |
	arguments := self
		             createRequestArgumentsForClassName: 'MCPToolClassMutationTestConfigured'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #traits put: #( 'TAbleToRotate' ).
	arguments at: #sharedVariables put: #( 'AlphaShared' 'BetaShared' ).
	arguments at: #sharedPools put: #( 'ChronologyConstants' ).
	arguments at: #layout put: 'WeakLayout'.
	result := self callToolNamed: 'class_create' withArguments: arguments.
	self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestConfigured'.
	self assert: (createdClass traits collect: [ :each | each name asString ] as: Array) equals: #( 'TAbleToRotate' ).
	self assert: createdClass traitCompositionString equals: 'TAbleToRotate'.
	"Asked for nothing on the class side, the class still uses the trait whole."
	self
		assert: (createdClass classSide traits collect: [ :each | each name asString ] as: Array)
		equals: #( 'TAbleToRotate classTrait' ).
	self assert: createdClass classSide traitCompositionString equals: 'TAbleToRotate classTrait'.
	self assert: createdClass classVarNames equals: #( #AlphaShared #BetaShared ).
	self assert: (createdClass sharedPools collect: [ :each | each name asString ] as: Array) equals: #( 'ChronologyConstants' ).
	self assert: createdClass classLayout class name equals: #WeakLayout
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateAcceptsSlotsAndTag [

	| createdClass result |
	result := self callToolNamed: 'class_create' withArguments: {
			          (#name -> 'MCPToolClassMutationTestTagged').
			          (#superclass -> 'Object').
			          (#package -> self generatedPackageName).
			          (#tag -> 'Generated').
			          (#slots -> #( 'firstName' 'lastName' )) } asDictionary.
	self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestTagged'.
	self assert: (createdClass slots collect: #name as: Array) equals: #( #firstName #lastName ).
	self assert: createdClass packageTagName asString equals: 'Generated'.
	self assert: createdClass category asString equals: self generatedPackageName , '-Generated'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateContextDefaultsTheSuperclassToObject [

	| request tool |
	tool := MCPToolCreateClass new.
	request := tool requestFromToolCallArguments: {
			           (#name -> 'MCPGeneratedClass').
			           (#package -> 'MCP-Generated') } asDictionary.
	self assert: (tool superclassNameIn: request) equals: 'Object'.
	self assert: ((tool requestedContextFor: request checked: true) at: #superclass) equals: 'Object'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateContextReadsTheDefinition [

	| context tool |
	tool := MCPToolCreateClass new.
	context := tool
		           requestedContextFor: (tool requestFromToolCallArguments: {
					            (#name -> 'MCPGeneratedClass').
					            (#superclass -> 'Object').
					            (#package -> 'MCP-Generated').
					            (#tag -> 'Models').
					            (#comment -> 'Generated comment.').
					            (#slots -> #( 'firstName' 'lastName' )).
					            (#classSlots -> #( 'defaultName' )).
					            (#traits -> #( 'TComparable' )).
					            (#sharedVariables -> #( 'Current' )).
					            (#sharedPools -> #( 'ChronologyConstants' )).
					            (#layout -> 'WeakLayout') } asDictionary)
		           checked: true.
	self assert: (context at: #class) equals: 'MCPGeneratedClass'.
	self assert: (context at: #superclass) equals: 'Object'.
	self assert: (context at: #package) equals: 'MCP-Generated'.
	self assert: (context at: #tag) equals: 'Models'.
	self assert: (context at: #comment) equals: 'Generated comment.'.
	self assert: (context at: #slots) equals: #( 'firstName' 'lastName' ).
	self assert: (context at: #classSlots) equals: #( 'defaultName' ).
	self assert: (context at: #traits) equals: #( 'TComparable' ).
	self assert: (context at: #sharedVariables) equals: #( 'Current' ).
	self assert: (context at: #sharedPools) equals: #( 'ChronologyConstants' ).
	self assert: (context at: #layout) equals: 'WeakLayout'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateCreatesClass [

	| createdClass result |
	result := self callToolNamed: 'class_create' withArguments: (self
			           createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			           superclassName: 'Object'
			           packageName: self generatedPackageName).
	self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestGenerated'.
	self assert: createdClass superclass equals: Object.
	self assert: createdClass packageName asString equals: self generatedPackageName.
	self assert: createdClass slots isEmpty
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateDefaultsTheSuperclassToObject [

	| createdClass result |
	result := self callToolNamed: 'class_create' withArguments: {
			          (#name -> 'MCPToolClassMutationTestDefaultSuperclass').
			          (#package -> self generatedPackageName) } asDictionary.
	createdClass := self classNamed: 'MCPToolClassMutationTestDefaultSuperclass'.
	self assert: createdClass superclass equals: Object.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateEnsuresMissingPackage [

	| createdClass |
	self callToolNamed: 'class_create' withArguments: (self
			 createRequestArgumentsForClassName: 'MCPToolClassMutationTestTemporaryPackage'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	createdClass := self classNamed: 'MCPToolClassMutationTestTemporaryPackage'.
	self assert: (self packageOrganizer hasPackage: self generatedPackageName).
	self assert: createdClass packageName asString equals: self generatedPackageName
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateNamesATraitATrait [

	| createdTrait result text |
	result := self callToolNamed: 'class_create' withArguments: {
			          (#name -> 'TMCPToolClassMutationTestTrait').
			          (#superclass -> 'Trait').
			          (#package -> self generatedPackageName) } asDictionary.
	createdTrait := self classNamed: 'TMCPToolClassMutationTestTrait'.
	text := (result at: #content) first at: #text.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: createdTrait isTrait.
	self assert: (text includesSubstring: 'Created trait TMCPToolClassMutationTestTrait.')
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalNamesTheSlotsTheClassDefinesThatTheCallLeavesOut [
	"class_create gives a class whole, so an agent that gives it again without a slot it defines may mean that slot to go, as when it renames colour to color. class_update keeps a slot it is not told to remove, so the refusal names each slot the class defines that the call leaves out, whether it writes a move, an add or no call at all. Made, the written move keeps the slot, as the refusal says."

	| refusal target |
	self
		createClassNamed: self reparentSuperclassName
		superclassName: 'Object'
		slots: #( #color )
		classSlots: #(  ).
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #( #radius #colour )
		classSlots: #(  ).
	refusal := [ :superclassName |
		           (self errorFrom: (self callToolNamed: 'class_create' withArguments: {
					             (#name -> self reparentTargetClassName).
					             (#superclass -> superclassName).
					             (#package -> self generatedPackageName).
					             (#slots -> #( 'radius' 'color' )) } asDictionary)) at: #message ].
	self
		assert: (refusal value: 'Object')
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update {"name":"MCPToolClassMutationTestReparentTarget","slots":{"add":["color"]}}. class_get shows it. MCPToolClassMutationTestReparentTarget also defines the slot colour, which this call does not list. class_update keeps it unless its slots argument removes or renames it.'.
	self
		assert: (refusal value: self reparentSuperclassName)
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update {"name":"MCPToolClassMutationTestReparentTarget","superclass":"MCPToolClassMutationTestReparentSuperclass"}. class_get shows it. MCPToolClassMutationTestReparentTarget also defines the slot colour, which this call does not list. class_update keeps it unless its slots argument removes or renames it.'.
	self deny: ((self callUpdateWrittenIn: (refusal value: self reparentSuperclassName)) at: #isError ifAbsent: [ false ]).
	target := self classNamed: self reparentTargetClassName.
	self assert: target superclass name equals: self reparentSuperclassName asSymbol.
	self assert: (target instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'radius' 'colour' ).
	self
		assert: (refusal value: self reparentSuperclassName)
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists and already has everything this call asks for. class_get shows it. MCPToolClassMutationTestReparentTarget also defines the slot colour, which this call does not list. class_update keeps it unless its slots argument removes or renames it.'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalNamesWhatTheClassHasThatTheListsTheCallGivesLeaveOut [
	"Each list class_create takes gives the class whole, and class_update keeps what it is not told to drop: a slot its patch does not remove, a trait, shared variable or shared pool the list it is given holds. So the refusal names, for each list the call gives, what the class has that the list leaves out. A list the call does not give leaves nothing out."

	| message |
	self callToolNamed: 'class_create' withArguments: (self
			 createRequestArgumentsForClassName: 'TMCPToolClassMutationTestTrait'
			 superclassName: 'Trait'
			 packageName: self generatedPackageName).
	self callToolNamed: 'class_create' withArguments: {
			(#name -> 'MCPToolClassMutationTestGenerated').
			(#superclass -> 'Object').
			(#package -> self generatedPackageName).
			(#slots -> #( 'a' 'b' 'c' )).
			(#classSlots -> #( 'made' 'kept' )).
			(#traits -> #( 'TMCPToolClassMutationTestTrait' )).
			(#sharedVariables -> #( 'Registry' 'Kept' )).
			(#sharedPools -> #( 'ChronologyConstants' )) } asDictionary.
	message := (self errorFrom: (self callToolNamed: 'class_create' withArguments: {
				             (#name -> 'MCPToolClassMutationTestGenerated').
				             (#superclass -> 'Object').
				             (#package -> self generatedPackageName).
				             (#slots -> #( 'a' )).
				             (#classSlots -> #( 'made' )).
				             (#traits -> #(  )).
				             (#sharedVariables -> #( 'Registry' )) } asDictionary)) at: #message.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestGenerated already exists and already has everything this call asks for. class_get shows it. MCPToolClassMutationTestGenerated also defines the slots b and c, which this call does not list. class_update keeps them unless its slots argument removes or renames them. MCPToolClassMutationTestGenerated also defines the class-side slot kept, which this call does not list. class_update keeps it unless its classSlots argument removes or renames it. MCPToolClassMutationTestGenerated also uses the trait TMCPToolClassMutationTestTrait, which this call does not list. class_update keeps it unless its traits argument leaves it out. MCPToolClassMutationTestGenerated also defines the shared variable Kept, which this call does not list. class_update keeps it unless its sharedVariables argument leaves it out.'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalNamingAnotherSuperclassAddsASlotTheClassWouldNoLongerInherit [
	"A slot the class inherits only from where it is now is gone once class_update moves it under the superclass this call names, so the written call adds it. Made, the call gives the class the slot asked for."

	| message target |
	self
		createClassNamed: self reparentSuperclassName
		superclassName: 'Object'
		slots: #( #inherited )
		classSlots: #(  ).
	self
		createClassNamed: self reparentTargetClassName
		superclassName: self reparentSuperclassName
		slots: #(  )
		classSlots: #(  ).
	message := (self errorFrom: (self callToolNamed: 'class_create' withArguments: {
				             (#name -> self reparentTargetClassName).
				             (#superclass -> 'Object').
				             (#package -> self generatedPackageName).
				             (#slots -> #( 'inherited' )) } asDictionary)) at: #message.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update {"name":"MCPToolClassMutationTestReparentTarget","superclass":"Object","slots":{"add":["inherited"]}}. class_get shows it.'.
	self deny: ((self callUpdateWrittenIn: message) at: #isError ifAbsent: [ false ]).
	target := self classNamed: self reparentTargetClassName.
	self assert: target superclass name equals: #Object.
	self assert: (target instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'inherited' )
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalNamingAnotherSuperclassAddsNoSlotThatSuperclassDefines [
	"class_update moves a class before it adds slots, so the slots the written call adds are those the class would lack under the superclass this call names. A slot that superclass defines, on either side, is not added again, which class_update would refuse. Made, the call gives the class every slot asked for."

	| message target |
	self
		createClassNamed: self reparentSuperclassName
		superclassName: 'Object'
		slots: #( #inherited )
		classSlots: #( #registry ).
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #( #own )
		classSlots: #(  ).
	message := (self errorFrom: (self callToolNamed: 'class_create' withArguments: {
				             (#name -> self reparentTargetClassName).
				             (#superclass -> self reparentSuperclassName).
				             (#package -> self generatedPackageName).
				             (#slots -> #( 'own' 'inherited' 'added' )).
				             (#classSlots -> #( 'registry' )) } asDictionary)) at: #message.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update {"name":"MCPToolClassMutationTestReparentTarget","superclass":"MCPToolClassMutationTestReparentSuperclass","slots":{"add":["added"]}}. class_get shows it.'.
	self deny: ((self callUpdateWrittenIn: message) at: #isError ifAbsent: [ false ]).
	target := self classNamed: self reparentTargetClassName.
	self assert: target superclass name equals: self reparentSuperclassName asSymbol.
	self assert: (target instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'own' 'added' ).
	self assert: (target classSide allInstVarNames includes: #registry)
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfAClassOfAnotherProjectWritesNoUpdate [
	"A class of another project, as Pharo's Stack in Collections-Stack, is not the caller's to change: the class_update call written from a class_create of the caller's own Stack would move Pharo's into the caller's package, reparent it and give it the caller's slots and comment, breaking whatever uses it. The refusal names the package the class is in and asks for another name, and writes no call."

	| error stack |
	stack := self class environment at: #Stack.
	error := self errorFrom: (self callToolNamed: 'class_create' withArguments: {
				          (#name -> 'Stack').
				          (#superclass -> 'Object').
				          (#package -> self generatedPackageName).
				          (#slots -> #( 'items' )).
				          (#comment -> 'A stack of items.') } asDictionary).
	self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self
		assert: (error at: #message)
		equals:
			('Class Stack already exists in package {1}, which belongs to another project than {2}. Choose another name for your class, such as one with your project''s prefix.'
				 format: {
						 stack package name.
						 self generatedPackageName }).
	self assert: (error at: #package) equals: stack package name asString
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfAClassThatHasItAllSaysNothingNeedsChanging [
	"A class that already has everything the call asks for needs no class_update call: the refusal says so rather than write one that changes nothing."

	| arguments error |
	arguments := {
		             (#name -> 'MCPToolClassMutationTestGenerated').
		             (#superclass -> 'Object').
		             (#package -> self generatedPackageName).
		             (#slots -> #( 'a' )) } asDictionary.
	self callToolNamed: 'class_create' withArguments: arguments.
	error := self errorFrom: (self callToolNamed: 'class_create' withArguments: arguments).
	self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self
		assert: (error at: #message)
		equals:
		'Class MCPToolClassMutationTestGenerated already exists and already has everything this call asks for. class_get shows it.'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfATraitWritesTheUpdateWhenTheCallNamesNoSuperclass [
	"A call that names no superclass asks for neither a class nor a trait. On a trait that exists, it is answered with the class_update call that gives the trait what it lacks, as a call that names Trait is. Made, that call gives the trait the slot asked for."

	| message |
	self callToolNamed: 'class_create' withArguments: (self
			 createRequestArgumentsForClassName: 'TMCPToolClassMutationTestTrait'
			 superclassName: 'Trait'
			 packageName: self generatedPackageName).
	message := (self errorFrom: (self callToolNamed: 'class_create' withArguments: {
				             (#name -> 'TMCPToolClassMutationTestTrait').
				             (#package -> self generatedPackageName).
				             (#slots -> #( 'color' )) } asDictionary)) at: #message.
	self
		assert: message
		equals:
		'Class TMCPToolClassMutationTestTrait already exists. Change it with class_update {"name":"TMCPToolClassMutationTestTrait","slots":{"add":["color"]}}. class_get shows it.'.
	self deny: ((self callUpdateWrittenIn: message) at: #isError ifAbsent: [ false ]).
	self
		assert: ((self classNamed: 'TMCPToolClassMutationTestTrait') instVarNames collect: [ :each | each asString ] as: Array)
		equals: #( 'color' )
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfAnExistingClassSaysHowToReachClassUpdate [
	"class_update is in tools/list, so the refusal gives the call to class_update itself, with the class already named in it, rather than a route through tool_call."

	| text |
	self callToolNamed: 'class_create' withArguments: (self
			 createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	text := self textFrom: (self callToolNamed: 'class_create' withArguments: {
				         (#name -> 'MCPToolClassMutationTestGenerated').
				         (#package -> self generatedPackageName).
				         (#slots -> #( 'color' )) } asDictionary).
	self assert:
		(text includesSubstring: 'Change it with class_update {"name":"MCPToolClassMutationTestGenerated","slots":{"add":["color"]}}.').
	self deny: (text includesSubstring: 'tool_call')
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfAnExistingClassWritesTheUpdateThatGivesItWhatItLacks [
	"An agent that asks class_create for a class that exists wants it to have that definition. The refusal writes the class_update call that gives it what it lacks, and nothing else: the slots it does not have are added, a list class_update replaces keeps what the class has, and what the class already has is left out. The call is written as a client reads text, a comment's lines ended by line feeds. Made, that call gives the class the definition asked for."

	| createdClass error message |
	self callToolNamed: 'class_create' withArguments: {
			(#name -> 'MCPToolClassMutationTestGenerated').
			(#package -> self generatedPackageName).
			(#slots -> #( 'a' )).
			(#sharedVariables -> #( 'Registry' )) } asDictionary.
	error := self errorFrom: (self callToolNamed: 'class_create' withArguments: {
				          (#name -> 'MCPToolClassMutationTestGenerated').
				          (#superclass -> 'Object').
				          (#package -> self generatedPackageName).
				          (#tag -> 'Model').
				          (#slots -> #( 'a' 'color' )).
				          (#classSlots -> #( 'made' )).
				          (#sharedVariables -> #( 'Registry' 'Other' )).
				          (#comment -> (String cr join: #( 'A generated class.' 'It has two lines.' ))) } asDictionary).
	message := error at: #message.
	self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestGenerated already exists. Change it with class_update {"name":"MCPToolClassMutationTestGenerated","tag":"Model","slots":{"add":["color"]},"classSlots":{"add":["made"]},"sharedVariables":["Registry","Other"],"comment":"A generated class.\nIt has two lines."}. class_get shows it.'.
	self deny: ((self callUpdateWrittenIn: message) at: #isError ifAbsent: [ false ]).
	createdClass := self classNamed: 'MCPToolClassMutationTestGenerated'.
	self assert: (createdClass instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'a' 'color' ).
	self assert: (createdClass classSide instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'made' ).
	self assert: (createdClass classVarNames collect: [ :each | each asString ] as: Set) equals: #( 'Registry' 'Other' ) asSet.
	self assert: createdClass mcpTagName equals: 'Model'.
	self assert: createdClass mcpComment lines equals: #( 'A generated class.' 'It has two lines.' )
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfTheOtherKindSaysWhichKindExists [
	"class_update makes no class a trait and no trait a class, so a call that asks for one where the other exists is told which exists, rather than that nothing needs changing."

	| refusalOf |
	self callToolNamed: 'class_create' withArguments: (self
			 createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	self callToolNamed: 'class_create' withArguments: (self
			 createRequestArgumentsForClassName: 'TMCPToolClassMutationTestTrait'
			 superclassName: 'Trait'
			 packageName: self generatedPackageName).
	refusalOf := [ :className :superclassName |
		             self errorFrom: (self
				              callToolNamed: 'class_create'
				              withArguments:
				              (self
					               createRequestArgumentsForClassName: className
					               superclassName: superclassName
					               packageName: self generatedPackageName)) ].
	self assert: ((refusalOf value: 'MCPToolClassMutationTestGenerated' value: 'Trait') at: #errorCode) equals: 'ClassAlreadyExists'.
	self
		assert: ((refusalOf value: 'MCPToolClassMutationTestGenerated' value: 'Trait') at: #message)
		equals:
		'Class MCPToolClassMutationTestGenerated already exists, and this call asks for a trait: class_update cannot make a class a trait. Choose another name for the trait. class_get shows the class.'.
	self
		assert: ((refusalOf value: 'TMCPToolClassMutationTestTrait' value: 'Object') at: #message)
		equals:
		'Trait TMCPToolClassMutationTestTrait already exists, and this call asks for a class: class_update cannot make a trait a class. Choose another name for the class. class_get shows the trait.'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalPullsUpASlotASubclassDefines [
	"class_update refuses to add a slot that a subclass of the class defines: it pulls the slot up from there instead. The call the refusal writes gives the class such a slot by pullUp, on either side, and adds the others. Made, it moves the slot from the subclass into the class."

	| child message target |
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: self reparentChildClassName
		superclassName: self reparentTargetClassName
		slots: #( #shared )
		classSlots: #( #registry ).
	message := (self errorFrom: (self callToolNamed: 'class_create' withArguments: {
				             (#name -> self reparentTargetClassName).
				             (#package -> self generatedPackageName).
				             (#slots -> #( 'shared' 'added' )).
				             (#classSlots -> #( 'registry' )) } asDictionary)) at: #message.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update {"name":"MCPToolClassMutationTestReparentTarget","slots":{"add":["added"],"pullUp":["shared"]},"classSlots":{"pullUp":["registry"]}}. class_get shows it.'.
	self deny: ((self callUpdateWrittenIn: message) at: #isError ifAbsent: [ false ]).
	target := self classNamed: self reparentTargetClassName.
	child := self classNamed: self reparentChildClassName.
	self assert: (target instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'added' 'shared' ).
	self assert: (target classSide instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'registry' ).
	self assert: child instVarNames isEmpty.
	self assert: child classSide instVarNames isEmpty
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalSaysWhichSlotsKeepTheClassFromTheSuperclassItNames [
	"A class cannot define a slot one of its superclasses has, so class_update refuses to move a class under a superclass that has a slot the class or one of its subclasses defines. The refusal writes no call that would fail so: it says which classes define which of those slots."

	| refusal |
	self
		createClassNamed: self reparentSuperclassName
		superclassName: 'Object'
		slots: #( #shared #width )
		classSlots: #(  ).
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #( #own #shared )
		classSlots: #(  ).
	refusal := [
		           (self errorFrom: (self callToolNamed: 'class_create' withArguments: {
					             (#name -> self reparentTargetClassName).
					             (#superclass -> self reparentSuperclassName).
					             (#package -> self generatedPackageName).
					             (#slots -> #( 'own' 'shared' )) } asDictionary)) at: #message ].
	self
		assert: refusal value
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. MCPToolClassMutationTestReparentTarget defines the slot shared, which MCPToolClassMutationTestReparentSuperclass already has. A class cannot define a slot one of its superclasses has, so class_update cannot move MCPToolClassMutationTestReparentTarget under MCPToolClassMutationTestReparentSuperclass until MCPToolClassMutationTestReparentTarget no longer defines shared. class_get shows the slots a class defines.'.
	self
		createClassNamed: self reparentChildClassName
		superclassName: self reparentTargetClassName
		slots: #( #width )
		classSlots: #(  ).
	self
		assert: refusal value
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. MCPToolClassMutationTestReparentTarget defines the slot shared, which MCPToolClassMutationTestReparentSuperclass already has. MCPToolClassMutationTestReparentChild, a subclass of MCPToolClassMutationTestReparentTarget, defines the slot width, which MCPToolClassMutationTestReparentSuperclass already has. A class cannot define a slot one of its superclasses has, so class_update cannot move MCPToolClassMutationTestReparentTarget under MCPToolClassMutationTestReparentSuperclass until MCPToolClassMutationTestReparentTarget and MCPToolClassMutationTestReparentChild no longer define those slots. class_get shows the slots a class defines.'.
	self assert: ((self callToolNamed: 'class_update' withArguments: {
				  (#name -> self reparentTargetClassName).
				  (#superclass -> self reparentSuperclassName) } asDictionary) at: #isError).
	self assert: (self classNamed: self reparentTargetClassName) superclass name equals: #Object
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusesAListWrittenAsOneName [
	"A client may send a list as the one string of an array. In the arguments whose names the class builder takes as they are, it is named as a list, with the string under name as for a class name, and nothing is made: no class, no package."

	{
		#( 'slots' 'a slot name' ).
		#( 'classSlots' 'a slot name' ).
		#( 'sharedVariables' 'a class variable name' ) } do: [ :each |
			| error result |
			result := self callToolNamed: 'class_create' withArguments: {
					          (#name -> 'MCPToolClassMutationTestGenerated').
					          (#package -> self generatedPackageName).
					          (each first -> #( '["Title" "Text"]' )) } asDictionary.
			error := self errorFrom: result.
			self assert: (result at: #isError).
			self assert: (error at: #errorCode) equals: 'NameIsAList'.
			self assert: (error at: #argument) equals: each first.
			self assert: (error at: #name) equals: '["Title" "Text"]'.
			self
				assert: (error at: #message)
				equals:
				('["Title" "Text"] is a list written as one string, not {1}. Pass several names as an array of strings.' format:
					 { each second }).
			self deny: (self class environment includesKey: #MCPToolClassMutationTestGenerated).
			self deny: (self packageOrganizer hasPackage: self generatedPackageName) ]
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateReturnsStructuredErrorWhenClassAlreadyExists [

	| arguments error result |
	arguments := self
		             createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	self callToolNamed: 'class_create' withArguments: arguments.
	result := self callToolNamed: 'class_create' withArguments: arguments.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self assert: ((error at: #message) beginsWith: 'Class MCPToolClassMutationTestGenerated already exists ').
	self assert: (((result at: #content) first at: #text) includesSubstring: (error at: #message)).
	self deny: (error includesKey: #guidance)
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateReturnsStructuredErrorWhenSuperclassIsMissing [

	| error result |
	result := self callToolNamed: 'class_create' withArguments: (self
			           createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			           superclassName: 'DefinitelyMissingSuperclass'
			           packageName: self generatedPackageName).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SuperclassNotFound'.
	self assert: (error at: #superclass) equals: 'DefinitelyMissingSuperclass'
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
	result := self callToolNamed: 'class_create' withArguments: arguments.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'create'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'TraitNotFound'.
	self assert: (error at: #trait) equals: 'DefinitelyMissingTrait'.
	self assert: (error at: #traits) equals: #( 'DefinitelyMissingTrait' ).
	self assert: (error at: #layout) equals: 'WeakLayout'.
	self assert: (error at: #package) equals: self generatedPackageName.
	self assert: (error at: #superclass) equals: 'Object'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateSetsClassComment [

	| arguments createdClass result |
	arguments := self
		             createRequestArgumentsForClassName: 'MCPToolClassMutationTestCommented'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	arguments at: #comment put: 'Created with a comment.'.
	result := self callToolNamed: 'class_create' withArguments: arguments.
	self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestCommented'.
	self assert: createdClass comment equals: 'Created with a comment.'
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateThatFailsLeavesNoPackageItMade [
	"The package is made for the class to land in, so a class that does not build takes it away again. A package that was there stays."

	| arguments |
	arguments := {
		             (#name -> 'MCPToolClassMutationTestGenerated').
		             (#package -> self generatedPackageName).
		             (#traits -> #( 'DefinitelyMissingTrait' )) } asDictionary.
	self assert: ((self callToolNamed: 'class_create' withArguments: arguments) at: #isError).
	self deny: (self class environment includesKey: #MCPToolClassMutationTestGenerated).
	self deny: (self packageOrganizer hasPackage: self generatedPackageName).
	self withoutEpiceaDuring: [ self packageOrganizer ensurePackage: self generatedPackageName ].
	self assert: ((self callToolNamed: 'class_create' withArguments: arguments) at: #isError).
	self assert: (self packageOrganizer hasPackage: self generatedPackageName)
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateWithoutASuperclassSaysItSubclassesObject [
	"A class made with no superclass given subclasses Object, which a caller that meant another, as for a test class, would not see in Created class Foo. The answer says so. A class given its superclass is answered as before."

	self
		assert: (self textFrom: (self callToolNamed: 'class_create' withArguments: {
						  (#name -> 'MCPToolClassMutationTestDefaultSuperclass').
						  (#package -> self generatedPackageName) } asDictionary))
		equals: 'Created class MCPToolClassMutationTestDefaultSuperclass, a subclass of Object.'.
	self
		assert: (self textFrom: (self callToolNamed: 'class_create' withArguments: (self
						   createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
						   superclassName: 'Object'
						   packageName: self generatedPackageName)))
		equals: 'Created class MCPToolClassMutationTestGenerated.'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testForceRemovesASlotInUseAndNamesItsUsers [
	"From Pharo 12 on, force removes a slot its methods use, and the answer's warnings name each of them, as the refusal without force does."

	| result |
	self createSlotUserFixture.
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestWarningRemoveSlotTarget').
			          (#slots -> (Dictionary with: 'remove' -> #( 'usedSlot' ))).
			          (#force -> true) } asDictionary.
	self refactoringsRefuseBreakingChanges ifTrue: [ ^ self assert: (result at: #isError) ].
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self assert: (self warningsFrom: result) asArray equals: self usedSlotUses.
	self assert: ((self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget') slots collect: #name as: Array) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testRefactoringWarningListsEveryImpact [
	"The text names every impact, each as a clause, and how to get past them, since a client reading text sees nothing of the error's details."

	| error impacts result text |
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
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestWarningPullUpTarget'
			           slotName: 'sharedSlot'
			           classSide: false).
	error := self errorFrom: result.
	impacts := error at: #impactMessages.
	text := (result at: #content) first at: #text.
	self denyEmpty: impacts.
	self assert:
		(text beginsWith: 'Refactoring warning for pullUpSlot on MCPToolClassMutationTestWarningPullUpTarget slot sharedSlot: ').
	self assert: (text lines first endsWith: ' Rerun with force: true to proceed anyway.').
	impacts do: [ :each |
			self assert: (text includesSubstring: ((each endsWith: '.')
						  ifTrue: [ each allButLast ]
						  ifFalse: [ each ])) ].
	self
		assert: (MCPToolUpdateClass new
				 refactoringWarningSummaryForAction: 'removeSlot'
				 requestedContext: {
						 (#class -> 'ZooAnimal').
						 (#slot -> 'weight') } asDictionary
				 impactMessages: #( 'ZooAnimal>>dailyRation reads weight.' 'ZooAnimal>>weigh: writes weight' ))
		equals:
		'Refactoring warning for removeSlot on ZooAnimal slot weight: ZooAnimal>>dailyRation reads weight; ZooAnimal>>weigh: writes weight. Rerun with force: true to proceed anyway.'.
	self
		assert: (MCPToolUpdateClass new
				 refactoringWarningSummaryForAction: 'removeSlot'
				 requestedContext: { (#class -> 'ZooAnimal') } asDictionary
				 impactMessages: #(  ))
		equals: 'Refactoring warning for removeSlot on ZooAnimal. Rerun with force: true to proceed anyway.'.
	self
		assert: (MCPToolUpdateClass new
				 refactoringWarningSummaryForAction: 'pullUpSlot'
				 requestedContext: { (#class -> 'ZooAnimal') } asDictionary
				 impactMessages: #( 'Not all subclasses have it. Pull it up anyway?' ))
		equals:
		'Refactoring warning for pullUpSlot on ZooAnimal: Not all subclasses have it. Pull it up anyway? Rerun with force: true to proceed anyway.'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testRemovingAClassSideSlotInUseNamesTheClassSideMethods [
	"A class-side slot is used by class-side methods, which the answer names on that side; the instance side's methods using a slot of the same class are not its users."

	| expected result |
	self createSlotUserFixture.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
			           slotName: 'usedClassSlot'
			           classSide: true).
	expected := 'MCPToolClassMutationTestWarningRemoveSlotTarget class>>readsUsedClassSlot reads usedClassSlot'.
	self assert: (result at: #isError).
	self assert: ((self errorFrom: result) at: #impactMessages) asArray equals: { expected }.
	self
		assert: ((self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget') classSide slots collect: #name as: Array)
		equals: #( #usedClassSlot )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testRemovingASlotInUseNamesTheMethodsThatUseIt [
	"A slot its methods still use is not removed without force, and the answer names each of them with what it does to the slot, those of the subclasses that inherit it included. Before Pharo 12 the removal fails, force or not, and says the same."

	| error result |
	self createSlotUserFixture.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
			           slotName: 'usedSlot'
			           classSide: false).
	self assert: (result at: #isError).
	self refactoringsRefuseBreakingChanges
		ifTrue: [
				self
					assert: (self summaryFrom: result)
					equals:
						('Failed to remove slot usedSlot from class MCPToolClassMutationTestWarningRemoveSlotTarget: {1}. Change them first.'
							 format: { ('; ' join: self usedSlotUses) }) ]
		ifFalse: [
				error := self errorFrom: result.
				self assert: (error at: #impactMessages) asArray equals: self usedSlotUses.
				self
					assert: (self summaryFrom: result)
					equals:
						('Refactoring warning for removeSlot on MCPToolClassMutationTestWarningRemoveSlotTarget slot usedSlot: {1}. Rerun with force: true to proceed anyway.'
							 format: { ('; ' join: self usedSlotUses) }) ].
	self
		assert: ((self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget') slots collect: #name as: Array)
		equals: #( #usedSlot )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testRetagSummaryNamesTheTag [
	"A class moved to a tag is named with the tag and the package it lies in; one moved to a package's root, with the package alone."

	self
		assert: (self summaryFrom: (self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForRecategorization))
		equals: ('Moved class {1} to tag {2} of package {3}.' format: {
					 self moveTargetClassName.
					 self destinationTagName.
					 self originalMovePackageName }).
	self
		assert: (self summaryFrom: (self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForMoveToPackage))
		equals: ('Moved class {1} to package {2}.' format: {
					 self moveTargetClassName.
					 self destinationPackageName })
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testSeveralUpdatesSayEachChange [
	"Each update says what it did, on a line of its own in the order applied, as it would alone; the text does not list the updates again as data."

	| lines result targetName |
	targetName := 'MCPToolClassMutationTestFusedTarget'.
	self
		createClassNamed: targetName
		superclassName: 'Object'
		slots: #( 'kept' )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> targetName).
			          (#superclass -> 'ProtoObject').
			          (#slots -> (Dictionary with: 'add' -> #( 'added' ))).
			          (#comment -> 'fused comment') } asDictionary.
	self deny: (self resultIndicatesError: result).
	lines := ((result at: #content) first at: #text) lines.
	self assert: lines asArray equals: {
			('Applied 3 updates to class {1}:' format: { targetName }).
			('Reparented class {1} to superclass ProtoObject.' format: { targetName }).
			('Added slot added to class {1}.' format: { targetName }).
			('Set comment for class {1}.' format: { targetName }) }.
	self assert: ((self dataFrom: result) at: #updates) size equals: 3
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateAddingASlotResumesAndReportsAWarningRaisedWhileMigratingInstances [
	"Pharo migrates the instances partway through the change. A warning raised there is resumed as at the boundary of the call, the change goes on, and the answer says what it warned of."

	self
		withInstanceOf: 'MCPToolClassMutationTestGenerated'
		under: 'Object'
		readingItsSlotBy: 'read: anObject Warning signal: ''Read while migrating.''. ^ super read: anObject'
		do: [ :instance |
				| result |
				result := self callToolNamed: 'class_update' withArguments: (self
						           updateRequestArgumentsForSlotAction: 'add'
						           className: 'MCPToolClassMutationTestGenerated'
						           slotName: 'extra'
						           classSide: false).
				self deny: (self resultIndicatesError: result) description: [ self textFrom: result ].
				self assert: (self warningsFrom: result) asArray equals: #( 'Read while migrating.' ).
				self assert: instance class slotNames equals: #( #migrated #extra ) ]
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateAddingASlotThatPharoAbandonsLeavesTheClassAsItWas [
	"The new class Pharo abandons is not left among the subclasses of the class's superclass, which lists the class again. The failure still says what a warning raised before it warned of."

	self
		withInstanceOf: 'MCPToolClassMutationTestGenerated'
		under: 'Object'
		readingItsSlotBy: 'read: anObject Warning signal: ''Read while migrating.''. ^ self error: ''This slot cannot be read.'''
		do: [ :instance |
				| result |
				result := self callToolNamed: 'class_update' withArguments: (self
						           updateRequestArgumentsForSlotAction: 'add'
						           className: 'MCPToolClassMutationTestGenerated'
						           slotName: 'extra'
						           classSide: false).
				self assert: (self resultIndicatesError: result) description: [ self textFrom: result ].
				self assert: (self warningsFrom: result) asArray equals: #( 'Read while migrating.' ).
				self assert: instance class slotNames equals: #( #migrated ).
				self assert: (Object subclasses select: [ :each | each name = instance class name ]) equals: { instance class } ]
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateAddsClassSideSlot [

	| result target |
	self
		createClassNamed: 'MCPToolClassMutationTestAddClassSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolClassMutationTestAddClassSlotTarget'
			           slotName: 'addedClassSlot'
			           classSide: true).
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestAddClassSlotTarget'.
	self assert: (target classSide slots collect: #name as: Array) equals: #( #addedClassSlot )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateAddsInstanceSlot [

	| result target |
	self
		createClassNamed: 'MCPToolClassMutationTestAddSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolClassMutationTestAddSlotTarget'
			           slotName: 'addedSlot'
			           classSide: false).
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestAddSlotTarget'.
	self assert: (target slots collect: #name as: Array) equals: #( #addedSlot )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateAppliesSeveralChangesInOneCall [

	| data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestFusedTarget'
		superclassName: 'Object'
		slots: #( 'kept' )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestFusedTarget').
			          (#superclass -> 'ProtoObject').
			          (#slots -> (Dictionary with: 'add' -> #( 'added' ))).
			          (#comment -> 'fused comment') } asDictionary.
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestFusedTarget'.
	self assert: target superclass name equals: #ProtoObject.
	self assert: target instVarNames asArray equals: #( 'kept' 'added' ).
	self assert: target mcpComment equals: 'fused comment'.
	self assert: ((data at: #updates) collect: [ :each | each at: #action ] as: Array) equals: #( 'reparent' 'addSlot' 'setComment' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateCanClearClassComment [

	| result target |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self withoutEpiceaDuring: [ (self classNamed: self commentTargetClassName) comment: 'original comment' ].
	result := self callToolNamed: 'class_update' withArguments: (self updateRequestArgumentsForClassComment: '').
	self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self assert: target mcpComment equals: ''
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateContextReadsTheArguments [

	| context request tool |
	tool := MCPToolUpdateClass new.
	request := tool requestFromToolCallArguments: {
			           (#name -> 'Object').
			           (#comment -> 'updated') } asDictionary.
	context := tool requestedContextFor: request checked: true.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #comment) equals: 'updated'.
	self assert: (tool classCommentIn: request) equals: 'updated'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateContextReportsOnlyTheSuppliedProperties [

	| context request tool |
	tool := MCPToolUpdateClass new.
	request := tool requestFromToolCallArguments: {
			           (#name -> 'ExistingClass').
			           (#tag -> 'Models').
			           (#comment -> '').
			           (#force -> true).
			           (#slots -> (Dictionary with: 'add' -> #( 'count' ))) } asDictionary.
	self assert: (tool classCommentIn: request) equals: ''.
	self assert: (tool suppliedPropertiesIn: request) asArray equals: #( 'tag' 'comment' 'slots' ).
	self assert: (tool slotDeltaIn: request side: false) added asArray equals: #( 'count' ).
	context := tool requestedContextFor: request checked: true.
	self assert: (context at: #name) equals: 'ExistingClass'.
	self assert: (context at: #tag) equals: 'Models'.
	self assert: (context at: #comment) equals: ''.
	self assert: (context at: #slots) equals: (Dictionary with: #add -> #( 'count' )).
	self deny: (context includesKey: #classSlots)
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateForcePullUpSlotContinuesPastRefactoringWarningAndReturnsWarnings [

	| childOne childTwo instance result target warnings |
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
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestWarningPullUpTarget').
			          (#slots -> (Dictionary with: 'pullUp' -> #( 'sharedSlot' ))).
			          (#force -> true) } asDictionary.
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
	self assert: instance slotProbe equals: 17
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateForceRemoveSlotContinuesPastRefactoringWarningAndReturnsWarnings [

	| result target warnings |
	self
		createClassNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( referencedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ referencedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget').
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestWarningRemoveSlotTarget').
			          (#slots -> (Dictionary with: 'remove' -> #( 'referencedSlot' ))).
			          (#force -> true) } asDictionary.
	self refactoringsRefuseBreakingChanges ifTrue: [ ^ self assert: (result at: #isError) ].
	warnings := self warningsFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assertIncludesReferencedSlotWarning: warnings.
	self assert: (target slots collect: #name as: Array) equals: #(  )
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdateMapsClassPatchFieldsToUpdateActions [

	self assert: (self updatePlansFor: { (#newName -> 'ObjectRenamed') }) first updateAction equals: 'rename'.
	self assert: (self updatePlansFor: { (#superclass -> 'ProtoObject') }) first updateAction equals: 'reparent'.
	self assert: (self updatePlansFor: { (#package -> 'MCP') }) first updateAction equals: 'move'.
	self assert: (self updatePlansFor: { (#tag -> 'Commands') }) first updateAction equals: 'move'.
	self assert: (self updatePlansFor: { (#comment -> '') }) first updateAction equals: 'setComment'.
	self
		assert: (self updatePlansFor: { (#slots -> (Dictionary with: 'replace' -> #( 'slot' ))) }) first updateAction
		equals: 'replaceDefinition'.
	self
		assert: (self updatePlansFor: { (#classSlots -> (Dictionary with: 'replace' -> #( 'Current' ))) }) first updateAction
		equals: 'replaceDefinition'.
	self assert: (self updatePlansFor: { (#traits -> #( 'TAbleToRotate' )) }) first updateAction equals: 'replaceTraits'.
	self assert: (self updatePlansFor: { (#sharedVariables -> #( 'Current' )) }) first updateAction equals: 'replaceSharedVariables'.
	self
		assert: (self updatePlansFor: { (#sharedPools -> #( 'ChronologyConstants' )) }) first updateAction
		equals: 'replaceSharedPools'.
	self assert: (self updatePlansFor: { (#layout -> 'WeakLayout') }) first updateAction equals: 'replaceLayout'
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdateMapsSlotActionsToUpdateActions [

	self
		assert: (self updatePlansFor: { (#slots -> (Dictionary with: 'add' -> #( 'addedSlot' ))) }) first updateAction
		equals: 'addSlot'.
	self
		assert: (self updatePlansFor: { (#slots -> (Dictionary with: 'remove' -> #( 'removedSlot' ))) }) first updateAction
		equals: 'removeSlot'.
	self
		assert:
		(self updatePlansFor: { (#slots -> (Dictionary with: 'rename' -> (Dictionary with: 'oldSlot' -> 'newSlot'))) }) first
			updateAction
		equals: 'renameSlot'.
	self
		assert: (self updatePlansFor: { (#slots -> (Dictionary with: 'pullUp' -> #( 'sharedSlot' ))) }) first updateAction
		equals: 'pullUpSlot'.
	self
		assert: (self updatePlansFor: { (#classSlots -> (Dictionary with: 'pushDown' -> #( 'sharedSlot' ))) }) first updateAction
		equals: 'pushDownSlot'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMoveEnsuresMissingDestinationPackage [

	| result |
	self removeDestinationPackage.
	result := self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForMoveToPackage.
	self dataFrom: result.
	self assert: (self packageOrganizer hasPackage: self destinationPackageName).
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMoveEnsuresMissingDestinationTag [

	| package result |
	self removeDestinationPackage.
	self withoutEpiceaDuring: [ self packageOrganizer ensurePackage: self destinationPackageName ].
	result := self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForMoveToPackageAndTag.
	self dataFrom: result.
	package := self packageOrganizer packageNamed: self destinationPackageName.
	self assert: (package hasTag: self destinationTagName).
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName.
	self assert: self currentTagOfMoveTargetClass equals: self destinationTagName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMovesClassToAnotherPackage [

	| result |
	result := self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForMoveToPackage.
	self dataFrom: result.
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMovesClassToExistingTag [

	| result |
	result := self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForMoveToPackageAndTag.
	self dataFrom: result.
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName.
	self assert: self currentTagOfMoveTargetClass equals: self destinationTagName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateOfAGlobalThatIsNotAClassIsRefused [
	"A tag alone looks the class up for its package. Transcript used to be asked for its package as if it were a class."

	| error result |
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'Transcript').
			          (#tag -> 'X') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'NotAClass'.
	self assert: (error at: #class) equals: 'Transcript'.
	self assert: (error at: #message) equals: 'Transcript is a global variable, not a class.'
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdatePlansADefinitionReplacement [

	| context plan |
	plan := (self updatePlansFor: {
			         (#slots -> (Dictionary with: 'replace' -> #( 'first' 'second' ))).
			         (#classSlots -> (Dictionary with: 'replace' -> #( 'Current' ))) }) first.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceDefinition'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #slots) equals: (Dictionary with: #replace -> #( 'first' 'second' )).
	self assert: (context at: #classSlots) equals: (Dictionary with: #replace -> #( 'Current' ))
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdatePlansALayoutReplacement [

	| context plan |
	plan := (self updatePlansFor: { (#layout -> 'WeakLayout') }) first.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceLayout'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #layout) equals: 'WeakLayout'
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdatePlansAMove [

	| context plan |
	plan := (self updatePlansFor: { (#package -> 'MCP') }) first.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'move'.
	self assert: (context at: #class) equals: 'Object'.
	self assert: (context at: #package) equals: 'MCP'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePlansAMoveIntoTheClassPackageWhenOnlyATagIsGiven [

	| context plan request tool |
	tool := MCPToolUpdateClass new.
	request := tool requestFromToolCallArguments: {
			           (#name -> self class name asString).
			           (#tag -> 'Requests') } asDictionary.
	plan := (tool updatePlansFor: request) first.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'move'.
	self assert: (tool movePackageNameIn: request) equals: self class packageName asString.
	self assert: (context at: #class) equals: self class name asString.
	self assert: (context at: #tag) equals: 'Requests'.
	self assert: (context at: #package) equals: self class packageName asString
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdatePlansASharedPoolReplacement [

	| context plan |
	plan := (self updatePlansFor: { (#sharedPools -> #( 'ChronologyConstants' )) }) first.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceSharedPools'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #sharedPools) equals: #( 'ChronologyConstants' )
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdatePlansASharedVariableReplacement [

	| context plan |
	plan := (self updatePlansFor: { (#sharedVariables -> #( 'Current' )) }) first.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceSharedVariables'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #sharedVariables) equals: #( 'Current' )
]

{ #category : 'tests - planning' }
MCPToolClassMutationTest >> testUpdatePlansATraitReplacement [

	| context plan |
	plan := (self updatePlansFor: { (#traits -> #( 'TAbleToRotate' )) }) first.
	context := plan requestedContext.
	self assert: plan updateAction equals: 'replaceTraits'.
	self assert: (context at: #name) equals: 'Object'.
	self assert: (context at: #traits) equals: #( 'TAbleToRotate' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePreservesSharedVariableValueWhenNameIsKept [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedVariablePreservationTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedVariables put: #( 'AlphaShared' ).
	self callToolNamed: 'class_create' withArguments: createArguments.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariablePreservationTarget'.
	targetClass writeClassVariableNamed: #AlphaShared value: 123.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSharedVariablesInClassNamed: 'MCPToolClassMutationTestSharedVariablePreservationTarget'
			           sharedVariables: #( 'AlphaShared' 'BetaShared' )).
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariablePreservationTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: targetClass classVarNames equals: #( #AlphaShared #BetaShared ).
	self assert: (targetClass readClassVariableNamed: #AlphaShared) equals: 123.
	self assert: (targetClass readClassVariableNamed: #BetaShared) isNil
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullUpSlotNamedOnItsHolderSaysWhichClassToName [
	"pullUp names the class the slot moves into. Naming the class that holds the slot is the likely misreading, and the answer names the class to use instead."

	| error result |
	self
		createClassNamed: 'MCPToolClassMutationTestPullUpParent'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestPullUpChild'
		superclassName: 'MCPToolClassMutationTestPullUpParent'
		slots: #( weight )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestPullUpChild'
			           slotName: 'weight'
			           classSide: false).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'PullUpSlotRefactoringError'.
	self assert: ((error at: #message) includesSubstring:
			 'name MCPToolClassMutationTestPullUpParent to move weight up from MCPToolClassMutationTestPullUpChild').
	self assert: (self classNamed: 'MCPToolClassMutationTestPullUpChild') slotNames equals: #( weight )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullUpSlotRefusesASlotATraitSupplies [
	"A slot a trait supplies is the trait's, not the class's, so no superclass would help and the answer names the trait instead."

	| error result |
	self withoutEpiceaDuring: [
			| trait |
			self packageOrganizer ensurePackage: self generatedPackageName.
			trait := (Trait << #MCPToolClassMutationTestPullUpWeighted)
				         slots: #( weight );
				         package: self generatedPackageName;
				         tag: self generatedTagName;
				         install.
			(Object << #MCPToolClassMutationTestPullUpTraitUser)
				traits: trait;
				package: self generatedPackageName;
				tag: self generatedTagName;
				install ].
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestPullUpTraitUser'
			           slotName: 'weight'
			           classSide: false).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'PullUpSlotRefactoringError'.
	self assert: ((error at: #message) includesSubstring: 'which the trait MCPToolClassMutationTestPullUpWeighted supplies').
	self deny: ((error at: #message) includesSubstring: ': name ')
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullUpSlotReturnsStructuredCommandErrorForRefactoringFailure [

	| error result |
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolMethodMutationTestTarget'
			           slotName: 'missingSlot'
			           classSide: false).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'PullUpSlotRefactoringError'.
	self assert: (error at: #causeClass) equals: self expectedRefactoringFailureCauseClassName.
	self assert: (error at: #class) equals: 'MCPToolMethodMutationTestTarget'.
	self assert: (error at: #slot) equals: 'missingSlot'.
	self assert: (error at: #side) equals: 'instance'.
	self assert: ((error at: #message) includesSubstring: 'missingSlot')
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullUpSlotStopsOnRefactoringWarningByDefault [

	| childOne childTwo error result target |
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
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestWarningPullUpTarget'
			           slotName: 'sharedSlot'
			           classSide: false).
	error := self errorFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestWarningPullUpTarget'.
	childOne := self classNamed: 'MCPToolClassMutationTestWarningPullUpChildOne'.
	childTwo := self classNamed: 'MCPToolClassMutationTestWarningPullUpChildTwo'.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'PullUpSlotRefactoringWarning'.
	self assert: (error at: #causeClass) equals: 'RBRefactoringWarning'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestWarningPullUpTarget'.
	self assert: (error at: #slot) equals: 'sharedSlot'.
	self assert: (error at: #side) equals: 'instance'.
	self assert: (error at: #forceSupported) equals: true.
	self assert: ((error at: #howToProceed) includesSubstring: 'force: true').
	self assert:
		((error at: #impactMessages) anySatisfy: [ :each | each includesSubstring: 'Not all subclasses have an instance variable named' ]).
	self assert: (target slots collect: #name as: Array) equals: #(  ).
	self assert: (childOne slots collect: #name as: Array) equals: #( #sharedSlot ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullUpStoppedPartwaySaysWhichValuesAreLost [
	"A subclass that gets the slot from a trait would have it twice once the class has it, which Pharo finds only after taking the slot out of the other subclasses."

	| instance result target traitUserInstance |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestPullUpTarget'
		          superclassName: 'Object'
		          slots: #(  )
		          classSlots: #(  ).
	instance := (self
		             createClassNamed: 'MCPToolClassMutationTestPullUpChildOne'
		             superclassName: target name
		             slots: #( sharedSlot )
		             classSlots: #(  )) new.
	instance instVarNamed: 'sharedSlot' put: 41.
	traitUserInstance := (self withoutEpiceaDuring: [
			                      (target << #MCPToolClassMutationTestPullUpTraitUser)
				                      traits: ((Trait << #MCPToolClassMutationTestPullUpWeighted)
						                       slots: #( sharedSlot );
						                       package: self generatedPackageName;
						                       install);
				                      package: self generatedPackageName;
				                      install ]) new.
	traitUserInstance instVarNamed: 'sharedSlot' put: 43.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: target name
			           slotName: 'sharedSlot'
			           classSide: false).
	self assert: (self resultIndicatesError: result).
	self
		assert:
		((self textFrom: result) endsWith:
			 '. The values sharedSlot held in instances of MCPToolClassMutationTestPullUpChildOne are lost.')
		description: [ self textFrom: result ].
	self assert: (traitUserInstance instVarNamed: 'sharedSlot') equals: 43
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePullsUpSlotsAcrossSubclasses [
	"Each instance of a subclass keeps what the slot held, and each subclass what its class-side slot held, along with what the slots after them hold."

	| childOne childTwo grandchild grandchildInstance instance result target |
	self
		createClassNamed: 'MCPToolClassMutationTestPullUpTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	childOne := self
		            createClassNamed: 'MCPToolClassMutationTestPullUpChildOne'
		            superclassName: 'MCPToolClassMutationTestPullUpTarget'
		            slots: #( sharedSlot keptSlot )
		            classSlots: #( sharedClassSlot keptClassSlot ).
	self
		createClassNamed: 'MCPToolClassMutationTestPullUpChildTwo'
		superclassName: 'MCPToolClassMutationTestPullUpTarget'
		slots: #( sharedSlot )
		classSlots: #( sharedClassSlot ).
	grandchild := self
		              createClassNamed: 'MCPToolClassMutationTestPullUpGrandchild'
		              superclassName: 'MCPToolClassMutationTestPullUpChildOne'
		              slots: #(  )
		              classSlots: #(  ).
	self ensureMethodSource: 'slotProbe ^ sharedSlot' protocol: 'testing' on: childOne.
	instance := childOne new.
	instance instVarNamed: 'sharedSlot' put: 41.
	instance instVarNamed: 'keptSlot' put: 7.
	childOne instVarNamed: 'sharedClassSlot' put: 23.
	childOne instVarNamed: 'keptClassSlot' put: 8.
	grandchildInstance := grandchild new.
	grandchildInstance instVarNamed: 'sharedSlot' put: 42.
	grandchild instVarNamed: 'sharedClassSlot' put: 24.
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestPullUpTarget').
			          (#slots -> (Dictionary with: 'pullUp' -> #( 'sharedSlot' ))).
			          (#classSlots -> (Dictionary with: 'pullUp' -> #( 'sharedClassSlot' ))) } asDictionary.
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestPullUpTarget'.
	childOne := self classNamed: 'MCPToolClassMutationTestPullUpChildOne'.
	childTwo := self classNamed: 'MCPToolClassMutationTestPullUpChildTwo'.
	grandchild := self classNamed: 'MCPToolClassMutationTestPullUpGrandchild'.
	self assert: (target slots collect: #name as: Array) equals: #( #sharedSlot ).
	self assert: (target classSide slots collect: #name as: Array) equals: #( #sharedClassSlot ).
	self assert: (childOne slots collect: #name as: Array) equals: #( #keptSlot ).
	self assert: (childTwo slots collect: #name as: Array) equals: #(  ).
	self assert: instance slotProbe equals: 41.
	self assert: (instance instVarNamed: 'keptSlot') equals: 7.
	self assert: grandchildInstance slotProbe equals: 42.
	self assert: (childOne instVarNamed: 'sharedClassSlot') equals: 23.
	self assert: (childOne instVarNamed: 'keptClassSlot') equals: 8.
	self assert: (grandchild instVarNamed: 'sharedClassSlot') equals: 24
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePushesDownSlotsToDirectSubclasses [
	"Each instance of a subclass keeps what the slot held, and each subclass what its class-side slot held, along with what the slots after them hold."

	| childOne childTwo instance result target |
	self
		createClassNamed: 'MCPToolClassMutationTestPushDownTarget'
		superclassName: 'Object'
		slots: #( sharedSlot keptSlot )
		classSlots: #( sharedClassSlot keptClassSlot ).
	childOne := self
		            createClassNamed: 'MCPToolClassMutationTestPushDownChildOne'
		            superclassName: 'MCPToolClassMutationTestPushDownTarget'
		            slots: #(  )
		            classSlots: #(  ).
	self
		createClassNamed: 'MCPToolClassMutationTestPushDownChildTwo'
		superclassName: 'MCPToolClassMutationTestPushDownTarget'
		slots: #(  )
		classSlots: #(  ).
	self ensureMethodSource: 'slotProbe ^ sharedClassSlot' protocol: 'testing' on: childOne classSide.
	instance := childOne new.
	instance instVarNamed: 'sharedSlot' put: 41.
	instance instVarNamed: 'keptSlot' put: 7.
	childOne instVarNamed: 'sharedClassSlot' put: 23.
	childOne instVarNamed: 'keptClassSlot' put: 8.
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestPushDownTarget').
			          (#slots -> (Dictionary with: 'pushDown' -> #( 'sharedSlot' ))).
			          (#classSlots -> (Dictionary with: 'pushDown' -> #( 'sharedClassSlot' ))) } asDictionary.
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestPushDownTarget'.
	childOne := self classNamed: 'MCPToolClassMutationTestPushDownChildOne'.
	childTwo := self classNamed: 'MCPToolClassMutationTestPushDownChildTwo'.
	self assert: (target classSide slots collect: #name as: Array) equals: #( #keptClassSlot ).
	self assert: (childOne classSide slots collect: #name as: Array) equals: #( #sharedClassSlot ).
	self assert: (childTwo classSide slots collect: #name as: Array) equals: #( #sharedClassSlot ).
	self assert: childOne slotProbe equals: 23.
	self assert: (childOne instVarNamed: 'keptClassSlot') equals: 8.
	self assert: (instance instVarNamed: 'sharedSlot') equals: 41.
	self assert: (instance instVarNamed: 'keptSlot') equals: 7
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdatePushingDownASlotThatPharoAbandonsInASubclassKeepsTheSubclassListed [
	"Pharo reshapes the subclasses that get the slot too, and lists the new subclass it abandons in place of the subclass. It has already changed the class by then. The instance of the subclass it abandons keeps its fields as they were, read here as stored since Pharo may have numbered anew the slots the old subclass reads them through."

	| target |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestPushDownTarget'
		          superclassName: 'Object'
		          slots: #( movedSlot keptSlot )
		          classSlots: #(  ).
	self withUnmigratableInstanceOf: 'MCPToolClassMutationTestPushDownChildOne' under: target name do: [ :instance |
			| result |
			instance instVarNamed: 'movedSlot' put: 41.
			instance instVarNamed: 'keptSlot' put: 7.
			result := self callToolNamed: 'class_update' withArguments: (self
					           updateRequestArgumentsForSlotAction: 'pushDown'
					           className: target name
					           slotName: 'movedSlot'
					           classSide: false).
			self assert: (self resultIndicatesError: result) description: [ self textFrom: result ].
			self
				assert: ((self textFrom: result) endsWith:
						 ': Pharo changed MCPToolClassMutationTestPushDownTarget but abandoned installing the new MCPToolClassMutationTestPushDownChildOne after Error: This slot cannot be read.')
				description: [ self textFrom: result ].
			self assert: instance class superclass equals: (self classNamed: target name).
			self
				assert: (instance class superclass subclasses select: [ :each | each name = instance class name ])
				equals: { instance class }.
			self assert: ((1 to: 2) collect: [ :index | instance instVarAt: index ]) equals: #( 41 7 ) ]
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReadsASlotPatch [

	| delta plan request tool |
	tool := MCPToolUpdateClass new.
	request := tool requestFromToolCallArguments: {
			           (#name -> 'ExistingClass').
			           (#classSlots -> (Dictionary with: 'rename' -> (Dictionary with: 'oldName' -> 'newName'))).
			           (#force -> true) } asDictionary.
	self assert: ((tool requestedContextFor: request checked: true) at: #name) equals: 'ExistingClass'.
	self assert: (tool slotDeltaIn: request side: false) isNil.
	delta := tool slotDeltaIn: request side: true.
	self deny: delta isEmpty.
	self assert: (delta renamed at: 'oldName') equals: 'newName'.
	self assert: delta added isEmpty.
	self deny: delta hasReplacement.
	self
		assert: ((tool requestedContextFor: request checked: true) at: #classSlots)
		equals: (Dictionary with: #rename -> delta renamed).
	plan := (tool updatePlansFor: request) first.
	self assert: plan updateAction equals: 'renameSlot'.
	self assert: plan slotName equals: 'oldName'.
	self assert: plan newSlotName equals: 'newName'.
	self assert: plan classSide
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRecategorizesWithinCurrentPackageWhenPackageNameIsOmitted [

	| package result |
	result := self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForRecategorization.
	self dataFrom: result.
	package := self packageOrganizer packageNamed: self originalMovePackageName.
	self assert: (package hasTag: self destinationTagName).
	self assert: self moveTargetClass packageName asString equals: self originalMovePackageName.
	self assert: self currentTagOfMoveTargetClass equals: self destinationTagName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRefusesAClassSideName [
	"class_update changes the whole class, so Foo class read as Foo would patch the instance side. It is refused while parsing, before anything changes."

	| error result target |
	self
		createClassNamed: 'MCPToolClassMutationTestAddSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestAddSlotTarget class').
			          (#slots -> { (#add -> #( 'made' )) } asDictionary) } asDictionary.
	error := self errorFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestAddSlotTarget'.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassSideNamed'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestAddSlotTarget'.
	self assert: (error at: #name) equals: 'MCPToolClassMutationTestAddSlotTarget class'.
	self
		assert: (error at: #message)
		equals:
		'MCPToolClassMutationTestAddSlotTarget class is the class side of MCPToolClassMutationTestAddSlotTarget. class_update changes the whole class: name MCPToolClassMutationTestAddSlotTarget, and use classSlots for class-side slots.'.
	self assert: target slots isEmpty.
	self assert: target classSide slots isEmpty
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRefusesASlotListWithThePatchItTakes [
	"class_create takes its slots as a list, and a caller that comes from it sends class_update one too. The refusal names the keys of the patch, with the list under the one that adds the slots."

	self
		assertResult: (self callDiscoveredToolNamed: 'class_update' withArguments: {
					 (#name -> self originalClassName).
					 (#slots -> #( 'color' )) } asDictionary)
		refusesArgumentsSaying:
		'slots must be object, not array. Give it as an object with the keys add, pullUp, pushDown, remove, rename or replace, for example {"add":["color"]}.'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRefusesASlotTheClassInherits [
	"A slot is removed or renamed in the class that defines it. Named on a subclass, the refusal says so, as a refactoring error, which every supported Pharo has."

	| error |
	self createSlotUserFixture.
	{
		((self
			  updateRequestArgumentsForSlotAction: 'remove'
			  className: 'MCPToolClassMutationTestSlotUserSubclass'
			  slotName: 'usedClassSlot'
			  classSide: true)
		 -> 'The variable usedClassSlot is not directly defined in the class MCPToolClassMutationTestSlotUserSubclass').
		((self
			  updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestSlotUserSubclass'
			  slotName: 'usedSlot'
			  newSlotName: 'renamedSlot'
			  classSide: false) -> 'The variable usedSlot is not directly defined in the class MCPToolClassMutationTestSlotUserSubclass') }
		do: [ :each |
				error := self errorFrom: (self callToolNamed: 'class_update' withArguments: each key).
				self assert: (error at: #causeClass) equals: 'RBRefactoringError'.
				self assert: ((error at: #message) endsWith: each value) ]
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemoveSlotStopsOnRefactoringWarningByDefault [

	| error result target |
	self
		createClassNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
		superclassName: 'Object'
		slots: #( referencedSlot )
		classSlots: #(  ).
	self
		ensureMethodSource: 'slotProbe ^ referencedSlot'
		protocol: 'testing'
		on: (self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget').
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestWarningRemoveSlotTarget'
			           slotName: 'referencedSlot'
			           classSide: false).
	error := self errorFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestWarningRemoveSlotTarget'.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'removeSlot'.
	self refactoringsRefuseBreakingChanges ifTrue: [
			self assert: (error at: #errorCode) equals: 'RemoveSlotRefactoringError'.
			^ self assert: (target slots collect: #name as: Array) equals: #( #referencedSlot ) ].
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'RemoveSlotRefactoringWarning'.
	self assert: (self expectedRefactoringWarningCauseClassNames includes: (error at: #causeClass)).
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestWarningRemoveSlotTarget'.
	self assert: (error at: #slot) equals: 'referencedSlot'.
	self assert: (error at: #side) equals: 'instance'.
	self assert: (error at: #forceSupported) equals: true.
	self assert: ((error at: #howToProceed) includesSubstring: 'force: true').
	self assertIncludesReferencedSlotWarning: (error at: #impactMessages).
	self assert: (target slots collect: #name as: Array) equals: #( #referencedSlot )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesClassSideSlot [
	"The class keeps what the class-side slot after the removed one holds."

	| result target |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestRemoveClassSlotTarget'
		          superclassName: 'Object'
		          slots: #(  )
		          classSlots: #( removableClassSlot keptClassSlot ).
	target instVarNamed: 'removableClassSlot' put: 41.
	target instVarNamed: 'keptClassSlot' put: 7.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestRemoveClassSlotTarget'
			           slotName: 'removableClassSlot'
			           classSide: true).
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRemoveClassSlotTarget'.
	self assert: (target classSide slots collect: #name as: Array) equals: #( #keptClassSlot ).
	self assert: (target instVarNamed: 'keptClassSlot') equals: 7
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesInstanceSlot [
	"An instance keeps what the slots after the removed one hold, a virtual one included, and stays read-only."

	| instance result target |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestRemoveSlotTarget'
		          superclassName: 'Object'
		          slots: {
				          #removableSlot.
				          #keptSlot.
				          (#flagSlot => BooleanSlot) }
		          classSlots: #(  ).
	instance := target new.
	instance instVarNamed: 'removableSlot' put: 41.
	instance instVarNamed: 'keptSlot' put: 8.
	instance instVarNamed: 'flagSlot' put: true.
	instance beReadOnlyObject.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestRemoveSlotTarget'
			           slotName: 'removableSlot'
			           classSide: false).
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRemoveSlotTarget'.
	self assert: (target slots collect: #name as: Array) equals: #( #keptSlot #flagSlot ).
	self assert: (instance instVarNamed: 'keptSlot') equals: 8.
	self assert: (instance instVarNamed: 'flagSlot').
	self assert: instance isReadOnlyObject
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesSharedPoolsWithEmptyArray [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedPoolRemovalTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedPools put: #( 'ChronologyConstants' ).
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self
			           updateRequestArgumentsForSharedPoolsInClassNamed: 'MCPToolClassMutationTestSharedPoolRemovalTarget'
			           sharedPools: #(  )).
	self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedPoolRemovalTarget'.
	self assert: targetClass sharedPools isEmpty
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesSharedVariablesWithEmptyArray [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedVariableRemovalTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedVariables put: #( 'AlphaShared' ).
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSharedVariablesInClassNamed: 'MCPToolClassMutationTestSharedVariableRemovalTarget'
			           sharedVariables: #(  )).
	self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariableRemovalTarget'.
	self assert: targetClass classVarNames isEmpty
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRemovesTraitsWithEmptyArray [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestTraitRemovalTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #traits put: #( 'TAbleToRotate' ).
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestTraitRemovalTarget' traits: #(  )).
	self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestTraitRemovalTarget'.
	self assert: targetClass traits isEmpty
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenameSlotReformatsWithTheFormatterOfTheClassPackage [

	| method result target |
	self createGeneratedPackageManifestWithNarrowFormatter.
	self
		createClassNamed: 'MCPToolClassMutationTestRenameSlotFormatterTarget'
		superclassName: 'Object'
		slots: #( oldSlot )
		classSlots: #(  ).
	[
		self
			ensureMethodSource: 'slotProbe ^ 1 between: oldSlot and: 2000000'
			protocol: 'testing'
			on: (self classNamed: 'MCPToolClassMutationTestRenameSlotFormatterTarget').
		result := self callToolNamed: 'class_update' withArguments: (self
				           updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestRenameSlotFormatterTarget'
				           slotName: 'oldSlot'
				           newSlotName: 'renamedSlot'
				           classSide: false).
		target := self classNamed: 'MCPToolClassMutationTestRenameSlotFormatterTarget'.
		method := target >> #slotProbe.
		self deny: (result at: #isError ifAbsent: [ false ]).
		self assert: (method sourceCode includesSubstring: 'renamedSlot').
		self assert: method sourceCode equals: (method ast formattedCodeIn: target).
		self deny: method sourceCode equals: method ast formattedCode ] ensure: [
			self removeClassNamed: 'MCPToolClassMutationTestRenameSlotFormatterTarget'.
			self removeGeneratedPackageManifest ]
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenameSlotThatCannotFinishChangesNothing [
	"Renaming an accessor onto a method the class has, or a sender with a temporary or an argument of the new name, would be refused only after the new slot was added and the senders before it rewritten."

	| refuses target |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestRenameSlotTarget'
		          superclassName: 'Object'
		          slots: #( oldSlot )
		          classSlots: #(  ).
	#( 'oldSlot ^ oldSlot' 'oldSlot: anObject oldSlot := anObject' 'slotProbe ^ self oldSlot' ) do: [ :each |
		self ensureMethodSource: each protocol: 'accessing' on: target ].
	refuses := [ :text |
		           | result sources |
		           sources := target methods collect: [ :each | each selector -> each sourceCode ] as: Dictionary.
		           result := self callToolNamed: 'class_update' withArguments: (self
				                      updateRequestArgumentsForSlotRenameInClassNamed: target name
				                      slotName: 'oldSlot'
				                      newSlotName: 'renamedSlot'
				                      classSide: false).
		           self assert: (self resultIndicatesError: result).
		           self assert: ((self textFrom: result) endsWith: text) description: [ self textFrom: result ].
		           target := self classNamed: target name.
		           self assert: (target slots collect: #name as: Array) equals: #( #oldSlot ).
		           self assert: (target methods collect: [ :each | each selector -> each sourceCode ] as: Dictionary) equals: sources ].
	self ensureMethodSource: 'renamedSlot ^ 42' protocol: 'accessing' on: target.
	refuses value:
		': Cannot rename accessor oldSlot to renamedSlot because MCPToolClassMutationTestRenameSlotTarget already defines renamedSlot.'.
	self removeSelector: #renamedSlot from: target.
	self ensureMethodSource: 'shadows: renamedSlot ^ oldSlot = renamedSlot' protocol: 'accessing' on: target.
	refuses value: ': MCPToolClassMutationTestRenameSlotTarget>>shadows: already has a temporary or an argument named renamedSlot.'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenamesClassSideSlotAndPreservesValue [
	"The class keeps what the class-side slot after the renamed one holds."

	| result target |
	self
		createClassNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #( oldClassSlot keptClassSlot ).
	target := self classNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'.
	self ensureMethodSource: 'oldClassSlot ^ oldClassSlot' protocol: 'accessing' on: target classSide.
	self ensureMethodSource: 'oldClassSlot: anObject oldClassSlot := anObject' protocol: 'accessing' on: target classSide.
	self ensureMethodSource: 'slotProbe ^ self oldClassSlot' protocol: 'testing' on: target classSide.
	target oldClassSlot: 73.
	target instVarNamed: 'keptClassSlot' put: 17.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'
			           slotName: 'oldClassSlot'
			           newSlotName: 'renamedClassSlot'
			           classSide: true).
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRenameClassSideSlotTarget'.
	self assert: (target classSide slots collect: #name as: Array) equals: #( #keptClassSlot #renamedClassSlot ).
	self deny: (target classSide includesSelector: #oldClassSlot).
	self deny: (target classSide includesSelector: #oldClassSlot:).
	self assert: (target classSide includesSelector: #renamedClassSlot).
	self assert: (target classSide includesSelector: #renamedClassSlot:).
	self assert: target renamedClassSlot equals: 73.
	self assert: (target instVarNamed: 'keptClassSlot') equals: 17.
	target renamedClassSlot: 91.
	self assert: target slotProbe equals: 91
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenamesInstanceSlotAndUpdatesReferences [
	"An instance keeps under the new name what the slot held, and what the slot after it holds."

	| instance result target |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestRenameSlotTarget'
		          superclassName: 'Object'
		          slots: #( oldSlot keptSlot )
		          classSlots: #(  ).
	self ensureMethodSource: 'oldSlot ^ oldSlot' protocol: 'accessing' on: target.
	self ensureMethodSource: 'oldSlot: anObject oldSlot := anObject' protocol: 'accessing' on: target.
	self ensureMethodSource: 'slotProbe ^ self oldSlot' protocol: 'testing' on: target.
	instance := target new.
	instance oldSlot: 37.
	instance instVarNamed: 'keptSlot' put: 7.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestRenameSlotTarget'
			           slotName: 'oldSlot'
			           newSlotName: 'renamedSlot'
			           classSide: false).
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestRenameSlotTarget'.
	self assert: (target slots collect: #name as: Array) equals: #( #keptSlot #renamedSlot ).
	self deny: (target includesSelector: #oldSlot).
	self deny: (target includesSelector: #oldSlot:).
	self assert: (target includesSelector: #renamedSlot).
	self assert: (target includesSelector: #renamedSlot:).
	self assert: instance renamedSlot equals: 37.
	self assert: instance slotProbe equals: 37.
	self assert: (instance instVarNamed: 'keptSlot') equals: 7.
	instance renamedSlot: 91.
	self assert: instance slotProbe equals: 91
]

{ #category : 'tests' }
MCPToolClassMutationTest >> testUpdateRenamesTheClassItsSubclassesAndItsReferences [
	"A rename is a refactoring that takes a second, so one rename is read every way, to a name a method already refers to besides. Loaded code can name a class before it exists, which a plain compile refuses."

	| referenceClass reference result |
	referenceClass := self classNamed: self referenceClassName.
	self withoutEpiceaDuring: [
			referenceClass methodInstaller
				logged: false;
				install: (referenceClass compiler
						 permitUndeclared: true;
						 compile: 'namesTheNewName ^ ' , self renamedClassName)
				into: referenceClass compiler: nil ].
	result := [ self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForRename ] ensure: [
		          self removeSelector: #namesTheNewName from: referenceClass ].
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self assert: (self class environment includesKey: self renamedClassName asSymbol).
	self deny: (self class environment includesKey: self originalClassName asSymbol).
	self assert: (self classNamed: self subclassName) superclass name asString equals: self renamedClassName.
	reference := referenceClass new.
	self assert: reference referencedClass name asString equals: self renamedClassName.
	self assert: reference newReferencedInstance class name asString equals: self renamedClassName
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateRenamingASlotThatPharoAbandonsInASubclassSaysTheClassChanged [
	"Pharo installs the class with the new slot before it abandons the subclass, whose instances have no new slot to take the values."

	| target |
	target := self
		          createClassNamed: 'MCPToolClassMutationTestRenameSlotTarget'
		          superclassName: 'Object'
		          slots: #( oldSlot )
		          classSlots: #(  ).
	self withUnmigratableInstanceOf: 'MCPToolClassMutationTestSlotUserSubclass' under: target name do: [ :instance |
			| result |
			result := self callToolNamed: 'class_update' withArguments: (self
					           updateRequestArgumentsForSlotRenameInClassNamed: target name
					           slotName: 'oldSlot'
					           newSlotName: 'renamedSlot'
					           classSide: false).
			self assert: (self resultIndicatesError: result) description: [ self textFrom: result ].
			self
				assert: ((self textFrom: result) endsWith:
						 ': Pharo changed MCPToolClassMutationTestRenameSlotTarget but abandoned installing the new MCPToolClassMutationTestSlotUserSubclass after Error: This slot cannot be read.')
				description: [ self textFrom: result ].
			self
				assert: ((self classNamed: target name) subclasses select: [ :each | each name = instance class name ])
				equals: { instance class } ]
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReparentThatPharoAbandonsSaysWhy [
	"Pharo migrates the instances inside a block that stops any unwinding through it, then goes on without installing the new class. The class stays where it was."

	self withUnmigratableInstanceOf: self reparentTargetClassName under: 'Object' do: [ :instance |
			| result superclass |
			superclass := self
				              createClassNamed: self reparentSuperclassName
				              superclassName: 'Object'
				              slots: #(  )
				              classSlots: #(  ).
			result := self callToolNamed: 'class_update' withArguments: {
					          (#name -> self reparentTargetClassName).
					          (#superclass -> self reparentSuperclassName) } asDictionary.
			self assert: (self resultIndicatesError: result) description: [ self textFrom: result ].
			self
				assert: ((self textFrom: result) endsWith:
						 ': Pharo abandoned installing the new MCPToolClassMutationTestReparentTarget after Error: This slot cannot be read.')
				description: [ self textFrom: result ].
			self assert: instance class equals: (self classNamed: self reparentTargetClassName).
			self assert: instance class superclass equals: Object.
			self assert: (Object subclasses includes: instance class).
			self assert: superclass subclasses isEmpty ]
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReparentsClassAndPreservesExistingState [
	"An instance made before the call keeps what its slots hold, under a superclass that has slots of its own."

	| instance result target |
	self
		createClassNamed: self reparentSuperclassName
		superclassName: 'Object'
		slots: #( betaSlot )
		classSlots: #(  ).
	instance := (self
		             createClassNamed: self reparentTargetClassName
		             superclassName: 'Object'
		             slots: #( alphaSlot )
		             classSlots: #(  )) new.
	instance instVarNamed: 'alphaSlot' put: 7.
	self ensureMethodSource: 'probeMethod ^ 41' protocol: 'testing' on: (self classNamed: self reparentTargetClassName).
	self withoutEpiceaDuring: [ (self classNamed: self reparentTargetClassName) comment: 'reparent comment' ].
	result := self callToolNamed: 'class_update' withArguments: self updateRequestArgumentsForReparent.
	self dataFrom: result.
	target := self classNamed: self reparentTargetClassName.
	self assert: target superclass name asString equals: self reparentSuperclassName.
	self assert: target new probeMethod equals: 41.
	self assert: target mcpComment equals: 'reparent comment'.
	self assert: (target slots collect: #name as: Array) equals: #( #alphaSlot ).
	self assert: instance class equals: target.
	self assert: (instance instVarNamed: 'alphaSlot') equals: 7
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesLayout [

	| result targetClass |
	self
		createClassNamed: 'MCPToolClassMutationTestLayoutTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self updateRequestArgumentsForLayoutInClassNamed: 'MCPToolClassMutationTestLayoutTarget' layout: 'WeakLayout').
	self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestLayoutTarget'.
	self assert: targetClass classLayout class name equals: #WeakLayout
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesSharedPools [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedPoolTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedPools put: #( 'ChronologyConstants' ).
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSharedPoolsInClassNamed: 'MCPToolClassMutationTestSharedPoolTarget'
			           sharedPools: #( 'TextConstants' )).
	self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedPoolTarget'.
	self assert: (targetClass sharedPools collect: [ :each | each name asString ] as: Array) equals: #( 'TextConstants' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesSharedVariables [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestSharedVariableTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #sharedVariables put: #( 'AlphaShared' ).
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSharedVariablesInClassNamed: 'MCPToolClassMutationTestSharedVariableTarget'
			           sharedVariables: #( 'BetaShared' )).
	self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestSharedVariableTarget'.
	self assert: targetClass classVarNames equals: #( #BetaShared )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesSlotDefinitionAndPreservesMatchingValues [

	| instance result target |
	self
		createClassNamed: 'MCPToolClassMutationTestDefinitionTarget'
		superclassName: 'Object'
		slots: #( oldSlot keptSlot )
		classSlots: #( oldClassSlot keptClassSlot ).
	target := self classNamed: 'MCPToolClassMutationTestDefinitionTarget'.
	instance := target new.
	instance instVarNamed: 'keptSlot' put: 13.
	target instVarNamed: 'keptClassSlot' put: 17.
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestDefinitionTarget').
			          (#slots -> (Dictionary with: 'replace' -> #( 'keptSlot' 'newSlot' ))).
			          (#classSlots -> (Dictionary with: 'replace' -> #( 'keptClassSlot' 'newClassSlot' ))) } asDictionary.
	self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestDefinitionTarget'.
	self assert: (target slots collect: #name as: Array) equals: #( #keptSlot #newSlot ).
	self assert: (target classSide slots collect: #name as: Array) equals: #( #keptClassSlot #newClassSlot ).
	self assert: (instance instVarNamed: 'keptSlot') equals: 13.
	self assert: (target instVarNamed: 'keptClassSlot') equals: 17
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacesTraits [

	| createArguments result targetClass |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	createArguments at: #traits put: #( 'TAbleToRotate' ).
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestTraitTarget' traits: #( 'TComparable' )).
	self dataFrom: result.
	targetClass := self classNamed: 'MCPToolClassMutationTestTraitTarget'.
	self assert: (targetClass traits collect: [ :each | each name asString ] as: Array) equals: #( 'TComparable' ).
	self assert: targetClass traitCompositionString equals: 'TComparable'.
	self assert: targetClass classSide traitCompositionString equals: 'TComparable classTrait'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReplacingTraitsSuggestsTraitsAndRefusesAClass [

	| createArguments error result |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestMissingTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self
			           updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget'
			           traits: #( 'TAbleToRotat' )).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'TraitNotFound'.
	self assert: ((error at: #suggestions) includes: 'TAbleToRotate').
	self assert: (error at: #traits) equals: #( 'TAbleToRotat' ).
	self assert: ((error at: #message) beginsWith: 'Trait TAbleToRotat does not exist. Did you mean: ').
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget' traits: #( 'Object' )).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'InvalidTrait'.
	self assert: (error at: #message) equals: 'Object is not a trait.'.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget'
			           traits: #( 'TAbleToRotate classTrait' )).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self classNamed: 'MCPToolClassMutationTestMissingTraitTarget') traits collect: #name as: Array)
		equals: #( #TAbleToRotate )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenAddSlotClassIsMissing [

	| error result |
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'add'
			           className: 'MCPToolClassMutationTestMissingAddSlot'
			           slotName: 'addedSlot'
			           classSide: false).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'addSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingAddSlot'.
	self assert: (error at: #slot) equals: 'addedSlot'.
	self assert: (error at: #side) equals: 'instance'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenCommentClassIsMissing [

	| error result suggestions |
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestMissing').
			          (#comment -> 'ignored') } asDictionary.
	error := self errorFrom: result.
	suggestions := error at: #suggestions.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'setComment'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissing'.
	self deny: (error includesKey: #scope).
	self assert: suggestions size <= 5.
	self assert: ((error at: #message) includesSubstring: 'MCPToolClassMutationTestMissing does not exist')
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenMoveClassIsMissing [

	| error result |
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestMissing').
			          (#package -> self destinationPackageName) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'move'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissing'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenPullUpSlotClassIsMissing [

	| error result |
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestMissingPullUp'
			           slotName: 'sharedSlot'
			           classSide: false).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'pullUpSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingPullUp'.
	self assert: (error at: #slot) equals: 'sharedSlot'.
	self assert: (error at: #side) equals: 'instance'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenRemoveSlotClassIsMissing [

	| error result |
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestMissingRemoveSlot'
			           slotName: 'removableSlot'
			           classSide: false).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'removeSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingRemoveSlot'.
	self assert: (error at: #slot) equals: 'removableSlot'.
	self assert: (error at: #side) equals: 'instance'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenRenameClassIsMissing [

	| error result suggestions |
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestMissing').
			          (#newName -> self renamedClassName) } asDictionary.
	error := self errorFrom: result.
	suggestions := error at: #suggestions.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'rename'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissing'.
	self deny: (error includesKey: #scope).
	self assert: suggestions size <= 5.
	self assert: ((error at: #message) includesSubstring: 'MCPToolClassMutationTestMissing does not exist')
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenRenameSlotClassIsMissing [

	| error result |
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSlotRenameInClassNamed: 'MCPToolClassMutationTestMissingRenameSlot'
			           slotName: 'oldSlot'
			           newSlotName: 'renamedSlot'
			           classSide: false).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'renameSlot'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingRenameSlot'.
	self assert: (error at: #slot) equals: 'oldSlot'.
	self assert: (error at: #newSlot) equals: 'renamedSlot'.
	self assert: (error at: #side) equals: 'instance'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReparentClassIsMissing [

	| error result |
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestMissing').
			          (#superclass -> self reparentSuperclassName) } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #updateAction) equals: 'reparent'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissing'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReparentSuperclassIsMissing [

	| error result |
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> self reparentTargetClassName).
			          (#superclass -> 'DefinitelyMissingSuperclass') } asDictionary.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'reparent'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SuperclassNotFound'.
	self assert: (error at: #superclass) equals: 'DefinitelyMissingSuperclass'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementLayoutIsInvalid [

	| error result |
	self
		createClassNamed: 'MCPToolClassMutationTestInvalidLayoutTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self updateRequestArgumentsForLayoutInClassNamed: 'MCPToolClassMutationTestInvalidLayoutTarget' layout: 'Object').
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceLayout'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'InvalidLayoutClass'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestInvalidLayoutTarget'.
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
	result := self
		          callToolNamed: 'class_update'
		          withArguments:
		          (self
			           updateRequestArgumentsForLayoutInClassNamed: 'MCPToolClassMutationTestMissingLayoutTarget'
			           layout: 'DefinitelyMissingLayout').
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceLayout'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'LayoutClassNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingLayoutTarget'.
	self assert: (error at: #layout) equals: 'DefinitelyMissingLayout'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementSharedPoolIsMissing [

	| createArguments error result |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestMissingSharedPoolTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForSharedPoolsInClassNamed: 'MCPToolClassMutationTestMissingSharedPoolTarget'
			           sharedPools: #( 'DefinitelyMissingSharedPool' )).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceSharedPools'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'SharedPoolNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingSharedPoolTarget'.
	self assert: (error at: #sharedPool) equals: 'DefinitelyMissingSharedPool'.
	self assert: (error at: #sharedPools) equals: #( 'DefinitelyMissingSharedPool' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReplacementTraitIsMissing [

	| createArguments error result |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestMissingTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	self callToolNamed: 'class_create' withArguments: createArguments.
	result := self callToolNamed: 'class_update' withArguments: (self
			           updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget'
			           traits: #( 'DefinitelyMissingTrait' )).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #action) equals: 'update'.
	self assert: (error at: #updateAction) equals: 'replaceTraits'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'TraitNotFound'.
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingTraitTarget'.
	self assert: (error at: #trait) equals: 'DefinitelyMissingTrait'.
	self assert: (error at: #traits) equals: #( 'DefinitelyMissingTrait' )
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateSetsClassComment [

	| result target |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	self withoutEpiceaDuring: [ (self classNamed: self commentTargetClassName) comment: 'original comment' ].
	result := self callToolNamed: 'class_update' withArguments: (self updateRequestArgumentsForClassComment: 'updated comment').
	self dataFrom: result.
	target := self classNamed: self commentTargetClassName.
	self assert: target mcpComment equals: 'updated comment'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateStopsAtTheFirstFailedChangeAndSaysWhatLanded [

	| error result target |
	self
		createClassNamed: 'MCPToolClassMutationTestStopTarget'
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	"The layout is replaced first and fails, so the comment after it is never attempted."
	result := self callToolNamed: 'class_update' withArguments: {
			          (#name -> 'MCPToolClassMutationTestStopTarget').
			          (#layout -> 'MCPNoSuchLayout').
			          (#comment -> 'never set') } asDictionary.
	target := self classNamed: 'MCPToolClassMutationTestStopTarget'.
	self assert: (result at: #isError ifAbsent: [ false ]).
	error := (result at: #structuredContent) at: #error.
	self assert: (error at: #failedUpdate) equals: 'replaceLayout'.
	self assert: (error at: #appliedUpdates) equals: #(  ).
	self assert: (error at: #skippedUpdates) equals: #( 'setComment' ).
	self deny: target comment = 'never set'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateWithNoPatchArgumentsAsksForNoUpdate [
	"The schema refuses such a call before the tool sees it. Given one anyway, the tool reports the class alone and asks for an update."

	| context request result tool |
	tool := MCPToolUpdateClass new.
	request := self unvalidatedToolRequestForTool: tool arguments: { (#name -> 'ExistingClass') }.
	self assert: (tool suppliedPropertiesIn: request) isEmpty.
	context := tool requestedContextFor: request checked: true.
	self assert: context size equals: 1.
	self assert: (context at: #name) equals: 'ExistingClass'.
	result := (tool executeWithRequest: request) asJRPCJSON.
	self assert: (self resultIndicatesError: result).
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'NoClassUpdateRequested'
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updatePlansFor: associations [
	"The plans class_update makes for these arguments on Object, in the order it would apply them, without applying any."

	| arguments tool |
	arguments := Dictionary new.
	arguments at: #name put: 'Object'.
	associations do: [ :each | arguments at: each key put: each value ].
	tool := MCPToolUpdateClass new.
	^ tool updatePlansFor: (tool requestFromToolCallArguments: arguments)
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForClassComment: aClassComment [

	^ {
		  (#name -> self commentTargetClassName).
		  (#comment -> aClassComment) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForLayoutInClassNamed: aClassName layout: aLayoutName [

	^ {
		  (#name -> aClassName).
		  (#layout -> aLayoutName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForMoveToPackage [

	^ {
		  (#name -> self moveTargetClassName).
		  (#package -> self destinationPackageName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForMoveToPackageAndTag [

	^ {
		  (#name -> self moveTargetClassName).
		  (#package -> self destinationPackageName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForRecategorization [

	^ {
		  (#name -> self moveTargetClassName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForRename [

	^ {
		  (#name -> self originalClassName).
		  (#newName -> self renamedClassName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForReparent [

	^ {
		  (#name -> self reparentTargetClassName).
		  (#superclass -> self reparentSuperclassName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSharedPoolsInClassNamed: aClassName sharedPools: someNames [

	^ {
		  (#name -> aClassName).
		  (#sharedPools -> someNames) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSharedVariablesInClassNamed: aClassName sharedVariables: someNames [

	^ {
		  (#name -> aClassName).
		  (#sharedVariables -> someNames) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSlotAction: slotAction className: aClassName slotName: aSlotName classSide: aBoolean [

	^ {
		  (#name -> aClassName).
		  ((aBoolean
			    ifTrue: [ #classSlots ]
			    ifFalse: [ #slots ]) -> (Dictionary with: slotAction -> { aSlotName })) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSlotRenameInClassNamed: aClassName slotName: aSlotName newSlotName: aNewSlotName classSide: aBoolean [

	^ {
		  (#name -> aClassName).
		  ((aBoolean
			    ifTrue: [ #classSlots ]
			    ifFalse: [ #slots ]) -> (Dictionary with: 'rename' -> (Dictionary with: aSlotName -> aNewSlotName))) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForTraitsInClassNamed: aClassName traits: someTraitNames [

	^ {
		  (#name -> aClassName).
		  (#traits -> someTraitNames) } asDictionary
]

{ #category : 'private - fixtures' }
MCPToolClassMutationTest >> usedSlotUses [
	"The methods of the fixture createSlotUserFixture makes that use its slot, as an answer names them."

	^ #( 'MCPToolClassMutationTestWarningRemoveSlotTarget>>bumpsUsed reads and writes usedSlot'
	     'MCPToolClassMutationTestWarningRemoveSlotTarget>>readsUsed reads usedSlot'
	     'MCPToolClassMutationTestWarningRemoveSlotTarget>>writesUsed: writes usedSlot'
	     'MCPToolClassMutationTestSlotUserSubclass>>subclassReadsUsed reads usedSlot' )
]

{ #category : 'private' }
MCPToolClassMutationTest >> withInstanceOf: aClassName under: aSuperclassName readingItsSlotBy: aReadSource do: aBlock [
	"Pharo reads each slot of an instance it migrates when it reshapes the instance's class, this one through aReadSource, the read: method of a slot class of its own."

	| slotClass |
	slotClass := self
		             createClassNamed: 'MCPToolClassMutationTestMigratedSlot'
		             superclassName: 'InstanceVariableSlot'
		             slots: #(  )
		             classSlots: #(  ).
	[
		self ensureMethodSource: aReadSource protocol: 'meta-object-protocol' on: slotClass.
		aBlock value: (self
				 createClassNamed: aClassName
				 superclassName: aSuperclassName
				 slots: { (#migrated => slotClass) }
				 classSlots: #(  )) new ] ensure: [
			self removeClassNamed: aClassName.
			self removeClassNamed: slotClass name ]
]

{ #category : 'private' }
MCPToolClassMutationTest >> withUnmigratableInstanceOf: aClassName under: aSuperclassName do: aBlock [
	"Pharo cannot migrate an instance whose slot cannot be read."

	self
		withInstanceOf: aClassName
		under: aSuperclassName
		readingItsSlotBy: 'read: anObject ^ self error: ''This slot cannot be read.'''
		do: aBlock
]
