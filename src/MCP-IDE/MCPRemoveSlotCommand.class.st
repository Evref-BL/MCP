"
Removes a slot from a class through the refactoring engine, or from its class side directly, refusing a slot the class side does not define itself and warning while methods use it.
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
MCPRemoveSlotCommand >> applyToBehavior: aBehavior [

	self classSide ifTrue: [ ^ self removeClassSideSlotFromBehavior: aBehavior ].
	(ReRemoveInstanceVariableRefactoring remove: self slotName from: aBehavior) execute
]

{ #category : 'private' }
MCPRemoveSlotCommand >> removeClassSideSlotFromBehavior: aBehavior [

	self validateSlotIsDefinedIn: aBehavior.
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
