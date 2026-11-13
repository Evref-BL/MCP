Extension { #name : 'MCPMessageNotUnderstoodHandlerRule' }

{ #category : '*MCP-IDE-Compatibility-Before14' }
MCPMessageNotUnderstoodHandlerRule class >> enabled [
	"Before Pharo 14, Renraku does not read enabledByDefault, and a rule that is off by default says so here, as ReImplementedNotSentRule does."

	^ enabled ifNil: [ enabled := self enabledByDefault ]
]
