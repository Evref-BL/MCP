Extension { #name : 'CodeError' }

{ #category : '*MCP-IDE-Compatibility-From12' }
CodeError >> mcpErrorPosition [

	^ self notice ifNil: [ self position ] ifNotNil: [ :syntaxNotice | syntaxNotice position ]
]

{ #category : '*MCP-IDE-Compatibility-From12' }
CodeError >> mcpMethodNode [

	^ self methodNode
]

{ #category : '*MCP-IDE-Compatibility-From12' }
CodeError >> mcpMutationFailureCauseForSyntaxNotice: aSyntaxNotice [

	^ self
]

{ #category : '*MCP-IDE-Compatibility-From12' }
CodeError >> mcpMutationFailureErrorCodeSuffix [

	^ 'SyntaxError'
]
