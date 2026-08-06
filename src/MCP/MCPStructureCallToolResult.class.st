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

	^ self asJRPCJSONForResponseFields: #both
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> asJRPCJSONForResponseFields: responseFields [

	| dictionary normalizedFields |
	normalizedFields := responseFields asSymbol.
	dictionary := Dictionary new.
	(self includesContentForResponseFields: normalizedFields) ifTrue: [ dictionary at: #content put: self content asJRPCJSON ].
	(self includesStructuredContentForResponseFields: normalizedFields) ifTrue: [
		self structuredContent ifNotNil: [ :structured | dictionary at: #structuredContent put: structured asJRPCJSON ] ].
	self isError ifTrue: [ dictionary at: #isError put: true ].
	^ dictionary
]

{ #category : 'converting' }
MCPStructureCallToolResult >> asMCPStructureCallToolResult [

	^ self
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> content [

	^ content ifNil: [ #(  ) ]
]

{ #category : 'accessing' }
MCPStructureCallToolResult >> content: anObject [

	content := anObject
]

{ #category : 'testing' }
MCPStructureCallToolResult >> includesContentForResponseFields: responseFields [

	^ responseFields = #content or: [ responseFields = #both ]
]

{ #category : 'testing' }
MCPStructureCallToolResult >> includesStructuredContentForResponseFields: responseFields [

	^ responseFields = #structuredContent or: [ responseFields = #both ]
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
