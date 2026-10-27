Extension { #name : 'EpMethodChange' }

{ #category : '*MCP-IDE' }
EpMethodChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addMethodChangeInfoFrom: self
]
