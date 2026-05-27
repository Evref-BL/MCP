"
Tool icon specification composed from a base icon and a badge icon.

Use this when a tool should advertise a stable visual identity derived from two symbolic icons rather than a single named icon.
"
Class {
	#name : 'MCPCompositeToolIconSpec',
	#superclass : 'MCPToolIconSpec',
	#instVars : [
		'baseIconSymbol',
		'badgeIconSymbol'
	],
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPCompositeToolIconSpec class >> baseIconNamed: aBaseIconSymbol badgeIconNamed: aBadgeIconSymbol [

	^ self new
		  baseIconSymbol: aBaseIconSymbol;
		  badgeIconSymbol: aBadgeIconSymbol;
		  yourself
]

{ #category : 'accessing' }
MCPCompositeToolIconSpec >> badgeIconSymbol [

	^ badgeIconSymbol
]

{ #category : 'accessing' }
MCPCompositeToolIconSpec >> badgeIconSymbol: anIconSymbol [

	badgeIconSymbol := anIconSymbol asSymbol
]

{ #category : 'accessing' }
MCPCompositeToolIconSpec >> baseIconSymbol [

	^ baseIconSymbol
]

{ #category : 'accessing' }
MCPCompositeToolIconSpec >> baseIconSymbol: anIconSymbol [

	baseIconSymbol := anIconSymbol asSymbol
]

{ #category : 'comparing' }
MCPCompositeToolIconSpec >> cacheKey [

	^ {
		  self class.
		  self baseIconSymbol.
		  self badgeIconSymbol }
]

{ #category : 'rendering' }
MCPCompositeToolIconSpec >> renderUsing: anIconFactory [

	^ anIconFactory iconForForm: (anIconFactory
			   compositeFormBaseIconNamed: self baseIconSymbol
			   badgeIconNamed: self badgeIconSymbol)
]
