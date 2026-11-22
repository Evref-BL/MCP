Extension { #name : 'MCPDebugWatchCommand' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPDebugWatchCommand >> doItCompiler [
	"A compiler for an expression standing alone, as evaluate: compiles it."

	^ Smalltalk compiler
		  noPattern: true;
		  yourself
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPDebugWatchCommand >> probeForTarget: aTarget index: anIndex [
	"Before Pharo 12, Pharo has no debug points, so the probe is a metalink of its own."

	^ self
		  nodeMatching: aTarget
		  ifFound: [ :node | MCPWatchProbe installOn: node script: (self scriptForTarget: aTarget index: anIndex) ]
]
