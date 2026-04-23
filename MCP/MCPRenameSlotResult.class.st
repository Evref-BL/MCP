"
Captures the updated class state after renaming a slot.
"
Class {
	#name : 'MCPRenameSlotResult',
	#superclass : 'Object',
	#instVars : [
		'classInfo',
		'oldSlotName',
		'newSlotName',
		'classSide'
	],
	#category : 'MCP-Internal',
	#package : 'MCP',
	#tag : 'Internal'
}

{ #category : 'instance creation' }
MCPRenameSlotResult class >> classInfo: aClassInfo oldSlotName: anOldSlotName newSlotName: aNewSlotName classSide: aBoolean [

	^ self new
		  classInfo: aClassInfo;
		  oldSlotName: anOldSlotName;
		  newSlotName: aNewSlotName;
		  classSide: aBoolean;
		  yourself
]

{ #category : 'converting' }
MCPRenameSlotResult >> asDictionary [

	| data |
	data := self classInfo asDictionary copy.
	data at: #oldSlotName put: self oldSlotName.
	data at: #newSlotName put: self newSlotName.
	data at: #classSide put: self classSide.
	^ data
]

{ #category : 'accessing' }
MCPRenameSlotResult >> classInfo [

	^ classInfo
]

{ #category : 'accessing' }
MCPRenameSlotResult >> classInfo: aClassInfo [

	classInfo := aClassInfo
]

{ #category : 'accessing' }
MCPRenameSlotResult >> classSide [

	^ classSide
]

{ #category : 'accessing' }
MCPRenameSlotResult >> classSide: aBoolean [

	classSide := aBoolean
]

{ #category : 'accessing' }
MCPRenameSlotResult >> newSlotName [

	^ newSlotName
]

{ #category : 'accessing' }
MCPRenameSlotResult >> newSlotName: aNewSlotName [

	newSlotName := aNewSlotName
]

{ #category : 'accessing' }
MCPRenameSlotResult >> oldSlotName [

	^ oldSlotName
]

{ #category : 'accessing' }
MCPRenameSlotResult >> oldSlotName: anOldSlotName [

	oldSlotName := anOldSlotName
]
