Extension { #name : 'OCUndeclaredVariableNotice' }

{ #category : '*MCP-IDE' }
OCUndeclaredVariableNotice >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP-IDE' }
OCUndeclaredVariableNotice >> mcpNoticeNode [

	^ self node
]
