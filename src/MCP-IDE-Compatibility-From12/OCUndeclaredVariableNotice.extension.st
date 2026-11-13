Extension { #name : 'OCUndeclaredVariableNotice' }

{ #category : '*MCP-IDE-Compatibility-From12' }
OCUndeclaredVariableNotice >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP-IDE-Compatibility-From12' }
OCUndeclaredVariableNotice >> mcpNoticeNode [

	^ self node
]
