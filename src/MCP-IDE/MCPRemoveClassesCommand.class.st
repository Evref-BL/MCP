"
Removes one or more classes from the image in one refactoring, once Pharo's check lets it. Force goes past a warning of that check, never past an error.

Once executed, it says what the removal changed besides the classes: the subclasses it moved up to a superclass, the packages it left empty and removed, and the facts force went past, as warning messages.
"
Class {
	#name : 'MCPRemoveClassesCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'classNames',
		'force',
		'resolvedClasses',
		'reparentedSubclassNames',
		'removedPackageNames',
		'warningMessages',
		'removedMethodNames',
		'methodsThatMayRefer'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRemoveClassesCommand class >> classNames: someClassNames [

	^ self classNames: someClassNames force: false
]

{ #category : 'instance creation' }
MCPRemoveClassesCommand class >> classNames: someClassNames force: forceRemoval [

	^ self new
		  classNames: someClassNames;
		  force: forceRemoval;
		  yourself
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> blockingFactsFor: anException [
	"The facts as they stand while they block the removal."

	^ self factsFor: anException sayingOfSubclasses: [ :aClass :names |
		  String streamContents: [ :stream | stream << aClass name << ' is not empty and has subclasses: ' << (', ' join: names) << '.' ] ]
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> classNames [

	^ classNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> classNames: someClassNames [

	classNames := someClassNames ifNil: [ #(  ) ] ifNotNil: [ someClassNames asArray ]
]

{ #category : 'executing' }
MCPRemoveClassesCommand >> execute [
	"The refactoring is handed the names of the classes the lookup resolved, not the names as given. The subclasses that move up, the methods that go with the classes and the packages the classes were in are read before the classes go."

	| refactoring packageNames |
	refactoring := self preparedRefactoringForClassNames: (self resolvedClasses collect: [ :each | each name ]).
	warningMessages := self validatePreparedRefactoring: refactoring.
	reparentedSubclassNames := self resolvedClasses flatCollect: [ :each | self subclassNamesReparentedWhenRemoving: each ].
	removedMethodNames := self resolvedClasses flatCollect: [ :each | self methodNamesOf: each ].
	packageNames := self resolvedClasses collect: [ :each |
		                each package ifNil: [ '' ] ifNotNil: [ :package | package name asString ] ].
	self performRemovalWithPreparedRefactoring: refactoring.
	removedPackageNames := OrderedCollection new.
	packageNames do: [ :each | self removePackageIfNowEmptyNamed: each recordingInto: removedPackageNames ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> factsFor: anException sayingOfSubclasses: aBlock [
	"One sentence per fact, class by class: the methods outside the removal that refer to it, then what aBlock says, given the class and their names, of the subclasses not asked for of one that is not empty. When none explains the check, its own text, on one line."

	| references facts |
	references := self referencesOutsideRemoval.
	facts := Array streamContents: [ :stream |
			         self resolvedClasses do: [ :each |
					         references at: each name asString ifPresent: [ :methods |
							         stream nextPut:
								         (String streamContents: [ :sentence |
									          sentence << each name << ' is referred to by ' << (self referenceListOf: methods) << '.' ]) ].
					         (self subclassesBlockingRemovalOf: each) ifNotEmpty: [ :names | stream nextPut: (aBlock value: each value: names) ] ] ].
	^ facts ifEmpty: [ { (MCPRefactoringText conditionText: anException mcpMessageText) } ]
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> force [

	^ force = true
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> force: aBoolean [

	force := aBoolean
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> forceGoesPast: anException [
	"Force goes past a refactoring warning, never past an error. Pharo 10 and 11 make their refactoring errors resumable, so whether an exception can be resumed does not tell the two apart."

	^ anException isKindOf: RBRefactoringWarning
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> forcedFactsFor: anException [
	"The facts force went past, as they stand once the classes are gone: a method that referred to a class still does, and the subclasses of one that was not empty lost what they inherited from it."

	^ self factsFor: anException sayingOfSubclasses: [ :aClass :names |
			  String streamContents: [ :stream |
					  stream << (MCPCommandError joinedNames: names) << ' lost what ' << (names size = 1
						   ifTrue: [ 'it' ]
						   ifFalse: [ 'they' ]) << ' inherited from ' << aClass name << '.' ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> isEmptyClass: aClass [

	^ aClass classVarNames isEmpty and: [ aClass instVarNames isEmpty and: [ aClass selectors isEmpty ] ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> method: aCompiledMethod holdsAnyOf: someLiterals [
	"Whether aCompiledMethod holds one of someLiterals, an identity set, among its literals at any depth, its blocks' included, or in a pragma, as its selector or among its arguments."

	^ (aCompiledMethod hasLiteralSuchThat: [ :each | someLiterals includes: each ]) or: [
			  aCompiledMethod pragmas anySatisfy: [ :pragma |
				  (someLiterals includes: pragma selector) or: [ pragma arguments hasLiteralSuchThat: [ :each | someLiterals includes: each ] ] ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> methodNamesOf: aClass [
	"The methods aClass defines itself, instance side then class side, each sorted, as Pharo writes them. What a trait gives it is the trait's, and stays."

	^ {
		  aClass.
		  aClass classSide } flatCollect: [ :behavior |
			  (behavior localMethods
				   collect: [ :each | String streamContents: [ :stream | stream << behavior name << '>>' << each selector ] ]
				   as: Array) sort ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> methodsThatMayRefer [
	"The methods outside the classes asked for, on either side, that hold one of them at any depth of their literals or in a pragma: by its name as a symbol, or as the value of a global, under its own name or another. Every method that Pharo's check or method_reference_search counts as referring to one of the classes is among them. One pass over the image finds them for all the classes."

	^ methodsThatMayRefer ifNil: [
			  | removed wanted |
			  removed := self resolvedClasses asIdentitySet.
			  wanted := (MCPClassReferenceQuery forClasses: self resolvedClasses) bindings.
			  self resolvedClasses do: [ :each | wanted add: each name ].
			  methodsThatMayRefer := OrderedCollection new.
			  Smalltalk globals allBehaviorsDo: [ :behavior |
					  (removed includes: behavior instanceSide) ifFalse: [
						  behavior methodsDo: [ :method | (self method: method holdsAnyOf: wanted) ifTrue: [ methodsThatMayRefer add: method ] ] ] ].
			  methodsThatMayRefer ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> referenceListOf: someMethods [
	"The first five, then how many more: method_reference_search lists them all."

	| names |
	names := (someMethods
		          collect: [ :each | String streamContents: [ :stream | stream << each methodClass name << '>>' << each selector ] ]
		          as: Set) asArray sort.
	names size <= 5 ifTrue: [ ^ ', ' join: names ].
	^ String streamContents: [ :stream |
		  stream << (', ' join: (names first: 5)) << ', and ' << (names size - 5) printString << ' more' ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> referencesOutsideRemoval [
	"Class name to the methods that refer to it, outside the classes asked for, on either side, found by the test method_reference_search makes among the methods that may refer to the classes."

	| references |
	references := Dictionary new.
	self resolvedClasses do: [ :each |
			((MCPClassReferenceQuery forClass: each) methodsReferringIn: self methodsThatMayRefer) ifNotEmpty: [ :referring |
				references at: each name asString put: referring ] ].
	^ references
]

{ #category : 'private' }
MCPRemoveClassesCommand >> removePackageIfNowEmptyNamed: aPackageName recordingInto: removedPackageNamesCollection [

	(self removePackageIfEmptyNamed: aPackageName) ifTrue: [
		(removedPackageNamesCollection includes: aPackageName) ifFalse: [ removedPackageNamesCollection add: aPackageName ] ]
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> removedMethodNames [
	"The methods that went with the classes execute removed, as Pharo writes them."

	^ removedMethodNames
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> removedPackageNames [
	"The packages execute removed because it left them empty."

	^ removedPackageNames
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> reparentedSubclassNames [
	"The subclasses execute moved to the superclass of a class it removed."

	^ reparentedSubclassNames
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> reparentedSubclassNamesBySuperclassName [
	"The subclasses execute moved, each once, under the name of the class it inherits from now, as the image has it."

	| grouped |
	grouped := OrderedDictionary new.
	self reparentedSubclassNames do: [ :each |
			| names |
			names := grouped at: (MCPImageLookup classNamed: each) superclass name asString ifAbsentPut: [ OrderedCollection new ].
			(names includes: each) ifFalse: [ names add: each ] ].
	^ grouped
]

{ #category : 'private' }
MCPRemoveClassesCommand >> resolvedClasses [

	^ resolvedClasses ifNil: [ resolvedClasses := self classNames collect: [ :each | MCPImageLookup classNamed: each ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> shouldReparentSubclassesWhenRemoving: aClass [
	"An empty class's subclasses move up to its superclass, and with force a non-empty one's too."

	aClass subclasses ifEmpty: [ ^ false ].
	aClass superclass ifNil: [ ^ false ].
	^ self force or: [ self isEmptyClass: aClass ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> signalBlockedBy: anException [
	"Force is offered only where it gets past the check."

	| facts forceSupported howToProceed names |
	facts := self blockingFactsFor: anException.
	forceSupported := self forceGoesPast: anException.
	howToProceed := forceSupported
		                ifTrue: [ 'Change that first, or resend with force: true to remove anyway.' ]
		                ifFalse: [ 'Change that first: force does not get past this check in this Pharo version.' ].
	names := self resolvedClasses collect: [ :each | each name asString ] as: Array.
	^ MCPCommandError
		  signalClassRemovalBlocked: (String streamContents: [ :stream |
				   stream << 'Did not remove ' << (', ' join: names) << '. ' << (' ' join: facts) << ' ' << howToProceed ])
		  details: (Dictionary new
				   at: #classes put: names;
				   at: #impactMessages put: facts;
				   at: #howToProceed put: howToProceed;
				   at: #forceSupported put: forceSupported;
				   yourself)
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> subclassNamesOf: aClass excluding: someNames [
	"The names of aClass's direct subclasses that are not among someNames, in order."

	^ ((aClass subclasses collect: [ :each | each name asString ] as: Array) reject: [ :each | someNames includes: each ]) sort
]

{ #category : 'private' }
MCPRemoveClassesCommand >> subclassNamesReparentedWhenRemoving: aClass [
	"A subclass asked for in the same call is removed, not reparented."

	(self shouldReparentSubclassesWhenRemoving: aClass) ifFalse: [ ^ #(  ) ].
	^ self subclassNamesOf: aClass excluding: (self resolvedClasses collect: [ :each | each name asString ])
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> subclassesBlockingRemovalOf: aClass [
	"An empty class's subclasses are reparented to its superclass; a non-empty one's block its removal, unless they go with it."

	(self isEmptyClass: aClass) ifTrue: [ ^ #(  ) ].
	^ self subclassNamesOf: aClass excluding: (self resolvedClasses collect: [ :each | each name asString ])
]

{ #category : 'private' }
MCPRemoveClassesCommand >> validatePreparedRefactoring: aRefactoring [
	"Pharo's check decides whether the removal is blocked, and the image says what blocks it. Force goes past a warning, and the removal then warns with the same facts, as they stand once the classes are gone; it cannot go past an error, which is all Pharo 10 and 11 signal."

	| blocking warnings |
	warnings := OrderedCollection new.
	[ aRefactoring checkPreconditions ]
		on: RBRefactoringWarning , RBRefactoringError
		do: [ :exception |
				(self force and: [ self forceGoesPast: exception ])
					ifTrue: [
							warnings addAll: (self forcedFactsFor: exception).
							exception resume: true ]
					ifFalse: [ blocking := exception ] ].
	blocking ifNotNil: [ self signalBlockedBy: blocking ].
	^ warnings asArray
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> warningMessages [
	"What blocked the removal and force went past, one sentence per fact."

	^ warningMessages
]
