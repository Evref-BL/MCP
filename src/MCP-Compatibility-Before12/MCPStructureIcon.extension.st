Extension { #name : 'MCPStructureIcon' }

{ #category : '*MCP-Compatibility-Before12' }
MCPStructureIcon class >> highScaleIconNamed: anIconSymbol [
	"Pharo 11 keeps its icons at the base scale only. Pharo 10 names glamorousGo the icon later versions name go, and lacks a few others, which are drawn with the closest icon it has. A tool icon is drawn at twice the base scale, which Pharo precomputes from 12 on."

	| icons formerName |
	icons := Smalltalk ui icons icons.
	formerName := {
		              (#refreshCircling -> #refresh).
		              (#autoReload -> #refresh).
		              (#editThiner -> #edit).
		              (#enable -> #checkBoxOn).
		              (#disable -> #checkBoxOff).
		              (#clearField -> #smallCancel) } asDictionary
		              at: anIconSymbol
		              ifAbsent: [ ('glamorous' , anIconSymbol capitalized) asSymbol ].
	^ (icons
		   at: anIconSymbol
		   ifAbsent: [ icons at: formerName ifAbsent: [ self error: 'Missing UI icon named ' , anIconSymbol asString ] ]) magnifyBy: 2
]
