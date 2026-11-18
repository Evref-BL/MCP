Extension { #name : 'EpMethodModification' }

{ #category : '*MCP-IDE' }
EpMethodModification >> mcpMethodBeforeChange [

	^ self oldMethod
]

{ #category : '*MCP-IDE' }
EpMethodModification >> mcpVersionKind [

	^ 'modified'
]
