"
Removes a slot from a class or metaclass through the refactoring engine.
"
Class {
	#name : 'MCPRemoveSlotCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'slotName',
		'classSide'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
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

{ #category : 'accessing' }
MCPRemoveSlotCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPRemoveSlotCommand >> className: aClassName [

	className := aClassName
]

{ #category : 'accessing' }
MCPRemoveSlotCommand >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPRemoveSlotCommand >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'private' }
MCPRemoveSlotCommand >> currentClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]

{ #category : 'private' }
MCPRemoveSlotCommand >> directlyDefinesSlotNamed: aSlotName inBehavior: aBehavior [

	^ aBehavior slots anySatisfy: [ :each |
		  each name asString = aSlotName ]
]

{ #category : 'executing' }
MCPRemoveSlotCommand >> execute [

	| currentClass refactoringBehavior updatedClass |
	currentClass := self currentClass.
	refactoringBehavior := self refactoringBehaviorForClass: currentClass.
	self classSide
		ifTrue: [ self removeClassSideSlotFromBehavior: refactoringBehavior ]
		ifFalse: [
		(self refactoringForBehavior: refactoringBehavior) execute ].
	updatedClass := Smalltalk globals at: self className asSymbol.
	^ MCPSlotResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  slotName: self slotName
		  classSide: self classSide
]

{ #category : 'private' }
MCPRemoveSlotCommand >> normalizedBehaviorNameFor: aBehavior [

	^ (aBehavior isMeta
		   ifTrue: [ aBehavior instanceSide name ]
		   ifFalse: [ aBehavior name ]) asString
]

{ #category : 'private' }
MCPRemoveSlotCommand >> refactoringBehaviorForClass: aClass [

	^ self classSide
		  ifTrue: [ aClass classSide ]
		  ifFalse: [ aClass ]
]

{ #category : 'private' }
MCPRemoveSlotCommand >> refactoringForBehavior: aBehavior [

	^ ReRemoveInstanceVariableRefactoring
		  remove: self slotName
		  from: aBehavior
]

{ #category : 'private' }
MCPRemoveSlotCommand >> removeClassSideSlotFromBehavior: aBehavior [

	(self directlyDefinesSlotNamed: self slotName inBehavior: aBehavior)
		ifFalse: [
			RBApplicabilityChecksFailedError signal:
				'The variable ' , self slotName
				, ' is not directly defined in the class '
				, (self normalizedBehaviorNameFor: aBehavior) ].
	self signalReferenceWarningIfNeededForBehavior: aBehavior.
	aBehavior removeInstVarNamed: self slotName
]

{ #category : 'private' }
MCPRemoveSlotCommand >> signalReferenceWarningIfNeededForBehavior: aBehavior [

	| hasReferences |
	hasReferences := aBehavior withAllSubclasses anySatisfy: [ :each |
		                 (each whichMethodsAccess: self slotName) isNotEmpty ].
	hasReferences ifTrue: [
		RBBreakingChangeChecksFailedWarning signal:
			' Variable ' , self slotName , ' is still referenced' ]
]

{ #category : 'accessing' }
MCPRemoveSlotCommand >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPRemoveSlotCommand >> slotName: aSlotName [

	slotName := aSlotName
]
