Class {
	#name : 'MCPReparentClassCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'superclassName'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPReparentClassCommand class >> className: aClassName superclassName: aSuperclassName [

	^ self new
		  className: aClassName;
		  superclassName: aSuperclassName;
		  yourself
]

{ #category : 'private' }
MCPReparentClassCommand >> builderForReparenting: aClass toSuperclass: aSuperclass [

	| builder |
	builder := ShiftClassBuilder new.
	builder fillInstanceSideFromClass: aClass.
	builder fillClassSideFromEnvironment: aClass environment.
	builder name: aClass name.
	builder superclass: aSuperclass.
	^ builder
]

{ #category : 'accessing' }
MCPReparentClassCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPReparentClassCommand >> className: aString [

	className := aString
]

{ #category : 'private' }
MCPReparentClassCommand >> currentClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]

{ #category : 'executing' }
MCPReparentClassCommand >> execute [

	| currentClass currentSuperclassName updatedClass superclass |
	currentClass := self currentClass.
	currentSuperclassName := currentClass superclass
		                         ifNil: [ '' ]
		                         ifNotNil: [ :aSuperclass |
		                         aSuperclass name asString ].
	currentSuperclassName = self superclassName ifTrue: [
		^ MCPReparentClassResult
			  classInfo: (MCPClassInfo fromClass: currentClass)
			  oldSuperclassName: currentSuperclassName ].
	superclass := self newSuperclass.
	(self builderForReparenting: currentClass toSuperclass: superclass)
		install.
	updatedClass := Smalltalk globals at: self className asSymbol.
	^ MCPReparentClassResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  oldSuperclassName: currentSuperclassName
]

{ #category : 'private' }
MCPReparentClassCommand >> newSuperclass [

	^ Smalltalk globals at: self superclassName asSymbol ifAbsent: [
		  MCPCommandError
			  signalMissingSuperclassNamed: self superclassName
			  forClassNamed: self className ]
]

{ #category : 'accessing' }
MCPReparentClassCommand >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
MCPReparentClassCommand >> superclassName: aString [

	superclassName := aString
]
