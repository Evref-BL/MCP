"
Abstract command for a change to one slot of a class.

It defines slotName and classSide, and executing it applies the change to the class or its class side as classSide says; subclasses make the change in applyToBehavior:.
"
Class {
	#name : 'MCPClassSlotCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'slotName',
		'classSide'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'testing' }
MCPClassSlotCommand class >> isAbstract [

	^ self == MCPClassSlotCommand
]

{ #category : 'private' }
MCPClassSlotCommand >> applyToBehavior: aBehavior [
	"Make the change on aBehavior, the class or its class side as classSide says."

	self subclassResponsibility
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
MCPClassSlotCommand >> definesSlotNamed: aSlotName in: aBehavior [

	^ aBehavior slots anySatisfy: [ :each | each name asString = aSlotName asString ]
]

{ #category : 'executing' }
MCPClassSlotCommand >> execute [

	self applyToBehavior: (self refactoringBehaviorForClass: self currentClass).
	^ self currentClass
]

{ #category : 'private' }
MCPClassSlotCommand >> refactoringBehaviorForClass: aClass [

	^ self classSide
		  ifTrue: [ aClass classSide ]
		  ifFalse: [ aClass ]
]

{ #category : 'accessing' }
MCPClassSlotCommand >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPClassSlotCommand >> slotName: aSlotName [

	slotName := aSlotName
]

{ #category : 'private' }
MCPClassSlotCommand >> validateSlotIsDefinedIn: aBehavior [

	(self definesSlotNamed: self slotName in: aBehavior) ifFalse: [
			RBRefactoringError signal: (String streamContents: [ :stream |
					 stream << 'The variable ' << self slotName << ' is not directly defined in the class ' << self className ]) ]
]
