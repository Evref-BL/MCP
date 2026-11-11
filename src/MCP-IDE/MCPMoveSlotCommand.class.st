"
Command that moves a slot up or down a class hierarchy.

It performs pull-up or push-down refactorings for instance-side or class-side slots and returns the affected class names.
"
Class {
	#name : 'MCPMoveSlotCommand',
	#superclass : 'MCPClassSlotCommand',
	#instVars : [
		'direction'
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
MCPMoveSlotCommand >> affectedClassNamesFor: aBehavior [

	| behaviors |
	behaviors := self direction = 'pullUpSlot'
		             ifTrue: [
		             aBehavior allSubclasses select: [ :each | self directlyDefinesSlotNamed: self slotName inBehavior: each ] ]
		             ifFalse: [
				             self direction = 'pushDownSlot'
					             ifTrue: [ aBehavior subclasses ]
					             ifFalse: [ Error signal: 'direction must be pullUpSlot or pushDownSlot.' ] ].
	^ (behaviors collect: [ :each | self normalizedAffectedClassNameFor: each ] as: Array) sort: [ :left :right | left <= right ]
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
MCPMoveSlotCommand >> directlyDefinesSlotNamed: aSlotName inBehavior: aBehavior [

	^ aBehavior slots anySatisfy: [ :each | each name asString = aSlotName ]
]

{ #category : 'executing' }
MCPMoveSlotCommand >> execute [

	| affectedClassNames currentClass refactoring refactoringBehavior updatedClass |
	currentClass := self currentClass.
	refactoringBehavior := self refactoringBehaviorForClass: currentClass.
	self validatePullUpInto: refactoringBehavior.
	affectedClassNames := self affectedClassNamesFor: refactoringBehavior.
	refactoring := self refactoringForBehavior: refactoringBehavior.
	refactoring execute.
	updatedClass := Smalltalk globals at: self className asSymbol.
	^ MCPMoveSlotResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  slotName: self slotName
		  classSide: self classSide
		  affectedClassNames: affectedClassNames
]

{ #category : 'private' }
MCPMoveSlotCommand >> normalizedAffectedClassNameFor: aBehavior [

	^ (aBehavior isMeta
		   ifTrue: [ aBehavior instanceSide name ]
		   ifFalse: [ aBehavior name ]) asString
]

{ #category : 'private' }
MCPMoveSlotCommand >> pullUpRefusalFor: aSlot in: aBehavior [
	"A slot the class defines itself suggests the caller named the class the slot is in, so the answer names the superclass to use. A slot a trait supplies is not the class's to move, and no superclass would help."

	| holderName |
	holderName := self normalizedAffectedClassNameFor: aBehavior.
	^ String streamContents: [ :stream |
			  stream << holderName << ' already has ' << self slotName.
			  aSlot isDefinedByOwningClass
				  ifTrue: [
						  stream << '. pullUp moves a slot into the class it names, from the subclasses that define it'.
						  aBehavior instanceSide superclass ifNotNil: [ :superclass |
							  stream << ': name ' << superclass name << ' to move ' << self slotName << ' up from ' << holderName ] ]
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

{ #category : 'private' }
MCPMoveSlotCommand >> validatePullUpInto: aBehavior [
	"A pull-up moves the slot into the class it names. Named on a class that already has the slot, the refactoring fails on a duplicate slot without saying which class to name."

	self direction = 'pullUpSlot' ifFalse: [ ^ self ].
	aBehavior slots
		detect: [ :each | each name asString = self slotName ]
		ifFound: [ :slot | RBRefactoringError signal: (self pullUpRefusalFor: slot in: aBehavior) ]
		ifNone: [ ]
]
