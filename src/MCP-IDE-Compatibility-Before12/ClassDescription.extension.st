Extension { #name : 'ClassDescription' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
ClassDescription >> mcpComment [
	"Before Pharo 12, a class without a comment answers a template from comment."

	^ self instanceSide organization classComment asString
]
