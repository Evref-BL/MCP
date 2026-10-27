Extension { #name : 'OCUndeclaredVariableWarning' }

{ #category : '*MCP-IDE' }
OCUndeclaredVariableWarning >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP-IDE' }
OCUndeclaredVariableWarning >> mcpMethodNode [

	^ self methodNode
]

{ #category : '*MCP-IDE' }
OCUndeclaredVariableWarning >> mcpNoticeNode [

	^ self node
]
