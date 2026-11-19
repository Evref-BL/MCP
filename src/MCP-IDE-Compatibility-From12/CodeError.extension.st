Extension { #name : 'CodeError' }

{ #category : '*MCP-IDE-Compatibility-From12' }
CodeError >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP-IDE-Compatibility-From12' }
CodeError >> mcpMethodNode [

	^ self methodNode
]

{ #category : '*MCP-IDE-Compatibility-From12' }
CodeError >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]
