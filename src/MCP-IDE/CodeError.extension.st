Extension { #name : 'CodeError' }

{ #category : '*MCP-IDE' }
CodeError >> mcpErrorPosition [

	^ self notice ifNil: [ self position ] ifNotNil: [ :syntaxNotice | syntaxNotice position ]
]

{ #category : '*MCP-IDE' }
CodeError >> mcpMethodNode [

	^ self methodNode
]

{ #category : '*MCP-IDE' }
CodeError >> mcpMutationFailureCauseForSyntaxNotice: aSyntaxNotice [

	^ self
]

{ #category : '*MCP-IDE' }
CodeError >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]
