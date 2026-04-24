Class {
	#name : 'MCPRemoveClassesCommand',
	#superclass : 'Object',
	#instVars : [
		'classNames',
		'force'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
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

	classNames := someClassNames
		             ifNil: [ #(  ) ]
		             ifNotNil: [ someClassNames asArray ]
]

{ #category : 'executing' }
MCPRemoveClassesCommand >> execute [

	| refactoring removedClasses removedPackageNames resolvedClasses warningMessages |
	resolvedClasses := self resolvedClasses.
	refactoring := self preparedRefactoringForClassNames: self classNames.
	warningMessages := self validatePreparedRefactoring: refactoring.
	removedClasses := resolvedClasses collect: [ :each |
		                  self resultForRemovedClass: each ].
	self performRemovalWithPreparedRefactoring: refactoring.
	removedPackageNames := OrderedCollection new.
	removedClasses do: [ :eachResult |
		self
			removePackageIfNowEmptyNamed: eachResult classInfo packageName
			recordingInto: removedPackageNames ].
	^ MCPRemoveClassesResult
		  removedClasses: removedClasses
		  removedPackageNames: removedPackageNames
		  warningMessages: warningMessages
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> force [

	^ force = true
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> force: aBoolean [

	force := aBoolean
]

{ #category : 'private' }
MCPRemoveClassesCommand >> isEmptyClass: aClass [

	^ aClass classVarNames isEmpty and: [
		  aClass instVarNames isEmpty and: [ aClass selectors isEmpty ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> performRemovalWithPreparedRefactoring: aRefactoring [

	aRefactoring removeClassChanges.
	aRefactoring performChanges
]

{ #category : 'private' }
MCPRemoveClassesCommand >> preparedRefactoringForClassNames: someClassNames [

	| refactoring |
	refactoring := ReRemoveClassRefactoring classNames:
		               (someClassNames collect: #asSymbol).
	refactoring prepareForExecution.
	^ refactoring
]

{ #category : 'private' }
MCPRemoveClassesCommand >> removePackageIfNowEmptyNamed: aPackageName recordingInto: removedPackageNamesCollection [

	aPackageName = '_UnpackagedPackage' ifTrue: [ ^ self ].
	PackageOrganizer default
		packageNamed: aPackageName
		ifPresent: [ :package |
			package definedClasses isEmpty ifTrue: [
				PackageOrganizer default removePackage: package.
				(removedPackageNamesCollection includes: aPackageName) ifFalse: [
					removedPackageNamesCollection add: aPackageName ] ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> resolvedClasses [

	^ self classNames collect: [ :each |
		  Smalltalk globals
			  at: each asSymbol
			  ifAbsent: [ MCPCommandError signalMissingClassNamed: each ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> resultForRemovedClass: aClass [

	| classInfo reparentedSubclassNames wasEmpty |
	classInfo := MCPClassInfo fromClass: aClass.
	wasEmpty := self isEmptyClass: aClass.
	reparentedSubclassNames := (self
		                            shouldReparentSubclassesWhenRemoving:
		                            aClass
		                            wasEmpty: wasEmpty)
		                           ifTrue: [ classInfo subclassNames ]
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

	^ aClass subclasses notEmpty and: [
		  aClass superclass notNil and: [ self force or: [ wasEmpty ] ] ]
]

{ #category : 'private' }
MCPRemoveClassesCommand >> validatePreparedRefactoring: aRefactoring [

	| warningMessages |
	warningMessages := OrderedCollection new.
	self force
		ifTrue: [
			[ aRefactoring checkPreconditions ]
				on: RBRefactoringWarning
				do: [ :warning |
					warningMessages add: warning messageText.
					warning resume: true ] ]
		ifFalse: [ aRefactoring checkPreconditions ].
	^ warningMessages asArray
]
