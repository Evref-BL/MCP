Extension { #name : 'EpMethodAddition' }

{ #category : '*MCP-IDE' }
EpMethodAddition >> mcpAddSourcesTo: anEntryInfo [

	anEntryInfo addSourceAfter: self sourceCode
]
