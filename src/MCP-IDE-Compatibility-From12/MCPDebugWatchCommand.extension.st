Extension { #name : 'MCPDebugWatchCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPDebugWatchCommand >> probeForTarget: aTarget index: anIndex [

	| node probe |
	node := self nodeMatching: aTarget.
	node ifNil: [ ^ nil ].
	probe := DebugPointManager installNew: WatchDebugPoint on: node withBehaviors: { ScriptBehavior }.
	(probe getBehavior: ScriptBehavior) script: (self scriptForTarget: aTarget index: anIndex).
	^ probe
]
