Extension { #name : 'MCPDebugWatchCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPDebugWatchCommand >> probeForTarget: aTarget index: anIndex [

	^ self nodeMatching: aTarget ifFound: [ :node |
			  | probe |
			  probe := DebugPointManager installNew: WatchDebugPoint on: node withBehaviors: { ScriptBehavior }.
			  (probe getBehavior: ScriptBehavior) script: (self scriptForTarget: aTarget index: anIndex).
			  probe ]
]
