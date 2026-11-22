Extension { #name : 'MCPDebugWatchCommand' }

{ #category : '*MCP-IDE-Compatibility-From12' }
MCPDebugWatchCommand >> probeForTarget: aTarget index: anIndex [
	"A watch debug point with a script behavior, whose hit never fails. Its link is kept to the base level, and its script set, before it goes in: a method other processes run, such as Object>>yourself, fires it at once, where an empty script would record nothing, and the probe's own work, which compiles the script and prints the value, may send the watched method again, which would fire it without end. The link comes first, since adding a behavior announces the change with the link's nodes."

	^ self nodeMatching: aTarget ifFound: [ :node |
			  | probe |
			  probe := MCPWatchDebugPoint new
				           node: node;
				           yourself.
			  probe link: (probe metaLink
					   level: 0;
					   yourself).
			  probe addBehavior: (ScriptBehavior new
					   script: (self scriptForTarget: aTarget index: anIndex);
					   yourself).
			  probe install.
			  DebugPoint add: probe.
			  probe ]
]
