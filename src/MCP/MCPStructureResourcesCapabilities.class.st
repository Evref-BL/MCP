"
MCP protocol structure for the resources capability.

It records optional resources capability flags advertised during initialization.
"
Class {
	#name : 'MCPStructureResourcesCapabilities',
	#superclass : 'Object',
	#instVars : [
		'subscribe',
		'listChanged'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureResourcesCapabilities >> asJRPCJSON [

	| dictionary |
	dictionary := Dictionary new.
	self listChanged ifNotNil: [ dictionary at: #listChanged put: self listChanged asJRPCJSON ].
	self subscribe ifNotNil: [ dictionary at: #subscribe put: self subscribe asJRPCJSON ].
	^ dictionary
]

{ #category : 'accessing' }
MCPStructureResourcesCapabilities >> listChanged [

	^ listChanged
]

{ #category : 'accessing' }
MCPStructureResourcesCapabilities >> listChanged: anObject [

	listChanged := anObject
]

{ #category : 'accessing' }
MCPStructureResourcesCapabilities >> subscribe [

	^ subscribe
]

{ #category : 'accessing' }
MCPStructureResourcesCapabilities >> subscribe: anObject [

	subscribe := anObject
]
