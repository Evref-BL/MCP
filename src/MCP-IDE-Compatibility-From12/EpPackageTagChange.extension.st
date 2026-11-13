Extension { #name : 'EpPackageTagChange' }

{ #category : '*MCP-IDE-Compatibility-From12' }
EpPackageTagChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addPackageTagChangeInfoFrom: self
]
