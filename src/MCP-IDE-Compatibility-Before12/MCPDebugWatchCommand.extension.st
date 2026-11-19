Extension { #name : 'MCPDebugWatchCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPDebugWatchCommand >> probeForTarget: aTarget index: anIndex [
	"Before Pharo 12, Pharo has no debug points, so the probe is a metalink of its own."

	| node |
	node := self nodeMatching: aTarget.
	node ifNil: [ ^ nil ].
	^ MCPWatchProbe installOn: node script: (self scriptForTarget: aTarget index: anIndex)
]
