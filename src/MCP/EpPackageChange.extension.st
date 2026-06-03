Extension { #name : 'EpPackageChange' }

{ #category : '*MCP' }
EpPackageChange >> mcpAddChangeHistoryInfoTo: anEntryInfo [

	anEntryInfo addPackageChangeInfoFrom: self
]
