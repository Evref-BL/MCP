"
Create tests exercise class creation tool requests. Update tests exercise class update tool requests and verify the structured data the tool builds from the changed class.
"
Class {
	#name : 'MCPToolClassMutationTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
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

	| action arguments request result tool toolClass |
	arguments := someArguments copy.
	action := arguments removeKey: #action ifAbsent: [ nil ].
	toolClass := action = 'create'
		             ifTrue: [ MCPToolCreateClass ]
		             ifFalse: [ self classToolClassForArguments: arguments ].
	tool := toolClass new.
	request := tool requestFromToolCallArguments: arguments.
	result := tool executeWithRequest: request.
	^ result asJRPCJSON
]

{ #category : 'private - calling' }
MCPToolClassMutationTest >> callUpdateWrittenIn: aMessage [
	"Make the tool_call a refusal of class_create writes, as a client that reads the text would."

	^ self callRawToolNamed: 'tool_call' withArguments: (STONJSON fromString: (aMessage
				    copyFrom: (aMessage indexOfSubCollection: 'tool_call {') + 'tool_call ' size
				    to: aMessage size - '. class_get shows it.' size))
]

{ #category : 'private - calling' }
MCPToolClassMutationTest >> classToolClassForArguments: arguments [

	^ ((arguments includesKey: #superclass) and: [ arguments includesKey: #package ])
		  ifTrue: [ MCPToolCreateClass ]
		  ifFalse: [ MCPToolUpdateClass ]
]

{ #category : 'private' }
MCPToolClassMutationTest >> commentTargetClassName [

	^ 'MCPToolClassMutationTestCommentTarget'
]

{ #category : 'private - create' }
MCPToolClassMutationTest >> createRequestArgumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ self createRequestArgumentsWith: {
			  (#name -> aClassName).
			  (#superclass -> aSuperclassName).
			  (#package -> aPackageName) }
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
	     'MCPToolClassMutationTestWarningRemoveSlotTarget' 'MCPToolClassMutationTestPullUpTarget'
	     'MCPToolClassMutationTestPullUpChildOne' 'MCPToolClassMutationTestPullUpChildTwo' 'MCPToolClassMutationTestPushDownTarget'
	     'MCPToolClassMutationTestPushDownChildOne' 'MCPToolClassMutationTestPushDownChildTwo'
	     'MCPToolClassMutationTestWarningPullUpTarget' 'MCPToolClassMutationTestWarningPullUpChildOne'
	     'MCPToolClassMutationTestWarningPullUpChildTwo' 'TMCPToolClassMutationTestTrait' )
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

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testASingleUpdateAnswersNoData [
	"Several updates in one call each add their action to the data, and nothing else."

	| result |
	self
		createClassNamed: self commentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: (self updateRequestArgumentsForClassComment: 'updated comment').
	self assert: (self dataFrom: result) isEmpty
]

{ #category : 'tests - schema' }
MCPToolClassMutationTest >> testClassToolSchemasDeclareExpectedInputs [

	| createProperties updateProperties |
	createProperties := MCPToolCreateClass new inputSchema properties collect: [ :each | each name ].
	updateProperties := MCPToolUpdateClass new inputSchema properties collect: [ :each | each name ].
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
	self assert: MCPToolUpdateClass new inputSchema required asSet equals: #( 'name' ) asSet
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateAcceptsClassSlots [

	| createdClass data result |
	result := self callToolWith: (self createRequestArgumentsWith: {
				           (#name -> 'MCPToolClassMutationTestClassSlots').
				           (#superclass -> 'Object').
				           (#package -> self generatedPackageName).
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
	arguments at: #sharedVariables put: #( 'AlphaShared' 'BetaShared' ).
	arguments at: #sharedPools put: #( 'ChronologyConstants' ).
	arguments at: #layout put: 'WeakLayout'.
	result := self callToolWith: arguments.
	data := self dataFrom: result.
	createdClass := self classNamed: 'MCPToolClassMutationTestConfigured'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (createdClass traits collect: [ :each | each name asString ] as: Array) equals: #( 'TAbleToRotate' ).
	self assert: createdClass traitCompositionString equals: 'TAbleToRotate'.
	"Asked for nothing on the class side, the class still uses the trait whole."
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
				           (#superclass -> 'Object').
				           (#package -> self generatedPackageName).
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
MCPToolClassMutationTest >> testCreateDefaultsTheSuperclassToObject [

	| createdClass result |
	result := self callToolWith: (self createRequestArgumentsWith: {
				           (#name -> 'MCPToolClassMutationTestDefaultSuperclass').
				           (#package -> self generatedPackageName) }).
	createdClass := self classNamed: 'MCPToolClassMutationTestDefaultSuperclass'.
	self assert: createdClass superclass equals: Object.
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
MCPToolClassMutationTest >> testCreateNamesATraitATrait [

	| createdTrait result text |
	result := self callToolWith: (self createRequestArgumentsWith: {
				           (#name -> 'TMCPToolClassMutationTestTrait').
				           (#superclass -> 'Trait').
				           (#package -> self generatedPackageName) }).
	createdTrait := self classNamed: 'TMCPToolClassMutationTestTrait'.
	text := (result at: #content) first at: #text.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: createdTrait isTrait.
	self assert: (text includesSubstring: 'Created trait TMCPToolClassMutationTestTrait.')
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
	message := (self errorFrom: (self callToolWith: (self createRequestArgumentsWith: {
					              (#name -> self reparentTargetClassName).
					              (#superclass -> 'Object').
					              (#package -> self generatedPackageName).
					              (#slots -> #( 'inherited' )) }))) at: #message.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call {"name":"class_update","arguments":{"name":"MCPToolClassMutationTestReparentTarget","superclass":"Object","slots":{"add":["inherited"]}}}. class_get shows it.'.
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
	message := (self errorFrom: (self callToolWith: (self createRequestArgumentsWith: {
					              (#name -> self reparentTargetClassName).
					              (#superclass -> self reparentSuperclassName).
					              (#package -> self generatedPackageName).
					              (#slots -> #( 'own' 'inherited' 'added' )).
					              (#classSlots -> #( 'registry' )) }))) at: #message.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call {"name":"class_update","arguments":{"name":"MCPToolClassMutationTestReparentTarget","superclass":"MCPToolClassMutationTestReparentSuperclass","slots":{"add":["added"]}}}. class_get shows it.'.
	self deny: ((self callUpdateWrittenIn: message) at: #isError ifAbsent: [ false ]).
	target := self classNamed: self reparentTargetClassName.
	self assert: target superclass name equals: self reparentSuperclassName asSymbol.
	self assert: (target instVarNames collect: [ :each | each asString ] as: Array) equals: #( 'own' 'added' ).
	self assert: (target classSide allInstVarNames includes: #registry)
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfAClassThatHasItAllSaysNothingNeedsChanging [
	"A class that already has everything the call asks for needs no class_update call: the refusal says so rather than write one that changes nothing."

	| arguments error |
	arguments := self createRequestArgumentsWith: {
			             (#name -> 'MCPToolClassMutationTestGenerated').
			             (#superclass -> 'Object').
			             (#package -> self generatedPackageName).
			             (#slots -> #( 'a' )) }.
	self callToolWith: arguments.
	error := self errorFrom: (self callToolWith: arguments).
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
	self callToolWith: (self
			 createRequestArgumentsForClassName: 'TMCPToolClassMutationTestTrait'
			 superclassName: 'Trait'
			 packageName: self generatedPackageName).
	message := (self errorFrom: (self callToolWith: (self createRequestArgumentsWith: {
					              (#name -> 'TMCPToolClassMutationTestTrait').
					              (#package -> self generatedPackageName).
					              (#slots -> #( 'color' )) }))) at: #message.
	self
		assert: message
		equals:
		'Class TMCPToolClassMutationTestTrait already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call {"name":"class_update","arguments":{"name":"TMCPToolClassMutationTestTrait","slots":{"add":["color"]}}}. class_get shows it.'.
	self deny: ((self callUpdateWrittenIn: message) at: #isError ifAbsent: [ false ]).
	self
		assert: ((self classNamed: 'TMCPToolClassMutationTestTrait') instVarNames collect: [ :each | each asString ] as: Array)
		equals: #( 'color' )
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfAnExistingClassSaysHowToReachClassUpdate [
	"class_update is not in every client's list, and a client that calls only what it lists cannot call it by its name. The refusal gives the call every client can make, with the class already named in it."

	| text |
	self callToolWith: (self
			 createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	text := self textFrom: (self callToolWith: (self createRequestArgumentsWith: {
					          (#name -> 'MCPToolClassMutationTestGenerated').
					          (#package -> self generatedPackageName).
					          (#slots -> #( 'color' )) })).
	self assert: (text includesSubstring:
			 'Change it with class_update, through tool_call when class_update is not in your list: tool_call {"name":"class_update","arguments":{"name":"MCPToolClassMutationTestGenerated","slots":{"add":["color"]}}}.')
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateRefusalOfAnExistingClassWritesTheUpdateThatGivesItWhatItLacks [
	"An agent that asks class_create for a class that exists wants it to have that definition. The refusal writes the class_update call that gives it what it lacks, and nothing else: the slots it does not have are added, a list class_update replaces keeps what the class has, and what the class already has is left out. The call is written as a client reads text, a comment's lines ended by line feeds. Made, that call gives the class the definition asked for."

	| createdClass error message |
	self callToolWith: (self createRequestArgumentsWith: {
				 (#name -> 'MCPToolClassMutationTestGenerated').
				 (#package -> self generatedPackageName).
				 (#slots -> #( 'a' )).
				 (#sharedVariables -> #( 'Registry' )) }).
	error := self errorFrom: (self callToolWith: (self createRequestArgumentsWith: {
					           (#name -> 'MCPToolClassMutationTestGenerated').
					           (#superclass -> 'Object').
					           (#package -> self generatedPackageName).
					           (#tag -> 'Model').
					           (#slots -> #( 'a' 'color' )).
					           (#classSlots -> #( 'made' )).
					           (#sharedVariables -> #( 'Registry' 'Other' )).
					           (#comment -> (String cr join: #( 'A generated class.' 'It has two lines.' ))) })).
	message := error at: #message.
	self assert: (error at: #errorCode) equals: 'ClassAlreadyExists'.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestGenerated already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call {"name":"class_update","arguments":{"name":"MCPToolClassMutationTestGenerated","tag":"Model","slots":{"add":["color"]},"classSlots":{"add":["made"]},"sharedVariables":["Registry","Other"],"comment":"A generated class.\nIt has two lines."}}. class_get shows it.'.
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
	self callToolWith: (self
			 createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	self callToolWith: (self
			 createRequestArgumentsForClassName: 'TMCPToolClassMutationTestTrait'
			 superclassName: 'Trait'
			 packageName: self generatedPackageName).
	refusalOf := [ :className :superclassName |
		             self errorFrom: (self callToolWith:
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
	message := (self errorFrom: (self callToolWith: (self createRequestArgumentsWith: {
					              (#name -> self reparentTargetClassName).
					              (#package -> self generatedPackageName).
					              (#slots -> #( 'shared' 'added' )).
					              (#classSlots -> #( 'registry' )) }))) at: #message.
	self
		assert: message
		equals:
		'Class MCPToolClassMutationTestReparentTarget already exists. Change it with class_update, through tool_call when class_update is not in your list: tool_call {"name":"class_update","arguments":{"name":"MCPToolClassMutationTestReparentTarget","slots":{"add":["added"],"pullUp":["shared"]},"classSlots":{"pullUp":["registry"]}}}. class_get shows it.'.
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
		           (self errorFrom: (self callToolWith: (self createRequestArgumentsWith: {
						              (#name -> self reparentTargetClassName).
						              (#superclass -> self reparentSuperclassName).
						              (#package -> self generatedPackageName).
						              (#slots -> #( 'own' 'shared' )) }))) at: #message ].
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
	self assert: ((self callToolWith: (self updateRequestArgumentsWith: {
					   (#name -> self reparentTargetClassName).
					   (#superclass -> self reparentSuperclassName) })) at: #isError).
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
			result := self callToolWith: (self createRequestArgumentsWith: {
						           (#name -> 'MCPToolClassMutationTestGenerated').
						           (#package -> self generatedPackageName).
						           (each first -> #( '["Title" "Text"]' )) }).
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
			self deny: (Smalltalk globals includesKey: #MCPToolClassMutationTestGenerated).
			self deny: (self packageOrganizer hasPackage: self generatedPackageName) ]
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
	self assert: ((error at: #message) beginsWith: 'Class MCPToolClassMutationTestGenerated already exists ').
	self assert: (((result at: #content) first at: #text) includesSubstring: (error at: #message)).
	self deny: (error includesKey: #guidance)
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
	result := self callToolWith: arguments.
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

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateThatFailsLeavesNoPackageItMade [
	"The package is made for the class to land in, so a class that does not build takes it away again. A package that was there stays."

	| arguments |
	arguments := self createRequestArgumentsWith: {
			             (#name -> 'MCPToolClassMutationTestGenerated').
			             (#package -> self generatedPackageName).
			             (#traits -> #( 'DefinitelyMissingTrait' )) }.
	self assert: ((self callToolWith: arguments) at: #isError).
	self deny: (Smalltalk globals includesKey: #MCPToolClassMutationTestGenerated).
	self deny: (self packageOrganizer hasPackage: self generatedPackageName).
	self withoutEpiceaDuring: [ self packageOrganizer ensurePackage: self generatedPackageName ].
	self assert: ((self callToolWith: arguments) at: #isError).
	self assert: (self packageOrganizer hasPackage: self generatedPackageName)
]

{ #category : 'tests - create' }
MCPToolClassMutationTest >> testCreateWithoutASuperclassSaysItSubclassesObject [
	"A class made with no superclass given subclasses Object, which a caller that meant another, as for a test class, would not see in Created class Foo. The answer says so. A class given its superclass is answered as before."

	self
		assert: (self textFrom: (self callToolWith: (self createRequestArgumentsWith: {
							   (#name -> 'MCPToolClassMutationTestDefaultSuperclass').
							   (#package -> self generatedPackageName) })))
		equals: 'Created class MCPToolClassMutationTestDefaultSuperclass, a subclass of Object.'.
	self
		assert: (self textFrom: (self callToolWith: (self
						   createRequestArgumentsForClassName: 'MCPToolClassMutationTestGenerated'
						   superclassName: 'Object'
						   packageName: self generatedPackageName)))
		equals: 'Created class MCPToolClassMutationTestGenerated.'
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
	result := self callToolWith: (self
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
				 refactoringWarningSummaryFor: nil
				 action: 'removeSlot'
				 requestedContext: {
						 (#class -> 'ZooAnimal').
						 (#slot -> 'weight') } asDictionary
				 impactMessages: #( 'ZooAnimal>>dailyRation reads weight.' 'ZooAnimal>>weigh: writes weight' ))
		equals:
		'Refactoring warning for removeSlot on ZooAnimal slot weight: ZooAnimal>>dailyRation reads weight; ZooAnimal>>weigh: writes weight. Rerun with force: true to proceed anyway.'.
	self
		assert: (MCPToolUpdateClass new
				 refactoringWarningSummaryFor: nil
				 action: 'removeSlot'
				 requestedContext: { (#class -> 'ZooAnimal') } asDictionary
				 impactMessages: #(  ))
		equals: 'Refactoring warning for removeSlot on ZooAnimal. Rerun with force: true to proceed anyway.'.
	self
		assert: (MCPToolUpdateClass new
				 refactoringWarningSummaryFor: nil
				 action: 'pullUpSlot'
				 requestedContext: { (#class -> 'ZooAnimal') } asDictionary
				 impactMessages: #( 'Not all subclasses have it. Pull it up anyway?' ))
		equals:
		'Refactoring warning for pullUpSlot on ZooAnimal: Not all subclasses have it. Pull it up anyway? Rerun with force: true to proceed anyway.'
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testRetagSummaryNamesTheTag [
	"A class moved to a tag is named with the tag and the package it lies in; one moved to a package's root, with the package alone."

	self
		assert: (self summaryFrom: (self callToolWith: self updateRequestArgumentsForRecategorization))
		equals: ('Moved class {1} to tag {2} of package {3}.' format: {
					 self moveTargetClassName.
					 self destinationTagName.
					 self originalMovePackageName }).
	self
		assert: (self summaryFrom: (self callToolWith: self updateRequestArgumentsForMoveToPackage))
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
	result := self callToolWith: {
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
MCPToolClassMutationTest >> testUpdateAppliesSeveralChangesInOneCall [

	| data result target |
	self
		createClassNamed: 'MCPToolClassMutationTestFusedTarget'
		superclassName: 'Object'
		slots: #( 'kept' )
		classSlots: #(  ).
	result := self callToolWith: {
			          (#name -> 'MCPToolClassMutationTestFusedTarget').
			          (#superclass -> 'ProtoObject').
			          (#slots -> (Dictionary with: 'add' -> #( 'added' ))).
			          (#comment -> 'fused comment') } asDictionary.
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestFusedTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: target superclass name equals: #ProtoObject.
	self assert: target instVarNames asArray equals: #( 'kept' 'added' ).
	self assert: target mcpComment equals: 'fused comment'.
	self assert: ((data at: #updates) collect: [ :each | each at: #action ] as: Array) equals: #( 'reparent' 'addSlot' 'setComment' )
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
	self assert: target mcpComment equals: ''.
	self deny: (result at: #isError ifAbsent: [ false ])
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
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#name -> 'MCPToolClassMutationTestWarningPullUpTarget').
				           (#slots -> (Dictionary with: 'pullUp' -> #( 'sharedSlot' ))).
				           (#force -> true) }).
	self refactoringsRefuseBreakingChanges ifTrue: [ ^ self assert: (result at: #isError) ].
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
	result := self callToolWith: (self updateRequestArgumentsWith: {
				           (#name -> 'MCPToolClassMutationTestWarningRemoveSlotTarget').
				           (#slots -> (Dictionary with: 'remove' -> #( 'referencedSlot' ))).
				           (#force -> true) }).
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

	| data result |
	self removeDestinationPackage.
	result := self callToolWith: self updateRequestArgumentsForMoveToPackage.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (self packageOrganizer hasPackage: self destinationPackageName).
	self assert: self moveTargetClass packageName asString equals: self destinationPackageName.
	self deny: (result at: #isError ifAbsent: [ false ])
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateMoveEnsuresMissingDestinationTag [

	| data package result |
	self removeDestinationPackage.
	self withoutEpiceaDuring: [ self packageOrganizer ensurePackage: self destinationPackageName ].
	result := self callToolWith: self updateRequestArgumentsForMoveToPackageAndTag.
	data := self dataFrom: result.
	package := self packageOrganizer packageNamed: self destinationPackageName.
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
MCPToolClassMutationTest >> testUpdateOfAGlobalThatIsNotAClassIsRefused [
	"A tag alone looks the class up for its package. Transcript used to be asked for its package as if it were a class."

	| error result |
	result := self callToolWith: {
			          (#action -> 'update').
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
	result := self callToolWith: (self
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
	result := self callToolWith: (self
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

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolMethodMutationTestTarget'
			           slotName: 'missingSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
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
	self refactoringsRefuseBreakingChanges ifTrue: [ ^ self assert: (result at: #isError) ].
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
	self refactoringsRefuseBreakingChanges ifTrue: [ ^ self assert: (result at: #isError) ].
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

	| data package result |
	result := self callToolWith: self updateRequestArgumentsForRecategorization.
	data := self dataFrom: result.
	package := self packageOrganizer packageNamed: self originalMovePackageName.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (package hasTag: self destinationTagName).
	self assert: self moveTargetClass packageName asString equals: self originalMovePackageName.
	self assert: self currentTagOfMoveTargetClass equals: self destinationTagName.
	self deny: (result at: #isError ifAbsent: [ false ])
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
	result := self callToolWith: {
			          (#action -> 'update').
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
		result := self callToolWith: (self
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

{ #category : 'tests' }
MCPToolClassMutationTest >> testUpdateRenamesTheClassItsSubclassesAndItsReferences [
	"A rename is a refactoring that takes a second, so one rename is read every way."

	| reference result |
	result := self callToolWith: self updateRequestArgumentsForRename.
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self assert: (Smalltalk globals includesKey: self renamedClassName asSymbol).
	self deny: (Smalltalk globals includesKey: self originalClassName asSymbol).
	self assert: (self classNamed: self subclassName) superclass name asString equals: self renamedClassName.
	reference := (self classNamed: self referenceClassName) new.
	self assert: reference referencedClass name asString equals: self renamedClassName.
	self assert: reference newReferencedInstance class name asString equals: self renamedClassName
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
	self assert: target mcpComment equals: 'reparent comment'.
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
				           (#name -> 'MCPToolClassMutationTestDefinitionTarget').
				           (#slots -> (Dictionary with: 'replace' -> #( 'keptSlot' 'newSlot' ))).
				           (#classSlots -> (Dictionary with: 'replace' -> #( 'keptClassSlot' 'newClassSlot' ))) }).
	data := self dataFrom: result.
	target := self classNamed: 'MCPToolClassMutationTestDefinitionTarget'.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (target slots collect: #name as: Array) equals: #( #keptSlot #newSlot ).
	self assert: (target classSide slots collect: #name as: Array) equals: #( #keptClassSlot #newClassSlot ).
	self assert: (instance instVarNamed: 'keptSlot') equals: 13.
	self assert: (target instVarNamed: 'keptClassSlot') equals: 17
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
MCPToolClassMutationTest >> testUpdateReplacingTraitsSuggestsTraitsAndRefusesAClass [

	| createArguments error result |
	createArguments := self
		                   createRequestArgumentsForClassName: 'MCPToolClassMutationTestMissingTraitTarget'
		                   superclassName: 'Object'
		                   packageName: self generatedPackageName.
	self callToolWith: createArguments.
	result := self callToolWith:
		          (self
			           updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget'
			           traits: #( 'TAbleToRotat' )).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'TraitNotFound'.
	self assert: ((error at: #suggestions) includes: 'TAbleToRotate').
	self assert: (error at: #traits) equals: #( 'TAbleToRotat' ).
	self assert: ((error at: #message) beginsWith: 'Trait TAbleToRotat does not exist. Did you mean: ').
	result := self callToolWith:
		          (self updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget' traits: #( 'Object' )).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'InvalidTrait'.
	self assert: (error at: #message) equals: 'Object is not a trait.'.
	result := self callToolWith: (self
			           updateRequestArgumentsForTraitsInClassNamed: 'MCPToolClassMutationTestMissingTraitTarget'
			           traits: #( 'TAbleToRotate classTrait' )).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self
		assert: ((self classNamed: 'MCPToolClassMutationTestMissingTraitTarget') traits collect: #name as: Array)
		equals: #( #TAbleToRotate )
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
	result := self callToolWith: {
			          (#action -> 'update').
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
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenDestinationTagIsMissing [

	self testUpdateMoveEnsuresMissingDestinationTag
]

{ #category : 'tests - update' }
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenMoveClassIsMissing [

	| error result structured |
	result := self callToolWith: {
			          (#action -> 'update').
			          (#name -> 'MCPToolClassMutationTestMissing').
			          (#package -> self destinationPackageName) } asDictionary.
	structured := self structuredContentFrom: result.
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

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'pullUp'
			           className: 'MCPToolClassMutationTestMissingPullUp'
			           slotName: 'sharedSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
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

	| error result structured |
	result := self callToolWith: (self
			           updateRequestArgumentsForSlotAction: 'remove'
			           className: 'MCPToolClassMutationTestMissingRemoveSlot'
			           slotName: 'removableSlot'
			           classSide: false).
	structured := self structuredContentFrom: result.
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
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissing'.
	self deny: (error includesKey: #scope).
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
MCPToolClassMutationTest >> testUpdateReturnsStructuredErrorWhenReparentSuperclassIsMissing [

	| error result |
	self
		createClassNamed: self reparentTargetClassName
		superclassName: 'Object'
		slots: #(  )
		classSlots: #(  ).
	result := self callToolWith: {
			          (#action -> 'update').
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
	result := self callToolWith:
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
	self assert: (error at: #class) equals: 'MCPToolClassMutationTestMissingTraitTarget'.
	self assert: (error at: #trait) equals: 'DefinitelyMissingTrait'.
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
	self assert: target mcpComment equals: 'updated comment'.
	self deny: (result at: #isError ifAbsent: [ false ])
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
	result := self callToolWith: {
			          (#action -> 'update').
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

{ #category : 'private - calling' }
MCPToolClassMutationTest >> toolName [

	self shouldNotImplement
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
		  (#action -> 'update').
		  (#name -> self commentTargetClassName).
		  (#comment -> aClassComment) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForLayoutInClassNamed: aClassName layout: aLayoutName [

	^ self updateRequestArgumentsWith: {
			  (#name -> aClassName).
			  (#layout -> aLayoutName) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForMoveToPackage [

	^ {
		  (#action -> 'update').
		  (#name -> self moveTargetClassName).
		  (#package -> self destinationPackageName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForMoveToPackageAndTag [

	^ {
		  (#action -> 'update').
		  (#name -> self moveTargetClassName).
		  (#package -> self destinationPackageName).
		  (#tag -> self destinationTagName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForRecategorization [

	^ {
		  (#action -> 'update').
		  (#name -> self moveTargetClassName).
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
		  (#name -> self reparentTargetClassName).
		  (#superclass -> self reparentSuperclassName) } asDictionary
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSharedPoolsInClassNamed: aClassName sharedPools: someNames [

	^ self updateRequestArgumentsWith: {
			  (#name -> aClassName).
			  (#sharedPools -> someNames) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSharedVariablesInClassNamed: aClassName sharedVariables: someNames [

	^ self updateRequestArgumentsWith: {
			  (#name -> aClassName).
			  (#sharedVariables -> someNames) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSlotAction: slotAction className: aClassName slotName: aSlotName classSide: aBoolean [

	^ self updateRequestArgumentsWith: {
			  (#name -> aClassName).
			  ((aBoolean
				    ifTrue: [ #classSlots ]
				    ifFalse: [ #slots ]) -> (Dictionary with: slotAction -> { aSlotName })) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForSlotRenameInClassNamed: aClassName slotName: aSlotName newSlotName: aNewSlotName classSide: aBoolean [

	^ self updateRequestArgumentsWith: {
			  (#name -> aClassName).
			  ((aBoolean
				    ifTrue: [ #classSlots ]
				    ifFalse: [ #slots ]) -> (Dictionary with: 'rename' -> (Dictionary with: aSlotName -> aNewSlotName))) }
]

{ #category : 'private - update' }
MCPToolClassMutationTest >> updateRequestArgumentsForTraitsInClassNamed: aClassName traits: someTraitNames [

	^ self updateRequestArgumentsWith: {
			  (#name -> aClassName).
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
