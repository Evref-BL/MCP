Class {
	#name : 'MCPToolCreateClassTest',
	#superclass : 'TestCase',
	#instVars : [
		'tool'
	],
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolCreateClassTest >> argumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName [

	^ self
		  argumentsForClassName: aClassName
		  superclassName: aSuperclassName
		  packageName: aPackageName
		  tag: nil
		  slots: nil
		  classSlots: nil
]

{ #category : 'private' }
MCPToolCreateClassTest >> argumentsForClassName: aClassName superclassName: aSuperclassName packageName: aPackageName tag: aTag slots: someSlots classSlots: someClassSlots [

	| arguments |
	arguments := {
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
MCPToolCreateClassTest >> classNamed: aClassName [

	^ self class environment at: aClassName asSymbol
]

{ #category : 'private' }
MCPToolCreateClassTest >> createdClassNames [

	^ #( 'MCPToolCreateClassTestGenerated'
	     'MCPToolCreateClassTestTagged' 'MCPToolCreateClassTestClassSlots'
	     'MCPToolCreateClassTestTemporaryPackage' )
]

{ #category : 'private' }
MCPToolCreateClassTest >> generatedPackageName [

	^ 'MCP-Tests-CreateClass'
]

{ #category : 'private' }
MCPToolCreateClassTest >> removeClassNamed: aClassName [

	| classSymbol |
	classSymbol := aClassName asSymbol.
	(self class environment includesKey: classSymbol) ifTrue: [
		(self class environment at: classSymbol) removeFromSystem ]
]

{ #category : 'private' }
MCPToolCreateClassTest >> removeGeneratedPackage [

	(self packageOrganizer hasPackage: self generatedPackageName)
		ifTrue: [
			self packageOrganizer removePackage:
				(self packageOrganizer packageNamed: self generatedPackageName) ]
]

{ #category : 'running' }
MCPToolCreateClassTest >> setUp [

	super setUp.
	tool := MCPToolCreateClass new.
	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage
]

{ #category : 'running' }
MCPToolCreateClassTest >> tearDown [

	self createdClassNames do: [ :each | self removeClassNamed: each ].
	self removeGeneratedPackage.
	super tearDown
]

{ #category : 'tests' }
MCPToolCreateClassTest >> testCreatesAClass [

	| createdClass result |
	result := tool executeWithArguments: (self
			           argumentsForClassName: 'MCPToolCreateClassTestGenerated'
			           superclassName: 'Object'
			           packageName: self generatedPackageName).
	createdClass := self classNamed: 'MCPToolCreateClassTestGenerated'.
	self assert: createdClass superclass equals: Object.
	self
		assert: createdClass packageName asString
		equals: self generatedPackageName.
	self assert: createdClass slots isEmpty.
	self assert: (result first text includesSubstring:
			 'Created class MCPToolCreateClassTestGenerated < Object')
]

{ #category : 'tests' }
MCPToolCreateClassTest >> testCreatesAClassWithClassSlots [

	| createdClass result |
	result := tool executeWithArguments: (self
			           argumentsForClassName:
			           'MCPToolCreateClassTestClassSlots'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: nil
			           slots: nil
			           classSlots: #( 'defaultName' )).
	createdClass := self classNamed: 'MCPToolCreateClassTestClassSlots'.
	self
		assert: (createdClass classSide slots collect: #name as: Array)
		equals: #( #defaultName ).
	self assert: (result first text includesSubstring: '1 class slot')
]

{ #category : 'tests' }
MCPToolCreateClassTest >> testCreatesAClassWithSlotsAndTag [

	| createdClass result |
	result := tool executeWithArguments: (self
			           argumentsForClassName: 'MCPToolCreateClassTestTagged'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: 'Generated'
			           slots: #( 'firstName' 'lastName' )
			           classSlots: nil).
	createdClass := self classNamed: 'MCPToolCreateClassTestTagged'.
	self
		assert: (createdClass slots collect: #name as: Array)
		equals: #( #firstName #lastName ).
	self assert: createdClass packageTagName asString equals: 'Generated'.
	self
		assert: createdClass category asString
		equals: self generatedPackageName , '-Generated'.
	self assert:
		(result first text includesSubstring: '2 instance slots')
]

{ #category : 'tests' }
MCPToolCreateClassTest >> testEnsuresThePackageBeforeCreatingTheClass [

	| createdClass |
	tool executeWithArguments: (self
			 argumentsForClassName: 'MCPToolCreateClassTestTemporaryPackage'
			 superclassName: 'Object'
			 packageName: self generatedPackageName).
	createdClass := self classNamed:
		                'MCPToolCreateClassTestTemporaryPackage'.
	self assert:
		(self packageOrganizer hasPackage: self generatedPackageName).
	self
		assert: createdClass packageName asString
		equals: self generatedPackageName
]

{ #category : 'tests' }
MCPToolCreateClassTest >> testSignalsAnErrorWhenTheClassAlreadyExists [

	| arguments error |
	arguments := self
		             argumentsForClassName:
		             'MCPToolCreateClassTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	tool executeWithArguments: arguments.
	error := [
	         tool executeWithArguments: arguments.
	         nil ]
		         on: Error
		         do: [ :anError | anError ].
	self assert: error notNil.
	self assert: (error messageText includesSubstring: 'already exists')
]
