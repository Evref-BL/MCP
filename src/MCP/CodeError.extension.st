Extension { #name : 'CodeError' }

{ #category : '*MCP' }
CodeError >> mcpErrorPosition [

	^ self notice
		  ifNil: [ self position ]
		  ifNotNil: [ :syntaxNotice | syntaxNotice position ]
]

{ #category : '*MCP' }
CodeError >> mcpMethodNode [

	^ self methodNode
]

{ #category : '*MCP' }
CodeError >> mcpMutationFailureCauseForSyntaxNotice: aSyntaxNotice [

	^ self
]

{ #category : '*MCP' }
CodeError >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]
