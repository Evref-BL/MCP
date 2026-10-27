Extension { #name : 'EpBehaviorChange' }

{ #category : '*MCP-IDE' }
EpBehaviorChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addBehaviorChangeInfoFrom: self
]
