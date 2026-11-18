Extension { #name : 'EpMethodModification' }

{ #category : '*MCP-IDE' }
EpMethodModification >> mcpAddSourcesTo: anEntryInfo [

	anEntryInfo
		addSourceBefore: self oldSourceCode;
		addSourceAfter: self newSourceCode
]

{ #category : '*MCP-IDE' }
EpMethodModification >> mcpMethodBeforeChange [

	^ self oldMethod
]

{ #category : '*MCP-IDE' }
EpMethodModification >> mcpVersionKind [

	^ 'modified'
]
