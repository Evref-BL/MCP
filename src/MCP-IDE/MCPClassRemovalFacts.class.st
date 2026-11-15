"
What blocks class_remove, gathered from the image once Pharo's removal check has refused it: for each class asked for, the methods that refer to it, the subclasses that would lose what it defines, and the classes that use it as a trait.

It says them as the refusal's text and details, and, when force went past the check, as warnings of what the removal left behind. Force is offered only where it gets past the check, from Pharo 12. When none of the facts explains the refusal, it quotes Pharo's check, cleaned to one line.
"
Class {
	#name : 'MCPClassRemovalFacts',
	#superclass : 'Object',
	#instVars : [
		'classes',
		'referencedBy',
		'subclasses',
		'users',
		'forced',
		'forceSupported',
		'conditionText'
	],
	#category : 'MCP-IDE-Utilities',
	#package : 'MCP-IDE',
	#tag : 'Utilities'
}

{ #category : 'printing' }
MCPClassRemovalFacts class >> referenceTextOf: aMethod [
	"aMethod as Class>>selector, or Class class>>selector on the class side. It may be a compiled method or a refactoring model's, which name their class and side alike."

	| behavior |
	behavior := aMethod methodClass.
	^ String streamContents: [ :stream |
			  stream nextPutAll: behavior instanceSide name.
			  behavior isMeta ifTrue: [ stream nextPutAll: ' class' ].
			  stream
				  nextPutAll: '>>';
				  nextPutAll: aMethod selector ]
]

{ #category : 'printing' }
MCPClassRemovalFacts class >> referenceTextsOf: someMethods [
	"Each method once, in order. Pharo 14 counts each referring method twice, once per side of the class it refers to."

	^ (someMethods collect: [ :each | self referenceTextOf: each ] as: Set) asArray sort
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> classNames [

	^ classes collect: [ :each | each name asString ]
]

{ #category : 'accessing' }
MCPClassRemovalFacts >> classes: someClasses [
	"The classes asked for, in the order they were asked for."

	classes := someClasses asArray
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> cleanedConditionText [
	"Pharo's own text, on one line, without its NOT and its closing period."

	| text |
	text := MCPRefactoringText withoutNegation: (MCPRefactoringText singleLine: conditionText).
	(text endsWith: '.') ifTrue: [ ^ text allButLast ].
	^ text
]

{ #category : 'accessing' }
MCPClassRemovalFacts >> conditionText: aString [
	"What Pharo's check said, quoted only when none of the facts explains its refusal."

	conditionText := aString
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> consequences [
	"What a forced removal leaves behind. A trait's users block it only before Pharo 12, where force does not get past the check."

	^ Array streamContents: [ :stream |
			  referencedBy ifNotEmpty: [ stream nextPut: self referenceConsequence ].
			  (self namesIn: subclasses) do: [ :each |
				  (self subclassesLeftBehindBy: each) ifNotEmpty: [ :names |
					  stream nextPut: (self subclassConsequenceFor: each leaving: names) ] ] ]
]

{ #category : 'texts' }
MCPClassRemovalFacts >> details [
	"What tool-reference.md promises a refactoring refusal carries, and the facts in full: referencedBy is not cut at five."

	| details |
	details := Dictionary new.
	details at: #classes put: self classNames.
	referencedBy ifNotEmpty: [ details at: #referencedBy put: referencedBy copy ].
	subclasses ifNotEmpty: [ details at: #subclasses put: subclasses copy ].
	users ifNotEmpty: [ details at: #users put: users copy ].
	details at: #impactMessages put: self impactMessages.
	self howToProceed ifNotEmpty: [ :sentence | details at: #howToProceed put: sentence ].
	details at: #forceSupported put: forceSupported.
	^ details
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> factsUsingPronoun: usesPronoun [
	"References first, then subclasses, then users, each in the order the classes were asked for."

	^ Array streamContents: [ :stream |
			  (self namesIn: referencedBy) do: [ :each | stream nextPut: (self referenceFactFor: each pronoun: usesPronoun) ].
			  (self namesIn: subclasses) do: [ :each | stream nextPut: (self subclassFactFor: each pronoun: usesPronoun) ].
			  (self namesIn: users) do: [ :each | stream nextPut: (self userFactFor: each pronoun: usesPronoun) ] ]
]

{ #category : 'accessing' }
MCPClassRemovalFacts >> forceSupported: aBoolean [
	"Whether force gets past the check: a warning can be gone past, an error cannot."

	forceSupported := aBoolean
]

{ #category : 'accessing' }
MCPClassRemovalFacts >> forced: aBoolean [

	forced := aBoolean
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> forcedReferenceWarningFor: aClassName [
	"Every method is named: once the class is gone, no search finds them by it."

	| methods |
	methods := referencedBy at: aClassName.
	^ String streamContents: [ :stream |
			  stream
				  print: methods size;
				  nextPutAll: (methods size = 1
						   ifTrue: [ ' method still referred to ' ]
						   ifFalse: [ ' methods still referred to ' ]);
				  nextPutAll: aClassName;
				  nextPutAll: (methods size = 1
						   ifTrue: [ ' and now refers to an undeclared variable: ' ]
						   ifFalse: [ ' and now refer to an undeclared variable: ' ]);
				  nextPutAll: (', ' join: methods);
				  nextPut: $. ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> forcedSubclassWarningFor: aClassName leaving: someNames [

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (self joinedNames: someNames);
				  nextPutAll: (someNames size = 1
						   ifTrue: [ ' no longer inherits' ]
						   ifFalse: [ ' no longer inherit' ]).
			  stream << ' the methods and variables ' << aClassName << ' defined.' ]
]

{ #category : 'texts' }
MCPClassRemovalFacts >> forcedWarnings [
	"What a removal forced past the check left behind, one warning per fact, in the refusal's order. With no fact, what Pharo's check said."

	self hasFacts ifFalse: [ ^ { (self cleanedConditionText copyWith: $.) } ].
	^ Array streamContents: [ :stream |
			  (self namesIn: referencedBy) do: [ :each | stream nextPut: (self forcedReferenceWarningFor: each) ].
			  (self namesIn: subclasses) do: [ :each |
				  (self subclassesLeftBehindBy: each) ifNotEmpty: [ :names |
					  stream nextPut: (self forcedSubclassWarningFor: each leaving: names) ] ] ]
]

{ #category : 'testing' }
MCPClassRemovalFacts >> hasFacts [
	"Whether anything the image answers explains the refusal. When nothing does, Pharo's check is quoted."

	^ referencedBy isNotEmpty or: [ subclasses isNotEmpty or: [ users isNotEmpty ] ]
]

{ #category : 'texts' }
MCPClassRemovalFacts >> howToProceed [
	"What to do first, then, where force gets past the check, what force would do instead. Empty when the check refused for a reason none of the facts gives and force cannot get past it."

	^ String streamContents: [ :stream |
			  self hasFacts
				  ifTrue: [
						  stream
							  nextPutAll: (self joinedNames: self steps) capitalized;
							  nextPutAll: ' first'.
						  forceSupported ifTrue: [
								  stream << ', or resend with force to remove ' << self removedObject << ' anyway'.
								  self consequences ifNotEmpty: [ :consequences | stream << ': ' << (self joinedFacts: consequences) ] ].
						  stream nextPut: $. ]
				  ifFalse: [ forceSupported ifTrue: [ stream << 'Resend with force to remove ' << self removedObject << ' anyway.' ] ] ]
]

{ #category : 'texts' }
MCPClassRemovalFacts >> impactMessages [
	"One sentence per fact, each naming its class, or what Pharo's check said when no fact explains it."

	self hasFacts ifFalse: [ ^ { self cleanedConditionText } ].
	^ (self factsUsingPronoun: false) collect: [ :each | each capitalized copyWith: $. ]
]

{ #category : 'initialization' }
MCPClassRemovalFacts >> initialize [

	super initialize.
	classes := #(  ).
	referencedBy := Dictionary new.
	subclasses := Dictionary new.
	users := Dictionary new.
	forced := false.
	forceSupported := false.
	conditionText := ''
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> isAboutOneClass [

	^ classes size = 1
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> joinedFacts: someStrings [
	"Facts are clauses, kept apart by a comma: A, A, and B, A, B, and C."

	^ String streamContents: [ :stream |
			  someStrings withIndexDo: [ :each :index |
					  index > 1 ifTrue: [
							  stream nextPutAll: (index = someStrings size
									   ifTrue: [ ', and ' ]
									   ifFalse: [ ', ' ]) ].
					  stream nextPutAll: each ] ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> joinedNames: someStrings [
	"A, A and B, A, B and C."

	^ String streamContents: [ :stream |
			  someStrings withIndexDo: [ :each :index |
					  index > 1 ifTrue: [
							  stream nextPutAll: (index = someStrings size
									   ifTrue: [ ' and ' ]
									   ifFalse: [ ', ' ]) ].
					  stream nextPutAll: each ] ]
]

{ #category : 'texts' }
MCPClassRemovalFacts >> message [
	"The refusal: what was not removed and why, then what to do. Force is offered only where it gets past the check; before Pharo 12 a call that passed it is told so, or agents resend it."

	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: self opening;
				  nextPutAll: ': '.
			  self hasFacts
				  ifTrue: [ stream nextPutAll: (self joinedFacts: (self factsUsingPronoun: self isAboutOneClass)) ]
				  ifFalse: [
						  stream nextPutAll: 'Pharo''s removal check refused '.
						  stream nextPutAll: (self isAboutOneClass
								   ifTrue: [ 'it' ]
								   ifFalse: [ 'them' ]).
						  self cleanedConditionText ifNotEmpty: [ :text | stream << ' (' << text << ')' ] ].
			  stream nextPut: $..
			  self howToProceed ifNotEmpty: [ :sentence |
					  stream
						  space;
						  nextPutAll: sentence ].
			  (forced and: [ forceSupported not ]) ifTrue: [ stream nextPutAll: ' Force does not get past this check before Pharo 12.' ] ]
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> namesIn: aDictionary [
	"The classes asked for that aDictionary has a fact about, in the order they were asked for."

	^ self classNames select: [ :each | aDictionary includesKey: each ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> opening [

	^ String streamContents: [ :stream |
			  self isAboutOneClass
				  ifTrue: [ stream << 'Did not remove ' << self classNames first ]
				  ifFalse: [ stream << 'Removed none of ' << (', ' join: self classNames) ] ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> referenceConsequence [

	| names |
	names := self namesIn: referencedBy.
	^ String streamContents: [ :stream |
			  stream nextPutAll: (self referringMethodCount = 1
					   ifTrue: [ 'the method will refer to ' ]
					   ifFalse: [ 'the methods will refer to ' ]).
			  names size = 1 ifTrue: [ stream nextPutAll: 'an ' ].
			  stream
				  nextPutAll: 'undeclared ';
				  nextPutAll: (self joinedNames: names) ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> referenceFactFor: aClassName pronoun: usesPronoun [
	"usesPronoun says it of the one class asked for; otherwise the class is named."

	| count |
	count := (referencedBy at: aClassName) size.
	^ String streamContents: [ :stream |
			  stream
				  print: count;
				  nextPutAll: (count = 1
						   ifTrue: [ ' method refers to ' ]
						   ifFalse: [ ' methods refer to ' ]);
				  nextPutAll: (usesPronoun
						   ifTrue: [ 'it' ]
						   ifFalse: [ aClassName ]) ]
]

{ #category : 'accessing' }
MCPClassRemovalFacts >> referencedBy: aDictionary [
	"Class name to the methods that refer to it, as Class>>selector."

	referencedBy := aDictionary
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> referringMethodCount [
	"A method that refers to several of the classes asked for counts once."

	| methods |
	methods := Set new.
	referencedBy do: [ :each | methods addAll: each ].
	^ methods size
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> removedObject [
	"What force would remove."

	^ self isAboutOneClass
		  ifTrue: [ self classNames first ]
		  ifFalse: [ 'the classes' ]
]

{ #category : 'signaling' }
MCPClassRemovalFacts >> signalBlocked [

	^ MCPCommandError signalClassRemovalBlocked: self message details: self details
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> steps [
	"What to change first, one step per kind of fact."

	^ Array streamContents: [ :stream |
			  referencedBy ifNotEmpty: [
					  stream nextPut: (self referringMethodCount = 1
							   ifTrue: [ 'change that method' ]
							   ifFalse: [ 'change those methods' ]) ].
			  self subclassNames ifNotEmpty: [ :names |
					  stream nextPut: (String streamContents: [ :step |
								   step << 'reparent ' << (self joinedNames: names) << ' with class_update or remove ' << (names size = 1
									    ifTrue: [ 'it' ]
									    ifFalse: [ 'them' ]) ]) ].
			  (self namesIn: users) do: [ :each | stream nextPut: (self userStepFor: each) ] ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> subclassConsequenceFor: aClassName leaving: someNames [

	^ String streamContents: [ :stream |
			  stream << (self joinedNames: someNames) << ' will move under ' << (self superclassNameOf: aClassName) << ' without what '
			  << aClassName << ' defines' ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> subclassFactFor: aClassName pronoun: usesPronoun [

	| names |
	names := subclasses at: aClassName.
	^ String streamContents: [ :stream |
			  usesPronoun
				  ifTrue: [ stream nextPutAll: 'its' ]
				  ifFalse: [ stream << aClassName << '''s' ].
			  stream
				  nextPutAll: (names size = 1
						   ifTrue: [ ' subclass ' ]
						   ifFalse: [ ' subclasses ' ]);
				  nextPutAll: (self joinedNames: names);
				  nextPutAll: (names size = 1
						   ifTrue: [ ' inherits' ]
						   ifFalse: [ ' inherit' ]);
				  nextPutAll: ' the methods and variables it defines' ]
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> subclassNames [
	"Every subclass the facts name, once, in the order of the classes they inherit from."

	| names |
	names := OrderedCollection new.
	(self namesIn: subclasses) do: [ :each |
		(subclasses at: each) do: [ :name | (names includes: name) ifFalse: [ names add: name ] ] ].
	^ names asArray
]

{ #category : 'accessing' }
MCPClassRemovalFacts >> subclasses: aDictionary [
	"Class name to the names of the subclasses that block its removal."

	subclasses := aDictionary
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> subclassesLeftBehindBy: aClassName [
	"The subclasses that block the removal of the class named aClassName and outlive it. A subclass asked for in the same call still blocks it from Pharo 12, but a forced removal takes it too, so nothing moves it or leaves it without what it inherited."

	^ (subclasses at: aClassName) reject: [ :each | self classNames includes: each ]
]

{ #category : 'private - names' }
MCPClassRemovalFacts >> superclassNameOf: aClassName [
	"Where the subclasses of the class named aClassName move when it is removed."

	| superclass |
	superclass := (classes detect: [ :each | each name asString = aClassName ]) superclass.
	^ superclass ifNil: [ 'nil' ] ifNotNil: [ superclass name ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> userFactFor: aTraitName pronoun: usesPronoun [

	| names |
	names := users at: aTraitName.
	^ String streamContents: [ :stream |
			  stream
				  nextPutAll: (self joinedNames: names);
				  nextPutAll: (names size = 1
						   ifTrue: [ ' uses ' ]
						   ifFalse: [ ' use ' ]);
				  nextPutAll: (usesPronoun
						   ifTrue: [ 'it' ]
						   ifFalse: [ aTraitName ]) ]
]

{ #category : 'private - texts' }
MCPClassRemovalFacts >> userStepFor: aTraitName [

	| names |
	names := users at: aTraitName.
	^ String streamContents: [ :stream |
			  stream << 'remove ' << aTraitName << ' from '.
			  names size = 1
				  ifTrue: [ stream << names first << '''s traits' ]
				  ifFalse: [ stream << 'the traits of ' << (self joinedNames: names) ].
			  stream nextPutAll: ' with class_update' ]
]

{ #category : 'accessing' }
MCPClassRemovalFacts >> users: aDictionary [
	"Trait name to the names of the classes that use it and block its removal."

	users := aDictionary
]
