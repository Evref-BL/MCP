Extension { #name : 'EpMethodRemoval' }

{ #category : '*MCP-IDE' }
EpMethodRemoval >> mcpAddSourcesTo: anEntryInfo [

	anEntryInfo addSourceBefore: self sourceCode
]

{ #category : '*MCP-IDE' }
EpMethodRemoval >> mcpIsMethodRemoval [

	^ true
]

{ #category : '*MCP-IDE' }
EpMethodRemoval >> mcpMethodBeforeChange [

	^ self methodRemoved
]

{ #category : '*MCP-IDE' }
EpMethodRemoval >> mcpVersionKind [

	^ 'removed'
]
