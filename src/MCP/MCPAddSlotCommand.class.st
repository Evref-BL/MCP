"
Adds a slot to a class or metaclass through the refactoring engine.
"
Class {
	#name : 'MCPAddSlotCommand',
	#superclass : 'MCPClassSlotCommand',
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
MCPAddSlotCommand >> refactoringForBehavior: aBehavior [

	^ RBAddInstanceVariableRefactoring
		  variable: self slotName
		  class: aBehavior
]
