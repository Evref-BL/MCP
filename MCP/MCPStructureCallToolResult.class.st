"
MCP protocol structure for a tool call result.

It contains the user-visible content blocks and optional structuredContent returned by a tool.
"
Class {
	#name : 'MCPStructureCallToolResult',
	#superclass : 'Object',
	#instVars : [
		'content',
		'structuredContent'
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
MCPStructureCallToolResult class >> content: aContent structuredContent: aStructuredContent [

	^ self new
		  content: aContent;
		  structuredContent: aStructuredContent;
		  yourself
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> asJRPCJSON [

	| dic |
	dic := Dictionary new.
	dic at: #content put: self content asJRPCJSON.
	self structuredContent ifNotNil: [
		dic at: #structuredContent put: self structuredContent asJRPCJSON ].
	self isError ifTrue: [ dic at: #isError put: true ].
	^ dic
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> content [

	^ content ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> content: anObject [

	content := anObject
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> isError [

	^ false
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> structuredContent [

	^ structuredContent
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> structuredContent: anObject [

	structuredContent := anObject
]
