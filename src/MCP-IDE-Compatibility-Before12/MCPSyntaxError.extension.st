Extension { #name : 'MCPSyntaxError' }

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPSyntaxError >> mcpErrorPosition [

	^ position
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPSyntaxError >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]

{ #category : '*MCP-IDE-Compatibility-Before12' }
MCPSyntaxError >> mcpSyntaxNotice [

	^ self
]
