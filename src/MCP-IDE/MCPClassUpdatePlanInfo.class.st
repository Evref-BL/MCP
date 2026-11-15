"
One change a class_update call asks for, planned before any change is made: its action, the context its errors report and, for a slot change, the slot, its new name and its side.

TMCPSequencedUpdate orders the plans by action and applies them in that order.
"
Class {
	#name : 'MCPClassUpdatePlanInfo',
	#superclass : 'Object',
	#instVars : [
		'requestedContext',
		'updateAction',
		'slotName',
		'newSlotName',
		'classSide'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPClassUpdatePlanInfo class >> updateAction: anUpdateAction requestedContext: aDictionary [

	^ self new
		  updateAction: anUpdateAction;
		  requestedContext: aDictionary;
		  yourself
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> classSide [

	^ classSide ifNil: [ false ]
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> newSlotName [

	^ newSlotName
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> newSlotName: aString [

	newSlotName := aString
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> requestedContext [

	^ requestedContext ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> requestedContext: aDictionary [

	requestedContext := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> slotName: aString [

	slotName := aString
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> updateAction [

	^ updateAction
]

{ #category : 'accessing' }
MCPClassUpdatePlanInfo >> updateAction: anObject [

	updateAction := anObject
]
