Extension { #name : 'ClassDescription' }

{ #category : '*MCP-IDE-Compatibility-From12' }
ClassDescription >> mcpComment [

	^ self comment
]

{ #category : '*MCP-IDE-Compatibility-From12' }
ClassDescription >> mcpCompile: aString classified: aProtocolNameOrNil [
	"From Pharo 12 on, compiling into no protocol files a new method as unclassified and keeps an existing method's protocol."

	^ self compile: aString classified: aProtocolNameOrNil
]
