Extension { #name : 'Object' }

{ #category : '*MCP' }
Object >> asMCPStructureCallToolResult [

	^ MCPStructureCallToolResult content: self
]

{ #category : '*MCP' }
Object >> mcpChangeHistoryReferenceString [

	^ self asString
]

{ #category : '*MCP' }
Object >> mcpChangeHistoryValueForSelector: aSelector [

	aSelector = #className ifTrue: [ ^ self className ].
	^ nil
]

{ #category : '*MCP' }
Object >> mcpDiffPackageName [

	^ nil
]

{ #category : '*MCP' }
Object >> mcpErrorPosition [

	^ nil
]

{ #category : '*MCP' }
Object >> mcpMethodNode [

	^ nil
]

{ #category : '*MCP' }
Object >> mcpMutationFailureNotice [

	^ self
]

{ #category : '*MCP' }
Object >> mcpNoticeNode [

	^ nil
]

{ #category : '*MCP' }
Object >> mcpSignalerContext [

	^ nil
]
