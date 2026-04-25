"
Replaces the slot shape of an existing class using the Shift class installer. Omitted slot sides are left unchanged, while supplied instance-side or class-side slot collections replace that side of the class definition.
"
Class {
	#name : 'MCPReplaceClassDefinitionCommand',
	#superclass : 'Object',
	#instVars : [
		'className',
		'slotNames',
		'classSlotNames',
		'replaceSlots',
		'replaceClassSlots'
	],
	#category : 'MCP-Commands',
	#package : 'MCP',
	#tag : 'Commands'
}

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> className [

	^ className
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> className: aClassName [

	className := aClassName
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> classSlotNames [

	^ classSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> classSlotNames: someNames [

	classSlotNames := someNames
		                  ifNil: [ #(  ) ]
		                  ifNotNil: [ someNames asArray ]
]

{ #category : 'private' }
MCPReplaceClassDefinitionCommand >> classSlotNamesFromClass: aClass [

	^ aClass classSide slots
		  collect: [ :each | each name asString ]
		  as: Array
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> classSlots [

	^ self classSlotNames collect: #asSymbol as: Array
]

{ #category : 'executing' }
MCPReplaceClassDefinitionCommand >> execute [

	| oldClassSlotNames oldInstanceSlotNames result targetClass updatedClass |
	targetClass := self targetClass.
	oldInstanceSlotNames := self instanceSlotNamesFromClass: targetClass.
	oldClassSlotNames := self classSlotNamesFromClass: targetClass.
	updatedClass := self replaceDefinitionOn: targetClass.
	result := MCPReplaceClassDefinitionResult classInfo:
		          (MCPClassInfo fromClass: updatedClass).
	result
		oldInstanceSlotNames: oldInstanceSlotNames;
		newInstanceSlotNames:
			(self instanceSlotNamesFromClass: updatedClass);
		oldClassSlotNames: oldClassSlotNames;
		newClassSlotNames: (self classSlotNamesFromClass: updatedClass).
	^ result
]

{ #category : 'private' }
MCPReplaceClassDefinitionCommand >> instanceSlotNamesFromClass: aClass [

	^ aClass slots collect: [ :each | each name asString ] as: Array
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> replaceClassSlots [

	^ replaceClassSlots ifNil: [ false ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> replaceClassSlots: aBoolean [

	replaceClassSlots := aBoolean
]

{ #category : 'private' }
MCPReplaceClassDefinitionCommand >> replaceDefinitionOn: aClass [

	^ ShiftClassInstaller update: aClass to: [ :builder |
		  self replaceSlots ifTrue: [ builder slots: self slots ].
		  self replaceClassSlots ifTrue: [
			  builder classSlots: self classSlots ] ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> replaceSlots [

	^ replaceSlots ifNil: [ false ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> replaceSlots: aBoolean [

	replaceSlots := aBoolean
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> slotNames [

	^ slotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> slotNames: someNames [

	slotNames := someNames
		             ifNil: [ #(  ) ]
		             ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> slots [

	^ self slotNames collect: #asSymbol as: Array
]

{ #category : 'private' }
MCPReplaceClassDefinitionCommand >> targetClass [

	^ Smalltalk globals
		  at: self className asSymbol
		  ifAbsent: [
		  MCPCommandError signalMissingClassNamed: self className ]
]
