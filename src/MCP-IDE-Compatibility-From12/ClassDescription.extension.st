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

{ #category : '*MCP-IDE-Compatibility-From12' }
ClassDescription >> mcpTagName [
	"The name of the tag the class is filed under, or nil when it is not tagged. From Pharo 12 on, an untagged class sits in its package's root tag, Uncategorized."

	^ self packageTag ifNotNil: [ :packageTag | packageTag isRoot ifFalse: [ packageTag name asString ] ]
]
