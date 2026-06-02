Extension { #name : 'SelectorException' }

{ #category : '*MCP' }
SelectorException >> mcpRepairMessageForContext: aContext [

	^ Message selector: self selector arguments: aContext arguments
]

{ #category : '*MCP' }
SelectorException >> mcpSelectorForContextLookup [

	^ self selector
]
