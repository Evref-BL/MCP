Extension { #name : 'MCPStructureIcon' }

{ #category : '*MCP-Compatibility-Before12' }
MCPStructureIcon class >> highScaleIcons [
	"Pharo 11 keeps its icons at one scale only."

	^ Smalltalk ui icons icons
]
