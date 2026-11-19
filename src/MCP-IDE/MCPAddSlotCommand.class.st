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

{ #category : 'private' }
MCPAddSlotCommand >> applyToBehavior: aBehavior [

	(RBAddInstanceVariableRefactoring variable: self slotName class: aBehavior) execute
]
