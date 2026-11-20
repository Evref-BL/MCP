"
Abstract command for a change to one slot of a class.

It defines slotName and classSide, and executing it applies the change to the class or its class side as classSide says; subclasses make the change in applyToBehavior:. Each object at or below the class keeps what each of its slots still there holds.
"
Class {
	#name : 'MCPClassSlotCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'slotName',
		'classSide',
		'heldValues'
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
	"A move takes a slot out of a class before it puts it back, a rename hands what a slot holds to a slot of another name, and from Pharo 12 a class that loses a slot is reshaped from its own slot objects, numbered anew before the instances are read through them, so each slot after the one removed takes what the slot before it held. What each slot at or below the class holds is put back under its name once the change is over, or has stopped, in the objects whose class Pharo reshaped: it leaves the others as they were."

	| behavior layouts |
	behavior := self refactoringBehaviorForClass: self currentClass.
	layouts := (behavior withAllSubclasses collect: [ :each | each classLayout ]) asIdentitySet.
	heldValues := self valuesHeldAtOrBelow: behavior.
	[ self installing: [ self applyToBehavior: behavior ] ] ensure: [ self restoreHeldValuesExceptUnder: layouts ].
	^ self currentClass
]

{ #category : 'private' }
MCPClassSlotCommand >> refactoringBehaviorForClass: aClass [

	^ self classSide
		  ifTrue: [ aClass classSide ]
		  ifFalse: [ aClass ]
]

{ #category : 'private' }
MCPClassSlotCommand >> restoreHeldValuesExceptUnder: someLayouts [
	"Each field goes back in place, wherever its slot now is, and nowhere for an object whose class no longer has the slot, or still has a layout of someLayouts: Pharo left that object as it was, and may have numbered anew the slots of its class. A read-only object stays read-only."

	heldValues do: [ :each |
			| holder |
			holder := each key.
			(someLayouts includes: holder class classLayout) ifFalse: [
					holder class slotNamed: (self slotNameAfterChange: each value key) ifFound: [ :slot |
							| readOnly |
							readOnly := holder beWritableObject.
							thisContext object: holder instVarAt: slot index put: each value value.
							holder setIsReadOnlyObject: readOnly ] ] ]
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
MCPClassSlotCommand >> slotNameAfterChange: aSlotName [
	"The name of the slot that holds after the change what the slot named aSlotName held before it."

	^ aSlotName
]

{ #category : 'private' }
MCPClassSlotCommand >> validateSlotIsDefinedIn: aBehavior [

	(self definesSlotNamed: self slotName in: aBehavior) ifFalse: [
			RBRefactoringError signal: (String streamContents: [ :stream |
					 stream << 'The variable ' << self slotName << ' is not directly defined in the class ' << self className ]) ]
]

{ #category : 'private' }
MCPClassSlotCommand >> valuesHeldAtOrBelow: aBehavior [
	"Each object whose class is aBehavior or one below it, with the name and the field of each slot defined at or below aBehavior, a hidden one included since it holds what virtual ones answer, nil included. A field is read as the object stores it, since a slot class of its own may compute or refuse what it reads, and an object need not inherit from Object. The slots aBehavior inherits keep their place, and a virtual slot has no field. Finding the instances of a class searches memory, but the only instance of a class side is its class."

	| inherited |
	inherited := aBehavior superclass ifNil: [ #(  ) ] ifNotNil: [ :superclass | superclass classLayout allSlots ].
	^ aBehavior withAllSubclasses flatCollect: [ :eachClass |
			  | slots |
			  slots := eachClass classLayout allSlots reject: [ :each | each isVirtual or: [ inherited includes: each ] ].
			  (eachClass isMeta
				   ifTrue: [ { eachClass instanceSide } ]
				   ifFalse: [ eachClass allInstances ]) flatCollect: [ :holder |
				  slots collect: [ :each | Association key: holder value: each name -> (thisContext object: holder instVarAt: each index) ] ] ]
]
