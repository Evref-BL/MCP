Extension { #name : 'OCCompilationError' }

{ #category : '*MCP-Compatibility-From14' }
OCCompilationError >> mcpCompilationAst [

	^ self compilationResult ast
]

{ #category : '*MCP-Compatibility-From14' }
OCCompilationError >> mcpNoticeNode [

	^ self mcpCompilationAst variableNodes
		  detect: [ :node | node variable isNotNil and: [ node variable isUndeclaredVariable ] ]
		  ifNone: [ nil ]
]
