Extension { #name : 'EpBehaviorChange' }

{ #category : '*MCP' }
EpBehaviorChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addBehaviorChangeInfoFrom: self
]
