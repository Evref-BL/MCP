Extension { #name : 'ClassDescription' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
ClassDescription >> mcpComment [
	"Before Pharo 12, a class without a comment answers a template from comment."

	^ self instanceSide organization classComment asString
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
ClassDescription >> mcpCompile: aString classified: aProtocolNameOrNil [
	"Before Pharo 12, compiling into no protocol fails. Unclassified files a new method where Pharo 12 files it with no protocol, and keeps an existing method's protocol, as no protocol does from Pharo 12 on."

	^ self
		  compile: aString
		  classified: (aProtocolNameOrNil ifNil: [ Protocol unclassified ])
]
