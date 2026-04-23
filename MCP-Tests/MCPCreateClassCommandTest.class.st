Class {
	#name : 'MCPCreateClassCommandTest',
	#superclass : 'MCPCommandTestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPCreateClassCommandTest >> createdClassNames [

	^ #( 'MCPCreateClassCommandTestGenerated'
	     'MCPCreateClassCommandTestTagged'
	     'MCPCreateClassCommandTestClassSlots'
	     'MCPCreateClassCommandTestConfigured'
	     'MCPCreateClassCommandTestTemporaryPackage' )
]

{ #category : 'private' }
MCPCreateClassCommandTest >> generatedPackageName [

	^ 'MCP-Tests-CreateClassCommand'
]

{ #category : 'private' }
MCPCreateClassCommandTest >> removeGeneratedPackage [

	self withoutEpiceaDuring: [
		(self packageOrganizer hasPackage: self generatedPackageName)
			ifTrue: [
				self packageOrganizer removePackage:
					(self packageOrganizer packageNamed: self generatedPackageName) ] ]
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
MCPCreateClassCommandTest >> testCreatesClassAndReturnsResultObject [

	| result createdClass |
	result := self executeCommand: (MCPCreateClassCommand
			           className: 'MCPCreateClassCommandTestGenerated'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: nil
			           slots: nil
			           classSlots: nil).
	createdClass := self classNamed: 'MCPCreateClassCommandTestGenerated'.
	self assert: createdClass superclass equals: Object.
	self
		assert: createdClass packageName asString
		equals: self generatedPackageName.
	self
		assert: result classInfo className
		equals: 'MCPCreateClassCommandTestGenerated'.
	self
		assert: result asDictionary
		equals: result classInfo asDictionary
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testCreatesClassWithTagSlotsAndClassSlots [

	| createdClass result |
	result := self executeCommand: (MCPCreateClassCommand
			           className: 'MCPCreateClassCommandTestTagged'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: 'Generated'
			           slots: #( 'firstName' 'lastName' )
			           classSlots: #( 'defaultName' )).
	createdClass := self classNamed: 'MCPCreateClassCommandTestTagged'.
	self
		assert: (createdClass slots collect: #name as: Array)
		equals: #( #firstName #lastName ).
	self
		assert: (createdClass classSide slots collect: #name as: Array)
		equals: #( #defaultName ).
	self assert: createdClass packageTagName asString equals: 'Generated'.
	self assert: result classInfo tag equals: 'Generated'
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testCreatesClassWithTraitsClassTraitsSharedVariablesSharedPoolsAndLayout [

	| createdClass result |
	result := self executeCommand: (MCPCreateClassCommand
			           className: 'MCPCreateClassCommandTestConfigured'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: 'Configured'
			           slots: #( 'firstName' )
			           classSlots: #( 'defaultName' )
			           traits: #( 'TAbleToRotate' )
			           classTraits: #( 'TAbleToRotate classTrait' )
			           sharedVariables: #( 'AlphaShared' 'BetaShared' )
			           sharedPools: #( 'ChronologyConstants' )
			           layout: 'WeakLayout').
	createdClass := self classNamed:
		                'MCPCreateClassCommandTestConfigured'.
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
	self assert: result classInfo traitNames equals: #( 'TAbleToRotate' ).
	self
		assert: result classInfo classTraitNames
		equals: #( 'TAbleToRotate classTrait' ).
	self
		assert: result classInfo sharedVariableNames
		equals: #( 'AlphaShared' 'BetaShared' ).
	self
		assert: result classInfo sharedPoolNames
		equals: #( 'ChronologyConstants' ).
	self assert: result classInfo layoutClassName equals: 'WeakLayout'
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testExistingClassSignalsCommandError [

	| error |
	self executeCommand: (MCPCreateClassCommand
			 className: 'MCPCreateClassCommandTestGenerated'
			 superclassName: 'Object'
			 packageName: self generatedPackageName
			 tag: nil
			 slots: nil
			 classSlots: nil).
	error := self captureCommandError: [
		         (MCPCreateClassCommand
			          className: 'MCPCreateClassCommandTestGenerated'
			          superclassName: 'Object'
			          packageName: self generatedPackageName
			          tag: nil
			          slots: nil
			          classSlots: nil) execute ].
	self assert: error errorCode equals: #ClassAlreadyExists.
	self
		assert: (error structuredDetails at: #className)
		equals: 'MCPCreateClassCommandTestGenerated'
]

{ #category : 'tests' }
MCPCreateClassCommandTest >> testMissingSuperclassSignalsCommandError [

	| error |
	error := self captureCommandError: [
		         (MCPCreateClassCommand
			          className: 'MCPCreateClassCommandTestGenerated'
			          superclassName: 'DefinitelyMissingSuperclass'
			          packageName: self generatedPackageName
			          tag: nil
			          slots: nil
			          classSlots: nil) execute ].
	self assert: error errorCode equals: #SuperclassNotFound.
	self
		assert: (error structuredDetails at: #superclassName)
		equals: 'DefinitelyMissingSuperclass'
]
