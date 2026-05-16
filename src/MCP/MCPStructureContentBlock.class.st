"
Base MCP protocol structure for content blocks.

Subclasses provide concrete content payloads such as text while sharing the content block type field.
"
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
