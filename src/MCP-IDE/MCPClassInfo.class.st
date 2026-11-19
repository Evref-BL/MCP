"
DTO for compact class metadata used by class queries and mutation reports.

It reads, from the class it keeps, the class name, its package and tag, and its slots, each when asked.
"
Class {
	#name : 'MCPClassInfo',
	#superclass : 'MCPDataTransferObject',
	#instVars : [
		'describedClass'
	],
	#category : 'MCP-IDE-DTOs',
	#package : 'MCP-IDE',
	#tag : 'DTOs'
}

{ #category : 'instance creation' }
MCPClassInfo class >> fromClass: aClass [

	^ self new initializeFromClass: aClass
]

{ #category : 'converting' }
MCPClassInfo >> asDictionary [

	^ {
		  (#class -> self className).
		  (#package -> self packageName).
		  (#tag -> self tag).
		  (#hasTag -> self hasTag).
		  (#instanceSlots -> self instanceSlotNames).
		  (#classSlots -> self classSlotNames) } asDictionary
]

{ #category : 'accessing' }
MCPClassInfo >> className [

	^ describedClass name asString
]

{ #category : 'accessing' }
MCPClassInfo >> classSlotNames [

	^ describedClass classSide slots collect: [ :each | each name asString ] as: Array
]

{ #category : 'accessing' }
MCPClassInfo >> hasTag [
	"Whether the class is filed under a tag of its own, rather than its package's root, whose name tag still answers so that a filter on it matches as it always has."

	^ describedClass mcpTagName isNotNil
]

{ #category : 'initialization' }
MCPClassInfo >> initializeFromClass: aClass [

	describedClass := aClass
]

{ #category : 'accessing' }
MCPClassInfo >> instanceSlotNames [

	^ describedClass slots collect: [ :each | each name asString ] as: Array
]

{ #category : 'accessing' }
MCPClassInfo >> packageName [

	^ describedClass package ifNil: [ '' ] ifNotNil: [ :aPackage | aPackage name asString ]
]

{ #category : 'accessing' }
MCPClassInfo >> tag [

	^ describedClass packageTagName asString
]
