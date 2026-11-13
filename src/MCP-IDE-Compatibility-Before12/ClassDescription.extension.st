Extension { #name : 'ClassDescription' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
ClassDescription >> mcpComment [
	"Before Pharo 12, a class without a comment answers a template from comment."

	^ self instanceSide organization classComment asString
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
ClassDescription >> mcpCompile: aString classified: aProtocolNameOrNil [
	"Before Pharo 12, compiling into no protocol fails; unclassified is the protocol Pharo 12 files such a method under."

	^ self
		  compile: aString
		  classified: (aProtocolNameOrNil ifNil: [ Protocol unclassified ])
]
