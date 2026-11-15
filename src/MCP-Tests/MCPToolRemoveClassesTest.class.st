"
Tests the class_remove tool.
"
Class {
	#name : 'MCPToolRemoveClassesTest',
	#superclass : 'MCPToolTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPToolRemoveClassesTest >> argumentsForClassName: aClassName [

	^ { (#class -> aClassName) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> argumentsForClassNames: someClassNames [

	^ { (#name -> someClassNames) } asDictionary
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> argumentsForClassNames: someClassNames force: aBoolean [

	^ {
		  (#name -> someClassNames).
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

	^ self ensureClassNamed: aClassName superclassName: aSuperclassName packageName: 'MCP-Tests'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> ensureClassNamed: aClassName superclassName: aSuperclassName packageName: aPackageName [

	| symbol superclass |
	symbol := aClassName asSymbol.
	(self class environment includesKey: symbol) ifTrue: [ ^ self ].
	superclass := self class environment at: aSuperclassName asSymbol.
	self withoutEpiceaDuring: [
			self packageOrganizer ensurePackage: aPackageName.
			(superclass << symbol)
				package: aPackageName;
				install ]
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> ensureMethodSource: aMethodSource onClassNamed: aClassName [

	self withoutEpiceaDuring: [ (self classNamed: aClassName) compile: aMethodSource classified: 'tests' ]
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> fixtureClassNames [
	"Removed in reverse order, so a subclass goes before its superclass."

	^ {
		  self simpleClassName.
		  self emptyParentClassName.
		  self emptyChildClassName.
		  self nonEmptyParentClassName.
		  self nonEmptyChildClassName.
		  self referencedClassName.
		  self secondReferencedClassName.
		  self senderClassName.
		  self mutualFirstClassName.
		  self mutualSecondClassName.
		  self packageCleanupClassName } asArray
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> fixturePrefix [

	^ self class name asString
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> howToProceed [
	"Force gets past Pharo's check from Pharo 12, where it signals a warning rather than an error."

	^ self refactoringsRefuseBreakingChanges
		  ifTrue: [ 'Change that first: force does not get past this check in this Pharo version.' ]
		  ifFalse: [ 'Change that first, or resend with force: true to remove anyway.' ]
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> missingClassName [

	^ self fixturePrefix , 'Missing'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> mutualFirstClassName [

	^ self fixturePrefix , 'MutualFirst'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> mutualSecondClassName [

	^ self fixturePrefix , 'MutualSecond'
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

	^ String streamContents: [ :stream | stream << 'useReferencedClass ^ ' << self referencedClassName << ' new' ]
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> referencedClassName [

	^ self fixturePrefix , 'Referenced'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> removeFixtureClasses [

	self fixtureClassNames reverseDo: [ :each | self removeClassNamed: each ].
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
	self ensureClassNamed: self emptyParentClassName superclassName: 'Object'.
	self ensureClassNamed: self emptyChildClassName superclassName: self emptyParentClassName.
	self ensureClassNamed: self nonEmptyParentClassName superclassName: 'Object'.
	self ensureClassNamed: self nonEmptyChildClassName superclassName: self nonEmptyParentClassName.
	self ensureClassNamed: self referencedClassName superclassName: 'Object'.
	self ensureClassNamed: self senderClassName superclassName: 'Object'.
	self ensureClassNamed: self packageCleanupClassName superclassName: 'Object' packageName: self packageCleanupPackageName.
	self ensureMethodSource: 'marker ^ 1' onClassNamed: self nonEmptyParentClassName.
	self ensureMethodSource: self referenceSenderMethodSource onClassNamed: self senderClassName
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> secondReferencedClassName [

	^ self fixturePrefix , 'ReferencedToo'
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
MCPToolRemoveClassesTest >> testAReferenceListStopsAtFiveMethods [
	"The text names the first five; method_reference_search lists them all."

	| result |
	1 to: 5 do: [ :index |
			self
				ensureMethodSource: ('refer{1} ^ {2}' format: {
							 index.
							 self referencedClassName })
				onClassNamed: self senderClassName ].
	result := self callToolWith: (self argumentsForClassNames: { self referencedClassName }).
	self assert: (((self errorFrom: result) at: #message) includesSubstring:
			 ('{1} is referred to by {2}>>refer1, {2}>>refer2, {2}>>refer3, {2}>>refer4, {2}>>refer5, and 1 more.' format: {
					  self referencedClassName.
					  self senderClassName }))
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testAnEmptyClassNamedWithItsSubclassReparentsNothing [
	"An empty class's subclasses are reparented to its superclass, but one asked for in the same call is removed."

	| data result |
	result := self callToolWith: (self argumentsForClassNames: {
				           self emptyParentClassName.
				           self emptyChildClassName }).
	data := self dataFrom: result.
	self deny: (self class environment includesKey: self emptyParentClassName asSymbol).
	self deny: (self class environment includesKey: self emptyChildClassName asSymbol).
	self assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ]) isEmpty.
	self deny: ((self textFrom: result) includesSubstring: 'Reparented')
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testClassesThatReferOnlyToEachOtherAreRemovedTogether [

	| result |
	self ensureClassNamed: self mutualFirstClassName superclassName: 'Object'.
	self ensureClassNamed: self mutualSecondClassName superclassName: 'Object'.
	self ensureMethodSource: ('other ^ {1}' format: { self mutualSecondClassName }) onClassNamed: self mutualFirstClassName.
	self ensureMethodSource: ('other ^ {1}' format: { self mutualFirstClassName }) onClassNamed: self mutualSecondClassName.
	result := self callToolWith: (self argumentsForClassNames: {
				           self mutualFirstClassName.
				           self mutualSecondClassName }).
	self deny: (result at: #isError ifAbsent: [ false ]) description: (self textFrom: result).
	self deny: (self class environment includesKey: self mutualFirstClassName asSymbol).
	self deny: (self class environment includesKey: self mutualSecondClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testForceRemovesNonEmptyClassAndReparentsSubclassesWithWarnings [

	| data result text |
	result := self callToolWith: (self argumentsForClassNames: { self nonEmptyParentClassName } force: true).
	self refactoringsRefuseBreakingChanges ifTrue: [
			self assert: (result at: #isError).
			self assert: (((self errorFrom: result) at: #message) endsWith: self howToProceed).
			^ self assert: (self class environment includesKey: self nonEmptyParentClassName asSymbol) ].
	data := self dataFrom: result.
	text := self textFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey: self nonEmptyParentClassName asSymbol).
	self assert: (self classNamed: self nonEmptyChildClassName) superclass name asString equals: 'Object'.
	self assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ]) equals: { self nonEmptyChildClassName } asArray.
	self assert: (self warningsFrom: result) asArray equals: { ('{1} is not empty and has subclasses: {2}.' format: {
				 self nonEmptyParentClassName.
				 self nonEmptyChildClassName }) }.
	self assert: text lines first equals: ('Force-removed class {1}. Reparented subclasses: {2}.' format: {
				 self nonEmptyParentClassName.
				 self nonEmptyChildClassName }).
	self deny: (text includesSubstring: 'reparentedSubclassNames')
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testForceRemovesReferencedClassAndReturnsWarnings [

	| error result |
	result := self callToolWith: (self argumentsForClassNames: { self referencedClassName } force: true).
	self refactoringsRefuseBreakingChanges ifTrue: [
			error := self errorFrom: result.
			self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
			self assert: ((error at: #message) endsWith: self howToProceed).
			^ self assert: (self class environment includesKey: self referencedClassName asSymbol) ].
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey: self referencedClassName asSymbol).
	self assert: ((self classNamed: self senderClassName) includesSelector: #useReferencedClass).
	self assert: (self warningsFrom: result) asArray equals: { ('{1} is referred to by {2}>>useReferencedClass.' format: {
				 self referencedClassName.
				 self senderClassName }) }
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testRefusalNamesReferencesAndSubclassesTogether [

	| error result |
	self
		ensureMethodSource: ('useNonEmptyParent ^ {1} new' format: { self nonEmptyParentClassName })
		onClassNamed: self senderClassName.
	result := self callToolWith: (self argumentsForClassNames: { self nonEmptyParentClassName }).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self
		assert: (error at: #message)
		equals:
			('Did not remove {1}. {1} is referred to by {3}>>useNonEmptyParent. {1} is not empty and has subclasses: {2}. {4}' format: {
					 self nonEmptyParentClassName.
					 self nonEmptyChildClassName.
					 self senderClassName.
					 self howToProceed })
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testRefusesAClassSideNameAndRemovesNothing [
	"Read as its class, Foo class would delete the whole class without a word. One such name refuses the call, before anything is looked up."

	| error result |
	result := self callToolWith: (self argumentsForClassNames: {
				           self simpleClassName.
				           (self simpleClassName , ' class') }).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassSideNamed'.
	self assert: (error at: #class) equals: self simpleClassName.
	self assert: (error at: #name) equals: self simpleClassName , ' class'.
	self assert: (error at: #message) equals: (String streamContents: [ :stream |
				 stream << self simpleClassName << ' class is the class side of ' << self simpleClassName
				 << ', and goes only with its class. Name ' << self simpleClassName
				 << ' to remove the class, or use method_remove with side class to remove class-side methods.' ]).
	self assert: (self class environment includesKey: self simpleClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testReturnsStructuredErrorWhenClassHasReferences [
	"Pharo's check decides, and the refusal names the method that refers to the class, offering force only where it gets past the check."

	| error result text |
	result := self callToolWith: (self argumentsForClassNames: { self referencedClassName }).
	error := self errorFrom: result.
	text := self textFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self assert: (error at: #classes) equals: { self referencedClassName } asArray.
	self assert: (error at: #message) equals: ('Did not remove {1}. {1} is referred to by {2}>>useReferencedClass. {3}' format: {
				 self referencedClassName.
				 self senderClassName.
				 self howToProceed }).
	self assert: (error at: #impactMessages) asArray equals: { ('{1} is referred to by {2}>>useReferencedClass.' format: {
				 self referencedClassName.
				 self senderClassName }) }.
	self assert: (error at: #forceSupported) equals: self refactoringsRefuseBreakingChanges not.
	#( 'RBRefactoring' 'NOT ' '<n>' 'Browse' ) do: [ :each | self deny: (text includesSubstring: each) ].
	self assert: (self class environment includesKey: self referencedClassName asSymbol)
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
	self assert: (error at: #errorClass) equals: 'MCPCommandError'.
	self assert: (error at: #errorCode) equals: 'ClassNotFound'.
	self assert: (error at: #class) equals: self missingClassName.
	self assert: (self class environment includesKey: self simpleClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testReturnsStructuredErrorWhenNonEmptyClassHasSubclasses [

	| error result |
	result := self callToolWith: (self argumentsForClassNames: { self nonEmptyParentClassName }).
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self assert: (error at: #classes) equals: { self nonEmptyParentClassName } asArray.
	self assert: (error at: #impactMessages) asArray equals: { ('{1} is not empty and has subclasses: {2}.' format: {
				 self nonEmptyParentClassName.
				 self nonEmptyChildClassName }) }.
	self assert: (self class environment includesKey: self nonEmptyParentClassName asSymbol).
	self assert: (self classNamed: self nonEmptyChildClassName) superclass name asString equals: self nonEmptyParentClassName
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testSafelyRemovesEmptyClassAndReparentsDirectSubclasses [

	| data result |
	result := self callToolWith: (self argumentsForClassNames: { self emptyParentClassName }).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey: self emptyParentClassName asSymbol).
	self assert: (self classNamed: self emptyChildClassName) superclass name asString equals: 'Object'.
	self assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ]) equals: { self emptyChildClassName } asArray
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testSafelyRemovesSimpleClass [

	| data result |
	result := self callToolWith: (self argumentsForClassNames: self batchClassNames).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey: self simpleClassName asSymbol).
	self deny: (self class environment includesKey: self packageCleanupClassName asSymbol).
	self deny: (self packageOrganizer hasPackage: self packageCleanupPackageName).
	self assert: (data at: #removedPackageNames ifAbsent: [ #(  ) ]) equals: { self packageCleanupPackageName } asArray
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testToolRequiresClassNameInSchema [

	| propertyNames schema |
	schema := MCPToolRemoveClasses new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: schema required asSet equals: #( 'name' ) asSet.
	self assert: (propertyNames includes: 'force')
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testTwoReferencedClassesAreEachNamed [

	| error result |
	self ensureClassNamed: self secondReferencedClassName superclassName: 'Object'.
	self
		ensureMethodSource: ('useReferencedToo ^ {1} new' format: { self secondReferencedClassName })
		onClassNamed: self senderClassName.
	result := self callToolWith: (self argumentsForClassNames: {
				           self referencedClassName.
				           self secondReferencedClassName }).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self
		assert: (error at: #message)
		equals:
			('Did not remove {1}, {2}. {1} is referred to by {3}>>useReferencedClass. {2} is referred to by {3}>>useReferencedToo. {4}'
				 format: {
						 self referencedClassName.
						 self secondReferencedClassName.
						 self senderClassName.
						 self howToProceed }).
	self assert: (self class environment includesKey: self referencedClassName asSymbol).
	self assert: (self class environment includesKey: self secondReferencedClassName asSymbol)
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> textFrom: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private - calling' }
MCPToolRemoveClassesTest >> toolName [

	^ 'class_remove'
]
