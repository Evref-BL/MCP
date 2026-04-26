"
MCP protocol structure for the tools capability.

It currently records whether the server can notify clients when the tool list changes.
"
Class {
	#name : 'MCPStructureToolsCapabilities',
	#superclass : 'Object',
	#instVars : [
		'listChanged'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureToolsCapabilities >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self listChanged ifNotNil: [
		dic at: #listChanged put: self listChanged asJRPCJSON ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureToolsCapabilities >> listChanged [

	^ listChanged
]

{ #category : 'accessing' }
MCPStructureToolsCapabilities >> listChanged: anObject [

	listChanged := anObject
]
