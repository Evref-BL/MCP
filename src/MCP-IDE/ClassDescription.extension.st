Extension { #name : 'ClassDescription' }

{ #category : '*MCP-IDE' }
ClassDescription >> mcpTagName [
	"The name of the tag the class is filed under, or nil when it is not tagged: an untagged class sits in its package's root tag."

	^ self packageTag ifNotNil: [ :packageTag | packageTag isRoot ifFalse: [ packageTag name asString ] ]
]
