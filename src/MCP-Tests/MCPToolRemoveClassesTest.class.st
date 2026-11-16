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
MCPToolRemoveClassesTest >> emptyGrandchildClassName [

	^ self fixturePrefix , 'EmptyGrandchild'
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
		  self packageCleanupClassName.
		  self simpleChildClassName.
		  self emptyGrandchildClassName } asArray
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
MCPToolRemoveClassesTest >> simpleChildClassName [

	^ self fixturePrefix , 'SimpleChild'
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
MCPToolRemoveClassesTest >> testAForcedRemovalSaysWhichClassTheSubclassesNowInheritFrom [
	"Each subclass moved up is named with the class it inherits from now, so that a class made again under the removed name is not taken to bring it back. What force went past is said as it stands once the classes are gone."

	| result |
	result := self callToolWith: (self
			           argumentsForClassNames: {
					           self emptyParentClassName.
					           self nonEmptyParentClassName }
			           force: true).
	self refactoringsRefuseBreakingChanges ifTrue: [
			self assert: (result at: #isError).
			^ self assert: ((self errorFrom: result) at: #errorCode) equals: 'ClassRemovalBlocked' ].
	self assert: (self textFrom: result) lines equals: {
			('Force-removed 2 classes: {1}, {2}. Their method {2}>>marker was removed with them. {3} and {4} now inherit from Object.'
				 format: {
						 self emptyParentClassName.
						 self nonEmptyParentClassName.
						 self emptyChildClassName.
						 self nonEmptyChildClassName }).
			('Warning: {1} lost what it inherited from {2}.' format: {
					 self nonEmptyChildClassName.
					 self nonEmptyParentClassName }) }
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testARefusalNamesWhatBlocksEachClass [
	"Each class asked for gets its facts, references then subclasses, and a long list of references stops at five, in its own words rather than Pharo's check. Force is offered where it gets past the check. Nothing is removed."

	| error result text |
	1 to: 5 do: [ :index |
			self
				ensureMethodSource: ('refer{1} ^ {2}' format: {
							 index.
							 self referencedClassName })
				onClassNamed: self senderClassName ].
	self
		ensureMethodSource: ('useNonEmptyParent ^ {1} new' format: { self nonEmptyParentClassName })
		onClassNamed: self senderClassName.
	result := self callToolWith: (self argumentsForClassNames: {
				           self nonEmptyParentClassName.
				           self referencedClassName }).
	error := self errorFrom: result.
	text := self textFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self
		assert: (error at: #message)
		equals:
			('Did not remove {1}, {3}. {1} is referred to by {4}>>useNonEmptyParent. {1} is not empty and has subclasses: {2}. {3} is referred to by {4}>>refer1, {4}>>refer2, {4}>>refer3, {4}>>refer4, {4}>>refer5, and 1 more. {5}'
				 format: {
						 self nonEmptyParentClassName.
						 self nonEmptyChildClassName.
						 self referencedClassName.
						 self senderClassName.
						 self howToProceed }).
	self assert: (error at: #impactMessages) size equals: 3.
	self assert: (self class environment includesKey: self referencedClassName asSymbol).
	self assert: (self classNamed: self nonEmptyChildClassName) superclass name asString equals: self nonEmptyParentClassName.
	self assert: (error at: #classes) equals: {
			self nonEmptyParentClassName.
			self referencedClassName } asArray.
	self assert: (error at: #howToProceed) equals: self howToProceed.
	self assert: (error at: #forceSupported) equals: self refactoringsRefuseBreakingChanges not.
	#( 'RBRefactoring' 'NOT ' '<n>' 'Browse' ) do: [ :each | self deny: (text includesSubstring: each) ]
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
	self deny: ((self textFrom: result) includesSubstring: 'inherit')
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
MCPToolRemoveClassesTest >> testEachSuperclassTheSubclassesMoveToIsNamed [
	"Subclasses that move to different classes are named class by class, in the order of the classes removed."

	| result |
	self ensureClassNamed: self simpleChildClassName superclassName: self simpleClassName.
	self ensureClassNamed: self emptyGrandchildClassName superclassName: self emptyChildClassName.
	result := self callToolWith: (self argumentsForClassNames: {
				           self simpleClassName.
				           self emptyChildClassName }).
	self deny: (result at: #isError ifAbsent: [ false ]).
	self assert: (self classNamed: self emptyGrandchildClassName) superclass name asString equals: self emptyParentClassName.
	self
		assert: (self textFrom: result)
		equals: ('Removed 2 classes: {1}, {2}. {3} now inherits from Object. {4} now inherits from {5}.' format: {
					 self simpleClassName.
					 self emptyChildClassName.
					 self simpleChildClassName.
					 self emptyGrandchildClassName.
					 self emptyParentClassName })
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testForceRemovesWhatBlocksAndWarnsOfIt [
	"Force goes past Pharo's check from Pharo 12: the classes go, the subclasses of a non-empty one move to its superclass, and the warnings say what blocked, as it stands once the classes are gone. Before 12 it cannot, and nothing is removed."

	| data result |
	result := self callToolWith: (self
			           argumentsForClassNames: {
					           self nonEmptyParentClassName.
					           self referencedClassName }
			           force: true).
	self refactoringsRefuseBreakingChanges ifTrue: [
			self assert: (result at: #isError).
			self assert: ((self errorFrom: result) at: #errorCode) equals: 'ClassRemovalBlocked'.
			self assert: (((self errorFrom: result) at: #message) endsWith: self howToProceed).
			^ self assert: (self class environment includesKey: self referencedClassName asSymbol) ].
	data := self dataFrom: result.
	self deny: (self class environment includesKey: self nonEmptyParentClassName asSymbol).
	self deny: (self class environment includesKey: self referencedClassName asSymbol).
	self assert: ((self classNamed: self senderClassName) includesSelector: #useReferencedClass).
	self assert: (self classNamed: self nonEmptyChildClassName) superclass name asString equals: 'Object'.
	self assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ]) equals: { self nonEmptyChildClassName } asArray.
	self assert: (self warningsFrom: result) asArray equals: {
			('{1} lost what it inherited from {2}.' format: {
					 self nonEmptyChildClassName.
					 self nonEmptyParentClassName }).
			('{1} is referred to by {2}>>useReferencedClass.' format: {
					 self referencedClassName.
					 self senderClassName }) }.
	self assert: ((self textFrom: result) lines first beginsWith: 'Force-removed ').
	self deny: ((self textFrom: result) includesSubstring: 'reparentedSubclassNames')
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testManyMethodsThatGoWithTheClassesAreCounted [
	"Past ten methods, the answer says how many went, without naming them: the count is what tells a caller it removed more than it meant to."

	1 to: 6 do: [ :index | self ensureMethodSource: ('first{1} ^ 1' format: { index }) onClassNamed: self simpleClassName ].
	1 to: 5 do: [ :index | self ensureMethodSource: ('second{1} ^ 1' format: { index }) onClassNamed: self packageCleanupClassName ].
	self
		assert: (self textFrom: (self callToolWith: (self argumentsForClassNames: self batchClassNames)))
		equals: ('Removed 2 classes: {1}, {2}. Their 11 methods were removed with them. Removed packages: {3}.' format: {
					 self simpleClassName.
					 self packageCleanupClassName.
					 self packageCleanupPackageName })
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
MCPToolRemoveClassesTest >> testSafelyRemovesEmptyClassAndReparentsDirectSubclasses [

	| data result |
	result := self callToolWith: (self argumentsForClassNames: { self emptyParentClassName }).
	data := self dataFrom: result.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey: self emptyParentClassName asSymbol).
	self assert: (self classNamed: self emptyChildClassName) superclass name asString equals: 'Object'.
	self assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ]) equals: { self emptyChildClassName } asArray.
	self assert: (self textFrom: result) equals: ('Removed class {1}. {2} now inherits from Object.' format: {
				 self emptyParentClassName.
				 self emptyChildClassName })
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
MCPToolRemoveClassesTest >> testTheMethodsThatGoWithTheClassesAreSaid [
	"Removing a class removes its methods, on both sides, which method_remove would have named one by one. The answer names them when there are few, each as Pharo writes it."

	self ensureMethodSource: 'beta ^ 2' onClassNamed: self simpleClassName.
	self ensureMethodSource: 'alpha ^ 1' onClassNamed: self simpleClassName.
	self withoutEpiceaDuring: [ (self classNamed: self simpleClassName) classSide compile: 'make ^ self new' classified: 'tests' ].
	self ensureMethodSource: 'gamma ^ 3' onClassNamed: self packageCleanupClassName.
	self
		assert: (self textFrom: (self callToolWith: (self argumentsForClassNames: { self simpleClassName })))
		equals: ('Removed class {1}. Its 3 methods were removed with it: {1}>>alpha, {1}>>beta and {1} class>>make.' format:
				 { self simpleClassName }).
	self
		assert: (self textFrom: (self callToolWith: (self argumentsForClassNames: { self packageCleanupClassName })))
		equals: ('Removed class {1}. Its method {1}>>gamma was removed with it. Removed packages: {2}.' format: {
					 self packageCleanupClassName.
					 self packageCleanupPackageName })
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testToolRequiresClassNameInSchema [

	| propertyNames schema |
	schema := MCPToolRemoveClasses new inputSchema.
	propertyNames := schema properties collect: [ :each | each name ].
	self assert: schema required asSet equals: #( 'name' ) asSet.
	self assert: (propertyNames includes: 'force')
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> textFrom: aResult [

	^ (aResult at: #content) first at: #text
]

{ #category : 'private - calling' }
MCPToolRemoveClassesTest >> toolName [

	^ 'class_remove'
]
