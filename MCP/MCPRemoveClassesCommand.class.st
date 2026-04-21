Class {
	#name : 'MCPRemoveClassesCommand',
	#superclass : 'Object',
	#instVars : [
		'className'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPRemoveClassesCommand class >> classNames: someClassNames [

	^ self new
		  classNames: someClassNames;
		  yourself
]

{ #category : 'private' }
MCPRemoveClassesCommand >> applySafeRemovalOf: aClass reparentedSubclassNames: someNames [

	| targetSuperclass |
	someNames ifNotEmpty: [
		targetSuperclass := aClass superclass.
		aClass subclasses do: [ :each | each superclass: targetSuperclass ] ].
	aClass removeFromSystem
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> classNames [

	^ className ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPRemoveClassesCommand >> classNames: someClassNames [

	className := someClassNames
		             ifNil: [ #(  ) ]
		             ifNotNil: [ someClassNames asArray ]
]

{ #category : 'executing' }
MCPRemoveClassesCommand >> execute [

	| removedClasses removedPackageNames resolvedClasses |
	resolvedClasses := self resolvedClasses.
	self validateSafeRemovalOfClassNames: self classNames.
	removedClasses := resolvedClasses collect: [ :each |
		                  self resultForRemovedClass: each ].
	removedPackageNames := OrderedCollection new.
	resolvedClasses with: removedClasses do: [ :eachClass :eachResult |
		self
			applySafeRemovalOf: eachClass
			reparentedSubclassNames: eachResult reparentedSubclassNames.
		self
			removePackageIfNowEmptyNamed: eachResult classInfo packageName
			recordingInto: removedPackageNames ].
	^ MCPRemoveClassesResult
		  removedClasses: removedClasses
		  removedPackageNames: removedPackageNames
]

{ #category : 'private' }
MCPRemoveClassesCommand >> isEmptyClass: aClass [

	^ aClass classVarNames isEmpty and: [
		  aClass instVarNames isEmpty and: [ aClass selectors isEmpty ] ]
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
	reparentedSubclassNames := (wasEmpty and: [ aClass superclass notNil ])
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
MCPRemoveClassesCommand >> validateSafeRemovalOfClassNames: someClassNames [

	| refactoring |
	refactoring := ReRemoveClassRefactoring classNames: someClassNames.
	refactoring prepareForExecution.
	refactoring checkPreconditions
]
