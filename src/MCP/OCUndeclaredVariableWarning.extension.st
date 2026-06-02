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
OCUndeclaredVariableWarning >> mcpMutationFailureNotice [

	^ self notice ifNil: [ self ]
]

{ #category : '*MCP' }
OCUndeclaredVariableWarning >> mcpNoticeNode [

	^ self node
]
