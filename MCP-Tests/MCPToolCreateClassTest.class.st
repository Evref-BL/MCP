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
MCPToolCreateClassTest >> dataFromResult: aResult [

	^ aResult structuredContent at: #data
]

{ #category : 'private' }
MCPToolCreateClassTest >> errorFromResult: aResult [

	^ aResult structuredContent at: #error
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

	| createdClass data result |
	result := tool executeWithArguments: (self
			           argumentsForClassName: 'MCPToolCreateClassTestGenerated'
			           superclassName: 'Object'
			           packageName: self generatedPackageName).
	data := self dataFromResult: result.
	createdClass := self classNamed: 'MCPToolCreateClassTestGenerated'.
	self assert: createdClass superclass equals: Object.
	self
		assert: createdClass packageName asString
		equals: self generatedPackageName.
	self assert: createdClass slots isEmpty.
	self
		assert: (data at: #className)
		equals: 'MCPToolCreateClassTestGenerated'.
	self assert: (data at: #superclassName) equals: 'Object'
]

{ #category : 'tests' }
MCPToolCreateClassTest >> testCreatesAClassWithClassSlots [

	| createdClass data result |
	result := tool executeWithArguments: (self
			           argumentsForClassName:
			           'MCPToolCreateClassTestClassSlots'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: nil
			           slots: nil
			           classSlots: #( 'defaultName' )).
	data := self dataFromResult: result.
	createdClass := self classNamed: 'MCPToolCreateClassTestClassSlots'.
	self
		assert: (createdClass classSide slots collect: #name as: Array)
		equals: #( #defaultName ).
	self assert: (data at: #classSlotNames) equals: #( 'defaultName' )
]

{ #category : 'tests' }
MCPToolCreateClassTest >> testCreatesAClassWithSlotsAndTag [

	| createdClass data result |
	result := tool executeWithArguments: (self
			           argumentsForClassName: 'MCPToolCreateClassTestTagged'
			           superclassName: 'Object'
			           packageName: self generatedPackageName
			           tag: 'Generated'
			           slots: #( 'firstName' 'lastName' )
			           classSlots: nil).
	data := self dataFromResult: result.
	createdClass := self classNamed: 'MCPToolCreateClassTestTagged'.
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

	| arguments result |
	arguments := self
		             argumentsForClassName:
		             'MCPToolCreateClassTestGenerated'
		             superclassName: 'Object'
		             packageName: self generatedPackageName.
	tool executeWithArguments: arguments.
	result := tool executeWithArguments: arguments.
	self assert: result isError.
	self
		assert: ((self errorFromResult: result) at: #message)
		equals: 'Class MCPToolCreateClassTestGenerated already exists.'
]
