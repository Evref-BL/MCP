"
Tests the class_remove tool.
"
Class {
	#name : 'MCPToolRemoveClassesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests-Tools',
	#package : 'MCP-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
MCPToolRemoveClassesTest >> argumentsForClassName: aClassName [

	^ { (#className -> aClassName) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> argumentsForClassNames: someClassNames [

	^ { (#classNames -> someClassNames) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> argumentsForClassNames: someClassNames force: aBoolean [

	^ {
		  (#classNames -> someClassNames).
		  (#force -> aBoolean) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> batchClassNames [

	^ {
		  self simpleClassName.
		  self packageCleanupClassName } asArray
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> emptyChildClassName [

	^ self fixturePrefix , 'EmptyChild'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> emptyParentClassName [

	^ self fixturePrefix , 'EmptyParent'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> ensureClassNamed: aClassName superclassName: aSuperclassName [

	^ self
		  ensureClassNamed: aClassName
		  superclassName: aSuperclassName
		  packageName: 'MCP-Tests'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> ensureClassNamed: aClassName superclassName: aSuperclassName packageName: aPackageName [

	| symbol superclass |
	symbol := aClassName asSymbol.
	(self class environment includesKey: symbol) ifTrue: [ ^ self ].
	superclass := self class environment at: aSuperclassName asSymbol.
	self withoutEpiceaDuring: [
			(superclass << symbol)
				package: aPackageName;
				install ]
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [
			(self classNamed: aClassName)
				compile: aMethodSource
				classified: 'tests' ]
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> fixtureClassNames [

	^ {
		  self simpleClassName.
		  self emptyParentClassName.
		  self emptyChildClassName.
		  self nonEmptyParentClassName.
		  self nonEmptyChildClassName.
		  self referencedClassName.
		  self senderClassName.
		  self packageCleanupClassName } asArray
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> nonEmptyChildClassName [

	^ self fixturePrefix , 'NonEmptyChild'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> nonEmptyParentClassName [

	^ self fixturePrefix , 'NonEmptyParent'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> packageCleanupClassName [

	^ self fixturePrefix , 'PackageCleanup'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> packageCleanupPackageName [

	^ self fixturePrefix , '-PackageCleanup'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> referenceSenderMethodSource [

	^ 'useReferencedClass ^ ' , self referencedClassName , ' new'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> referencedClassName [

	^ self fixturePrefix , 'Referenced'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each |
		self removeClassNamed: each ].
	self removePackageNamed: self packageCleanupPackageName
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> removedClassesFrom: aResult [

	^ (self dataFrom: aResult) at: #removedClasses
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> restoreFixtureClasses [

	self removeFixtureClasses.
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
		ensureClassNamed: self packageCleanupClassName
		superclassName: 'Object'
		packageName: self packageCleanupPackageName.
	self
		ensureMethodSource: 'marker ^ 1'
		onClassNamed: self nonEmptyParentClassName.
	self
		ensureMethodSource: self referenceSenderMethodSource
		onClassNamed: self senderClassName
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> senderClassName [

	^ self fixturePrefix , 'Sender'
]

{ #category : 'running' }
MCPToolRemoveClassesTest >> setUp [

	super setUp.
	self restoreFixtureClasses
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> simpleClassName [

	^ self fixturePrefix , 'Simple'
]

{ #category : 'running' }
MCPToolRemoveClassesTest >> tearDown [

	self removeFixtureClasses.
	super tearDown
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testForceRemovesNonEmptyClassAndReparentsSubclassesWithWarnings [

	| data result structured warnings |
	result := self callToolWith: (self
			           argumentsForClassNames: { self nonEmptyParentClassName }
			           force: true).
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	warnings := structured at: #warnings.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey:
			 self nonEmptyParentClassName asSymbol).
	self
		assert:
			(self classNamed: self nonEmptyChildClassName) superclass name
				asString
		equals: 'Object'.
	self
		assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ])
		equals: { self nonEmptyChildClassName } asArray.
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: self nonEmptyParentClassName)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testForceRemovesReferencedClassAndReturnsWarnings [

	| result structured warnings |
	result := self callToolWith:
		          (self
			           argumentsForClassNames: { self referencedClassName }
			           force: true).
	structured := self structuredContentFrom: result.
	warnings := structured at: #warnings.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(self class environment includesKey:
			 self referencedClassName asSymbol).
	self assert:
		((self classNamed: self senderClassName) includesSelector:
			 #useReferencedClass).
	self assert: warnings size equals: 1.
	self assert:
		(warnings first includesSubstring: self referencedClassName)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testReturnsStructuredErrorWhenClassHasReferences [

	| error result structured |
	result := self callToolWith:
		          (self argumentsForClassNames: { self referencedClassName }).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #classNames)
		equals: { self referencedClassName } asArray.
	self assert:
		(self class environment includesKey:
			 self referencedClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testReturnsStructuredErrorWhenClassIsMissing [

	| error result structured |
	result := self callToolWith: (self argumentsForClassNames: {
				           self simpleClassName.
				           self missingClassName }).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #className) equals: self missingClassName.
	self assert:
		(self class environment includesKey: self simpleClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testReturnsStructuredErrorWhenNonEmptyClassHasSubclasses [

	| error result structured |
	result := self callToolWith:
		          (self argumentsForClassNames:
			           { self nonEmptyParentClassName }).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (structured at: #status) equals: 'error'.
	self
		assert: (error at: #classNames)
		equals: { self nonEmptyParentClassName } asArray.
	self assert: (self class environment includesKey:
			 self nonEmptyParentClassName asSymbol).
	self
		assert:
			(self classNamed: self nonEmptyChildClassName) superclass name
				asString
		equals: self nonEmptyParentClassName
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testSafelyRemovesEmptyClassAndReparentsDirectSubclasses [

	| data result |
	result := self callToolWith:
		          (self argumentsForClassNames:
			           { self emptyParentClassName }).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey:
			 self emptyParentClassName asSymbol).
	self
		assert:
		(self classNamed: self emptyChildClassName) superclass name asString
		equals: 'Object'.
	self
		assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ])
		equals: { self emptyChildClassName } asArray
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testSafelyRemovesSimpleClass [

	| data result |
	result := self callToolWith:
		          (self argumentsForClassNames: self batchClassNames).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny:
		(self class environment includesKey: self simpleClassName asSymbol).
	self deny: (self class environment includesKey:
			 self packageCleanupClassName asSymbol).
	self deny:
		(PackageOrganizer default hasPackage: self packageCleanupPackageName).
	self
		assert: (data at: #removedPackageNames ifAbsent: [ #(  ) ])
		equals: { self packageCleanupPackageName } asArray
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testToolRequiresClassNameInSchema [

	| propertyNames schema |
	schema := MCPToolRemoveClasses new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: schema required asSet equals: #( 'classNames' ) asSet.
	self assert: (propertyNames includes: 'force')
]

{ #category : 'private - calling' }
MCPToolRemoveClassesTest >> toolName [

	^ 'class_remove'
]
