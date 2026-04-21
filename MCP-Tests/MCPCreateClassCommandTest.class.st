Class {
	#name : 'MCPCreateClassCommandTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests-Internal',
	#package : 'MCP-Tests',
	#tag : 'Internal'
}

{ #category : 'private' }
MCPCreateClassCommandTest >> captureCommandError: aBlock [

	^ [
	  aBlock value.
	  self fail: 'Expected MCPCommandError' ]
		  on: MCPCommandError
		  do: [ :error | error ]
]

{ #category : 'private' }
MCPCreateClassCommandTest >> classNamed: aClassName [

	^ Smalltalk globals at: aClassName asSymbol
]

{ #category : 'private' }
MCPCreateClassCommandTest >> createdClassNames [

	^ #( 'MCPCreateClassCommandTestGenerated'
	     'MCPCreateClassCommandTestTagged'
	     'MCPCreateClassCommandTestClassSlots'
	     'MCPCreateClassCommandTestTemporaryPackage' )
]

{ #category : 'private' }
MCPCreateClassCommandTest >> generatedPackageName [

	^ 'MCP-Tests-CreateClassCommand'
]

{ #category : 'private' }
MCPCreateClassCommandTest >> removeClassNamed: aClassName [

	| classSymbol |
	classSymbol := aClassName asSymbol.
	(Smalltalk globals includesKey: classSymbol) ifTrue: [
		(Smalltalk globals at: classSymbol) removeFromSystem ]
]

{ #category : 'private' }
MCPCreateClassCommandTest >> removeGeneratedPackage [

	(self packageOrganizer hasPackage: self generatedPackageName)
		ifTrue: [
			self packageOrganizer removePackage:
				(self packageOrganizer packageNamed: self generatedPackageName) ]
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
	result := (MCPCreateClassCommand
		           className: 'MCPCreateClassCommandTestGenerated'
		           superclassName: 'Object'
		           packageName: self generatedPackageName
		           tag: nil
		           slots: nil
		           classSlots: nil) execute.
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
	result := (MCPCreateClassCommand
		           className: 'MCPCreateClassCommandTestTagged'
		           superclassName: 'Object'
		           packageName: self generatedPackageName
		           tag: 'Generated'
		           slots: #( 'firstName' 'lastName' )
		           classSlots: #( 'defaultName' )) execute.
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
MCPCreateClassCommandTest >> testExistingClassSignalsCommandError [

	| error |
	(MCPCreateClassCommand
		 className: 'MCPCreateClassCommandTestGenerated'
		 superclassName: 'Object'
		 packageName: self generatedPackageName
		 tag: nil
		 slots: nil
		 classSlots: nil) execute.
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
