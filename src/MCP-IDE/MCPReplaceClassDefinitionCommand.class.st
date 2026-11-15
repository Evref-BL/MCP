"
Replaces the slot shape of an existing class using the Shift class installer. Omitted slot sides are left unchanged, while supplied instance-side or class-side slot collections replace that side of the class definition.
"
Class {
	#name : 'MCPReplaceClassDefinitionCommand',
	#superclass : 'MCPClassCommand',
	#instVars : [
		'slotNames',
		'classSlotNames',
		'replaceSlots',
		'replaceClassSlots'
	],
	#category : 'MCP-IDE-Commands',
	#package : 'MCP-IDE',
	#tag : 'Commands'
}

{ #category : 'instance creation' }
MCPReplaceClassDefinitionCommand class >> className: aClassName slotNames: someSlotNames classSlotNames: someClassSlotNames [
	"Each list replaces its side of the class. nil leaves that side as it is, where an empty list removes every slot it has."

	^ self new
		  className: aClassName;
		  slotNames: someSlotNames;
		  classSlotNames: someClassSlotNames;
		  replaceSlots: someSlotNames isNotNil;
		  replaceClassSlots: someClassSlotNames isNotNil;
		  yourself
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> classSlotNames [

	^ classSlotNames ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> classSlotNames: someNames [

	classSlotNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> classSlots [

	^ self classSlotNames collect: #asSymbol as: Array
]

{ #category : 'executing' }
MCPReplaceClassDefinitionCommand >> execute [

	^ self replaceDefinitionOn: self targetClass
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> replaceClassSlots [

	^ replaceClassSlots ifNil: [ false ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> replaceClassSlots: aBoolean [

	replaceClassSlots := aBoolean
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

	slotNames := someNames ifNil: [ #(  ) ] ifNotNil: [ someNames asArray ]
]

{ #category : 'accessing' }
MCPReplaceClassDefinitionCommand >> slots [

	^ self slotNames collect: #asSymbol as: Array
]

{ #category : 'private' }
MCPReplaceClassDefinitionCommand >> targetClass [

	^ MCPImageLookup classNamed: self className
]
