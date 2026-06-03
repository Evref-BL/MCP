Extension { #name : 'EpMethodChange' }

{ #category : '*MCP' }
EpMethodChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addMethodChangeInfoFrom: self
]
