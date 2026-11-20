"
Tests command-level class creation behavior.
"
Class {
	#name : 'MCPCreateClassCommandTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private - errors' }
MCPCreateClassCommandTest >> captureCommandError: aBlock [

	^ [
		  aBlock value.
		  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private' }
MCPCreateClassCommandTest >> commandCreating: aClassName superclass: aSuperclassName [
	"The command class_create builds for a class given only its superclass."

	^ MCPCreateClassCommand
		  className: aClassName
		  superclassName: aSuperclassName
		  packageName: self generatedPackageName
		  tag: nil
		  slots: nil
		  classSlots: nil
		  traits: nil
		  sharedVariables: nil
		  sharedPools: nil
		  layout: nil
]

{ #category : 'private' }
MCPCreateClassCommandTest >> createdClassNames [

	^ #( 'MCPCreateClassCommandTestGenerated' 'MCPCreateClassCommandTestTagged' 'MCPCreateClassCommandTestClassSlots'
	     'MCPCreateClassCommandTestConfigured' 'MCPCreateClassCommandTestTemporaryPackage'
	     'TMCPCreateClassCommandTestTrait' )
]

{ #category : 'private' }
MCPCreateClassCommandTest >> errorCreating: aClassName superclass: aSuperclassName [

	^ self errorCreating: aClassName superclass: aSuperclassName configuredBy: [ :command | command ]
]

{ #category : 'private' }
MCPCreateClassCommandTest >> errorCreating: aClassName superclass: aSuperclassName configuredBy: aBlock [

	| command |
	command := self commandCreating: aClassName superclass: aSuperclassName.
	aBlock value: command.
	^ self captureCommandError: [ command execute ]
]

{ #category : 'private' }
MCPCreateClassCommandTest >> generatedPackageName [

	^ 'MCP-Tests-CreateClassCommand'
]

{ #category : 'private' }
MCPCreateClassCommandTest >> removeGeneratedPackage [

	self withoutEpiceaDuring: [
			(self packageOrganizer hasPackage: self generatedPackageName) ifTrue: [
				self packageOrganizer removePackage: (self packageOrganizer packageNamed: self generatedPackageName) ] ]
]

{ #category : 'running' }
MCPCreateClassCommandTest >> setUp [

	super setUp.
	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage
]

{ #category : 'running' }
MCPCreateClassCommandTest >> tearDown [

	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage.
	super tearDown
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testAClassSideNameIsRefused [
	"Read as its class, the name would make a class named after a metaclass, or say the class already exists."

	| error |
	error := self errorCreating: 'MCPCreateClassCommandTestGenerated class' superclass: 'Object'.
	self assert: error errorCode equals: #ClassSideNamed.
	self
		assert: error messageText
		equals:
		'MCPCreateClassCommandTestGenerated class is the class side of MCPCreateClassCommandTestGenerated, which class_create makes with the class. Name MCPCreateClassCommandTestGenerated, and give class-side slots in classSlots.'.
	self assert: (error details at: #class) equals: 'MCPCreateClassCommandTestGenerated'.
	self assert: (error details at: #name) equals: 'MCPCreateClassCommandTestGenerated class'.
	self deny: (Smalltalk globals includesKey: #MCPCreateClassCommandTestGenerated)
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testAGlobalThatIsNotAClassIsRefusedAsSuperclassBeforeAnythingIsBuilt [
	"Transcript is a global variable, which used to reach class code as if it were a class."

	| error |
	error := self errorCreating: 'MCPCreateClassCommandTestGenerated' superclass: 'Transcript'.
	self assert: error errorCode equals: #NotAClass.
	self assert: error messageText equals: 'Transcript is a global variable, not a class.'.
	self assert: (error details at: #superclass) equals: 'Transcript'.
	self assert: (error details at: #class) equals: 'MCPCreateClassCommandTestGenerated'.
	self deny: (Smalltalk globals includesKey: #MCPCreateClassCommandTestGenerated)
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testAListWrittenAsOneNameIsRefused [

	| error |
	error := self errorCreating: '{"MCPCreateClassCommandTestGenerated","MCPCreateClassCommandTestTagged"}' superclass: 'Object'.
	self assert: error errorCode equals: #ClassNameIsAList.
	self assert:
		(error messageText endsWith: 'is a list written as one string, not a class name. Pass several names as an array of strings.')
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testANameAGlobalVariableHoldsIsRefused [

	| error |
	error := self errorCreating: 'Transcript' superclass: 'Object'.
	self assert: error errorCode equals: #GlobalAlreadyExists.
	self assert: error messageText equals: 'Transcript already names a global variable. Choose another class name.'.
	self assert: (error details at: #class) equals: 'Transcript'.
	self deny: Transcript isClass
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testAPackageIsRemovedOnlyWhileItDefinesNoClass [
	"A create that fails removes the package it made by the rule class_remove follows: a class may have landed in it before the build failed, and the package then stays with it."

	| command |
	command := MCPCreateClassCommand new.
	(self commandCreating: 'MCPCreateClassCommandTestGenerated' superclass: 'Object') execute.
	self deny: (command removePackageIfEmptyNamed: self generatedPackageName).
	self assert: (self packageOrganizer hasPackage: self generatedPackageName).
	self withoutEpiceaDuring: [ (self classNamed: 'MCPCreateClassCommandTestGenerated') removeFromSystem ].
	self assert: (command removePackageIfEmptyNamed: self generatedPackageName).
	self deny: (self packageOrganizer hasPackage: self generatedPackageName)
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testClassesOfTheWrongKindAreRefusedSayingWhatTheRoleNeeds [

	| error |
	error := self
		         errorCreating: 'MCPCreateClassCommandTestGenerated'
		         superclass: 'Object'
		         configuredBy: [ :command | command sharedPools: #( 'MCPCreateClassCommandTest' ) ].
	self assert: error errorCode equals: #InvalidSharedPool.
	self assert: error messageText equals: 'MCPCreateClassCommandTest is not a shared pool: a pool is a subclass of SharedPool.'.
	self assert: (error details at: #sharedPool) equals: 'MCPCreateClassCommandTest'.
	error := self
		         errorCreating: 'MCPCreateClassCommandTestGenerated'
		         superclass: 'Object'
		         configuredBy: [ :command | command layout: 'Object' ].
	self assert: error errorCode equals: #InvalidLayoutClass.
	self assert: error messageText equals: 'Object is not a layout class: name a subclass of AbstractLayout, such as VariableLayout.'.
	self assert: (error details at: #layout) equals: 'Object'.
	error := self
		         errorCreating: 'MCPCreateClassCommandTestGenerated'
		         superclass: 'Object'
		         configuredBy: [ :command | command traits: #( 'Object' ) ].
	self assert: error errorCode equals: #InvalidTrait.
	self assert: error messageText equals: 'Object is not a trait.'.
	self deny: (Smalltalk globals includesKey: #MCPCreateClassCommandTestGenerated)
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testCreatesClassAndAnswersIt [

	| result createdClass |
	result := (self commandCreating: 'MCPCreateClassCommandTestGenerated' superclass: 'Object') execute.
	createdClass := self classNamed: 'MCPCreateClassCommandTestGenerated'.
	self assert: createdClass superclass equals: Object.
	self assert: createdClass packageName asString equals: self generatedPackageName.
	self assert: result identicalTo: createdClass
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testCreatesClassWithTagSlotsAndClassSlots [

	| createdClass result |
	result := ((self commandCreating: 'MCPCreateClassCommandTestTagged' superclass: 'Object')
		           tag: 'Generated';
		           slots: #( #firstName #lastName );
		           classSlots: #( #defaultName );
		           yourself) execute.
	createdClass := self classNamed: 'MCPCreateClassCommandTestTagged'.
	self assert: (createdClass slots collect: #name as: Array) equals: #( #firstName #lastName ).
	self assert: (createdClass classSide slots collect: #name as: Array) equals: #( #defaultName ).
	self assert: createdClass packageTagName asString equals: 'Generated'.
	self assert: (MCPClassInfo fromClass: result) tag equals: 'Generated'
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testCreatesClassWithTraitsSharedVariablesSharedPoolsAndLayout [

	| createdClass |
	(MCPCreateClassCommand
		 className: 'MCPCreateClassCommandTestConfigured'
		 superclassName: 'Object'
		 packageName: self generatedPackageName
		 tag: 'Configured'
		 slots: #( #firstName )
		 classSlots: #( #defaultName )
		 traits: #( 'TAbleToRotate' )
		 sharedVariables: #( 'AlphaShared' 'BetaShared' )
		 sharedPools: #( 'ChronologyConstants' )
		 layout: 'WeakLayout') execute.
	createdClass := self classNamed: 'MCPCreateClassCommandTestConfigured'.
	self assert: (createdClass traits collect: [ :each | each name asString ] as: Array) equals: #( 'TAbleToRotate' ).
	"The class side comes with the trait: the class uses TAbleToRotate as a whole."
	self
		assert: (createdClass classSide traits collect: [ :each | each name asString ] as: Array)
		equals: #( 'TAbleToRotate classTrait' ).
	self assert: createdClass classVarNames equals: #( #AlphaShared #BetaShared ).
	self assert: (createdClass sharedPools collect: [ :each | each name asString ] as: Array) equals: #( 'ChronologyConstants' ).
	self assert: createdClass classLayout class name equals: #WeakLayout
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testCreatesTraitWhenSuperclassIsTrait [

	| createdTrait |
	(self commandCreating: 'TMCPCreateClassCommandTestTrait' superclass: 'Trait') execute.
	createdTrait := self classNamed: 'TMCPCreateClassCommandTestTrait'.
	self assert: createdTrait isTrait.
	self assert: createdTrait superclass isNil
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testExistingClassSignalsCommandError [

	| error |
	(self commandCreating: 'MCPCreateClassCommandTestGenerated' superclass: 'Object') execute.
	error := self errorCreating: 'MCPCreateClassCommandTestGenerated' superclass: 'Object'.
	self assert: error errorCode equals: #ClassAlreadyExists.
	self assert: (error structuredDetails at: #class) equals: 'MCPCreateClassCommandTestGenerated'.
	self assert: (error messageText includesSubstring: 'Change it with class_update')
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testMissingSuperclassSignalsCommandError [

	| error |
	error := self errorCreating: 'MCPCreateClassCommandTestGenerated' superclass: 'DefinitelyMissingSuperclass'.
	self assert: error errorCode equals: #SuperclassNotFound.
	self assert: (error structuredDetails at: #superclass) equals: 'DefinitelyMissingSuperclass'
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testMisspeltNamesSuggestNamesOfTheirRole [
	"A misspelt pool suggests pools, a misspelt layout layouts, and a misspelt trait traits."

	| error |
	error := self
		         errorCreating: 'MCPCreateClassCommandTestGenerated'
		         superclass: 'Object'
		         configuredBy: [ :command | command sharedPools: #( 'ChronologyConstant' ) ].
	self assert: error errorCode equals: #SharedPoolNotFound.
	self assert: ((error details at: #suggestions) includes: 'ChronologyConstants').
	self assert: (error messageText beginsWith: 'Shared pool ChronologyConstant does not exist. Did you mean: ').
	error := self
		         errorCreating: 'MCPCreateClassCommandTestGenerated'
		         superclass: 'Object'
		         configuredBy: [ :command | command layout: 'WeakLayot' ].
	self assert: error errorCode equals: #LayoutClassNotFound.
	self assert: ((error details at: #suggestions) includes: 'WeakLayout').
	self assert: (error messageText beginsWith: 'Layout class WeakLayot does not exist. Did you mean: ').
	error := self
		         errorCreating: 'MCPCreateClassCommandTestGenerated'
		         superclass: 'Object'
		         configuredBy: [ :command | command traits: #( 'TAbleToRotat' ) ].
	self assert: error errorCode equals: #TraitNotFound.
	self assert: ((error details at: #suggestions) includes: 'TAbleToRotate').
	self assert: ((error details at: #suggestions) allSatisfy: [ :each | (Smalltalk globals classNamed: each) isTrait ])
]
