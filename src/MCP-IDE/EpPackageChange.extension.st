Extension { #name : 'EpPackageChange' }

{ #category : '*MCP-IDE' }
EpPackageChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addPackageChangeInfoFrom: self
]
