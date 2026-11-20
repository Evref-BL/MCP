"
One change a class_update call asks for, planned before any change is made: its action, the context its errors report and, for a slot change, the slot, its new name and its side.

MCPToolUpdateClass orders the plans by action and applies them in that order.
"
Class {
	#name : 'MCPClassUpdateSpec',
	#superclass : 'Object',
	#instVars : [
		'requestedContext',
		'updateAction',
		'slotName',
		'newSlotName',
		'classSide'
	],
	#category : 'MCP-IDE-Specs',
	#package : 'MCP-IDE',
	#tag : 'Specs'
}

{ #category : 'instance creation' }
MCPClassUpdateSpec class >> updateAction: anUpdateAction requestedContext: aDictionary [

	^ self new
		  updateAction: anUpdateAction;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> classSide [

	^ classSide ifNil: [ false ]
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> newSlotName [

	^ newSlotName
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> newSlotName: aString [

	newSlotName := aString
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> requestedContext [

	^ requestedContext ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> requestedContext: aDictionary [

	requestedContext := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> slotName: aString [

	slotName := aString
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> updateAction [

	^ updateAction
]

{ #category : 'accessing' }
MCPClassUpdateSpec >> updateAction: anObject [

	updateAction := anObject
]
