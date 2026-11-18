Extension { #name : 'EpMethodModification' }

{ #category : '*MCP-IDE' }
EpMethodModification >> mcpAddSourcesTo: anEntryInfo [

	anEntryInfo
		addSourceBefore: self oldSourceCode;
		addSourceAfter: self newSourceCode
]
