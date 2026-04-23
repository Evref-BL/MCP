Class {
	#name : 'MCPMoveSlotResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'slotName',
		'classSide',
		'affectedClassNames'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPMoveSlotResult class >> classInfo: aClassInfo slotName: aSlotName classSide: aBoolean affectedClassNames: someClassNames [

	^ self new
		  classInfo: aClassInfo;
		  slotName: aSlotName;
		  classSide: aBoolean;
		  affectedClassNames: someClassNames;
		  yourself
]

{ #category : 'accessing' }
MCPMoveSlotResult >> affectedClassNames [

	^ affectedClassNames
]

{ #category : 'accessing' }
MCPMoveSlotResult >> affectedClassNames: someClassNames [

	affectedClassNames := someClassNames
]

{ #category : 'converting' }
MCPMoveSlotResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #slotName put: self slotName.
	data at: #classSide put: self classSide.
	data at: #affectedClassNames put: self affectedClassNames.
	^ data
]

{ #category : 'accessing' }
MCPMoveSlotResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPMoveSlotResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPMoveSlotResult >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPMoveSlotResult >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'accessing' }
MCPMoveSlotResult >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPMoveSlotResult >> slotName: aSlotName [

	slotName := aSlotName
]
