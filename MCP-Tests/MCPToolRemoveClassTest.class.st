Class {
	#name : 'MCPToolRemoveClassTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRemoveClassTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'pharo-remove-class' withParams: someArguments
]

{ #category : 'private' }
MCPToolRemoveClassTest >> childClassName [

	^ 'MCPToolRemoveClassTestChild'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> createClassNamed: aClassName superclassName: aSuperclassName tag: aTag slots: someSlots classSlots: someClassSlots [

	| builder createdClass |
	self packageOrganizer ensurePackage: self generatedPackageName.
	builder := (self class environment at: aSuperclassName asSymbol)
	           << aClassName asSymbol.
	builder package: self generatedPackageName.
	aTag ifNotNil: [ builder tag: aTag ].
	someSlots ifNotNil: [
		builder slots: (someSlots collect: [ :each | each asSymbol ]) ].
	someClassSlots ifNotNil: [
		builder classSlots:
			(someClassSlots collect: [ :each | each asSymbol ]) ].
	createdClass := builder install.
	^ createdClass
]

{ #category : 'private' }
MCPToolRemoveClassTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolRemoveClassTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolRemoveClassTest >> generatedPackageName [

	^ 'MCP-Tests-RemoveClass'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> parentClassName [

	^ 'MCPToolRemoveClassTestParent'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> removableClassName [

	^ 'MCPToolRemoveClassTestRemovable'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> removeClassNamed: aClassName [

	| classSymbol |
	classSymbol := aClassName asSymbol.
	(self class environment includesKey: classSymbol) ifTrue: [
		(self class environment at: classSymbol) removeFromSystem ]
]

{ #category : 'private' }
MCPToolRemoveClassTest >> removeGeneratedPackage [

	(self packageOrganizer hasPackage: self generatedPackageName)
		ifTrue: [
			self packageOrganizer removePackage:
				(self packageOrganizer packageNamed: self generatedPackageName) ]
]

{ #category : 'running' }
MCPToolRemoveClassTest >> setUp [

	super setUp.
	self removeClassNamed: self childClassName.
	self removeClassNamed: self parentClassName.
	self removeClassNamed: self removableClassName.
	self removeGeneratedPackage
]

{ #category : 'private' }
MCPToolRemoveClassTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolRemoveClassTest >> tearDown [

	self removeClassNamed: self childClassName.
	self removeClassNamed: self parentClassName.
	self removeClassNamed: self removableClassName.
	self removeGeneratedPackage.
	super tearDown
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testRejectsRemovalWhenClassHasSubclasses [

	| error result structured |
	self
		createClassNamed: self parentClassName
		superclassName: 'Object'
		tag: nil
		slots: nil
		classSlots: nil.
	self
		createClassNamed: self childClassName
		superclassName: self parentClassName
		tag: nil
		slots: nil
		classSlots: nil.
	result := self callToolWith:
		          { (#className -> self parentClassName) } asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'ClassHasSubclasses'.
	self assert:
		((error at: #subclassNames) includes: self childClassName).
	self assert:
		(self class environment includesKey: self parentClassName asSymbol).
	self assert:
		(self class environment includesKey: self childClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testRemovesClassAndReturnsMetadata [

	| data result |
	self
		createClassNamed: self removableClassName
		superclassName: 'Object'
		tag: 'Generated'
		slots: #( 'firstName' 'lastName' )
		classSlots: #( 'defaultName' ).
	result := self callToolWith:
		          { (#className -> self removableClassName) } asDictionary.
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(self class environment includesKey:
			 self removableClassName asSymbol).
	self assert: (data at: #className) equals: self removableClassName.
	self assert: (data at: #superclassName) equals: 'Object'.
	self
		assert: (data at: #packageName)
		equals: self generatedPackageName.
	self assert: (data at: #tag) equals: 'Generated'.
	self
		assert: (data at: #instanceSlotNames)
		equals: #( 'firstName' 'lastName' ).
	self assert: (data at: #classSlotNames) equals: #( 'defaultName' ).
	self assert: (data at: #subclassNames) equals: #(  )
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith:
		          { (#className -> 'MCPToolRemoveClassTestMissing') }
			          asDictionary.
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'ClassNotFound'.
	self
		assert: (error at: #className)
		equals: 'MCPToolRemoveClassTestMissing'
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testToolRequiresClassNameInSchema [

	self
		assert: MCPToolRemoveClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]
