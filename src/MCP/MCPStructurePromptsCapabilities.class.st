"
MCP protocol structure for the prompts capability.

It records optional prompts capability flags advertised during initialization.
"
Class {
	#name : 'MCPStructurePromptsCapabilities',
	#superclass : 'Object',
	#instVars : [
		'listChanged'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructurePromptsCapabilities >> asJRPCJSON [

	| dictionary |
	dictionary := Dictionary new.
	self listChanged ifNotNil: [ dictionary at: #listChanged put: self listChanged asJRPCJSON ].
	^ dictionary
]

{ #category : 'accessing' }
MCPStructurePromptsCapabilities >> listChanged [

	^ listChanged
]

{ #category : 'accessing' }
MCPStructurePromptsCapabilities >> listChanged: anObject [

	listChanged := anObject
]
