Extension { #name : 'EpPackageTagChange' }

{ #category : '*MCP-IDE' }
EpPackageTagChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addPackageTagChangeInfoFrom: self
]
