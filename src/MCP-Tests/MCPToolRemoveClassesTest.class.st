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
MCPToolRemoveClassesTest >> ensureTraitNamed: aTraitName usedByClassNamed: aClassName [

	self withoutEpiceaDuring: [
			| trait |
			trait := (Trait << aTraitName asSymbol)
				         package: 'MCP-Tests';
				         install.
			trait compile: 'usedMarker ^ 1' classified: 'tests'.
			(Object << aClassName asSymbol)
				traits: trait;
				package: 'MCP-Tests';
				install ]
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> fixtureClassNames [
	"Removed in reverse order, so a trait's user goes before the trait."

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
		  self selfReferencedClassName.
		  self usedTraitName.
		  self traitUserClassName.
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
MCPToolRemoveClassesTest >> selfReferencedClassName [

	^ self fixturePrefix , 'SelfReferenced'
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
MCPToolRemoveClassesTest >> testAClassReferencedOnlyFromItsOwnClassSideIsNeverRefusedInPharosWords [
	"Pharo 12 and 13 count a class-side method of the class itself as a reference, and 14 does not. Either way the answer is the image's: removed, or refused naming that method."

	| result |
	self ensureClassNamed: self selfReferencedClassName superclassName: 'Object'.
	self withoutEpiceaDuring: [
			(self classNamed: self selfReferencedClassName) classSide
				compile: ('make ^ {1} new' format: { self selfReferencedClassName })
				classified: 'tests' ].
	result := self callToolWith: (self argumentsForClassNames: { self selfReferencedClassName }).
	(result at: #isError ifAbsent: [ false ]) ifFalse: [
		^ self deny: (self class environment includesKey: self selfReferencedClassName asSymbol) ].
	self assert: ((self errorFrom: result) at: #errorCode) equals: 'ClassRemovalBlocked'.
	self assert: ((self textFrom: result) includesSubstring: ('{1} class>>make' format: { self selfReferencedClassName })).
	self deny: ((self textFrom: result) includesSubstring: 'Pharo''s removal check')
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testANonEmptyClassNamedWithItsSubclassFollowsPharosCheck [
	"Before Pharo 12 the subclass check leaves out the classes asked for, so a class goes with its subclass. From 12 it compares the subclasses' names with a dictionary's values, so, as read, naming the subclass does not lift it; force then removes both, and nothing says the subclass moved."

	| error result |
	result := self callToolWith: (self argumentsForClassNames: {
				           self nonEmptyParentClassName.
				           self nonEmptyChildClassName }).
	self refactoringsRefuseBreakingChanges ifFalse: [
			error := self errorFrom: result.
			self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
			self assert: ((error at: #subclasses) at: self nonEmptyParentClassName) equals: { self nonEmptyChildClassName }.
			self
				assert: (error at: #message)
				equals:
					('Removed none of {1}, {2}: {1}''s subclass {2} inherits the methods and variables it defines. Reparent {2} with class_update or remove it first, or resend with force to remove the classes anyway.'
						 format: {
								 self nonEmptyParentClassName.
								 self nonEmptyChildClassName }).
			self assert: (self class environment includesKey: self nonEmptyChildClassName asSymbol).
			result := self callToolWith: (self
					           argumentsForClassNames: {
							           self nonEmptyParentClassName.
							           self nonEmptyChildClassName }
					           force: true).
			self assert: (self warningsFrom: result) isEmpty.
			self deny: ((self textFrom: result) includesSubstring: 'Reparented') ].
	self deny: (result at: #isError ifAbsent: [ false ]) description: [ self textFrom: result ].
	self deny: (self class environment includesKey: self nonEmptyParentClassName asSymbol).
	self deny: (self class environment includesKey: self nonEmptyChildClassName asSymbol)
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testAReferenceListStopsAtFiveMethods [
	"The text names the first five; method_reference_search lists them all, and the details hold every one."

	| error result text |
	1 to: 5 do: [ :index |
			self
				ensureMethodSource: ('refer{1} ^ {2}' format: {
							 index.
							 self referencedClassName })
				onClassNamed: self senderClassName ].
	result := self callToolWith: (self argumentsForClassNames: { self referencedClassName }).
	error := self errorFrom: result.
	text := self textFrom: result.
	self assert: ((error at: #message) beginsWith:
			 ('Did not remove {1}: 6 methods refer to it. Change those methods first' format: { self referencedClassName })).
	self assert: ((error at: #referencedBy) at: self referencedClassName) size equals: 6.
	self assert: (text lines includes:
			 ('referencedBy: {1}>>refer1, {1}>>refer2, {1}>>refer3, {1}>>refer4, {1}>>refer5, and 1 more (method_reference_search lists them)'
				  format: { self senderClassName }))
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testATraitSomeClassUsesNamesItsUsers [
	"Before Pharo 12 a trait some class uses is not removed, its users counted as Pharo counts them, even when they are asked for too."

	| error result |
	self refactoringsRefuseBreakingChanges ifFalse: [
		^ self skip: 'From Pharo 12 the classes using a trait do not block its removal.' ].
	self ensureTraitNamed: self usedTraitName usedByClassNamed: self traitUserClassName.
	result := self callToolWith: (self argumentsForClassNames: { self usedTraitName }).
	error := self errorFrom: result.
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self
		assert: (error at: #message)
		equals: ('Did not remove {1}: {2} uses it. Remove {1} from {2}''s traits with class_update first.' format: {
					 self usedTraitName.
					 self traitUserClassName }).
	self assert: ((error at: #users) at: self usedTraitName) equals: { self traitUserClassName }.
	self assert: (self class environment includesKey: self usedTraitName asSymbol)
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

	| data result structured text warnings |
	result := self callToolWith: (self argumentsForClassNames: { self nonEmptyParentClassName } force: true).
	self refactoringsRefuseBreakingChanges ifTrue: [
			self assert: (result at: #isError).
			self assert: (((self errorFrom: result) at: #message) endsWith: 'Force does not get past this check before Pharo 12.').
			^ self assert: (self class environment includesKey: self nonEmptyParentClassName asSymbol) ].
	structured := self structuredContentFrom: result.
	data := self dataFrom: result.
	text := self textFrom: result.
	warnings := structured at: #warnings.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey: self nonEmptyParentClassName asSymbol).
	self assert: (self classNamed: self nonEmptyChildClassName) superclass name asString equals: 'Object'.
	self assert: (data at: #reparentedSubclassNames ifAbsent: [ #(  ) ]) equals: { self nonEmptyChildClassName } asArray.
	self assert: warnings asArray equals: { ('{1} no longer inherits the methods and variables {2} defined.' format: {
				 self nonEmptyChildClassName.
				 self nonEmptyParentClassName }) }.
	self assert: text lines first equals: ('Force-removed class {1}. Reparented subclasses: {2}.' format: {
				 self nonEmptyParentClassName.
				 self nonEmptyChildClassName }).
	self deny: (text includesSubstring: 'reparentedSubclassNames')
]

{ #category : 'tests' }
MCPToolRemoveClassesTest >> testForceRemovesReferencedClassAndReturnsWarnings [

	| error result structured warnings |
	result := self callToolWith: (self argumentsForClassNames: { self referencedClassName } force: true).
	self refactoringsRefuseBreakingChanges ifTrue: [
			error := self errorFrom: result.
			self assert: (result at: #isError).
			self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
			self
				assert: (error at: #message)
				equals:
					('Did not remove {1}: 1 method refers to it. Change that method first. Force does not get past this check before Pharo 12.'
						 format: { self referencedClassName }).
			^ self assert: (self class environment includesKey: self referencedClassName asSymbol) ].
	structured := self structuredContentFrom: result.
	warnings := structured at: #warnings.
	self deny: (result at: #isError ifAbsent: [ false ]).
	self deny: (self class environment includesKey: self referencedClassName asSymbol).
	self assert: ((self classNamed: self senderClassName) includesSelector: #useReferencedClass).
	self
		assert: warnings asArray
		equals: { ('1 method still referred to {1} and now refers to an undeclared variable: {2}>>useReferencedClass.' format: {
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
	self assert: (error at: #message) equals: (self refactoringsRefuseBreakingChanges
			 ifTrue: [
					 'Did not remove {1}: 1 method refers to it, and its subclass {2} inherits the methods and variables it defines. Change that method and reparent {2} with class_update or remove it first.'
						 format: {
								 self nonEmptyParentClassName.
								 self nonEmptyChildClassName } ]
			 ifFalse: [
					 'Did not remove {1}: 1 method refers to it, and its subclass {2} inherits the methods and variables it defines. Change that method and reparent {2} with class_update or remove it first, or resend with force to remove {1} anyway: the method will refer to an undeclared {1}, and {2} will move under Object without what {1} defines.'
						 format: {
								 self nonEmptyParentClassName.
								 self nonEmptyChildClassName } ]).
	self assert: (error at: #impactMessages) size equals: 2
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
	"Pharo's check decides, and the refusal names the method that refers to the class in its own words, offering force only where it gets past the check."

	| error result text |
	result := self callToolWith: (self argumentsForClassNames: { self referencedClassName }).
	error := self errorFrom: result.
	text := self textFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self assert: (error at: #classes) equals: { self referencedClassName } asArray.
	self assert: (error at: #message) equals: (self refactoringsRefuseBreakingChanges
			 ifTrue: [ 'Did not remove {1}: 1 method refers to it. Change that method first.' format: { self referencedClassName } ]
			 ifFalse: [
					 'Did not remove {1}: 1 method refers to it. Change that method first, or resend with force to remove {1} anyway: the method will refer to an undeclared {1}.'
						 format: { self referencedClassName } ]).
	self assert: (text lines includes: ('referencedBy: {1}>>useReferencedClass' format: { self senderClassName })).
	self
		assert: ((error at: #referencedBy) at: self referencedClassName)
		equals: { ('{1}>>useReferencedClass' format: { self senderClassName }) }.
	self assert: (error at: #impactMessages) equals: { ('1 method refers to {1}.' format: { self referencedClassName }) }.
	self assert: (error at: #forceSupported) equals: self refactoringsRefuseBreakingChanges not.
	self assert: (text includesSubstring: 'resend with force') equals: self refactoringsRefuseBreakingChanges not.
	#( 'RBRefactoring' 'NOT ' '<n>' 'Browse' ) do: [ :each | self deny: (text includesSubstring: each) ].
	self deny: (text lines anySatisfy: [ :each | each endsWith: ' ' ]).
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

	| error result structured |
	result := self callToolWith: (self argumentsForClassNames: { self nonEmptyParentClassName }).
	structured := self structuredContentFrom: result.
	error := self errorFrom: result.
	self assert: (result at: #isError).
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self assert: (error at: #classes) equals: { self nonEmptyParentClassName } asArray.
	self assert: ((error at: #message) includesSubstring:
			 ('its subclass {1} inherits the methods and variables it defines' format: { self nonEmptyChildClassName })).
	self assert: ((error at: #subclasses) at: self nonEmptyParentClassName) equals: { self nonEmptyChildClassName }.
	self deny: (error includesKey: #referencedBy).
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
MCPToolRemoveClassesTest >> testTwoReferencedClassesAreEachNamedOnTheirOwnLine [

	| error result text |
	self ensureClassNamed: self secondReferencedClassName superclassName: 'Object'.
	self
		ensureMethodSource: ('useReferencedToo ^ {1} new' format: { self secondReferencedClassName })
		onClassNamed: self senderClassName.
	result := self callToolWith: (self argumentsForClassNames: {
				           self referencedClassName.
				           self secondReferencedClassName }).
	error := self errorFrom: result.
	text := self textFrom: result.
	self assert: (error at: #errorCode) equals: 'ClassRemovalBlocked'.
	self assert: ((error at: #message) beginsWith:
			 ('Removed none of {1}, {2}: 1 method refers to {1}, and 1 method refers to {2}. Change those methods first' format: {
					  self referencedClassName.
					  self secondReferencedClassName })).
	self assert: (text lines includes: 'referencedBy:').
	self assert: (text lines includes: ('  {1}: {2}>>useReferencedClass' format: {
					  self referencedClassName.
					  self senderClassName })).
	self assert: (text lines includes: ('  {1}: {2}>>useReferencedToo' format: {
					  self secondReferencedClassName.
					  self senderClassName })).
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

{ #category : 'private' }
MCPToolRemoveClassesTest >> traitUserClassName [

	^ self fixturePrefix , 'TraitUser'
]

{ #category : 'private' }
MCPToolRemoveClassesTest >> usedTraitName [

	^ 'T' , self fixturePrefix , 'Used'
]
