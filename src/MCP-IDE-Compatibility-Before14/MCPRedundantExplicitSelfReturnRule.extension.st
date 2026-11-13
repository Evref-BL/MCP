Extension { #name : 'MCPRedundantExplicitSelfReturnRule' }

{ #category : '*MCP-IDE-Compatibility-Before14' }
MCPRedundantExplicitSelfReturnRule class >> enabled [
	"Before Pharo 14, Renraku does not read enabledByDefault, and a rule that is off by default says so here, as ReImplementedNotSentRule does."

	^ enabled ifNil: [ enabled := self enabledByDefault ]
]
