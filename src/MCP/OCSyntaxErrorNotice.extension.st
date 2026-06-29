Extension { #name : 'OCSyntaxErrorNotice' }

{ #category : '*MCP' }
OCSyntaxErrorNotice >> mcpErrorPosition [

	^ self position
]

{ #category : '*MCP' }
OCSyntaxErrorNotice >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]
