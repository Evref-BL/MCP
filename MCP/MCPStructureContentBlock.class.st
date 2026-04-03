Class {
	#name : 'MCPStructureContentBlock',
	#superclass : 'Object',
	#instVars : [
		'type'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureContentBlock >> asJRPCJSON [

	^ { (#type -> self type asJRPCJSON) } asDictionary
]

{ #category : 'accessing' }
MCPStructureContentBlock >> type [

	^ type
]

{ #category : 'accessing' }
MCPStructureContentBlock >> type: anObject [

	type := anObject
]
