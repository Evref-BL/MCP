Extension { #name : 'EpCodeChange' }

{ #category : '*MCP' }
EpCodeChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addCodeChangeInfoFrom: self
]
