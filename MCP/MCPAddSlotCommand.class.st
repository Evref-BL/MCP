"
Adds a slot to a class or metaclass through the refactoring engine.
"
Class {
	#name : 'MCPAddSlotCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'slotName',
		'classSide'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPAddSlotCommand class >> className: aClassName slotName: aSlotName classSide: aBoolean [

	^ self new
		  className: aClassName;
		  slotName: aSlotName;
		  classSide: aBoolean;
		  yourself
]

{ #category : 'accessing' }
MCPAddSlotCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPAddSlotCommand >> className: aClassName [

	className := aClassName
]

{ #category : 'accessing' }
MCPAddSlotCommand >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPAddSlotCommand >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'private' }
MCPAddSlotCommand >> currentClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]

{ #category : 'executing' }
MCPAddSlotCommand >> execute [

	| currentClass refactoringBehavior updatedClass |
	currentClass := self currentClass.
	refactoringBehavior := self refactoringBehaviorForClass: currentClass.
	(self refactoringForBehavior: refactoringBehavior) execute.
	updatedClass := Smalltalk globals at: self className asSymbol.
	^ MCPSlotResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  slotName: self slotName
		  classSide: self classSide
]

{ #category : 'private' }
MCPAddSlotCommand >> refactoringBehaviorForClass: aClass [

	^ self classSide
		  ifTrue: [ aClass classSide ]
		  ifFalse: [ aClass ]
]

{ #category : 'private' }
MCPAddSlotCommand >> refactoringForBehavior: aBehavior [

	^ RBAddInstanceVariableRefactoring
		  variable: self slotName
		  class: aBehavior
]

{ #category : 'accessing' }
MCPAddSlotCommand >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPAddSlotCommand >> slotName: aSlotName [

	slotName := aSlotName
]
