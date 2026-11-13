Extension { #name : 'MCPStructureIcon' }

{ #category : '*MCP-Compatibility-Before12' }
MCPStructureIcon class >> highScaleIconNamed: anIconSymbol [
	"Pharo 11 keeps its icons at the base scale only, and Pharo 10 names glamorousGo the icon later versions name go. A tool icon is drawn at twice the base scale, which Pharo precomputes from 12 on."

	| icons |
	icons := Smalltalk ui icons icons.
	^ (icons at: anIconSymbol ifAbsent: [
		   icons
			   at: ('glamorous' , anIconSymbol capitalized) asSymbol
			   ifAbsent: [ self error: 'Missing UI icon named ' , anIconSymbol asString ] ]) magnifyBy: 2
]
