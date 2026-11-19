"
Removes a slot from a class or metaclass through the refactoring engine.
"
Class {
	#name : 'MCPRemoveSlotCommand',
	#superclass : 'MCPClassSlotCommand',
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRemoveSlotCommand class >> className: aClassName slotName: aSlotName classSide: aBoolean [

	^ self new
		  className: aClassName;
		  slotName: aSlotName;
		  classSide: aBoolean;
		  yourself
]

{ #category : 'private' }
MCPRemoveSlotCommand >> directlyDefinesSlotNamed: aSlotName inBehavior: aBehavior [

	^ aBehavior slots anySatisfy: [ :each | each name asString = aSlotName ]
]

{ #category : 'executing' }
MCPRemoveSlotCommand >> execute [

	| refactoringBehavior |
	refactoringBehavior := self refactoringBehaviorForClass: self currentClass.
	self classSide
		ifTrue: [ self removeClassSideSlotFromBehavior: refactoringBehavior ]
		ifFalse: [ (self refactoringForBehavior: refactoringBehavior) execute ].
	^ Smalltalk globals at: self className asSymbol
]

{ #category : 'private' }
MCPRemoveSlotCommand >> normalizedBehaviorNameFor: aBehavior [

	^ (aBehavior isMeta
		   ifTrue: [ aBehavior instanceSide name ]
		   ifFalse: [ aBehavior name ]) asString
]

{ #category : 'private' }
MCPRemoveSlotCommand >> refactoringForBehavior: aBehavior [

	^ ReRemoveInstanceVariableRefactoring remove: self slotName from: aBehavior
]

{ #category : 'private' }
MCPRemoveSlotCommand >> removeClassSideSlotFromBehavior: aBehavior [

	(self directlyDefinesSlotNamed: self slotName inBehavior: aBehavior) ifFalse: [
			RBApplicabilityChecksFailedError signal: (String streamContents: [ :stream |
						 stream << 'The variable ' << self slotName << ' is not directly defined in the class '
						 << (self normalizedBehaviorNameFor: aBehavior) ]) ].
	self signalReferenceWarningIfNeededForBehavior: aBehavior.
	aBehavior removeInstVarNamed: self slotName
]

{ #category : 'private' }
MCPRemoveSlotCommand >> signalReferenceWarningIfNeededForBehavior: aBehavior [
	"The warning a slot removal stops at while methods use the slot, as RBRefactoringWarning, which every supported Pharo has and the tool lets force past: Pharo's breaking-change warning is missing from Pharo 10 and is a plain Warning in Pharo 11."

	| hasReferences |
	hasReferences := aBehavior withAllSubclasses anySatisfy: [ :each | (each whichMethodsAccess: self slotName) isNotEmpty ].
	hasReferences ifTrue: [
			RBRefactoringWarning signal:
				(String streamContents: [ :stream | stream << ' Variable ' << self slotName << ' is still referenced' ]) ]
]
