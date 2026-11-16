"
Adds a slot to a class or metaclass through the refactoring engine.
"
Class {
	#name : 'MCPAddSlotCommand',
	#superclass : 'MCPClassSlotCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
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

	(self refactoringForBehavior: (self refactoringBehaviorForClass: self currentClass)) execute.
	^ Smalltalk globals at: self className asSymbol
]

{ #category : 'private' }
MCPAddSlotCommand >> refactoringForBehavior: aBehavior [

	^ RBAddInstanceVariableRefactoring variable: self slotName class: aBehavior
]
