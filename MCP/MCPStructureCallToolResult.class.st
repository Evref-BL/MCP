Class {
	#name : 'MCPStructureCallToolResult',
	#superclass : 'Object',
	#instVars : [
		'content'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'accessing' }
MCPStructureCallToolResult class >> content: aContent [

	^ self new
		  content: aContent;
		  yourself
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	self content ifNotNil: [
		dic at: #content put: self content asJRPCJSON ].

	^ dic
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> content [

	^ content
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> content: anObject [

	content := anObject
]
