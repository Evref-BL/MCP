Class {
	#name : 'MCPToolRemoveClassTest',
	#superclass : 'TestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRemoveClassTest >> argumentsForClassName: aClassName [

	^ { (#className -> aClassName) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClassTest >> callToolWith: someArguments [

	^ MCP new rpcToolCall: 'pharo-remove-class' withParams: someArguments
]

{ #category : 'private' }
MCPToolRemoveClassTest >> classNamed: aClassName [

	^ self class environment at: aClassName asSymbol
]

{ #category : 'private' }
MCPToolRemoveClassTest >> dataFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #data
]

{ #category : 'private' }
MCPToolRemoveClassTest >> emptyChildClassName [

	^ self fixturePrefix , 'EmptyChild'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> emptyParentClassName [

	^ self fixturePrefix , 'EmptyParent'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> ensureClassNamed: aClassName superclassName: aSuperclassName [

	| symbol superclass |
	symbol := aClassName asSymbol.
	(self class environment includesKey: symbol) ifTrue: [ ^ self ].
	superclass := self class environment at: aSuperclassName asSymbol.
	(superclass << symbol)
		package: 'MCP-Tests';
		install
]

{ #category : 'private' }
MCPToolRemoveClassTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	(self classNamed: aClassName)
		compile: aMethodSource
		classified: 'tests'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> errorFrom: aResult [

	^ (self structuredContentFrom: aResult) at: #error
]

{ #category : 'private' }
MCPToolRemoveClassTest >> fixtureClassNames [

	^ {
		  self simpleClassName.
		  self emptyParentClassName.
		  self emptyChildClassName.
		  self nonEmptyParentClassName.
		  self nonEmptyChildClassName.
		  self referencedClassName.
		  self senderClassName } asArray
]

{ #category : 'private' }
MCPToolRemoveClassTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPToolRemoveClassTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> nonEmptyChildClassName [

	^ self fixturePrefix , 'NonEmptyChild'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> nonEmptyParentClassName [

	^ self fixturePrefix , 'NonEmptyParent'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> referenceSenderMethodSource [

	^ 'useReferencedClass ^ ' , self referencedClassName , ' new'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> referencedClassName [

	^ self fixturePrefix , 'Referenced'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> removeClassNamed: aClassName [

	| symbol |
	symbol := aClassName asSymbol.
	(self class environment includesKey: symbol) ifTrue: [
		(self class environment at: symbol) removeFromSystem ]
]

{ #category : 'private' }
MCPToolRemoveClassTest >> restoreFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ].
	self ensureClassNamed: self simpleClassName superclassName: 'Object'.
	self
		ensureClassNamed: self emptyParentClassName
		superclassName: 'Object'.
	self
		ensureClassNamed: self emptyChildClassName
		superclassName: self emptyParentClassName.
	self
		ensureClassNamed: self nonEmptyParentClassName
		superclassName: 'Object'.
	self
		ensureClassNamed: self nonEmptyChildClassName
		superclassName: self nonEmptyParentClassName.
	self
		ensureClassNamed: self referencedClassName
		superclassName: 'Object'.
	self ensureClassNamed: self senderClassName superclassName: 'Object'.
	self
		ensureMethodSource: 'marker ^ 1'
		onClassNamed: self nonEmptyParentClassName.
	self
		ensureMethodSource: self referenceSenderMethodSource
		onClassNamed: self senderClassName
]

{ #category : 'private' }
MCPToolRemoveClassTest >> senderClassName [

	^ self fixturePrefix , 'Sender'
]

{ #category : 'running' }
MCPToolRemoveClassTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'private' }
MCPToolRemoveClassTest >> simpleClassName [

	^ self fixturePrefix , 'Simple'
]

{ #category : 'private' }
MCPToolRemoveClassTest >> structuredContentFrom: aResult [

	^ aResult at: #structuredContent
]

{ #category : 'running' }
MCPToolRemoveClassTest >> tearDown [

	self restoreFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testReturnsStructuredErrorWhenClassHasReferences [

	| error result structured |
	result := self callToolWith:
		          (self argumentsForClassName: self referencedClassName).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #className) equals: self referencedClassName.
	self assert:
		(self class environment includesKey:
			 self referencedClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith:
		          (self argumentsForClassName: self missingClassName).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: self missingClassName
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testReturnsStructuredErrorWhenNonEmptyClassHasSubclasses [

	| error result structured |
	result := self callToolWith:
		          (self argumentsForClassName: self nonEmptyParentClassName).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #className)
		equals: self nonEmptyParentClassName.
	self assert: (self class environment includesKey:
			 self nonEmptyParentClassName asSymbol).
	self
		assert:
			(self classNamed: self nonEmptyChildClassName) superclass name
				asString
		equals: self nonEmptyParentClassName
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testSafelyRemovesEmptyClassAndReparentsDirectSubclasses [

	| data result |
	result := self callToolWith:
		          (self argumentsForClassName: self emptyParentClassName).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey:
			 self emptyParentClassName asSymbol).
	self
		assert:
		(self classNamed: self emptyChildClassName) superclass name asString
		equals: 'Object'.
	self assert: (data at: #wasEmpty).
	self
		assert: (data at: #subclassNames)
		equals: { self emptyChildClassName } asArray.
	self
		assert: (data at: #reparentedSubclassNames)
		equals: { self emptyChildClassName } asArray.
	self assert: (data at: #reparentedToSuperclassName) equals: 'Object'
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testSafelyRemovesSimpleClass [

	| data result |
	result := self callToolWith:
		          (self argumentsForClassName: self simpleClassName).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(self class environment includesKey: self simpleClassName asSymbol).
	self assert: (data at: #className) equals: self simpleClassName.
	self assert: (data at: #wasEmpty).
	self assert: (data at: #subclassNames) isEmpty.
	self assert: (data at: #reparentedSubclassNames) isEmpty
]

{ #category : 'tests' }
MCPToolRemoveClassTest >> testToolRequiresClassNameInSchema [

	self
		assert: MCPToolRemoveClass new inputSchema required asSet
		equals: #( 'className' ) asSet
]
