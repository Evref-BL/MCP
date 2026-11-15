"
Command that removes one or more classes from the image.

It gathers removal warnings, removes now-empty packages when applicable, and returns an MCPRemoveClassesResult describing removed classes and warnings.
"
Class {
	#name : 'MCPRemoveClassesCommand',
	#superclass : 'MCPCommand',
	#instVars : [
		'classNames',
		'force',
		'resolvedClasses'
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
	"The refactoring is handed the names of the classes the lookup resolved, not the request's text."

	| refactoring removedClasses removedPackageNames warningMessages |
	refactoring := self preparedRefactoringForClassNames: (self resolvedClasses collect: [ :each | each name ]).
	warningMessages := self validatePreparedRefactoring: refactoring.
	removedClasses := self resolvedClasses collect: [ :each | self resultForRemovedClass: each ].
	self performRemovalWithPreparedRefactoring: refactoring.
	removedPackageNames := OrderedCollection new.
	removedClasses do: [ :eachResult |
		self removePackageIfNowEmptyNamed: eachResult classInfo packageName recordingInto: removedPackageNames ].
	^ MCPRemoveClassesResult removedClasses: removedClasses removedPackageNames: removedPackageNames warningMessages: warningMessages
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

{ #category : 'private' }
MCPRemoveClassesCommand >> isEmptyClass: aClass [

	^ aClass classVarNames isEmpty and: [ aClass instVarNames isEmpty and: [ aClass selectors isEmpty ] ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> referencesOutsideRemoval [
	"Class name to the methods that refer to it, outside the classes asked for, on either side, found by the test method_reference_search makes. One scan of the image's methods per class asked for."

	| methods references |
	methods := OrderedCollection new.
	Smalltalk globals allBehaviorsDo: [ :behavior |
		(self resolvedClasses includes: behavior instanceSide) ifFalse: [ behavior methodsDo: [ :method | methods add: method ] ] ].
	references := Dictionary new.
	self resolvedClasses do: [ :each |
			((MCPClassReferenceQuery forClass: each) methodsReferringIn: methods) ifNotEmpty: [ :referring |
				references at: each name asString put: referring ] ].
	^ references
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> removalFactsFor: anException refactoring: aRefactoring [
	"What blocks the removal, gathered only once Pharo's check has refused it."

	^ MCPClassRemovalFacts new
		  classes: self resolvedClasses;
		  referencedBy: ((self referencesBlockingRemovalBy: anException refactoring: aRefactoring) collect: [ :methods |
					   MCPClassRemovalFacts referenceTextsOf: methods ]);
		  subclasses: self subclassesBlockingRemoval;
		  users: self usersBlockingRemoval;
		  forced: self force;
		  forceSupported: (self forceGoesPast: anException);
		  conditionText: anException messageText;
		  yourself
]

{ #category : 'private' }
MCPRemoveClassesCommand >> removePackageIfNowEmptyNamed: aPackageName recordingInto: removedPackageNamesCollection [

	aPackageName = '_UnpackagedPackage' ifTrue: [ ^ self ].
	self packageOrganizer packageNamed: aPackageName ifPresent: [ :package |
			package definedClasses isEmpty ifTrue: [
					self packageOrganizer removePackage: package.
					(removedPackageNamesCollection includes: aPackageName) ifFalse: [ removedPackageNamesCollection add: aPackageName ] ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> resolvedClasses [

	^ resolvedClasses ifNil: [ resolvedClasses := self classNames collect: [ :each | MCPImageLookup classNamed: each ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> resultForRemovedClass: aClass [
	"A subclass asked for in the same call is removed, not reparented."

	| classInfo reparentedSubclassNames wasEmpty |
	classInfo := MCPClassInfo fromClass: aClass.
	wasEmpty := self isEmptyClass: aClass.
	reparentedSubclassNames := (self shouldReparentSubclassesWhenRemoving: aClass wasEmpty: wasEmpty)
		                           ifTrue: [
		                           classInfo subclassNames reject: [ :each |
			                           self resolvedClasses anySatisfy: [ :removed | removed name asString = each ] ] ]
		                           ifFalse: [ #(  ) ].
	^ MCPRemoveClassResult
		  classInfo: classInfo
		  wasEmpty: wasEmpty
		  reparentedToSuperclassName: (reparentedSubclassNames isEmpty
				   ifTrue: [ '' ]
				   ifFalse: [ classInfo superclassName ])
		  reparentedSubclassNames: reparentedSubclassNames
]

{ #category : 'private' }
MCPRemoveClassesCommand >> shouldReparentSubclassesWhenRemoving: aClass wasEmpty: wasEmpty [

	aClass subclasses ifEmpty: [ ^ false ].
	aClass superclass ifNil: [ ^ false ].
	^ self force or: [ wasEmpty ]
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> subclassNamesOf: aClass excluding: someNames [
	"The names of aClass's direct subclasses that are not among someNames, in order."

	^ ((aClass subclasses collect: [ :each | each name asString ] as: Array) reject: [ :each | someNames includes: each ]) sort
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> subclassesBlockingRemoval [
	"Class name to the subclasses that block its removal. Only a class that is not empty is blocked by its subclasses: an empty one's are reparented to its superclass."

	| subclasses |
	subclasses := Dictionary new.
	self resolvedClasses do: [ :each |
			(self isEmptyClass: each) ifFalse: [
				(self subclassesBlockingRemovalOf: each) ifNotEmpty: [ :names | subclasses at: each name asString put: names ] ] ].
	^ subclasses
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> traitUserNamesOf: aClass [
	"The names of the classes and traits that use aClass, when it is a trait, in order."

	aClass isTrait ifFalse: [ ^ #(  ) ].
	^ (aClass users collect: [ :each | each name asString ] as: Set) asArray sort
]

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> usersBlockingRemoval [
	"Trait name to the classes using it that block its removal."

	| users |
	users := Dictionary new.
	self resolvedClasses do: [ :each |
		(self usersBlockingRemovalOf: each) ifNotEmpty: [ :names | users at: each name asString put: names ] ].
	^ users
]

{ #category : 'private' }
MCPRemoveClassesCommand >> validatePreparedRefactoring: aRefactoring [
	"Pharo's check decides whether the removal is blocked; what blocks it is said from what the image answers, never from the check's text. Force goes past a warning, and the removal then warns of what it left behind. It cannot go past an error, which is all Pharo 10 and 11 signal."

	| blocking warningMessages |
	warningMessages := OrderedCollection new.
	[ aRefactoring checkPreconditions ]
		on: RBRefactoringWarning , RBRefactoringError
		do: [ :exception |
				(self force and: [ self forceGoesPast: exception ])
					ifTrue: [
							warningMessages addAll: (self removalFactsFor: exception refactoring: aRefactoring) forcedWarnings.
							exception resume: true ]
					ifFalse: [ blocking := exception ] ].
	blocking ifNotNil: [ (self removalFactsFor: blocking refactoring: aRefactoring) signalBlocked ].
	^ warningMessages asArray
]
