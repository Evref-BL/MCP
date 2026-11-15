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

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> blockingFactsFor: anException [
	"One sentence per fact, class by class: the methods outside the removal that refer to it, and the subclasses not asked for of one that is not empty. When none explains the check, its own text, on one line."

	| references facts |
	references := self referencesOutsideRemoval.
	facts := Array streamContents: [ :stream |
			         self resolvedClasses do: [ :each |
					         references
						         at: each name asString
						         ifPresent: [ :methods | stream nextPut: each name , ' is referred to by ' , (self referenceListOf: methods) , '.' ].
					         (self subclassesBlockingRemovalOf: each) ifNotEmpty: [ :names |
						         stream nextPut: each name , ' is not empty and has subclasses: ' , (', ' join: names) , '.' ] ] ].
	^ facts ifEmpty: [ { (MCPRefactoringText withoutNegation: (MCPRefactoringText singleLine: anException messageText)) } ]
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
MCPRemoveClassesCommand >> referenceListOf: someMethods [
	"The first five, then how many more: method_reference_search lists them all."

	| names |
	names := (someMethods collect: [ :each | each methodClass name , '>>' , each selector ] as: Set) asArray sort.
	names size <= 5 ifTrue: [ ^ ', ' join: names ].
	^ (', ' join: (names first: 5)) , ', and ' , (names size - 5) printString , ' more'
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
MCPRemoveClassesCommand >> signalBlockedBy: anException [
	"Force is offered only where it gets past the check."

	| facts forceSupported howToProceed |
	facts := self blockingFactsFor: anException.
	forceSupported := self forceGoesPast: anException.
	howToProceed := forceSupported
		                ifTrue: [ 'Change that first, or resend with force: true to remove anyway.' ]
		                ifFalse: [ 'Change that first: force does not get past this check in this Pharo version.' ].
	^ MCPCommandError
		  signalClassRemovalBlocked:
			  'Did not remove ' , (', ' join: (self resolvedClasses collect: [ :each | each name ])) , '. ' , (' ' join: facts) , ' '
			  , howToProceed
		  details: (Dictionary new
				   at: #classes put: (self resolvedClasses collect: [ :each | each name asString ]) asArray;
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

{ #category : 'private - facts' }
MCPRemoveClassesCommand >> subclassesBlockingRemovalOf: aClass [
	"An empty class's subclasses are reparented to its superclass; a non-empty one's block its removal, unless they go with it."

	(self isEmptyClass: aClass) ifTrue: [ ^ #(  ) ].
	^ self subclassNamesOf: aClass excluding: (self resolvedClasses collect: [ :each | each name asString ])
]

{ #category : 'private' }
MCPRemoveClassesCommand >> validatePreparedRefactoring: aRefactoring [
	"Pharo's check decides whether the removal is blocked, and the image says what blocks it. Force goes past a warning, and the removal then warns with the same facts; it cannot go past an error, which is all Pharo 10 and 11 signal."

	| blocking warningMessages |
	warningMessages := OrderedCollection new.
	[ aRefactoring checkPreconditions ]
		on: RBRefactoringWarning , RBRefactoringError
		do: [ :exception |
				(self force and: [ self forceGoesPast: exception ])
					ifTrue: [
							warningMessages addAll: (self blockingFactsFor: exception).
							exception resume: true ]
					ifFalse: [ blocking := exception ] ].
	blocking ifNotNil: [ self signalBlockedBy: blocking ].
	^ warningMessages asArray
]
