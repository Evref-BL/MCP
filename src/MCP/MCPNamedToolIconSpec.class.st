"
Tool icon specification backed by one symbolic icon name.

The concrete icon rendering is deferred to MCPStructureIcon so tool metadata can stay compact and stable.
"
Class {
	#name : 'MCPNamedToolIconSpec',
	#superclass : 'MCPToolIconSpec',
	#instVars : [
		'iconSymbol'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPNamedToolIconSpec class >> iconNamed: anIconSymbol [

	^ self new
		  iconSymbol: anIconSymbol;
		  yourself
]

{ #category : 'comparing' }
MCPNamedToolIconSpec >> cacheKey [

	^ {
		  self class.
		  self iconSymbol }
]

{ #category : 'accessing' }
MCPNamedToolIconSpec >> iconSymbol [

	^ iconSymbol
]

{ #category : 'accessing' }
MCPNamedToolIconSpec >> iconSymbol: anIconSymbol [

	iconSymbol := anIconSymbol asSymbol
]

{ #category : 'rendering' }
MCPNamedToolIconSpec >> renderUsing: anIconFactory [

	^ anIconFactory iconForForm: (anIconFactory highScaleFormNamed: self iconSymbol)
]
