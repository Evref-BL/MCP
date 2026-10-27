Extension { #name : 'EpCodeChange' }

{ #category : '*MCP-IDE' }
EpCodeChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addCodeChangeInfoFrom: self
]
