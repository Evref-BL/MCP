"
Renames an instance-side slot through the refactoring engine. It rejects class-side slot renames explicitly.
"
Class {
	#name : 'MCPRenameSlotCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'slotName',
		'newSlotName',
		'classSide'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPRenameSlotCommand class >> className: aClassName slotName: aSlotName newSlotName: aNewSlotName classSide: aBoolean [

	^ self new
		  className: aClassName;
		  slotName: aSlotName;
		  newSlotName: aNewSlotName;
		  classSide: aBoolean;
		  yourself
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> className: aClassName [

	className := aClassName
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'private' }
MCPRenameSlotCommand >> currentClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]

{ #category : 'executing' }
MCPRenameSlotCommand >> execute [

	| currentClass updatedClass |
	self classSide ifTrue: [ self signalClassSideRenameIsUnsupported ].
	currentClass := self currentClass.
	(self refactoringForClass: currentClass) execute.
	updatedClass := Smalltalk globals at: self className asSymbol.
	^ MCPRenameSlotResult
		  classInfo: (MCPClassInfo fromClass: updatedClass)
		  oldSlotName: self slotName
		  newSlotName: self newSlotName
		  classSide: false
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> newSlotName [

	^ newSlotName
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> newSlotName: aNewSlotName [

	newSlotName := aNewSlotName
]

{ #category : 'private' }
MCPRenameSlotCommand >> refactoringForClass: aClass [

	^ RBRenameInstanceVariableRefactoring
		  rename: self slotName
		  to: self newSlotName
		  in: aClass
		  renameAccessors: true
]

{ #category : 'private' }
MCPRenameSlotCommand >> signalClassSideRenameIsUnsupported [

	MCPCommandError
		signalErrorCode: #RenameSlotClassSideUnsupported
		message:
		'Class-side slot rename is not supported. renameSlot only supports instance-side slots.'
		details: {
				(#className -> self className).
				(#slotName -> self slotName).
				(#newSlotName -> self newSlotName).
				(#classSide -> self classSide) } asDictionary
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPRenameSlotCommand >> slotName: aSlotName [

	slotName := aSlotName
]
