Class {
	#name : 'MCPRemoveClassCommand',
	#superclass : 'Object',
	#instVars : [
		'className'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPRemoveClassCommand class >> className: aClassName [

	^ self new
		  className: aClassName;
		  yourself
]

{ #category : 'private' }
MCPRemoveClassCommand >> applySafeRemovalOf: aClass reparentedSubclassNames: someNames [

	| targetSuperclass |
	someNames ifNotEmpty: [
		targetSuperclass := aClass superclass.
		aClass subclasses do: [ :each | each superclass: targetSuperclass ] ].
	aClass removeFromSystem
]

{ #category : 'accessing' }
MCPRemoveClassCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPRemoveClassCommand >> className: aString [

	className := aString
]

{ #category : 'executing' }
MCPRemoveClassCommand >> execute [

	| classInfo removedClass reparentedSubclassNames result wasEmpty |
	removedClass := Smalltalk globals
		                at: self className asSymbol
		                ifAbsent: [
		                MCPCommandError signalMissingClassNamed:
			                self className ].
	self validateSafeRemovalOfClassNamed: self className.
	classInfo := MCPClassInfo fromClass: removedClass.
	wasEmpty := self isEmptyClass: removedClass.
	reparentedSubclassNames := (wasEmpty and: [
		                            removedClass superclass notNil ])
		                           ifTrue: [ classInfo subclassNames ]
		                           ifFalse: [ #(  ) ].
	self
		applySafeRemovalOf: removedClass
		reparentedSubclassNames: reparentedSubclassNames.
	result := MCPRemoveClassResult
		          classInfo: classInfo
		          wasEmpty: wasEmpty
		          reparentedToSuperclassName:
			          (reparentedSubclassNames isEmpty
				           ifTrue: [ '' ]
				           ifFalse: [ classInfo superclassName ])
		          reparentedSubclassNames: reparentedSubclassNames.
	^ result
]

{ #category : 'private' }
MCPRemoveClassCommand >> isEmptyClass: aClass [

	^ aClass classVarNames isEmpty and: [
		  aClass instVarNames isEmpty and: [ aClass selectors isEmpty ] ]
]

{ #category : 'private' }
MCPRemoveClassCommand >> validateSafeRemovalOfClassNamed: aClassName [

	| refactoring |
	refactoring := ReRemoveClassRefactoring classNames: { aClassName }.
	refactoring prepareForExecution.
	refactoring checkPreconditions
]
