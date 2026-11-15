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
	"The name of the tag the class is filed under, or nil when it is not tagged. Before Pharo 12, Pharo files an untagged class under a tag named after its package, and PharoBackwardCompatibility, which answers packageTagName there, names that tag Uncategorized, as Pharo 12 does. Nil, an empty name and the package's own name are read as no tag as well."

	| packageName tagName |
	tagName := (self packageTagName ifNil: [ ^ nil ]) asString.
	packageName := self package ifNotNil: [ :package | package name asString ].
	(tagName isEmpty or: [ tagName = 'Uncategorized' or: [ tagName = packageName ] ]) ifTrue: [ ^ nil ].
	^ tagName
]
