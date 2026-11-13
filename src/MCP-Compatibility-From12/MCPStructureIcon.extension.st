Extension { #name : 'MCPStructureIcon' }

{ #category : '*MCP-Compatibility-From12' }
MCPStructureIcon class >> highScaleIcons [
	"The icons at twice the base scale, which Pharo precomputes from 12 on."

	^ Smalltalk ui icons iconsPerScale at: 2.0 ifAbsent: [ self error: 'Missing precomputed scale 2.0 icons.' ]
]
