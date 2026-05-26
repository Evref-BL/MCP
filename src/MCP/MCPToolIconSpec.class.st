"
Abstract icon specification used by MCP tools.

Subclasses describe how an icon should be rendered without forcing MCPTool instances to eagerly render PNG data URIs.
"
Class {
	#name : 'MCPToolIconSpec',
	#superclass : 'Object',
	#category : 'MCP-Structure',
	#package : 'MCP',
	#tag : 'Structure'
}

{ #category : 'instance creation' }
MCPToolIconSpec class >> baseIconNamed: aBaseIconSymbol badgeIconNamed: aBadgeIconSymbol [

	^ MCPCompositeToolIconSpec
		  baseIconNamed: aBaseIconSymbol
		  badgeIconNamed: aBadgeIconSymbol
]

{ #category : 'instance creation' }
MCPToolIconSpec class >> named: anIconSymbol [

	^ MCPNamedToolIconSpec iconNamed: anIconSymbol
]

{ #category : 'comparing' }
MCPToolIconSpec >> cacheKey [

	self subclassResponsibility
]

{ #category : 'rendering' }
MCPToolIconSpec >> renderUsing: anIconFactory [

	self subclassResponsibility
]
