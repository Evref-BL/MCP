Extension { #name : 'EpPackageTagChange' }

{ #category : '*MCP' }
EpPackageTagChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addPackageTagChangeInfoFrom: self
]
