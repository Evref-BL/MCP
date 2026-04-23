"
Captures the updated class state after a slot edit.
"
Class {
	#name : 'MCPSlotResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'slotName',
		'classSide'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPSlotResult class >> classInfo: aClassInfo slotName: aSlotName classSide: aBoolean [

	^ self new
		  classInfo: aClassInfo;
		  slotName: aSlotName;
		  classSide: aBoolean;
		  yourself
]

{ #category : 'converting' }
MCPSlotResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #slotName put: self slotName.
	data at: #classSide put: self classSide.
	^ data
]

{ #category : 'accessing' }
MCPSlotResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPSlotResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPSlotResult >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPSlotResult >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'accessing' }
MCPSlotResult >> slotName [

	^ slotName
]

{ #category : 'accessing' }
MCPSlotResult >> slotName: aSlotName [

	slotName := aSlotName
]
