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

{ #category : '*MCP-IDE-Compatibility-Before12' }
ClassDescription >> mcpTagName [
	"The name of the tag the class is filed under, or nil when it is not tagged. Before Pharo 12, an untagged class answers nil, an empty name or its package's own name for its tag."

	| packageName tagName |
	tagName := self packageTagName ifNil: [ ^ nil ].
	packageName := self package ifNotNil: [ :package | package name asString ].
	(tagName isEmpty or: [ tagName asString = packageName ]) ifTrue: [ ^ nil ].
	^ tagName asString
]
