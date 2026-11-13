Extension { #name : 'MCPStructureIcon' }

{ #category : '*MCP-Compatibility-Before12' }
MCPStructureIcon class >> highScaleIconNamed: anIconSymbol [
	"Pharo 11 keeps its icons at the base scale only. A tool icon is drawn at twice that, which Pharo precomputes from 12 on."

	^ (Smalltalk ui icons icons at: anIconSymbol ifAbsent: [ self error: 'Missing UI icon named ' , anIconSymbol asString ])
		  magnifyBy: 2
]
