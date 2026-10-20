Extension { #name : 'OCSyntaxErrorNotice' }

{ #category : '*MCP-Compatibility-From13' }
OCSyntaxErrorNotice >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP-Compatibility-From13' }
OCSyntaxErrorNotice >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]

{ #category : '*MCP-Compatibility-From13' }
OCSyntaxErrorNotice >> mcpSyntaxNotice [

	^ self
]
