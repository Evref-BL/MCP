Class {
	#name : 'MCPMoveSlotCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'slotName',
		'direction',
		'classSide'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
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
			             aBehavior allSubclasses select: [ :each |
				             self
					             directlyDefinesSlotNamed: self slotName
					             inBehavior: each ] ]
		             ifFalse: [
			             self direction = 'pushDownSlot'
				             ifTrue: [ aBehavior subclasses ]
				             ifFalse: [
				             Error signal:
					             'direction must be pullUpSlot or pushDownSlot.' ] ].
	^ ((behaviors collect: [ :each |
		    self normalizedAffectedClassNameFor: each ])
		   asSortedCollection: [ :left :right | left <= right ]) asArray
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> className: aClassName [

	className := aClassName
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'private' }
MCPMoveSlotCommand >> currentClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
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

	^ aBehavior slots anySatisfy: [ :each |
		  each name asString = aSlotName ]
]

{ #category : 'executing' }
MCPMoveSlotCommand >> execute [

	| affectedClassNames currentClass refactoring refactoringBehavior updatedClass |
	currentClass := self currentClass.
	refactoringBehavior := self refactoringBehaviorForClass: currentClass.
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
MCPMoveSlotCommand >> refactoringBehaviorForClass: aClass [

	^ self classSide
		  ifTrue: [ aClass classSide ]
		  ifFalse: [ aClass ]
]

{ #category : 'private' }
MCPMoveSlotCommand >> refactoringForBehavior: aBehavior [

	^ (self direction = 'pullUpSlot'
		   ifTrue: [ RBPullUpInstanceVariableRefactoring ]
		   ifFalse: [
			   self direction = 'pushDownSlot'
				   ifTrue: [ RBPushDownInstanceVariableRefactoring ]
				   ifFalse: [
				   Error signal: 'direction must be pullUpSlot or pushDownSlot.' ] ])
		  variable: self slotName
		  class: aBehavior
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPMoveSlotCommand >> slotName: aSlotName [

	slotName := aSlotName
]
