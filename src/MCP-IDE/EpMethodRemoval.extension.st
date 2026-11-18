Extension { #name : 'EpMethodRemoval' }

{ #category : '*MCP-IDE' }
EpMethodRemoval >> mcpAddSourcesTo: anEntryInfo [

	anEntryInfo addSourceBefore: self sourceCode
]
