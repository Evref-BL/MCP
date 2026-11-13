Extension { #name : 'EpPackageChange' }

{ #category : '*MCP-IDE-Compatibility-From12' }
EpPackageChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addPackageChangeInfoFrom: self
]
