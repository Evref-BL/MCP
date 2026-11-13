Extension { #name : 'ClassDescription' }

{ #category : '*MCP-IDE-Compatibility-From12' }
ClassDescription >> mcpComment [

	^ self comment
]

{ #category : '*MCP-IDE-Compatibility-From12' }
ClassDescription >> mcpCompile: aString classified: aProtocolNameOrNil [
	"From Pharo 12 on, compiling into no protocol files the method as unclassified."

	^ self compile: aString classified: aProtocolNameOrNil
]
