Extension { #name : 'OCUndeclaredVariableWarning' }

{ #category : '*MCP' }
OCUndeclaredVariableWarning >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP' }
OCUndeclaredVariableWarning >> mcpMethodNode [

	^ self methodNode
]

{ #category : '*MCP' }
OCUndeclaredVariableWarning >> mcpNoticeNode [

	^ PharoCompatibility undeclaredVariableNodeFromException: self
]
