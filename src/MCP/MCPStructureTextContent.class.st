"
MCP protocol structure for a text content block.

Tools use it for the human-readable text portion of call results.
"
Class {
	#name : 'MCPStructureTextContent',
	#superclass : 'MCPStructureContentBlock',
	#instVars : [
		'text'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureTextContent class >> text: aText [

	^ self new
		  text: aText;
		  yourself
]

{ #category : 'accessing' }
MCPStructureTextContent >> asJRPCJSON [

	| dic |
	dic := super asJRPCJSON.
	self text ifNotNil: [ :tex | dic at: #text put: tex asJRPCJSON ].
	^ dic
]

{ #category : 'initialization' }
MCPStructureTextContent >> initialize [

	super initialize.
	type := 'text'
]

{ #category : 'accessing' }
MCPStructureTextContent >> text [

	^ text
]

{ #category : 'accessing' }
MCPStructureTextContent >> text: anObject [

	text := anObject
]
