"
Abstract command for class-slot operations.

Subclasses provide #slotName, #classSide, and the operation-specific refactoring.
"
Class {
	#name : 'MCPClassSlotCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'slotName',
		'classSide'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPClassSlotCommand class >> isAbstract [

	^ self == MCPClassSlotCommand
]

{ #category : 'accessing' }
MCPClassSlotCommand >> classSide [

	^ classSide ifNil: [ false ]
]

{ #category : 'accessing' }
MCPClassSlotCommand >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'private' }
MCPClassSlotCommand >> refactoringBehaviorForClass: aClass [

	^ self classSide
		  ifTrue: [ aClass classSide ]
		  ifFalse: [ aClass ]
]

{ #category : 'private' }
MCPClassSlotCommand >> refactoringForBehavior: aBehavior [

	self subclassResponsibility
]

{ #category : 'accessing' }
MCPClassSlotCommand >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPClassSlotCommand >> slotName: aSlotName [

	slotName := aSlotName
]
