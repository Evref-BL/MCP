"
Tool icon specification composed from a base icon and one or two badge icons.

Use this when a tool should advertise a stable visual identity derived from symbolic icons. A single badge is rendered at the bottom right. When a left badge is present, the left badge represents the object or noun and the right badge represents the action.
"
Class {
	#name : 'MCPCompositeToolIconSpec',
	#superclass : 'MCPToolIconSpec',
	#instVars : [
		'baseIconSymbol',
		'badgeIconSymbol',
		'leftBadgeIconSymbol'
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

{ #category : 'instance creation' }
MCPCompositeToolIconSpec class >> baseIconNamed: aBaseIconSymbol leftBadgeIconNamed: aLeftBadgeIconSymbol rightBadgeIconNamed: aRightBadgeIconSymbol [

	^ self new
		  baseIconSymbol: aBaseIconSymbol;
		  leftBadgeIconSymbol: aLeftBadgeIconSymbol;
		  badgeIconSymbol: aRightBadgeIconSymbol;
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
		  self leftBadgeIconSymbol.
		  self badgeIconSymbol }
]

{ #category : 'accessing' }
MCPCompositeToolIconSpec >> leftBadgeIconSymbol [

	^ leftBadgeIconSymbol
]

{ #category : 'accessing' }
MCPCompositeToolIconSpec >> leftBadgeIconSymbol: anIconSymbol [

	leftBadgeIconSymbol := anIconSymbol ifNotNil: [ anIconSymbol asSymbol ]
]

{ #category : 'rendering' }
MCPCompositeToolIconSpec >> renderUsing: anIconFactory [

	self leftBadgeIconSymbol ifNil: [
		^ anIconFactory iconForForm:
			  (anIconFactory compositeFormBaseIconNamed: self baseIconSymbol badgeIconNamed: self badgeIconSymbol) ].
	^ anIconFactory iconForForm: (anIconFactory
			   compositeFormBaseIconNamed: self baseIconSymbol
			   leftBadgeIconNamed: self leftBadgeIconSymbol
			   rightBadgeIconNamed: self badgeIconSymbol)
]
