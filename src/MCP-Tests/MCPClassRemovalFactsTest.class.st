"
Tests the words class_remove says what blocks it in, from the facts alone, on every Pharo version: Pharo 10 and 11 refuse where 12 and later warn, and a trait's users block only before 12.
"
Class {
	#name : 'MCPClassRemovalFactsTest',
	#superclass : 'MCPTestCase',
	#category : 'MCP-Tests',
	#package : 'MCP-Tests'
}

{ #category : 'private' }
MCPClassRemovalFactsTest >> factsAbout: someClasses [
	"Facts as Pharo 12 and later gather them for a call that did not pass force: a warning, which force gets past."

	^ MCPClassRemovalFacts new
		  classes: someClasses;
		  forced: false;
		  forceSupported: true;
		  yourself
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testAMethodThatGoesWithAClassAskedForIsNotSaidToBeLeftBehind [
	"Pharo 12 and 13 count a class-side method of a class asked for as a reference to it. It blocks the removal, but force removes it with its class, so neither the refusal's consequences nor the forced warnings say it will refer to an undeclared class."

	| facts |
	facts := (self factsAbout: { Set })
		         referencedBy: (Dictionary with: 'Set' -> #( 'EvalA>>a' 'Set class>>withAll:' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Did not remove Set: 2 methods refer to it. Change those methods first, or resend with force to remove Set anyway: the method will refer to an undeclared Set.'.
	self
		assert: facts forcedWarnings
		equals: #( '1 method still referred to Set and now refers to an undeclared variable: EvalA>>a.' ).
	facts referencedBy: (Dictionary with: 'Set' -> #( 'Set class>>withAll:' )).
	self
		assert: facts message
		equals: 'Did not remove Set: 1 method refers to it. Change that method first, or resend with force to remove Set anyway.'.
	self assert: facts forcedWarnings isEmpty.
	facts
		classes: {
				Set.
				Bag };
		referencedBy: (Dictionary with: 'Set' -> #( 'Bag class>>withAll:' )).
	self
		assert: facts message
		equals:
		'Removed none of Set, Bag: 1 method refers to Set. Change that method first, or resend with force to remove the classes anyway.'.
	self assert: facts forcedWarnings isEmpty
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testAReferencedClassSaysHowManyMethodsReferToIt [

	| facts |
	facts := (self factsAbout: { Set })
		         referencedBy: (Dictionary with:
					          'Set'
					          -> #( 'EvalShapesTest>>testAreas' 'EvalShapesTest>>testDrawingIsLaidOutLeftToRight'
						             'EvalShapesTest>>testSummary' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Did not remove Set: 3 methods refer to it. Change those methods first, or resend with force to remove Set anyway: the methods will refer to an undeclared Set.'.
	self assert: facts impactMessages equals: #( '3 methods refer to Set.' ).
	self
		assert: facts howToProceed
		equals: 'Change those methods first, or resend with force to remove Set anyway: the methods will refer to an undeclared Set.'.
	self assert: (facts details at: #forceSupported).
	self assert: (facts details at: #classes) equals: #( 'Set' ).
	self assert: ((facts details at: #referencedBy) at: 'Set') size equals: 3.
	self deny: (facts details includesKey: #subclasses).
	self deny: (facts details includesKey: #users)
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testASubclassAskedForTooIsNotSaidToMove [
	"From Pharo 12 a subclass named in the same call still blocks its superclass, but force removes it with the class, so nothing says it moves or loses what it inherited."

	| facts |
	facts := (self factsAbout: {
				          Set.
				          IdentitySet })
		         subclasses: (Dictionary with: 'Set' -> #( 'IdentitySet' 'EvalRect' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Removed none of Set, IdentitySet: Set''s subclasses IdentitySet and EvalRect inherit the methods and variables it defines. Reparent IdentitySet and EvalRect with class_update or remove them first, or resend with force to remove the classes anyway: EvalRect will move under HashedCollection without what Set defines.'.
	self assert: facts forcedWarnings equals: #( 'EvalRect no longer inherits the methods and variables Set defined.' ).
	facts subclasses: (Dictionary with: 'Set' -> #( 'IdentitySet' )).
	self
		assert: facts message
		equals:
		'Removed none of Set, IdentitySet: Set''s subclass IdentitySet inherits the methods and variables it defines. Reparent IdentitySet with class_update or remove it first, or resend with force to remove the classes anyway.'.
	self assert: facts forcedWarnings isEmpty
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testATraitsUsersAreNamed [

	| facts |
	facts := (self factsAbout: { TAssertable })
		         forceSupported: false;
		         users: (Dictionary with: 'TAssertable' -> #( 'EvalStockItem' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Did not remove TAssertable: EvalStockItem uses it. Remove TAssertable from EvalStockItem''s traits with class_update first.'.
	self assert: facts impactMessages equals: #( 'EvalStockItem uses TAssertable.' ).
	facts users: (Dictionary with: 'TAssertable' -> #( 'EvalBin' 'EvalStockItem' )).
	self
		assert: facts message
		equals:
		'Did not remove TAssertable: EvalBin and EvalStockItem use it. Remove TAssertable from the traits of EvalBin and EvalStockItem with class_update first.'.
	self assert: ((facts details at: #users) at: 'TAssertable') equals: #( 'EvalBin' 'EvalStockItem' )
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testBeforePharo12ForceIsNotOffered [

	| facts |
	facts := (self factsAbout: { Set })
		         forceSupported: false;
		         referencedBy: (Dictionary with: 'Set' -> #( 'EvalA>>a' 'EvalA>>b' 'EvalA>>c' ));
		         yourself.
	self assert: facts message equals: 'Did not remove Set: 3 methods refer to it. Change those methods first.'.
	self deny: (facts details at: #forceSupported).
	facts forced: true.
	self
		assert: facts message
		equals:
		'Did not remove Set: 3 methods refer to it. Change those methods first. Force does not get past this check before Pharo 12.'.
	self assert: (facts details at: #howToProceed) equals: 'Change those methods first.'
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testOneReferringMethodIsSaidInTheSingular [

	| facts |
	facts := (self factsAbout: { Set })
		         referencedBy: (Dictionary with: 'Set' -> #( 'EvalShapesTest>>testAreas' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Did not remove Set: 1 method refers to it. Change that method first, or resend with force to remove Set anyway: the method will refer to an undeclared Set.'.
	self
		assert: facts forcedWarnings
		equals: #( '1 method still referred to Set and now refers to an undeclared variable: EvalShapesTest>>testAreas.' )
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testReferencesArePrintedOnceInOrder [
	"Pharo 14 counts each referring method twice; the class side reads as Pharo prints it."

	self
		assert: (MCPClassRemovalFacts referenceTextsOf: {
					 (Object >> #printString).
					 (Character class >> #value:).
					 (Object >> #printString) })
		equals: #( 'Character class>>value:' 'Object>>printString' )
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testReferencesComeBeforeSubclasses [

	| facts |
	facts := (self factsAbout: { Set })
		         referencedBy: (Dictionary with: 'Set' -> #( 'EvalBin>>add:' 'EvalStockTest>>setUp' ));
		         subclasses: (Dictionary with: 'Set' -> #( 'EvalPerishableItem' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Did not remove Set: 2 methods refer to it, and its subclass EvalPerishableItem inherits the methods and variables it defines. Change those methods and reparent EvalPerishableItem with class_update or remove it first, or resend with force to remove Set anyway: the methods will refer to an undeclared Set, and EvalPerishableItem will move under HashedCollection without what Set defines.'.
	self
		assert: facts forcedWarnings
		equals: #( '2 methods still referred to Set and now refer to an undeclared variable: EvalBin>>add:, EvalStockTest>>setUp.'
			   'EvalPerishableItem no longer inherits the methods and variables Set defined.' )
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testSeveralClassesAreEachNamed [

	| facts |
	facts := (self factsAbout: {
				          Set.
				          Bag })
		         referencedBy: (Dictionary newFrom: {
						          ('Set' -> #( 'EvalA>>a' 'EvalA>>b' )).
						          ('Bag' -> #( 'EvalA>>c' 'EvalA>>d' )) });
		         yourself.
	self
		assert: facts message
		equals:
		'Removed none of Set, Bag: 2 methods refer to Set, and 2 methods refer to Bag. Change those methods first, or resend with force to remove the classes anyway: the methods will refer to undeclared Set and Bag.'.
	self assert: facts impactMessages equals: #( '2 methods refer to Set.' '2 methods refer to Bag.' ).
	self assert: (facts details at: #classes) equals: #( 'Set' 'Bag' )
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testSubclassesOfAClassThatIsNotEmptyAreNamed [

	| facts |
	facts := (self factsAbout: { Set })
		         subclasses: (Dictionary with: 'Set' -> #( 'EvalCircle' 'EvalRect' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Did not remove Set: its subclasses EvalCircle and EvalRect inherit the methods and variables it defines. Reparent EvalCircle and EvalRect with class_update or remove them first, or resend with force to remove Set anyway: EvalCircle and EvalRect will move under HashedCollection without what Set defines.'.
	self
		assert: facts impactMessages
		equals: #( 'Set''s subclasses EvalCircle and EvalRect inherit the methods and variables it defines.' ).
	self assert: facts forcedWarnings equals: #( 'EvalCircle and EvalRect no longer inherit the methods and variables Set defined.' )
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testThreeFactsJoinWithCommas [

	| facts |
	facts := (self factsAbout: {
				          Set.
				          Bag.
				          Dictionary })
		         referencedBy: (Dictionary newFrom: {
						          ('Set' -> #( 'EvalA>>a' )).
						          ('Dictionary' -> #( 'EvalA>>a' )) });
		         subclasses: (Dictionary with: 'Bag' -> #( 'EvalX' 'EvalY' 'EvalZ' ));
		         yourself.
	self
		assert: facts message
		equals:
		'Removed none of Set, Bag, Dictionary: 1 method refers to Set, 1 method refers to Dictionary, and Bag''s subclasses EvalX, EvalY and EvalZ inherit the methods and variables it defines. Change that method and reparent EvalX, EvalY and EvalZ with class_update or remove them first, or resend with force to remove the classes anyway: the method will refer to undeclared Set and Dictionary, and EvalX, EvalY and EvalZ will move under Collection without what Bag defines.'
]

{ #category : 'tests' }
MCPClassRemovalFactsTest >> testWithoutAFactPharosCheckIsQuoted [

	| facts |
	facts := (self factsAbout: { Set })
		         forceSupported: false;
		         conditionText: 'Cannot remove top level class<n>when it has subclasses';
		         yourself.
	self
		assert: facts message
		equals: 'Did not remove Set: Pharo''s removal check refused it (Cannot remove top level class when it has subclasses).'.
	self assert: facts impactMessages equals: #( 'Cannot remove top level class when it has subclasses' ).
	self deny: (facts details includesKey: #howToProceed).
	facts forced: true.
	self
		assert: facts message
		equals:
		'Did not remove Set: Pharo''s removal check refused it (Cannot remove top level class when it has subclasses). Force does not get past this check before Pharo 12.'.
	facts := (self factsAbout: {
				          Set.
				          Bag })
		         conditionText: 'NOT Set has subclasses.  and Bag is not empty. ';
		         yourself.
	self
		assert: facts message
		equals:
		'Removed none of Set, Bag: Pharo''s removal check refused them (Set has subclasses. and Bag is not empty). Resend with force to remove the classes anyway.'.
	self assert: facts forcedWarnings equals: #( 'Set has subclasses. and Bag is not empty.' )
]
