"
Moves a slot up or down a class hierarchy and answers the class.

It performs pull-up or push-down refactorings for instance-side or class-side slots. Each instance below the class keeps what the slot held in it.
"
Class {
	#name : 'MCPMoveSlotCommand',
	#superclass : 'MCPClassSlotCommand',
	#instVars : [
		'direction',
		'heldValues'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPMoveSlotCommand class >> className: aClassName slotName: aSlotName direction: aDirection classSide: aBoolean [

	^ self new
		  className: aClassName;
		  slotName: aSlotName;
		  direction: aDirection;
		  classSide: aBoolean;
		  yourself
]

{ #category : 'private' }
MCPMoveSlotCommand >> applyToBehavior: aBehavior [
	"RB moves the slot by two class changes, taking it out before it puts it where it goes, so what it held is gone in between. What the slot holds below aBehavior is put back wherever the slot is once the move is over, or has stopped."

	self validatePullUpInto: aBehavior.
	heldValues := self valuesHeldBelow: aBehavior.
	[ (self refactoringForBehavior: aBehavior) execute ] ensure: [
		heldValues do: [ :each | (self holdsSlot: each key) ifTrue: [ each key writeSlotNamed: self slotName value: each value ] ] ]
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> direction [

	^ direction
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> direction: aDirection [

	direction := aDirection
]

{ #category : 'private' }
MCPMoveSlotCommand >> holdsSlot: anObject [

	^ anObject class hasSlotNamed: self slotName
]

{ #category : 'private' }
MCPMoveSlotCommand >> pullUpRefusalFor: aSlot in: aBehavior [
	"A slot the class defines itself suggests the caller named the class the slot is in, so the answer names the superclass to use. A slot a trait supplies is not the class's to move, and no superclass would help."

	^ String streamContents: [ :stream |
			  stream << self className << ' already has ' << self slotName.
			  aSlot isDefinedByOwningClass
				  ifTrue: [
						  stream << '. pullUp moves a slot into the class it names, from the subclasses that define it'.
						  aBehavior instanceSide superclass ifNotNil: [ :superclass |
							  stream << ': name ' << superclass name << ' to move ' << self slotName << ' up from ' << self className ] ]
				  ifFalse: [ stream << ', which the trait ' << aSlot definingClass name << ' supplies' ].
			  stream nextPut: $. ]
]

{ #category : 'private' }
MCPMoveSlotCommand >> refactoringForBehavior: aBehavior [

	^ (self direction = 'pullUpSlot'
		   ifTrue: [ RePullUpInstanceVariableRefactoring ]
		   ifFalse: [
				   self direction = 'pushDownSlot'
					   ifTrue: [ RBPushDownInstanceVariableRefactoring ]
					   ifFalse: [ Error signal: 'direction must be pullUpSlot or pushDownSlot.' ] ]) variable: self slotName class: aBehavior
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> unrestoredHolders [
	"The objects whose value the move could not put back, because it stopped partway with their class lacking the slot."

	^ (heldValues ifNil: [ #(  ) ]) collect: [ :each | each key ] thenReject: [ :each | self holdsSlot: each ]
]

{ #category : 'private' }
MCPMoveSlotCommand >> validatePullUpInto: aBehavior [
	"A pull-up moves the slot into the class it names. Named on a class that already has the slot, the refactoring fails on a duplicate slot without saying which class to name."

	self direction = 'pullUpSlot' ifFalse: [ ^ self ].
	aBehavior slots
		detect: [ :each | each name asString = self slotName ]
		ifFound: [ :slot | RBRefactoringError signal: (self pullUpRefusalFor: slot in: aBehavior) ]
		ifNone: [ ]
]

{ #category : 'private' }
MCPMoveSlotCommand >> valuesHeldBelow: aBehavior [
	"Each instance of a subclass of aBehavior with what the slot holds there, unless nil, which a slot holds once added. An instance of aBehavior itself has no such slot in a pull-up, and loses it in a push-down. The instances of a class side are its classes."

	^ ((aBehavior allSubclasses select: [ :each | each hasSlotNamed: self slotName ]) flatCollect: [ :each | each allInstances ])
		  collect: [ :each | each -> (each readSlotNamed: self slotName) ]
		  thenSelect: [ :each | each value isNotNil ]
]
