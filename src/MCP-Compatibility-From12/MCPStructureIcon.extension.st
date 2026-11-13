Extension { #name : 'MCPStructureIcon' }

{ #category : '*MCP-Compatibility-From12' }
MCPStructureIcon class >> highScaleIconNamed: anIconSymbol [
	"The icon at twice the base scale, which Pharo precomputes from 12 on."

	| scaledIcons |
	scaledIcons := Smalltalk ui icons iconsPerScale at: 2.0 ifAbsent: [ self error: 'Missing precomputed scale 2.0 icons.' ].
	^ scaledIcons at: anIconSymbol ifAbsent: [ self error: 'Missing UI icon named ' , anIconSymbol asString ]
]
